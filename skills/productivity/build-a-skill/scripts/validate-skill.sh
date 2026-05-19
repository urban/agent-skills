#!/usr/bin/env bash
#
# validate_skill.sh - Validate build-a-skill skill deterministically
#
# Usage:
#   validate_skill.sh <skill-dir> [--json|--quiet]
#
# <skill-dir> is required.
#
# Exit codes:
#   0 = Valid (clean)
#   1 = Error (invalid)
#   2 = Warnings only
#
set -euo pipefail

# Colors (disabled if not tty)
if [[ -t 1 ]]; then
  RED='\033[0;31m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'; NC='\033[0m'
else
  RED=''; YELLOW=''; GREEN=''; NC=''
fi

JSON_MODE=false
QUIET_MODE=false
TARGET_PATH=""
ERRORS=0
WARNINGS=0
LAST_RC=0
declare -a RESULTS=()
declare -a SKILL_FILES=()

log() {
  local level="$1"
  local message="$2"
  local color=""
  local prefix=""
  local to_stderr=false

  case "${level}" in
    error) ((ERRORS++)) || true; color="${RED}"; prefix="ERROR"; to_stderr=true ;;
    warning) ((WARNINGS++)) || true; color="${YELLOW}"; prefix="WARNING"; to_stderr=true ;;
    info) color="${GREEN}"; prefix="OK" ;;
    *) return 1 ;;
  esac

  if $JSON_MODE; then
    RESULTS+=("{\"level\":\"${level}\",\"message\":\"${message}\"}")
  elif ! $QUIET_MODE; then
    if $to_stderr; then
      echo -e "${color}${prefix}${NC}: ${message}" >&2
    else
      echo -e "${color}${prefix}${NC}: ${message}"
    fi
  fi
}

command_help() {
  echo "Usage: validate_skill.sh <skill-dir> [--json|--quiet]"
  echo "Exit codes: 0=valid, 1=error, 2=warnings-only"
  exit "${1:-1}"
}

collect_skill_files_in_dir() {
  local dir="$1"
  while IFS= read -r file; do
    [[ -n "${file}" ]] && SKILL_FILES+=("${file}")
  done < <(find "${dir}" -maxdepth 1 -type f -name "*.md" 2>/dev/null | LC_ALL=C sort)
}

run_linter() {
  local linter="$1"
  local target="$2"
  local args=("${linter}" "${target}")

  if $JSON_MODE; then
    args+=(--json)
  fi
  if $QUIET_MODE; then
    args+=(--quiet)
  fi

  set +e
  "${args[@]}" >/dev/null 2>&1
  LAST_RC=$?
  set -e
}

report_linter_result() {
  local rc="$1"
  local ok_message="$2"
  local warning_message="$3"
  local error_message="$4"
  local unexpected_message="$5"

  case "${rc}" in
    0) [[ -n "${ok_message}" ]] && log info "${ok_message}" ;;
    1) log error "${error_message}" ;;
    2) log warning "${warning_message}" ;;
    *) log error "${unexpected_message}" ;;
  esac
}

print_json_output() {
  echo "{"
  echo "  \"valid\": $([ ${ERRORS} -eq 0 ] && echo "true" || echo "false"),"
  echo "  \"errors\": ${ERRORS},"
  echo "  \"warnings\": ${WARNINGS},"
  echo "  \"results\": ["

  local first=true
  local result
  for result in "${RESULTS[@]}"; do
    if $first; then first=false; else echo ","; fi
    echo -n "    ${result}"
  done
  echo ""
  echo "  ]"
  echo "}"
}

SCRIPT_DIR=""
NAMING_LINTER=""
SECTION_LINTER=""
REFERENCES_LINTER=""
SIZE_CHECKS_LINTER=""
SKILL_DIR=""
SKILL_MD=""
SKILL_LABEL=""

