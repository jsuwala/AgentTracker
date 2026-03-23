#!/usr/bin/env bash

set -euo pipefail

AGENT_TRACKER_OWNER="${AGENT_TRACKER_OWNER:-jsuwala}"
AGENT_TRACKER_REPO="${AGENT_TRACKER_REPO:-AgentTracker}"
AGENT_TRACKER_REF="${AGENT_TRACKER_REF:-main}"
AGENT_TRACKER_SOURCE_ROOT="${AGENT_TRACKER_SOURCE_ROOT:-}"
AGENT_TRACKER_BASE_URL="${AGENT_TRACKER_BASE_URL:-}"

if [[ -n "${AGENT_TRACKER_TARGET_ROOT:-}" ]]; then
  TARGET_ROOT="${AGENT_TRACKER_TARGET_ROOT}"
elif command -v git >/dev/null 2>&1; then
  if TARGET_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    :
  else
    TARGET_ROOT="$(pwd)"
  fi
else
  TARGET_ROOT="$(pwd)"
fi

if [[ -n "$AGENT_TRACKER_SOURCE_ROOT" && -n "$AGENT_TRACKER_BASE_URL" ]]; then
  echo "Set only one of AGENT_TRACKER_SOURCE_ROOT or AGENT_TRACKER_BASE_URL." >&2
  exit 1
fi

if [[ -z "$AGENT_TRACKER_SOURCE_ROOT" && -z "$AGENT_TRACKER_BASE_URL" ]]; then
  AGENT_TRACKER_BASE_URL="https://raw.githubusercontent.com/${AGENT_TRACKER_OWNER}/${AGENT_TRACKER_REPO}/${AGENT_TRACKER_REF}"
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

REQUIRED_DIRECTORIES=(
  ".claude"
  ".claude/skills"
  ".claude/skills/PRD"
  ".claude/skills/PRDJsonReviewer"
  ".claude/skills/PRDReview"
  ".claude/skills/PRDToAgentTracking"
  "AgentTracker"
  "AgentTracker/PRDs"
  "AgentTracker/active"
  "AgentTracker/archive"
  "AgentTracker/artifacts"
)

MANAGED_FILES=(
  ".claude/skills/PRD/SKILL.md:.claude/skills/PRD/SKILL.md:644"
  ".claude/skills/PRDJsonReviewer/SKILL.md:.claude/skills/PRDJsonReviewer/SKILL.md:644"
  ".claude/skills/PRDReview/SKILL.md:.claude/skills/PRDReview/SKILL.md:644"
  ".claude/skills/PRDToAgentTracking/SKILL.md:.claude/skills/PRDToAgentTracking/SKILL.md:644"
  "AgentTracker/prompt.md:AgentTracker/prompt.md:644"
  "AgentTracker/run-agent-loop-claude.sh:AgentTracker/run-agent-loop-claude.sh:755"
)

require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required command not found: $command_name" >&2
    exit 1
  fi
}

download_file() {
  local url="$1"
  local destination="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$destination"
    return
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -qO "$destination" "$url"
    return
  fi

  echo "curl or wget is required to install AgentTracker assets." >&2
  exit 1
}

stage_source_file() {
  local source_relative_path="$1"
  local staged_file="$2"

  if [[ -n "$AGENT_TRACKER_SOURCE_ROOT" ]]; then
    local source_file="${AGENT_TRACKER_SOURCE_ROOT%/}/${source_relative_path}"
    if [[ ! -f "$source_file" ]]; then
      echo "Missing source file: $source_file" >&2
      exit 1
    fi
    cp "$source_file" "$staged_file"
    return
  fi

  download_file "${AGENT_TRACKER_BASE_URL%/}/${source_relative_path}" "$staged_file"
}

resolve_playwright_cli() {
  local npm_prefix
  local npm_global_bin

  if command -v playwright-cli >/dev/null 2>&1; then
    command -v playwright-cli
    return
  fi

  npm_prefix="$(npm prefix -g 2>/dev/null || true)"
  npm_global_bin="${npm_prefix%/}/bin/playwright-cli"

  if [[ -x "$npm_global_bin" ]]; then
    echo "$npm_global_bin"
    return
  fi

  echo "playwright-cli is not available on PATH after npm installation." >&2
  echo "Add your npm global bin directory to PATH and rerun InstallOrUpdate.sh." >&2
  exit 1
}

ensure_directories() {
  local relative_path

  for relative_path in "${REQUIRED_DIRECTORIES[@]}"; do
    mkdir -p "${TARGET_ROOT%/}/${relative_path}"
  done
}

sync_file() {
  local source_relative_path="$1"
  local destination_relative_path="$2"
  local mode="$3"
  local destination_path="${TARGET_ROOT%/}/${destination_relative_path}"
  local staged_file="${TMP_DIR}/$(basename "$destination_relative_path").$$"
  local status="installed"

  stage_source_file "$source_relative_path" "$staged_file"

  mkdir -p "$(dirname "$destination_path")"

  if [[ -f "$destination_path" ]]; then
    if cmp -s "$staged_file" "$destination_path"; then
      status="unchanged"
    else
      status="updated"
    fi
  fi

  if [[ "$status" != "unchanged" ]]; then
    mv "$staged_file" "$destination_path"
  else
    rm -f "$staged_file"
  fi

  chmod "$mode" "$destination_path"
  printf "%-10s %s\n" "$status" "$destination_relative_path"
}

cleanup_legacy_review_skill() {
  local legacy_skill_dir="${TARGET_ROOT%/}/.claude/skills/PRDReviewer"

  if [[ -e "$legacy_skill_dir" ]]; then
    rm -rf "$legacy_skill_dir"
    printf "%-10s %s\n" "removed" ".claude/skills/PRDReviewer"
  fi
}

install_playwright_cli() {
  echo "Installing Playwright CLI globally..."
  require_command npm
  npm install -g @playwright/cli@latest
  hash -r 2>/dev/null || true
}

install_playwright_skills() {
  local playwright_cli_bin="$1"

  echo "Installing Playwright CLI skills into: $TARGET_ROOT"
  (
    cd "$TARGET_ROOT"
    "$playwright_cli_bin" install --skills
  )
}

main() {
  local file_spec
  local source_relative_path
  local destination_relative_path
  local mode
  local playwright_cli_bin

  echo "Installing AgentTracker assets into: $TARGET_ROOT"
  ensure_directories

  for file_spec in "${MANAGED_FILES[@]}"; do
    IFS=":" read -r source_relative_path destination_relative_path mode <<< "$file_spec"
    sync_file "$source_relative_path" "$destination_relative_path" "$mode"
  done

  cleanup_legacy_review_skill
  install_playwright_cli
  playwright_cli_bin="$(resolve_playwright_cli)"
  install_playwright_skills "$playwright_cli_bin"

  echo "AgentTracker install/update complete."
}

main "$@"
