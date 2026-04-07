#!/usr/bin/env bash
#
# structure.sh - Deterministic validation for required/optional sections
#
# Usage:
#   structure.sh [<skill-file>] [--json|--quiet]
#
# If <skill-file> is omitted, it validates the default file inferred from this script path.
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
  echo "Usage: structure.sh [<skill-file>] [--json|--quiet]"
  echo "Exit codes: 0=valid, 1=error, 2=warnings-only"
  exit 1
}

TARGET_PATH=""
for arg in "$@"; do
  case "$arg" in
    --json) JSON_MODE=true ;;
    --quiet) QUIET_MODE=true ;;
    -h|--help) usage ;;
    -*) echo "Unknown option: $arg"; usage ;;
    *) TARGET_PATH="$arg" ;;
  esac
done

if [[ -z "${TARGET_PATH}" ]]; then
  # .../scripts/structure.sh -> default skill file is ../SKILL.md
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  TARGET_PATH="${SCRIPT_DIR}/../SKILL.md"
fi

if [[ -d "${TARGET_PATH}" ]]; then
  log_error "Directory input is not supported; pass a markdown file path instead: ${TARGET_PATH}"
  exit 1
fi

if [[ ! -f "${TARGET_PATH}" ]]; then
  log_error "Skill file not found: ${TARGET_PATH}"
  exit 1
fi

TARGET_DIR="$(cd "$(dirname "${TARGET_PATH}")" 2>/dev/null && pwd)" || {
  log_error "Unable to resolve file directory: ${TARGET_PATH}"
  exit 1
}
TARGET_FILE="$(basename "${TARGET_PATH}")"

if [[ "${TARGET_FILE}" != *.md ]]; then
  log_error "Expected a markdown file (*.md): ${TARGET_FILE}"
  exit 1
fi

SKILL_MD="${TARGET_DIR}/${TARGET_FILE}"

# Section presence/order checks (top-level ## headings only, outside fenced code blocks)
TOP_LEVEL_SECTIONS=()
while IFS= read -r section; do
  [[ -n "${section}" ]] && TOP_LEVEL_SECTIONS+=("${section}")
done < <(
  awk '
    BEGIN { in_fence = 0 }
    /^```/ { in_fence = !in_fence; next }
    in_fence == 0 && /^##[[:space:]]+/ {
      line = $0
      sub(/^##[[:space:]]+/, "", line)
      gsub(/[[:space:]]+$/, "", line)
      print line
    }
  ' "${SKILL_MD}" 2>/dev/null
)

count_section_occurrences() {
  local target="$1"
  local count=0
  local section
  for section in "${TOP_LEVEL_SECTIONS[@]}"; do
    [[ "${section}" == "${target}" ]] && ((count++))
  done
  echo "${count}"
}

first_section_index() {
  local target="$1"
  local idx=0
  local section
  for section in "${TOP_LEVEL_SECTIONS[@]}"; do
    if [[ "${section}" == "${target}" ]]; then
      echo "${idx}"
      return 0
    fi
    ((idx++))
  done
  echo "-1"
}

REQUIRED_SECTIONS=(
  "Rules"
  "Constraints"
  "Requirements"
  "Workflow"
  "Gotchas"
  "Deliverables"
  "Validation Checklist"
)

OPTIONAL_SECTIONS=(
  "References"
  "Deterministic Validation"
)

ORDERED_SECTIONS=(
  "Rules"
  "Constraints"
  "Requirements"
  "Workflow"
  "Gotchas"
  "Deliverables"
  "References"
  "Validation Checklist"
  "Deterministic Validation"
)

ORDER_DISPLAY="Rules -> Constraints -> Requirements -> Workflow -> Gotchas -> Deliverables -> References -> Validation Checklist -> Deterministic Validation"

for section in "${REQUIRED_SECTIONS[@]}"; do
  count="$(count_section_occurrences "${section}")"
  if [[ "${count}" -eq 0 ]]; then
    log_error "Missing required section: ${section}"
  elif [[ "${count}" -gt 1 ]]; then
    log_error "Section appears multiple times (must be unique): ${section}"
  fi
done

for section in "${OPTIONAL_SECTIONS[@]}"; do
  count="$(count_section_occurrences "${section}")"
  if [[ "${count}" -gt 1 ]]; then
    log_error "Optional section appears multiple times (must be unique): ${section}"
  fi
done

prev_idx=-1
prev_section=""
for section in "${ORDERED_SECTIONS[@]}"; do
  idx="$(first_section_index "${section}")"
  if [[ "${idx}" -ge 0 ]]; then
    if [[ "${prev_idx}" -ge 0 && "${idx}" -lt "${prev_idx}" ]]; then
      log_error "Section order invalid: '${section}' appears before '${prev_section}'. Expected order: ${ORDER_DISPLAY}"
      break
    fi
    prev_idx="${idx}"
    prev_section="${section}"
  fi
done

if [[ "${ERRORS}" -eq 0 ]]; then
  log_info "Section presence and ordering validation passed"
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
