#!/usr/bin/env bash
#
# frontmatter.sh - Deterministic lint for skill naming + SKILL.md frontmatter
#
# Usage:
#   frontmatter.sh [<skill-file>] [--json|--quiet]
#
# If <skill-file> is omitted, it lints the default file inferred from this script path.
#
# Exit codes:
#   0 = Valid (may include warnings)
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
  echo "Usage: frontmatter.sh [<skill-file>] [--json|--quiet]"
  echo ""
  echo "Exit codes: 0=valid, 1=error, 2=warnings-only"
  exit 1
}

# Parse args
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

# Resolve target: single markdown file only
if [[ -z "${TARGET_PATH}" ]]; then
  # .../scripts/frontmatter.sh -> default skill file is ../SKILL.md
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  TARGET_PATH="${SCRIPT_DIR}/../SKILL.md"
fi

if [[ -d "${TARGET_PATH}" ]]; then
  log_error "Directory input is not supported; pass a markdown file path instead: ${TARGET_PATH}"
  exit 1
fi

if [[ ! -f "${TARGET_PATH}" ]]; then
  log_error "Skill file not found: ${TARGET_PATH}"
  if $JSON_MODE; then
    echo "{\"valid\":false,\"errors\":${ERRORS},\"warnings\":${WARNINGS},\"results\":[${RESULTS[*]}]}"
  fi
  exit 1
fi

TARGET_DIR="$(cd "$(dirname "${TARGET_PATH}")" 2>/dev/null && pwd)" || {
  log_error "Unable to resolve file directory: ${TARGET_PATH}"
  exit 1
}
TARGET_FILE="$(basename "${TARGET_PATH}")"

if [[ "${TARGET_FILE}" != *.md ]]; then
  log_error "Expected a markdown file (*.md): ${TARGET_FILE}"
  if $JSON_MODE; then
    echo "{\"valid\":false,\"errors\":${ERRORS},\"warnings\":${WARNINGS},\"results\":[${RESULTS[*]}]}"
  fi
  exit 1
fi

SKILL_MD="${TARGET_DIR}/${TARGET_FILE}"
if [[ "${TARGET_FILE}" == "SKILL.md" ]]; then
  SKILL_NAME="$(basename "${TARGET_DIR}")"
  NAME_SOURCE_LABEL="parent directory"
else
  SKILL_NAME="${TARGET_FILE%.md}"
  NAME_SOURCE_LABEL="file basename"
fi

