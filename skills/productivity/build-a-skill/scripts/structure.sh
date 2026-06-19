#!/usr/bin/env bash
#
# structure.sh - Deterministic validation for workflow and knowledge skill sections
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
    [[ "${section}" == "${target}" ]] && ((count++)) || true
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
    ((idx++)) || true
  done
  echo "-1"
}

count_present_sections() {
  local present=0
  local section
  for section in "$@"; do
    if [[ "$(count_section_occurrences "${section}")" -gt 0 ]]; then
      ((present++)) || true
    fi
  done
  echo "${present}"
}

validate_required_sections() {
  local section
  local count
  for section in "$@"; do
    count="$(count_section_occurrences "${section}")"
    if [[ "${count}" -eq 0 ]]; then
      log_error "Missing required section: ${section}"
    elif [[ "${count}" -gt 1 ]]; then
      log_error "Section appears multiple times (must be unique): ${section}"
    fi
  done
}

validate_optional_sections() {
  local section
  local count
  for section in "$@"; do
    count="$(count_section_occurrences "${section}")"
    if [[ "${count}" -gt 1 ]]; then
      log_error "Optional section appears multiple times (must be unique): ${section}"
    fi
  done
}

validate_disallowed_sections() {
  local section
  local count
  for section in "$@"; do
    count="$(count_section_occurrences "${section}")"
    if [[ "${count}" -gt 0 ]]; then
      log_error "Disallowed section: ${section}. Put subjective quality criteria in Deliverables for workflow skills and executable checks in Deterministic Validation. Knowledge skills should not use a validation checklist."
    fi
  done
}

validate_section_order() {
  local order_display="$1"
  shift

  local prev_idx=-1
  local prev_section=""
  local section
  local idx

  for section in "$@"; do
    idx="$(first_section_index "${section}")"
    if [[ "${idx}" -ge 0 ]]; then
      if [[ "${prev_idx}" -ge 0 && "${idx}" -lt "${prev_idx}" ]]; then
        log_error "Section order invalid: '${section}' appears before '${prev_section}'. Expected order: ${order_display}"
        break
      fi
      prev_idx="${idx}"
      prev_section="${section}"
    fi
  done
}

COMMON_REQUIRED_SECTIONS=(
  "Rules"
  "Constraints"
  "Gotchas"
)

WORKFLOW_ONLY_SECTIONS=(
  "Requirements"
  "Workflow"
  "Deliverables"
)

KNOWLEDGE_ONLY_SECTIONS=(
  "Knowledge Boundaries"
  "Patterns"
)

WORKFLOW_REQUIRED_SECTIONS=(
  "Rules"
  "Constraints"
  "Requirements"
  "Workflow"
  "Gotchas"
  "Deliverables"
)

KNOWLEDGE_REQUIRED_SECTIONS=(
  "Rules"
  "Constraints"
  "Knowledge Boundaries"
  "Patterns"
  "Gotchas"
)

OPTIONAL_SECTIONS=(
  "References"
  "Deterministic Validation"
)

DISALLOWED_SECTIONS=(
  "Validation Checklist"
)

WORKFLOW_ORDERED_SECTIONS=(
  "Rules"
  "Constraints"
  "Requirements"
  "Workflow"
  "Gotchas"
  "Deliverables"
  "References"
  "Deterministic Validation"
)

KNOWLEDGE_ORDERED_SECTIONS=(
  "Rules"
  "Constraints"
  "Knowledge Boundaries"
  "Patterns"
  "Gotchas"
  "References"
  "Deterministic Validation"
)

WORKFLOW_ORDER_DISPLAY="Rules -> Constraints -> Requirements -> Workflow -> Gotchas -> Deliverables -> References -> Deterministic Validation"
KNOWLEDGE_ORDER_DISPLAY="Rules -> Constraints -> Knowledge Boundaries -> Patterns -> Gotchas -> References -> Deterministic Validation"

validate_disallowed_sections "${DISALLOWED_SECTIONS[@]}"
validate_optional_sections "${OPTIONAL_SECTIONS[@]}"

WORKFLOW_MARKERS="$(count_present_sections "${WORKFLOW_ONLY_SECTIONS[@]}")"
KNOWLEDGE_MARKERS="$(count_present_sections "${KNOWLEDGE_ONLY_SECTIONS[@]}")"
CONTRACT="workflow"

if [[ "${WORKFLOW_MARKERS}" -gt 0 && "${KNOWLEDGE_MARKERS}" -gt 0 ]]; then
  log_error "Mixed section contracts: workflow sections (Requirements/Workflow/Deliverables) and knowledge sections (Knowledge Boundaries/Patterns) both appear. Split the skill or move secondary material into references/."
  CONTRACT="mixed"
elif [[ "${KNOWLEDGE_MARKERS}" -gt 0 ]]; then
  CONTRACT="knowledge"
fi

case "${CONTRACT}" in
  workflow)
    validate_required_sections "${WORKFLOW_REQUIRED_SECTIONS[@]}"
    validate_section_order "${WORKFLOW_ORDER_DISPLAY}" "${WORKFLOW_ORDERED_SECTIONS[@]}"
    ;;
  knowledge)
    validate_required_sections "${KNOWLEDGE_REQUIRED_SECTIONS[@]}"
    validate_section_order "${KNOWLEDGE_ORDER_DISPLAY}" "${KNOWLEDGE_ORDERED_SECTIONS[@]}"
    ;;
  mixed)
    validate_required_sections "${COMMON_REQUIRED_SECTIONS[@]}"
    ;;
esac

if [[ "${ERRORS}" -eq 0 ]]; then
  case "${CONTRACT}" in
    workflow) log_info "Section validation passed for workflow contract" ;;
    knowledge) log_info "Section validation passed for knowledge/capability contract" ;;
  esac
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
