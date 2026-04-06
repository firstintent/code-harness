# Playbook

Unattended run protocol. Activated when user says "run unattended" or "follow tasks".
When user is present, interact directly — this file is not needed.

## Complexity Gate (before anything else)

**Simple task** (all true: clear pattern to follow, <5 files, no architecture decisions, <15 min):
→ Implement directly. No plan, no decisions.md. Stop hook evaluator still runs.

**Complex task** (any true: ambiguous requirements, new architecture choices, 3+ modules, >30 min, touches auth/payments/data deletion):
→ Full flow: plan → decisions → evaluator.

**Unsure?** Start simple. Auto-escalate if you hit a decision point or scope grows.

## Unattended Loop

1. Read .harness/tasks.md, pick the first undone task
2. Implement it
3. Stop hook evaluator runs automatically
4. Evaluator pass → mark task done in tasks.md, move to next
5. Evaluator fail → fix issues, let evaluator re-run
6. Need human judgment → append to .harness/decisions.md, skip to next task
7. All tasks done or all blocked → notify user
8. Do not stop

## Reject Handling

User says "reject:" → ask reason → generate a project-specific standard in .claude/rules/ → fix → re-evaluate.

## Evaluator: Test First

1. Run the project's test suite if it exists. Tests passing = strongest signal.
2. For code not covered by tests, evaluator does functional verification (try to use the feature).
3. No tests at all → evaluator flags "add tests for critical paths" as first feedback.

A rule that can be expressed as a test should become a test, not stay a rule.

Standard lifecycle: `rule (text) → test (mechanical) → hook (write-time block)`

## First Evaluation (no project-specific rules yet)

If .claude/rules/ has no project-specific standards:
1. Evaluator analyzes project structure and recommends 3-5 standards
2. Main agent writes them to .claude/rules/project-standards.md marked [auto-generated, needs review]
3. These take effect immediately; remind user to review when present

## On-Demand Components

These files do NOT exist at install time. Create them when first needed:

| File | Created when |
|------|-------------|
| .claude/rules/project-standards.md | First evaluator run |
| .harness/log.tsv | First evaluator completion |

## Multi-Machine (optional extension)

Not included by default. If needed, set MACHINE_ID env var and add claim/sync protocol to .claude/rules/.
