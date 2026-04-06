#!/bin/bash
# install.sh — Install or update code-harness
#
# Usage:
#   ./install.sh [OPTIONS] [/path/to/project]
#   curl -sSL https://raw.githubusercontent.com/firstintent/code-harness/main/install.sh | bash -s -- [OPTIONS]
#
# Options:
#   --update     Update .claude/harness/ only (your files stay untouched)
#   --force      Overwrite ALL files including your customizations
#   --version    Show installed version
#   -h, --help   Show this help

set -e

FORCE=0; UPDATE=0; SHOW_VERSION=0; TARGET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)   FORCE=1; shift ;;
    --update)  UPDATE=1; shift ;;
    --version) SHOW_VERSION=1; shift ;;
    -h|--help)
      echo "Usage: $0 [--update|--force] [/path/to/project]"
      echo ""
      echo "  --update   Replace .claude/harness/ only (safe)"
      echo "  --force    Overwrite everything including your customizations"
      echo "  --version  Show installed version"
      echo ""
      echo "Installed files (minimal, does NOT touch CLAUDE.md):"
      echo "  .claude/settings.json  — Stop hook (evaluator + loop detection)"
      echo "  .claude/harness/       — framework (playbook + evaluator)"
      echo "  .claude/rules/harness.md — entry point (auto-loaded by Claude Code)"
      echo "  .harness/tasks.md      — task list"
      echo "  .harness/decisions.md  — async decisions"
      echo ""
      echo "On-demand files (created by Claude when needed):"
      echo "  .claude/rules/project-standards.md — project-specific standards"
      echo "  .harness/log.tsv       — evaluator history"
      exit 0 ;;
    *) TARGET="$1"; shift ;;
  esac
done

TARGET=$(cd "${TARGET:-.}" && pwd)

# --version
if [ "$SHOW_VERSION" -eq 1 ]; then
  [ -f "$TARGET/.claude/harness/VERSION" ] && echo "code-harness $(cat "$TARGET/.claude/harness/VERSION")" || echo "code-harness not installed"
  exit 0
fi

# Find source (local or download)
SELF="${BASH_SOURCE[0]:-$0}"
if [ -f "$SELF" ] && [ -d "$(dirname "$SELF")/.claude/harness" ]; then
  SRC=$(cd "$(dirname "$SELF")" && pwd)
else
  echo "Downloading code-harness..."
  TMPDIR=$(mktemp -d); trap "rm -rf $TMPDIR" EXIT
  git clone --depth 1 https://github.com/firstintent/code-harness.git "$TMPDIR/code-harness" 2>/dev/null
  SRC="$TMPDIR/code-harness"
fi

VER=$(cat "$SRC/.claude/harness/VERSION")

# ── Update: just replace .claude/harness/ ──
if [ "$UPDATE" -eq 1 ]; then
  OLD_VER="none"
  [ -f "$TARGET/.claude/harness/VERSION" ] && OLD_VER=$(cat "$TARGET/.claude/harness/VERSION")
  echo "code-harness: $OLD_VER → $VER"
  mkdir -p "$TARGET/.claude"
  rm -rf "$TARGET/.claude/harness"
  cp -r "$SRC/.claude/harness" "$TARGET/.claude/harness"
  echo "Updated .claude/harness/ ($(ls "$TARGET/.claude/harness/" | wc -l) files)"
  echo "Your files untouched: .claude/rules/, .harness/"
  exit 0
fi

# ── Full install ──
echo "Installing code-harness $VER into: $TARGET"
echo ""

CREATED=(); SKIPPED=()

copy_if_new() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -f "$dst" ] && [ "$FORCE" -eq 0 ]; then
    SKIPPED+=("$(basename "$dst")")
  else
    cp "$src" "$dst"; CREATED+=("$dst")
  fi
}

# Framework (always install)
mkdir -p "$TARGET/.claude"
rm -rf "$TARGET/.claude/harness"
cp -r "$SRC/.claude/harness" "$TARGET/.claude/harness"
CREATED+=(".claude/harness/ ($VER)")

# Core files (only on first install)
copy_if_new "$SRC/.claude/settings.json"       "$TARGET/.claude/settings.json"
copy_if_new "$SRC/.claude/rules/harness.md"   "$TARGET/.claude/rules/harness.md"
copy_if_new "$SRC/.harness/tasks.md"           "$TARGET/.harness/tasks.md"
copy_if_new "$SRC/.harness/decisions.md"  "$TARGET/.harness/decisions.md"

# .gitignore
if [ -f "$TARGET/.gitignore" ]; then
  if ! grep -q ".claude/memory.md" "$TARGET/.gitignore" 2>/dev/null; then
    echo -e "\n# Code Harness\n.claude/memory.md\nCLAUDE.local.md\n.claude/settings.local.json" >> "$TARGET/.gitignore"
    CREATED+=(".gitignore (appended)")
  fi
elif [ -f "$SRC/.gitignore" ]; then
  cp "$SRC/.gitignore" "$TARGET/.gitignore"; CREATED+=(".gitignore")
fi

# Report
echo "Created:"
for f in "${CREATED[@]}"; do echo "  ✓ $f"; done
[ ${#SKIPPED[@]} -gt 0 ] && echo "" && echo "Skipped (already exist): ${SKIPPED[*]}"

echo ""
echo "Next steps:"
echo "  cd $TARGET && claude"
echo "  > run unattended"
echo ""
echo "Update:  install.sh --update $TARGET"
