## Interactive Mode (default)

When user gives a development request:
1. Assess complexity (see .claude/harness/playbook.md).
2. Simple → implement directly. Complex → design first, then implement.
3. Hit a point needing human judgment → write to .harness/decisions.md, continue with next task or best-guess default.
4. Stop hook evaluator runs automatically — test first, rules second.

## Unattended Mode

Activated by: "run unattended" or "follow tasks".
Follow .claude/harness/playbook.md — read tasks.md, loop until done.
