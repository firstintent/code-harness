#!/bin/bash
# check-ownership.sh
# PreToolUse hook for multi-machine coordination.
# Prevents editing files owned by another machine's task.
#
# Only active when MACHINE_ID is set in environment.
# Skip this hook for single-machine setups by not setting MACHINE_ID.
#
# Exit 0 = allow, Exit 2 = block

# Skip if not in multi-machine mode
if [ -z "$MACHINE_ID" ]; then
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

TASKS_FILE="$CLAUDE_PROJECT_DIR/.harness/tasks.md"

# Skip if tasks.md doesn't exist
if [ ! -f "$TASKS_FILE" ]; then
  exit 0
fi

# Find the owns patterns for the current machine's claimed tasks
MY_OWNS=$(grep -A2 "claimed: $MACHINE_ID" "$TASKS_FILE" | grep "owns:" | sed 's/.*owns: //' | tr ',' '\n' | xargs)

# If current machine has no claimed tasks with owns, allow everything
if [ -z "$MY_OWNS" ]; then
  exit 0
fi

# Check if the file matches any of our owned patterns
MATCH=false
for pattern in $MY_OWNS; do
  # Use bash glob matching
  if [[ "$FILE_PATH" == $pattern ]]; then
    MATCH=true
    break
  fi
done

if [ "$MATCH" = true ]; then
  exit 0
fi

# File is not in our owns list. Check if it's owned by someone else.
ALL_OWNS=$(grep "owns:" "$TASKS_FILE" | sed 's/.*owns: //' | tr ',' '\n' | xargs)

IS_OWNED_BY_OTHER=false
for pattern in $ALL_OWNS; do
  if [[ "$FILE_PATH" == $pattern ]]; then
    IS_OWNED_BY_OTHER=true
    break
  fi
done

if [ "$IS_OWNED_BY_OTHER" = true ]; then
  echo "Blocked: $FILE_PATH is owned by another machine's task. Coordinate via .harness/decisions.md." >&2
  exit 2
fi

# File is not owned by anyone (shared file) — allow with warning
echo "Note: $FILE_PATH is a shared file. If this change affects other machines, write to .harness/decisions.md." >&2
exit 0
