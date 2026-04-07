#!/usr/bin/env bash
#
# references.sh - Deterministic validation for local markdown links in SKILL.md and references/
#
# Usage:
#   references.sh [<skill-file>] [--json|--quiet]
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
  echo "Usage: references.sh [<skill-file>] [--json|--quiet]"
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
  # .../scripts/references.sh -> default skill file is ../SKILL.md
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
CONTEXT_DIR="${TARGET_DIR}"

if [[ ! -f "${SKILL_MD}" ]]; then
  log_error "Skill file not found: ${SKILL_MD}"
  exit 1
fi

display_path() {
  local file="$1"
  if [[ "${file}" == "${CONTEXT_DIR}/"* ]]; then
    echo "${file#${CONTEXT_DIR}/}"
    return 0
  fi
  echo "${file}"
}

is_within_context_dir() {
  local path="$1"
  if [[ "${path}" == "${CONTEXT_DIR}" || "${path}" == "${CONTEXT_DIR}/"* ]]; then
    return 0
  fi
  return 1
}

resolve_link_path() {
  local base_dir="$1"
  local target="$2"
  local link_dir
  local link_name

  link_dir="$(dirname "${target}")"
  link_name="$(basename "${target}")"

  set +e
  link_dir="$(cd "${base_dir}" 2>/dev/null && cd "${link_dir}" 2>/dev/null && pwd -P)"
  local rc=$?
  set -e
  if [[ ${rc} -ne 0 || -z "${link_dir}" ]]; then
    echo ""
    return 1
  fi

  echo "${link_dir}/${link_name}"
}

check_links_in_file() {
  local file="$1"
  local base_dir
  local target
  local full

  base_dir="$(cd "$(dirname "${file}")" && pwd)"

  # Extract markdown link targets from non-fenced code content only.
  # Skip http(s), mailto.
  while IFS= read -r link; do
    target="$(printf '%s' "${link}" | sed -nE 's/.*\(([^)]+)\).*/\1/p')"
    if [[ -z "${target}" ]]; then
      continue
    fi
    if [[ "${target}" == http* ]] || [[ "${target}" == mailto:* ]]; then
      continue
    fi

    # Normalize: drop anchors. Anchor-only links are valid in-file references.
    target="${target%%#*}"
    if [[ -z "${target}" ]]; then
      continue
    fi

    if ! full="$(resolve_link_path "${base_dir}" "${target}")"; then
      log_error "Broken link in $(display_path "${file}"): ${target}"
      continue
    fi

    if ! is_within_context_dir "${full}"; then
      log_error "Link target escapes skill directory in $(display_path "${file}"): ${target}"
      continue
    fi

    if [[ ! -e "${full}" ]]; then
      log_error "Broken link in $(display_path "${file}"): ${target}"
    fi
  done < <(
    awk '
      BEGIN { in_fence = 0 }
      /^```/ { in_fence = !in_fence; next }
      in_fence == 0 { print }
    ' "${file}" 2>/dev/null | grep -oE '\[[^]]+\]\([^)]+\)' || true
  )
}

check_links_in_file "${SKILL_MD}"

REFERENCES_DIR="${CONTEXT_DIR}/references"
if [[ -d "${REFERENCES_DIR}" ]]; then
  while IFS= read -r -d '' ref; do
    check_links_in_file "${ref}"
  done < <(find "${REFERENCES_DIR}" -name "*.md" -print0 2>/dev/null || true)
fi

if [[ ${ERRORS} -eq 0 ]]; then
  log_info "Reference/link validation passed"
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
