#!/bin/bash
# protect-arch.sh
# PreToolUse hook that enforces architectural boundaries.
# Edit the RULES array below to match your project's architecture.
#
# Exit 0 = allow, Exit 2 = block (feedback sent to Claude)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty')

# Skip if no file path (e.g. new file creation without path yet)
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# ============================================================
# ARCHITECTURE RULES
# Add your project-specific rules below.
# Each rule: source pattern, forbidden import pattern, message
# ============================================================

# Example: UI layer cannot import from service layer directly
if [[ "$FILE_PATH" == src/ui/* ]] || [[ "$FILE_PATH" == src/components/* ]]; then
  if echo "$CONTENT" | grep -qE "from.*['\"].*service|import.*service"; then
    echo "Architecture violation: UI layer cannot import from service layer directly. Use providers or hooks for data access." >&2
    exit 2
  fi
fi

# Example: API handlers cannot import UI components
if [[ "$FILE_PATH" == src/api/* ]] || [[ "$FILE_PATH" == src/routes/* ]]; then
  if echo "$CONTENT" | grep -qE "from.*['\"].*components|import.*components"; then
    echo "Architecture violation: API layer cannot import UI components." >&2
    exit 2
  fi
fi

# Example: No direct database calls outside repo/dal layer
# Uncomment and adjust for your project:
# if [[ "$FILE_PATH" != src/repo/* ]] && [[ "$FILE_PATH" != src/dal/* ]]; then
#   if echo "$CONTENT" | grep -qE "\.query\(|\.execute\(|SELECT.*FROM|INSERT.*INTO"; then
#     echo "Architecture violation: Direct database calls only allowed in src/repo/ or src/dal/. Use repository pattern." >&2
#     exit 2
#   fi
# fi

exit 0