validate_linter_executables() {
  local linter
  for linter in "${NAMING_LINTER}" "${SECTION_LINTER}" "${REFERENCES_LINTER}" "${SIZE_CHECKS_LINTER}"; do
    if [[ ! -x "${linter}" ]]; then
      log error "Missing or non-executable linter: ${linter}"
      return 1
    fi
  done
}

resolve_primary_skill_markdown() {
  collect_skill_files_in_dir "${SKILL_DIR}"
  if [[ ${#SKILL_FILES[@]} -eq 0 ]]; then
    log error "No markdown files found in ${SKILL_DIR}"
    return 1
  fi

  if [[ -f "${SKILL_DIR}/SKILL.md" ]]; then
    SKILL_MD="${SKILL_DIR}/SKILL.md"
  elif [[ ${#SKILL_FILES[@]} -eq 1 ]]; then
    SKILL_MD="${SKILL_FILES[0]}"
  else
    log error "Multiple markdown files found in ${SKILL_DIR} and SKILL.md is missing"
    return 1
  fi

  SKILL_LABEL="$(basename "${SKILL_MD}")"
}

validate_naming_and_frontmatter() {
  local skill_file display_file
  local naming_has_errors=false
  local naming_has_warnings=false

  for skill_file in "${SKILL_FILES[@]}"; do
    run_linter "${NAMING_LINTER}" "${skill_file}"
    display_file="${skill_file#${SKILL_DIR}/}"

    case "${LAST_RC}" in
      0) ;;
      1)
        naming_has_errors=true
        log error "Naming/frontmatter validation failed for ${display_file} (run scripts/frontmatter.sh for details)"
        ;;
      2)
        naming_has_warnings=true
        log warning "Naming/frontmatter validation has warnings for ${display_file} (run scripts/frontmatter.sh for details)"
        ;;
      *)
        naming_has_errors=true
        log error "Naming/frontmatter linter returned unexpected exit code ${LAST_RC} for ${display_file}"
        ;;
    esac
  done

  if ! $naming_has_errors && ! $naming_has_warnings; then
    log info "Naming/frontmatter validation passed for ${#SKILL_FILES[@]} file(s)"
  fi
}

run_size_check_and_log() {
  local target="$1"
  local check_type="$2"
  local output rc entry level message
  local parsed=false

  set +e
  output="$("${SIZE_CHECKS_LINTER}" "${target}" --type "${check_type}" --json 2>/dev/null)"
  rc=$?
  set -e

  while IFS= read -r entry; do
    [[ -z "${entry}" ]] && continue
    parsed=true
    level="$(printf '%s\n' "${entry}" | sed -nE 's/.*"level":"([^"]+)".*/\1/p')"
    message="$(printf '%s\n' "${entry}" | sed -nE 's/.*"message":"([^"]*)".*/\1/p')"
    if [[ -n "${level}" && -n "${message}" ]]; then
      log "${level}" "${message}"
    fi
  done < <(printf '%s\n' "${output}" | grep -oE '\{"level":"[^"]+","message":"[^"]*"\}' || true)

  if ! $parsed; then
    local display_target="${target#${SKILL_DIR}/}"
    case "${rc}" in
      0) ;;
      1) log error "Size validation failed for ${display_target} (run scripts/size-checks.sh --type ${check_type} for details)" ;;
      2) log warning "Size validation has warnings for ${display_target} (run scripts/size-checks.sh --type ${check_type} for details)" ;;
      *) log error "Size linter returned unexpected exit code ${rc} for ${display_target}" ;;
    esac
  fi
}

command_default() {
  local inputs_valid="$1"
  local dependencies_valid="$2"

  if [[ "${inputs_valid}" == "true" && "${dependencies_valid}" == "true" ]]; then
    validate_naming_and_frontmatter
    run_size_check_and_log "${SKILL_MD}" "skill"

    run_linter "${SECTION_LINTER}" "${SKILL_MD}"
    report_linter_result "${LAST_RC}" \
      "Section validation passed for ${SKILL_LABEL}" \
      "Section validation has warnings for ${SKILL_LABEL} (run scripts/structure.sh for details)" \
      "Section validation failed for ${SKILL_LABEL} (run scripts/structure.sh for details)" \
      "Section linter returned unexpected exit code ${LAST_RC} for ${SKILL_LABEL}"

    local references_dir ref
    references_dir="${SKILL_DIR}/references"
    if [[ -d "${references_dir}" ]]; then
      while IFS= read -r -d '' ref; do
        run_size_check_and_log "${ref}" "reference"
      done < <(find "${references_dir}" -name "*.md" -print0 2>/dev/null || true)
    fi

    run_linter "${REFERENCES_LINTER}" "${SKILL_MD}"
    report_linter_result "${LAST_RC}" \
      "Reference/link validation passed for ${SKILL_LABEL}" \
      "Reference/link validation has warnings for ${SKILL_LABEL} (run scripts/references.sh for details)" \
      "Reference/link validation failed for ${SKILL_LABEL} (run scripts/references.sh for details)" \
      "Reference/link linter returned unexpected exit code ${LAST_RC} for ${SKILL_LABEL}"
  fi

  if $JSON_MODE; then
    print_json_output
  elif ! $QUIET_MODE; then
    local summary_color="${GREEN}"
    local summary_text="Skill is valid"

    if [[ ${ERRORS} -gt 0 ]]; then
      summary_color="${RED}"
      summary_text="Skill has ${ERRORS} error(s) and ${WARNINGS} warning(s)"
    elif [[ ${WARNINGS} -gt 0 ]]; then
      summary_color="${YELLOW}"
      summary_text="Skill is valid with ${WARNINGS} warning(s)"
    fi

    echo ""
    echo -e "${summary_color}${summary_text}${NC}"
  fi
}

main() {
  # parse arguments
  local arg
  for arg in "$@"; do
    case "$arg" in
      --json) JSON_MODE=true ;;
      --quiet) QUIET_MODE=true ;;
      -h|--help) command_help 0 ;;
      -*)
        echo "Unknown option: $arg" >&2
        command_help 1
        ;;
      *)
        if [[ -n "${TARGET_PATH}" ]]; then
          echo "Only one <skill-dir> positional argument is supported" >&2
          command_help 1
        fi
        TARGET_PATH="$arg"
        ;;
    esac
  done

  if [[ -z "${TARGET_PATH}" ]]; then
    log error "Missing required argument: <skill-dir>"
    command_help 1
  fi

  local inputs_valid=true
  local dependencies_valid=true

  if [[ -d "${TARGET_PATH}" ]]; then
    SKILL_DIR="$(cd "${TARGET_PATH}" 2>/dev/null && pwd)" || {
      log error "Directory not found: ${TARGET_PATH}"
      inputs_valid=false
    }
  else
    if [[ -f "${TARGET_PATH}" ]]; then
      log error "Expected a skill directory, received file: ${TARGET_PATH}"
    else
      log error "Target directory not found: ${TARGET_PATH}"
    fi
    inputs_valid=false
  fi

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  NAMING_LINTER="${SCRIPT_DIR}/frontmatter.sh"
  SECTION_LINTER="${SCRIPT_DIR}/structure.sh"
  REFERENCES_LINTER="${SCRIPT_DIR}/references.sh"
  SIZE_CHECKS_LINTER="${SCRIPT_DIR}/size-checks.sh"

  if $inputs_valid && ! validate_linter_executables; then
    dependencies_valid=false
  fi
  if $inputs_valid && $dependencies_valid && ! resolve_primary_skill_markdown; then
    dependencies_valid=false
  fi

  command_default "${inputs_valid}" "${dependencies_valid}"

  if [[ ${ERRORS} -gt 0 ]]; then
      exit 1
  fi
  if [[ ${WARNINGS} -gt 0 ]]; then
      exit 2
  fi
  exit 0

}

main "$@"
