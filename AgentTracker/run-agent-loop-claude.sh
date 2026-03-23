#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop (Claude-only)
# Usage: ./run-agent-loop-claude.sh [max_iterations]

set -e

echo "Updating Claude CLI to the latest version..."
claude update

# Parse arguments
MAX_ITERATIONS=10

while [[ $# -gt 0 ]]; do
  case $1 in
    *)
      # Assume it's max_iterations if it's a number
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS="$1"
      fi
      shift
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/active/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/active/progress.txt"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"
ACTIVE_DIR="$SCRIPT_DIR/active"
ENV_FILE="$SCRIPT_DIR/../.env"
MAX_ATTEMPTS=2

mkdir -p "$ACTIVE_DIR"

read_env_value() {
  local key="$1"
  awk -v k="$key" '
    /^[[:space:]]*#/ { next }
    {
      line = $0
      sub(/^[[:space:]]*export[[:space:]]+/, "", line)
      if (line ~ "^[[:space:]]*" k "[[:space:]]*=") {
        sub("^[[:space:]]*" k "[[:space:]]*=", "", line)
        sub(/\r$/, "", line)
        print line
        exit
      }
    }
  ' "$ENV_FILE"
}

load_env_vars_from_file() {
  if [ ! -f "$ENV_FILE" ]; then
    echo "Warning: .env file not found at $ENV_FILE"
    return 1
  fi

  for var in \
    ANTHROPIC_FOUNDRY_RESOURCE \
    CLAUDE_CODE_USE_FOUNDRY \
    ANTHROPIC_FOUNDRY_API_KEY \
    ANTHROPIC_DEFAULT_SONNET_MODEL \
    ANTHROPIC_DEFAULT_HAIKU_MODEL \
    ANTHROPIC_DEFAULT_OPUS_MODEL; do
    value="$(read_env_value "$var")"
    if [ -n "$value" ]; then
      case "$value" in
        \"*\"|\'*\')
          value="${value#\"}"
          value="${value%\"}"
          value="${value#\'}"
          value="${value%\'}"
          ;;
      esac
      export "$var=$value"
      echo "Loaded $var from .env"
    else
      echo "Warning: $var not set in $ENV_FILE"
    fi
  done
}

# Archive previous run if branch changed
if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")
  
  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
    # Archive the previous run
    DATE=$(date +%Y-%m-%d)
    # Strip "AgentTracker/" prefix from branch name for folder
    FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^AgentTracker/||')
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"
    
    echo "Archiving previous run: $LAST_BRANCH"
    mkdir -p "$ARCHIVE_FOLDER"
    [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
    echo "   Archived to: $ARCHIVE_FOLDER"
    
    # Reset progress file for new run
    echo "# AgentTracker Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
  fi
fi

# Track current branch
if [ -f "$PRD_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  if [ -n "$CURRENT_BRANCH" ]; then
    echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
  fi
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# AgentTracker Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

echo "Starting AgentTracker - Claude CLI - Max iterations: $MAX_ITERATIONS"

for i in $(seq 1 $MAX_ITERATIONS); do
  ITERATION_STARTED_AT=$(date '+%Y-%m-%d %H:%M:%S %Z')
  echo ""
  echo "========================================================================================"
  echo "  AgentTracker Iteration $i of $MAX_ITERATIONS (claude) - Started: $ITERATION_STARTED_AT"
  echo "========================================================================================"

  echo "!!! NOTE: Claude does not output anything until completion of the iteration."

  ATTEMPT=1
  CLAUDE_OUTPUT=""
  while true; do
    if [[ "$ATTEMPT" -gt 1 ]]; then
      echo "----- Retrying after limit hit at $(date) -----"
    fi

    # Claude Code: use --dangerously-skip-permissions for autonomous operation, --print for output
    CLAUDE_OUTPUT="$(claude --dangerously-skip-permissions --verbose --print < "$SCRIPT_DIR/prompt.md" 2>&1 | tee /dev/stderr || true)"

    if grep -qi "hit your limit" <<< "$CLAUDE_OUTPUT"; then
      if [[ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]]; then
        echo "Limit hit again after $MAX_ATTEMPTS attempts; continuing to next iteration."
        break
      fi
      echo "Detected limit message. Loading .env values and retrying iteration..."
      load_env_vars_from_file || true
      ATTEMPT=$((ATTEMPT + 1))
      continue
    fi
    break
  done
  
  # Check for completion signal
  if grep -q "<promise>COMPLETE</promise>" <<< "$CLAUDE_OUTPUT"; then
    echo ""
    echo "AgentTracker completed all tasks!"
    echo "Completed at iteration $i of $MAX_ITERATIONS"
    exit 0
  fi
  
  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "AgentTracker reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "Check $PROGRESS_FILE for status."
exit 1
