# code-harness

**English** | [简体中文](README_CN.md)

A quality-first control plane for Claude Code. Test every change, queue async decisions, run unattended — zero custom software, no CLAUDE.md modification.

## Philosophy

Most harness systems over-invest in **process** (task queues, claim protocols, GC loops) and under-invest in **verification**. code-harness flips this: the entire value is a reliable quality signal on every change. Process grows only when needed.

Inspired by [autoresearch](https://github.com/karpathy/autoresearch): skip the process, never skip the check.

## What it does

- **Stop hook evaluator** runs after every task — tests first, rules second
- **Loop detection** catches stuck agents and forces them to move on
- **Auto-generated standards** — evaluator analyzes your project and creates project-specific rules on first run
- **Async decisions** — Claude writes questions to a file instead of blocking; keeps working
- **No CLAUDE.md modification** — installs via `.claude/rules/` which Claude Code auto-loads

## Quick start

```bash
# Install
curl -sSL https://raw.githubusercontent.com/firstintent/code-harness/main/install.sh | bash -s -- /path/to/project

# Start
cd your-project && claude
```

Interactive use — just give Claude a task. The evaluator runs automatically.

Unattended — say `run unattended`. Claude reads `.harness/tasks.md` and loops.

## What gets installed

```
your-project/
├── .claude/
│   ├── settings.json              # Hooks: evaluator + loop detection + compaction recovery
│   ├── harness/    ← FRAMEWORK (replaced by --update)
│   │   ├── VERSION
│   │   ├── evaluator.md           # QA subagent: test → use → rules
│   │   └── playbook.md            # Unattended protocol
│   └── rules/      ← YOURS (never overwritten)
│       └── harness.md             # Entry point (auto-loaded by Claude Code)
│
└── .harness/       ← YOURS (never overwritten)
    ├── tasks.md                   # Task list
    └── decisions.md               # Async decision queue
```

**On-demand files** (created by Claude when first needed):
- `.claude/rules/project-standards.md` — auto-generated from your codebase
- `.harness/log.tsv` — evaluator history

## How it works

```
User request or tasks.md
         ↓
   Claude implements
         ↓
   Stop hook fires
    ┌────┴────┐
    │ Loop    │ Stuck? → write to decisions.md, skip task
    │ detect  │ Not stuck? → continue
    └────┬────┘
         ↓
   Evaluator subagent
    1. Run tests
    2. Try to use the feature
    3. Check project rules
         ↓
   Pass → mark done, next task
   Fail → fix, re-evaluate
```

## Usage

### Interactive development

```
> Add subscription billing to the Claude Code runtime
```

Claude assesses complexity, designs if complex, implements, evaluator auto-checks.
If Claude hits a point needing your judgment, it writes to `.harness/decisions.md` and continues.

### Unattended overnight

```
> run unattended
```

Next morning: tasks done, decisions queued for you.

### Reject and improve

```
> reject: OAuth doesn't handle token expiry
```

Claude generates a project-specific standard from your feedback, fixes the code, re-evaluates.

### Update

```bash
curl -sSL https://raw.githubusercontent.com/firstintent/code-harness/main/install.sh | bash -s -- --update
```

Replaces `.claude/harness/` only. Your rules, tasks, and decisions are untouched.

## Design decisions

**No pre-installed quality standards.** Generic rules ("no dead code", "consistent error handling") give a false sense of quality control. The evaluator generates project-specific standards from your actual codebase on first run.

**Tests > rules > hooks.** A rule that can be expressed as a test should become a test. Standard lifecycle: `rule (text) → test (mechanical) → hook (write-time block)`.

**No CLAUDE.md modification.** `.claude/rules/*.md` is auto-loaded by Claude Code. No need to touch the project's existing CLAUDE.md.

**Multi-machine is optional.** Not installed by default. Add it when you actually need it.

**Complexity gate.** Simple tasks (clear pattern, <5 files, <15 min) skip plan/decisions overhead. Quality checks never skip.

## Inspired by

- [autoresearch](https://github.com/karpathy/autoresearch) (Karpathy) — minimal file-driven agent loop, val_bpb on every run
- [Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) (Anthropic) — generator-evaluator separation
- [Harness Engineering](https://openai.com/index/harness-engineering/) (OpenAI) — repository as system of record
- [Building a C Compiler](https://www.anthropic.com/engineering/building-c-compiler) (Carlini) — multi-agent parallel development

## License

MIT
