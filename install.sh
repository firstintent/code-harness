#!/bin/bash
# install.sh — Install or update code-harness in a project
#
# Usage:
#   ./install.sh /path/to/project                  # First install
#   ./install.sh --update /path/to/project          # Update framework files only
#   ./install.sh --force --dashboard /path/to/project
#   curl -sSL https://raw.githubusercontent.com/firstintent/code-harness/main/install.sh | bash -s -- /path/to/project
#
# Options:
#   --update     Update framework files (.claude/harness/) only, skip user files
#   --force      Overwrite all files including user files
#   --dashboard  Also install dashboard.py
#   -h, --help   Show this help

set -e

usage() {
  echo "Usage: $0 [OPTIONS] [/path/to/project]"
  echo ""
  echo "Options:"
  echo "  --update     Update framework files only (safe, won't touch your customizations)"
  echo "  --force      Overwrite ALL files including user customizations"
  echo "  --dashboard  Also install dashboard.py"
  echo "  --version    Show installed version"
  echo "  -h, --help   Show this help"
  echo ""
  echo "File ownership:"
  echo "  .claude/harness/  — framework (updated by --update)"
  echo "  .claude/rules/    — yours (never overwritten by --update)"
  echo "  .claude/hooks/    — yours (never overwritten by --update)"
  echo "  .harness/         — yours (never overwritten by --update)"
}

# Parse args
FORCE=0
UPDATE=0
DASHBOARD=0
SHOW_VERSION=0
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)     FORCE=1; shift ;;
    --update)    UPDATE=1; shift ;;
    --dashboard) DASHBOARD=1; shift ;;
    --version)   SHOW_VERSION=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *)           TARGET="$1"; shift ;;
  esac
done

TARGET="${TARGET:-.}"

if [ ! -d "$TARGET" ]; then
  echo "Error: $TARGET is not a directory"
  exit 1
fi

TARGET=$(cd "$TARGET" && pwd)

# --version: show installed version and exit
if [ "$SHOW_VERSION" -eq 1 ]; then
  VERSION_FILE="$TARGET/.claude/harness/VERSION"
  if [ -f "$VERSION_FILE" ]; then
    echo "code-harness $(cat "$VERSION_FILE")"
  else
    echo "code-harness not installed in $TARGET"
  fi
  exit 0
fi

# Detect script source directory (works locally and via curl-pipe)
SELF="${BASH_SOURCE[0]:-$0}"
if [ -f "$SELF" ] && [ -d "$(dirname "$SELF")/.claude/harness" ]; then
  SCRIPT_DIR=$(cd "$(dirname "$SELF")" && pwd)
else
  echo "Downloading code-harness..."
  TMPDIR=$(mktemp -d)
  trap "rm -rf $TMPDIR" EXIT
  git clone --depth 1 https://github.com/firstintent/code-harness.git "$TMPDIR/code-harness" 2>/dev/null
  SCRIPT_DIR="$TMPDIR/code-harness"
fi

UPSTREAM_VERSION=$(cat "$SCRIPT_DIR/.claude/harness/VERSION")

# Track what we create/update/skip
CREATED=()
UPDATED=()
SKIPPED=()

copy_file() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -f "$dst" ]; then
    if [ "$FORCE" -eq 1 ]; then
      cp "$src" "$dst"
      UPDATED+=("$dst")
    else
      SKIPPED+=("$dst")
    fi
  else
    cp "$src" "$dst"
    CREATED+=("$dst")
  fi
}

# Framework files — always updated by --update
copy_framework() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -f "$dst" ]; then
    cp "$src" "$dst"
    UPDATED+=("$dst")
  else
    cp "$src" "$dst"
    CREATED+=("$dst")
  fi
}

# ── Update mode ──
if [ "$UPDATE" -eq 1 ]; then
  LOCAL_VERSION_FILE="$TARGET/.claude/harness/VERSION"
  if [ -f "$LOCAL_VERSION_FILE" ]; then
    LOCAL_VERSION=$(cat "$LOCAL_VERSION_FILE")
    echo "Updating code-harness: $LOCAL_VERSION → $UPSTREAM_VERSION"
  else
    echo "Installing code-harness framework: $UPSTREAM_VERSION"
  fi
  echo ""

  # Only update .claude/harness/ (framework directory)
  copy_framework "$SCRIPT_DIR/.claude/harness/VERSION"            "$TARGET/.claude/harness/VERSION"
  copy_framework "$SCRIPT_DIR/.claude/harness/evaluator.md"       "$TARGET/.claude/harness/evaluator.md"
  copy_framework "$SCRIPT_DIR/.claude/harness/playbook.md"        "$TARGET/.claude/harness/playbook.md"
  copy_framework "$SCRIPT_DIR/.claude/harness/base-standards.md"  "$TARGET/.claude/harness/base-standards.md"
  copy_framework "$SCRIPT_DIR/.claude/harness/check-ownership.sh" "$TARGET/.claude/harness/check-ownership.sh"
  copy_framework "$SCRIPT_DIR/.claude/settings.json"              "$TARGET/.claude/settings.json"
  copy_framework "$SCRIPT_DIR/CLAUDE.md"                          "$TARGET/CLAUDE.md"

  chmod +x "$TARGET/.claude/harness/"*.sh 2>/dev/null

  if [ "$DASHBOARD" -eq 1 ]; then
    copy_framework "$SCRIPT_DIR/dashboard.py" "$TARGET/dashboard.py"
  fi

  echo "Updated framework files:"
  for f in "${UPDATED[@]}"; do echo "  ↑ $f"; done
  for f in "${CREATED[@]}"; do echo "  ✓ $f (new)"; done
  echo ""
  echo "User files untouched: .claude/rules/, .claude/hooks/, .harness/"
  echo "Version: $UPSTREAM_VERSION"
  exit 0
