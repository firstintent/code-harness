#!/bin/bash
# start-machine.sh — Start code-harness on a multi-machine node
#
# Usage:
#   MACHINE_ID=A ./start-machine.sh
#   MACHINE_ID=B ./start-machine.sh --with-telegram
#
# Each machine should have MACHINE_ID set uniquely (A, B, C, etc.)
# Each machine should have its own Claude Code account authenticated.

set -e

if [ -z "$MACHINE_ID" ]; then
  echo "Error: MACHINE_ID not set. Export it first:"
  echo "  export MACHINE_ID=A"
  exit 1
fi

echo "Starting code-harness on machine $MACHINE_ID"

# Pull latest code and harness state
git pull --rebase

# Build the startup prompt
PROMPT="You are machine $MACHINE_ID in a multi-machine code-harness setup.

Follow the multi-machine coordination protocol in .claude/rules/playbook.md:
1. git pull to get latest state
2. Read .harness/tasks.md — claim the highest priority unclaimed task
3. Check .harness/decisions.md for any resolved decisions that unblock tasks
4. Execute claimed tasks following the playbook
5. After each task: update tasks.md, append log.tsv, push
6. Sync every 15 minutes
7. When all tasks done or blocked: run GC
8. Never stop. Keep checking for new tasks and resolved decisions."

# Start with or without Telegram
if [ "$1" = "--with-telegram" ]; then
  echo "Starting with Telegram channel..."
  claude --channels plugin:telegram@claude-plugins-official
else
  echo "Starting interactive session..."
  # Paste the prompt manually, or use -p for headless:
  # claude -p "$PROMPT" --allowedTools "Read,Edit,Write,Bash,Grep,Glob"
  echo ""
  echo "Paste this prompt to start:"
  echo "---"
  echo "$PROMPT"
  echo "---"
  echo ""
  claude
fi