# Expected skill name must be lowercase-hyphen
if [[ ! "${SKILL_NAME}" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  log_error "Invalid expected name '${SKILL_NAME}' derived from ${NAME_SOURCE_LABEL} (must be lowercase alphanumeric with single hyphens)"
else
  log_info "Expected name format ok from ${NAME_SOURCE_LABEL}: ${SKILL_NAME}"
fi

if [[ ! -f "${SKILL_MD}" ]]; then
  log_error "Skill file not found: ${SKILL_MD}"
  # Hard stop: cannot validate further
  if $JSON_MODE; then
    echo "{\"valid\":false,\"errors\":${ERRORS},\"warnings\":${WARNINGS},\"results\":[${RESULTS[*]}]}"
  fi
  exit 1
fi

CONTENT="$(cat "${SKILL_MD}")"

# Must start with YAML frontmatter fence on line 1
if [[ ! "${CONTENT}" =~ ^--- ]]; then
  log_error "${TARGET_FILE} must start with '---' (YAML frontmatter)"
  if $JSON_MODE; then
    echo "{\"valid\":false,\"errors\":${ERRORS},\"warnings\":${WARNINGS},\"results\":[${RESULTS[*]}]}"
  fi
  exit 1
fi

# Extract frontmatter using awk between first and second --- line
FRONTMATTER="$(awk '
  BEGIN{inside=0}
  /^---[[:space:]]*$/{
    if(inside==0){inside=1; next}
    else{exit}
  }
  inside==1{print}
' "${SKILL_MD}" || true)"

if [[ -z "${FRONTMATTER}" ]]; then
  log_error "Invalid frontmatter format (missing closing '---')"
  if $JSON_MODE; then
    echo "{\"valid\":false,\"errors\":${ERRORS},\"warnings\":${WARNINGS},\"results\":[${RESULTS[*]}]}"
  fi
  exit 1
fi

# Disallow XML tags in YAML (it is usually a copy/paste bug)
if [[ "${FRONTMATTER}" =~ \<[a-zA-Z]+\> ]]; then
  log_error "Frontmatter contains XML tags (YAML frontmatter must be YAML only)"
fi

# Extract name: allow quoted or unquoted single-line scalar
NAME="$(printf '%s\n' "${FRONTMATTER}" | sed -nE 's/^[[:space:]]*name:[[:space:]]*//p' | head -n 1 || true)"
NAME="${NAME%$'\r'}"
NAME="${NAME#\"}"; NAME="${NAME%\"}"
NAME="${NAME#\'}"; NAME="${NAME%\'}"

if [[ -z "${NAME}" ]]; then
  log_error "Missing 'name' field in frontmatter"
else
  if [[ ! "${NAME}" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    log_error "Invalid name format '${NAME}' (must be lowercase alphanumeric with single hyphens)"
  fi
  if [[ "${NAME}" != "${SKILL_NAME}" ]]; then
    log_error "Name mismatch: frontmatter '${NAME}' != expected '${SKILL_NAME}' (${NAME_SOURCE_LABEL})"
  else
    log_info "Frontmatter name matches expected name: ${NAME}"
  fi
  if [[ ${#NAME} -gt 64 ]]; then
    log_error "Name too long: ${#NAME} chars (max 64)"
  fi
fi

DESCRIPTION="$(printf '%s\n' "${FRONTMATTER}" | sed -nE 's/^[[:space:]]*description:[[:space:]]*//p' | head -n 1 || true)"
DESCRIPTION="${DESCRIPTION%$'\r'}"
DESCRIPTION="${DESCRIPTION#\"}"; DESCRIPTION="${DESCRIPTION%\"}"
DESCRIPTION="${DESCRIPTION#\'}"; DESCRIPTION="${DESCRIPTION%\'}"

if [[ -z "${DESCRIPTION}" ]]; then
  log_error "Missing 'description' field in frontmatter"
else
  log_info "Description present"
  if [[ ${#DESCRIPTION} -lt 20 ]]; then
    log_warning "Description is short (${#DESCRIPTION} chars), consider 50+ for reliable activation"
  elif [[ ${#DESCRIPTION} -gt 1024 ]]; then
    log_error "Description too long: ${#DESCRIPTION} chars (max 1024)"
  fi

  # Trigger phrase heuristic: “Use when …” or “Use for …”
  if [[ ! "${DESCRIPTION}" =~ [Uu]se[[:space:]]when ]] && [[ ! "${DESCRIPTION}" =~ [Uu]se[[:space:]]for ]]; then
    log_warning "Description lacks activation trigger phrase ('Use when ...' or 'Use for ...')"
  fi
fi

# Summary / JSON
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

if ! $JSON_MODE && ! $QUIET_MODE; then
  echo ""
  if [[ ${ERRORS} -eq 0 && ${WARNINGS} -eq 0 ]]; then
    echo -e "${GREEN}Naming/frontmatter lint: clean${NC}"
  elif [[ ${ERRORS} -eq 0 ]]; then
    echo -e "${YELLOW}Naming/frontmatter lint: ${WARNINGS} warning(s)${NC}"
  else
    echo -e "${RED}Naming/frontmatter lint: ${ERRORS} error(s), ${WARNINGS} warning(s)${NC}"
  fi
fi

if [[ ${ERRORS} -gt 0 ]]; then
  exit 1
elif [[ ${WARNINGS} -gt 0 ]]; then
  exit 2
else
  exit 0
fi
