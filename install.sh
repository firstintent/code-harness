#!/bin/bash
# install.sh — Install code-harness into an existing project
#
# Usage:
#   ./install.sh /path/to/your/project
#   ./install.sh .                      # current directory
#
# This script copies the harness files without overwriting existing ones.
# After install, start Claude Code and say:
#   "Read the codebase and update .harness/architecture.md and .claude/hooks/protect-arch.sh"

set -e

TARGET="${1:-.}"

if [ ! -d "$TARGET" ]; then
  echo "Error: $TARGET is not a directory"
  exit 1
fi

# Resolve to absolute path
TARGET=$(cd "$TARGET" && pwd)
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

echo "Installing code-harness into: $TARGET"
echo ""

# Track what we create vs skip
CREATED=()
SKIPPED=()

copy_if_missing() {
  local src="$1"
  local dst="$2"
  local dir=$(dirname "$dst")
  
  mkdir -p "$dir"
  
  if [ -f "$dst" ]; then
    SKIPPED+=("$dst (already exists)")
  else
    cp "$src" "$dst"
    CREATED+=("$dst")
  fi
}

# CLAUDE.md — only create if none exists
if [ -f "$TARGET/CLAUDE.md" ]; then
  echo "⚠  CLAUDE.md already exists. Adding harness imports to the end."
  
  # Check if harness imports are already there
  if ! grep -q ".harness/learned.md" "$TARGET/CLAUDE.md" 2>/dev/null; then
    echo "" >> "$TARGET/CLAUDE.md"
    echo "# Code Harness" >> "$TARGET/CLAUDE.md"
    echo "Follow the playbook in .claude/rules/playbook.md for all tasks." >> "$TARGET/CLAUDE.md"
    echo "When evaluating work, check all rules in .claude/rules/ that match current file paths." >> "$TARGET/CLAUDE.md"
    echo "Track reject/accept signals in .harness/log.tsv." >> "$TARGET/CLAUDE.md"
    echo "" >> "$TARGET/CLAUDE.md"
    echo "@.harness/learned.md" >> "$TARGET/CLAUDE.md"
    echo "@.harness/architecture.md" >> "$TARGET/CLAUDE.md"
    CREATED+=("CLAUDE.md (appended harness section)")
  else
    SKIPPED+=("CLAUDE.md (harness imports already present)")
  fi
else
  copy_if_missing "$SCRIPT_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"
fi

# .claude/ files
copy_if_missing "$SCRIPT_DIR/.claude/settings.json" "$TARGET/.claude/settings.json"
copy_if_missing "$SCRIPT_DIR/.claude/agents/evaluator.md" "$TARGET/.claude/agents/evaluator.md"
copy_if_missing "$SCRIPT_DIR/.claude/hooks/protect-arch.sh" "$TARGET/.claude/hooks/protect-arch.sh"
copy_if_missing "$SCRIPT_DIR/.claude/hooks/check-ownership.sh" "$TARGET/.claude/hooks/check-ownership.sh"
copy_if_missing "$SCRIPT_DIR/.claude/rules/playbook.md" "$TARGET/.claude/rules/playbook.md"
copy_if_missing "$SCRIPT_DIR/.claude/rules/base-standards.md" "$TARGET/.claude/rules/base-standards.md"
copy_if_missing "$SCRIPT_DIR/.claude/rules/api-quality.md" "$TARGET/.claude/rules/api-quality.md"
copy_if_missing "$SCRIPT_DIR/.claude/rules/frontend-quality.md" "$TARGET/.claude/rules/frontend-quality.md"

# .harness/ files
copy_if_missing "$SCRIPT_DIR/.harness/tasks.md" "$TARGET/.harness/tasks.md"
copy_if_missing "$SCRIPT_DIR/.harness/decisions.md" "$TARGET/.harness/decisions.md"
copy_if_missing "$SCRIPT_DIR/.harness/learned.md" "$TARGET/.harness/learned.md"
copy_if_missing "$SCRIPT_DIR/.harness/inbox.md" "$TARGET/.harness/inbox.md"
copy_if_missing "$SCRIPT_DIR/.harness/log.tsv" "$TARGET/.harness/log.tsv"
copy_if_missing "$SCRIPT_DIR/.harness/architecture.md" "$TARGET/.harness/architecture.md"

# Make hooks executable
chmod +x "$TARGET/.claude/hooks/"*.sh 2>/dev/null

# Add to .gitignore
GITIGNORE="$TARGET/.gitignore"
if [ -f "$GITIGNORE" ]; then
  if ! grep -q ".claude/memory.md" "$GITIGNORE" 2>/dev/null; then
    echo "" >> "$GITIGNORE"
    echo "# Code Harness (per-user, not shared)" >> "$GITIGNORE"
    echo ".claude/memory.md" >> "$GITIGNORE"
    echo "CLAUDE.local.md" >> "$GITIGNORE"
    echo ".claude/settings.local.json" >> "$GITIGNORE"
    CREATED+=(".gitignore (appended harness entries)")
  fi
else
  cp "$SCRIPT_DIR/.gitignore" "$GITIGNORE"
  CREATED+=(".gitignore")
fi

echo ""
echo "Created:"
for f in "${CREATED[@]}"; do
  echo "  ✓ $f"
done

if [ ${#SKIPPED[@]} -gt 0 ]; then
  echo ""
  echo "Skipped:"
  for f in "${SKIPPED[@]}"; do
    echo "  - $f"
  done
fi

echo ""
echo "Next steps:"
echo "  1. cd $TARGET"
echo "  2. Edit .claude/hooks/protect-arch.sh for your architecture"
echo "  3. Start Claude Code: claude"
echo "  4. Say: \"Read the codebase, update .harness/architecture.md, adjust .claude/rules/ paths\""
echo ""
echo "Or write tasks in .harness/tasks.md and say: \"Execute tasks\""
