#!/bin/bash
# cron-gc.sh — Daily garbage collection run
# Add to crontab: 0 3 * * * /path/to/project/scripts/cron-gc.sh
#
# Runs a headless Claude Code session that:
# 1. Analyzes log.tsv for criteria health
# 2. Reviews inbox.md for mature drafts
# 3. Scans codebase for pattern inconsistencies
# 4. Writes report to .harness/gc-report.md

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

# Pull latest
git pull --rebase 2>/dev/null || true

claude -p "You are running a scheduled GC for code-harness. Follow the GC section in .claude/rules/playbook.md. Write your report to .harness/gc-report.md. After writing the report, commit and push it." \
  --bare \
  --allowedTools "Read,Grep,Glob,Write,Bash" \
  > .harness/swarm-logs/gc-$(date +%Y%m%d).log 2>&1

echo "GC complete. Report at .harness/gc-report.md"
