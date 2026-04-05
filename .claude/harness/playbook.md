# Playbook

This is the operating manual for code-harness. Follow these rules for all tasks.

## Task Execution

### Starting a Task
1. Read .harness/tasks.md
2. If multi-machine mode (MACHINE_ID is set): follow the multi-machine protocol below
3. If single-machine: pick the highest priority unclaimed task
4. Check .harness/decisions.md — if the task is blocked by an unresolved decision, skip it
5. Write a plan (3-5 bullet points), wait for user confirmation
6. After confirmation, implement one feature at a time

### Completing a Task
1. After implementation, the Stop hook automatically triggers the evaluator
2. If evaluator fails: fix the issues, let it re-run
3. If evaluator passes: update tasks.md, append to log.tsv, git commit and push

### When Nothing is Blocked
If all remaining tasks are blocked by decisions, do a GC cycle (see below).
If GC is also done, re-check decisions.md for newly resolved items.

## Reject Signal Handling

When the user says "reject:" or sends a reject via Telegram/Discord channel:

1. Ask for the reason (if not already stated)
2. Check .claude/harness/*.md and .claude/rules/*.md — does any existing standard cover this issue?
   - YES but evaluator missed it → append to .harness/log.tsv with `missed: <standard_id>`
   - NO → write a DRAFT standard to .harness/inbox.md with:
     - Proposed id (e.g. DRAFT-A004)
     - Description
     - suggested_paths (which rules file it should go in)
     - source: reject @ <date>, "<reason>"
3. Fix the code
4. Let Stop hook evaluator re-verify

## GC (Garbage Collection)

When the user says "do GC" or when all tasks are blocked:

1. Read .harness/inbox.md — move mature DRAFTs to the appropriate .claude/rules/*.md file
2. Read .harness/log.tsv — analyze:
   - Which standards are triggered most often?
   - Which standards have high miss rates (evaluator missed them)?
   - Which standards have never been triggered (consider removing)?
3. Read /memory — check if auto memory has entries that conflict with rules
4. Scan the codebase for pattern inconsistencies (e.g. multiple date formats, duplicate utilities)
5. Check if any standard is now mechanical enough to promote to a PreToolUse hook
6. Output a GC report

## Standard Lifecycle

Standards evolve through four stages:

```
auto memory note → .harness/inbox.md DRAFT → .claude/rules/*.md standard → .claude/hooks/ or .claude/harness/ mechanical check
```

Each promotion increases determinism:
- auto memory: Claude's own association (may not follow)
- inbox DRAFT: advisory, evaluator notes but doesn't enforce
- rules standard: evaluator checks and fails if violated
- hook: code cannot be written if it violates

When promoting a standard to a hook, record in log.tsv:
```
<date>	criteria-promote	-	-	-	promote	<id> moved from rules to hook
```

## Notification Rules (via Telegram/Discord channel)

Send a notification when:
- A new decision is written to decisions.md (include summary)
- A task is completed (include evaluator result)
- Evaluator fails the same standard 3+ times consecutively (may need human direction)
- GC report is generated
- All tasks are blocked by decisions for 30+ minutes (nudge for responses)
- Account quota exhausted (StopFailure hook handles this)

## Execution Mode Selection

Read the `mode` tag in tasks.md:

### [mode: single] (default)
Single session. Stop hook auto-QA.

### [mode: parallel]
Launch subagents for each subtask. Rules:
- Each subtask should take < 15 minutes
- Subtasks don't need to communicate with each other
- Lead waits for all subagents, then does integration check

### [mode: team]
Create an agent team. Rules:
- Use when subtasks each take 30+ minutes
- Or when subtasks need real-time cross-communication
- All teammates inherit the same hooks (automatic)
- Cross-teammate interface decisions → write to decisions.md
- Require plan approval for teammates before implementation

### [mode: swarm]
Decompose into independent sub-tasks, generate swarm-launcher.sh. Rules:
- Each sub-task must only modify its own files, not shared files
- If a sub-task needs to modify shared files → not suitable for swarm, downgrade to team
- After all sub-tasks complete, run a summary session for integration check

### Mode Selection Logic (if not tagged)
1. Can one session do this? → single
2. Can it split into independent subtasks?
   a. All subtasks are the same type repeated N times? → swarm
   b. Subtasks are different but each < 15 min? → parallel (subagent)
   c. Subtasks are different and each > 30 min? → team
3. Do subtasks need real-time communication? → team
4. Unsure? → start with single, upgrade if needed

Don't default to team. Team token cost is 3-5x single.

## Multi-Machine Coordination

Only active when MACHINE_ID environment variable is set.

### Task Claiming
1. `git pull --rebase`
2. Find the first unclaimed task, or a task whose claim has timed out
3. Timeout: `[claimed: X, since: T]` where current_time - T > 2 hours → abandoned
4. Mark: `[claimed: <MACHINE_ID>, since: <current_time>]`
5. `git commit -m "claim T<id>" .harness/tasks.md && git push`
6. If push fails (someone else claimed simultaneously) → `git pull --rebase`, pick next task

### Claim Renewal
Every 30 minutes or after completing a sub-step, update the `since` timestamp and push.
Prevents long tasks from being mistakenly reclaimed.

### Task Completion
1. Commit code + update tasks.md `[done: <MACHINE_ID>, at: <time>]`
2. Append to log.tsv
3. `git push`

### Sync Protocol
Pull at these times:
- Before claiming a new task
- After completing a task, before pushing
- Every 15 minutes during long tasks

Push at these times:
- After claiming a task
- After completing a task (code + tasks.md + log.tsv)
- After writing to decisions.md
- After writing to learned.md

### Conflict Resolution
- tasks.md conflict: re-pull, abandon current claim, pick next task
- decisions.md conflict: usually auto-merges (append-only)
- Code conflict: write to decisions.md for human resolution
- log.tsv conflict: usually auto-merges (append-only)

### Git Sync Template
```
git stash push -m "harness-sync" 2>/dev/null
git pull --rebase
git stash pop 2>/dev/null
# resolve conflicts if any
git push
```
