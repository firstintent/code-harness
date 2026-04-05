#!/bin/bash
# install.sh — Install code-harness into an existing project
#
# Usage:
#   ./install.sh /path/to/your/project
#   ./install.sh --force --dashboard /path/to/project
#   curl -sSL https://raw.githubusercontent.com/firstintent/code-harness/main/install.sh | bash -s -- /path/to/project
#
# Options:
#   --force      Overwrite existing files
#   --dashboard  Also install dashboard.py
#   -h, --help   Show this help

set -e

usage() {
  echo "Usage: $0 [OPTIONS] /path/to/project"
  echo ""
  echo "Options:"
  echo "  --force      Overwrite existing files"
  echo "  --dashboard  Also install dashboard.py"
  echo "  -h, --help   Show this help"
}

# Parse args
FORCE=0
DASHBOARD=0
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)     FORCE=1; shift ;;
    --dashboard) DASHBOARD=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *)           TARGET="$1"; shift ;;
  esac
done

TARGET="${TARGET:-.}"

if [ ! -d "$TARGET" ]; then
  echo "Error: $TARGET is not a directory"
  exit 1
fi

# Resolve to absolute path
TARGET=$(cd "$TARGET" && pwd)

# Detect script source directory (works locally and via curl-pipe)
SELF="${BASH_SOURCE[0]:-$0}"
if [ -f "$SELF" ] && [ -d "$(dirname "$SELF")/.harness" ]; then
  SCRIPT_DIR=$(cd "$(dirname "$SELF")" && pwd)
else
  echo "Downloading code-harness..."
  TMPDIR=$(mktemp -d)
  trap "rm -rf $TMPDIR" EXIT
  git clone --depth 1 https://github.com/firstintent/code-harness.git "$TMPDIR/code-harness" 2>/dev/null
  SCRIPT_DIR="$TMPDIR/code-harness"
fi

echo "Installing code-harness into: $TARGET"
echo ""

# Track what we create vs skip
CREATED=()
SKIPPED=()

copy_file() {
  local src="$1"
  local dst="$2"
  local dir=$(dirname "$dst")

  mkdir -p "$dir"

  if [ -f "$dst" ] && [ "$FORCE" -eq 0 ]; then
    SKIPPED+=("$dst (already exists, use --force to overwrite)")
  else
    cp "$src" "$dst"
    CREATED+=("$dst")
  fi
}

# CLAUDE.md — only create if none exists (or --force)
if [ -f "$TARGET/CLAUDE.md" ] && [ "$FORCE" -eq 0 ]; then
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
  copy_file "$SCRIPT_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"
fi

# .claude/ files
copy_file "$SCRIPT_DIR/.claude/settings.json" "$TARGET/.claude/settings.json"
copy_file "$SCRIPT_DIR/.claude/agents/evaluator.md" "$TARGET/.claude/agents/evaluator.md"
copy_file "$SCRIPT_DIR/.claude/hooks/protect-arch.sh" "$TARGET/.claude/hooks/protect-arch.sh"
copy_file "$SCRIPT_DIR/.claude/hooks/check-ownership.sh" "$TARGET/.claude/hooks/check-ownership.sh"
copy_file "$SCRIPT_DIR/.claude/rules/playbook.md" "$TARGET/.claude/rules/playbook.md"
copy_file "$SCRIPT_DIR/.claude/rules/base-standards.md" "$TARGET/.claude/rules/base-standards.md"
copy_file "$SCRIPT_DIR/.claude/rules/api-quality.md" "$TARGET/.claude/rules/api-quality.md"
copy_file "$SCRIPT_DIR/.claude/rules/frontend-quality.md" "$TARGET/.claude/rules/frontend-quality.md"

# .harness/ files
copy_file "$SCRIPT_DIR/.harness/tasks.md" "$TARGET/.harness/tasks.md"
copy_file "$SCRIPT_DIR/.harness/decisions.md" "$TARGET/.harness/decisions.md"
copy_file "$SCRIPT_DIR/.harness/learned.md" "$TARGET/.harness/learned.md"
copy_file "$SCRIPT_DIR/.harness/inbox.md" "$TARGET/.harness/inbox.md"
copy_file "$SCRIPT_DIR/.harness/log.tsv" "$TARGET/.harness/log.tsv"
copy_file "$SCRIPT_DIR/.harness/architecture.md" "$TARGET/.harness/architecture.md"

# Dashboard (optional)
if [ "$DASHBOARD" -eq 1 ]; then
  copy_file "$SCRIPT_DIR/dashboard.py" "$TARGET/dashboard.py"
fi

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
  if [ -f "$SCRIPT_DIR/.gitignore" ]; then
    cp "$SCRIPT_DIR/.gitignore" "$GITIGNORE"
  else
    echo "# Code Harness (per-user, not shared)" > "$GITIGNORE"
    echo ".claude/memory.md" >> "$GITIGNORE"
    echo "CLAUDE.local.md" >> "$GITIGNORE"
    echo ".claude/settings.local.json" >> "$GITIGNORE"
  fi
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

if [ "$DASHBOARD" -eq 1 ]; then
  echo ""
  echo "Dashboard:"
  echo "  python dashboard.py $TARGET"
fi
