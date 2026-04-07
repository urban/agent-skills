#!/usr/bin/env bash
#
# size-checks.sh - Deterministic markdown size checks
#
# Usage:
#   size-checks.sh <markdown-file> --type <skill|reference> [--json|--quiet]
#
# Exit codes:
#   0 = Valid (clean)
#   1 = Error (invalid)
#   2 = Warnings only
#
set -euo pipefail

# Colors (disabled if not tty)
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  YELLOW='\033[0;33m'
  GREEN='\033[0;32m'
  NC='\033[0m'
else
  RED='' YELLOW='' GREEN='' NC=''
fi

JSON_MODE=false
QUIET_MODE=false
TARGET_PATH=""
CHECK_TYPE=""
ERRORS=0
WARNINGS=0
declare -a RESULTS=()

log_error() {
  ((ERRORS++)) || true
  if $JSON_MODE; then
    RESULTS+=("{\"level\":\"error\",\"message\":\"$1\"}")
  elif ! $QUIET_MODE; then
    echo -e "${RED}ERROR${NC}: $1" >&2
  fi
}

log_warning() {
  ((WARNINGS++)) || true
  if $JSON_MODE; then
    RESULTS+=("{\"level\":\"warning\",\"message\":\"$1\"}")
  elif ! $QUIET_MODE; then
    echo -e "${YELLOW}WARNING${NC}: $1" >&2
  fi
}

log_info() {
  if $JSON_MODE; then
    RESULTS+=("{\"level\":\"info\",\"message\":\"$1\"}")
  elif ! $QUIET_MODE; then
    echo -e "${GREEN}OK${NC}: $1"
  fi
}

usage() {
  echo "Usage: size-checks.sh <markdown-file> --type <skill|reference> [--json|--quiet]"
  echo "Exit codes: 0=valid, 1=error, 2=warnings-only"
  exit "${1:-1}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_MODE=true ;;
    --quiet|--quite) QUIET_MODE=true ;;
    --type)
      shift
      [[ $# -gt 0 ]] || usage 1
      CHECK_TYPE="$1"
      ;;
    -h|--help) usage 0 ;;
    -*)
      echo "Unknown option: $1" >&2
      usage 1
      ;;
    *)
      if [[ -n "${TARGET_PATH}" ]]; then
        echo "Only one <markdown-file> positional argument is supported" >&2
        usage 1
      fi
      TARGET_PATH="$1"
      ;;
  esac
  shift
done

if [[ -z "${TARGET_PATH}" ]]; then
  log_error "Missing required argument: <markdown-file>"
  usage 1
fi
if [[ -z "${CHECK_TYPE}" ]]; then
  log_error "Missing required option: --type <skill|reference>"
  usage 1
fi
if [[ "${CHECK_TYPE}" != "skill" && "${CHECK_TYPE}" != "reference" ]]; then
  log_error "Invalid --type value '${CHECK_TYPE}' (expected 'skill' or 'reference')"
  usage 1
fi
if [[ -d "${TARGET_PATH}" ]]; then
  log_error "Directory input is not supported; pass a markdown file path instead: ${TARGET_PATH}"
  exit 1
fi
if [[ ! -f "${TARGET_PATH}" ]]; then
  log_error "Markdown file not found: ${TARGET_PATH}"
  exit 1
fi

TARGET_DIR="$(cd "$(dirname "${TARGET_PATH}")" 2>/dev/null && pwd)" || {
  log_error "Unable to resolve file directory: ${TARGET_PATH}"
  exit 1
}
TARGET_FILE="$(basename "${TARGET_PATH}")"
TARGET_MD="${TARGET_DIR}/${TARGET_FILE}"

if [[ "${TARGET_FILE}" != *.md ]]; then
  log_error "Expected a markdown file (*.md): ${TARGET_FILE}"
  exit 1
fi

LINE_COUNT="$(wc -l < "${TARGET_MD}" | tr -d ' ')"
if [[ "${CHECK_TYPE}" == "skill" ]]; then
  if [[ "${LINE_COUNT}" -gt 500 ]]; then
    log_warning "${TARGET_FILE} has ${LINE_COUNT} lines, recommend splitting into references/ for progressive disclosure"
  elif [[ "${LINE_COUNT}" -gt 200 ]]; then
    log_info "${TARGET_FILE} is ${LINE_COUNT} lines"
  fi
else
  if [[ "${LINE_COUNT}" -gt 200 ]]; then
    log_warning "${TARGET_FILE} has ${LINE_COUNT} lines, consider splitting"
  fi
fi

if $JSON_MODE; then
  echo "{"
  echo "  \"valid\": $([ ${ERRORS} -eq 0 ] && echo "true" || echo "false"),"
  echo "  \"errors\": ${ERRORS},"
  echo "  \"warnings\": ${WARNINGS},"
  echo "  \"results\": ["
  first=true
  for r in "${RESULTS[@]}"; do
    if $first; then first=false; else echo ","; fi
    echo -n "    ${r}"
  done
  echo ""
  echo "  ]"
  echo "}"
fi

if [[ ${ERRORS} -gt 0 ]]; then
  exit 1
elif [[ ${WARNINGS} -gt 0 ]]; then
  exit 2
else
  exit 0
fi