fi

# ── Full install mode ──
echo "Installing code-harness $UPSTREAM_VERSION into: $TARGET"
echo ""

# CLAUDE.md
if [ -f "$TARGET/CLAUDE.md" ] && [ "$FORCE" -eq 0 ]; then
  if ! grep -q ".harness/learned.md" "$TARGET/CLAUDE.md" 2>/dev/null; then
    echo "" >> "$TARGET/CLAUDE.md"
    echo "# Code Harness" >> "$TARGET/CLAUDE.md"
    echo "Follow the playbook in .claude/harness/playbook.md for all tasks." >> "$TARGET/CLAUDE.md"
    echo "When evaluating work, check all standards in .claude/harness/ and .claude/rules/ that match current file paths." >> "$TARGET/CLAUDE.md"
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

# Framework files (.claude/harness/) — upstream-managed
copy_file "$SCRIPT_DIR/.claude/harness/VERSION"            "$TARGET/.claude/harness/VERSION"
copy_file "$SCRIPT_DIR/.claude/harness/evaluator.md"       "$TARGET/.claude/harness/evaluator.md"
copy_file "$SCRIPT_DIR/.claude/harness/playbook.md"        "$TARGET/.claude/harness/playbook.md"
copy_file "$SCRIPT_DIR/.claude/harness/base-standards.md"  "$TARGET/.claude/harness/base-standards.md"
copy_file "$SCRIPT_DIR/.claude/harness/check-ownership.sh" "$TARGET/.claude/harness/check-ownership.sh"
copy_file "$SCRIPT_DIR/.claude/settings.json"              "$TARGET/.claude/settings.json"

# User files (.claude/rules/, .claude/hooks/) — only on first install
copy_file "$SCRIPT_DIR/.claude/rules/api-quality.md"       "$TARGET/.claude/rules/api-quality.md"
copy_file "$SCRIPT_DIR/.claude/rules/frontend-quality.md"  "$TARGET/.claude/rules/frontend-quality.md"
copy_file "$SCRIPT_DIR/.claude/hooks/protect-arch.sh"      "$TARGET/.claude/hooks/protect-arch.sh"

# State files (.harness/) — only on first install
copy_file "$SCRIPT_DIR/.harness/tasks.md"         "$TARGET/.harness/tasks.md"
copy_file "$SCRIPT_DIR/.harness/decisions.md"     "$TARGET/.harness/decisions.md"
copy_file "$SCRIPT_DIR/.harness/learned.md"       "$TARGET/.harness/learned.md"
copy_file "$SCRIPT_DIR/.harness/inbox.md"         "$TARGET/.harness/inbox.md"
copy_file "$SCRIPT_DIR/.harness/log.tsv"          "$TARGET/.harness/log.tsv"
copy_file "$SCRIPT_DIR/.harness/architecture.md"  "$TARGET/.harness/architecture.md"

# Dashboard (optional)
if [ "$DASHBOARD" -eq 1 ]; then
  copy_file "$SCRIPT_DIR/dashboard.py" "$TARGET/dashboard.py"
fi

# Make hooks executable
chmod +x "$TARGET/.claude/hooks/"*.sh "$TARGET/.claude/harness/"*.sh 2>/dev/null

# .gitignore
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
  echo "# Code Harness (per-user, not shared)" > "$GITIGNORE"
  echo ".claude/memory.md" >> "$GITIGNORE"
  echo "CLAUDE.local.md" >> "$GITIGNORE"
  echo ".claude/settings.local.json" >> "$GITIGNORE"
  CREATED+=(".gitignore")
fi

# Report
echo ""
echo "Created:"
for f in "${CREATED[@]}"; do echo "  ✓ $f"; done

if [ ${#UPDATED[@]} -gt 0 ]; then
  echo ""
  echo "Updated:"
  for f in "${UPDATED[@]}"; do echo "  ↑ $f"; done
fi

if [ ${#SKIPPED[@]} -gt 0 ]; then
  echo ""
  echo "Skipped:"
  for f in "${SKIPPED[@]}"; do echo "  - $f"; done
fi

echo ""
echo "Next steps:"
echo "  1. cd $TARGET"
echo "  2. Edit .claude/hooks/protect-arch.sh for your architecture"
echo "  3. Start Claude Code: claude"
echo "  4. Say: \"Read the codebase, update .harness/architecture.md, adjust .claude/rules/ paths\""
echo ""
echo "Or write tasks in .harness/tasks.md and say: \"Execute tasks\""
echo ""
echo "To update later: install.sh --update $TARGET"

if [ "$DASHBOARD" -eq 1 ]; then
  echo ""
  echo "Dashboard: python dashboard.py $TARGET"
fi
