# code-harness

**English** | [简体中文](README_CN.md)

A file-driven control plane for Claude Code. Build large projects with sustained quality, async human decisions, and multi-machine coordination — zero custom software.

## What it does

code-harness is a set of configuration files that turn Claude Code into an autonomous development system with built-in quality control. It uses Claude Code's native mechanisms (hooks, subagents, rules, channels) to:

- **Prevent code drift** — architectural constraints enforced mechanically via hooks
- **Auto-evaluate every change** — Stop hook triggers an independent evaluator after each task
- **Accumulate judgment** — reject signals become permanent quality standards
- **Run unattended** — decisions that need human input queue up in a file; Claude keeps working on other tasks
- **Scale to multiple machines** — git-based task claiming and file ownership

## How it works

```
Claude Code (execution) ← .claude/rules/*.md (standards)
         ↓                        ↑
    Stop hook          reject signal from human
         ↓                        ↑
  evaluator subagent → .harness/log.tsv
```

The system has three layers of defense against drift:

1. **PreToolUse hooks** — hard constraints, code that violates them can't be written
2. **Stop hook evaluator** — checks every completed task against rules, forces fixes
3. **Human reject signals** — when the evaluator misses something, the human's correction becomes a new rule

## Quick start

### 1. Install

```bash
# One-liner (downloads and installs)
curl -sSL https://raw.githubusercontent.com/firstintent/code-harness/main/install.sh | bash -s -- /path/to/your/project

# With dashboard
curl -sSL https://raw.githubusercontent.com/firstintent/code-harness/main/install.sh | bash -s -- --dashboard /path/to/your/project

# Or clone first, then install locally
git clone https://github.com/firstintent/code-harness.git
./code-harness/install.sh /path/to/your/project
```

Options: `--force` to overwrite existing files, `--dashboard` to include the web dashboard.

### 2. Customize for your project

Edit these files for your project:

- `.claude/hooks/protect-arch.sh` — add your architecture rules
- `.claude/rules/base-standards.md` — adjust baseline standards
- `.claude/rules/api-quality.md` — adjust paths and API standards
- `.claude/rules/frontend-quality.md` — adjust paths and frontend standards
- `.harness/architecture.md` — describe your project structure

Or let Claude do it:

```
> Read the codebase and update .harness/architecture.md,
> then adjust .claude/hooks/protect-arch.sh to match the architecture.
```

### 3. Start working

```bash
cd your-project
claude
```

```
> Read .harness/tasks.md and execute tasks in order.
```

That's it. The hooks handle everything else automatically.

## File structure

```
your-project/
├── CLAUDE.md                           # Entry point (3 lines)
├── .claude/
│   ├── settings.json                   # Hooks configuration
│   ├── agents/
│   │   └── evaluator.md                # QA evaluator subagent
│   ├── hooks/
│   │   ├── protect-arch.sh             # Architecture constraints
│   │   └── check-ownership.sh          # Multi-machine file ownership
│   └── rules/
│       ├── playbook.md                 # Workflow instructions
│       ├── base-standards.md           # Global quality standards
│       ├── api-quality.md              # API standards (path-scoped)
│       └── frontend-quality.md         # Frontend standards (path-scoped)
│
└── .harness/
    ├── tasks.md                        # Task list + claim status
    ├── decisions.md                    # Decision queue (human async)
    ├── learned.md                      # Cross-session knowledge
    ├── inbox.md                        # New standards staging
    ├── log.tsv                         # Evaluator history
    └── architecture.md                 # Project architecture map
```

## Usage scenarios

### Daily development (single machine)

```
> Implement user registration with email validation
```

Claude implements → Stop hook triggers evaluator → evaluator checks rules → fixes issues → done.

### Reject and improve

```
> reject: OAuth doesn't handle token expiry
```

Claude proposes a new standard → you approve → it's added to rules → all future OAuth code is checked against it.

### Unattended overnight run

```
> Read .harness/tasks.md. Execute all tasks.
> When you need a human decision, write to decisions.md and move to the next task.
> Don't stop.
```

Next morning: 8 tasks done, 3 decisions waiting for you.

### Multi-machine parallel development

On each machine:

```bash
export MACHINE_ID=A  # B, C on other machines
claude
```

```
> You are machine $MACHINE_ID. Follow multi-machine protocol in playbook.
> Claim and execute tasks from .harness/tasks.md.
```

### With Telegram for remote control

```bash
# One-time setup
/plugin install telegram@claude-plugins-official
/telegram:configure <bot-token>

# Start with channel
claude --channels plugin:telegram@claude-plugins-official
```

Now you can send tasks, get notifications, and respond to decisions from your phone.

### GC (garbage collection)

```
> Do a GC run
```

Claude analyzes log.tsv, reviews inbox.md, scans for drift, reports what needs attention.

## Execution modes

| Mode | When to use | How it works |
|------|-------------|--------------|
| `single` | Default, most tasks | One session + auto-evaluation |
| `parallel` | Independent subtasks < 15 min each | Subagents run in parallel |
| `team` | Subtasks > 30 min or need cross-communication | Agent team with independent sessions |
| `swarm` | Bulk identical tasks, fully independent | Multiple headless `claude -p` in parallel |

Tag tasks in tasks.md: `[mode: parallel]`, `[mode: team]`, etc.

## Standards lifecycle

```
auto memory → inbox.md DRAFT → rules/*.md standard → hooks/ mechanical check
```

Each promotion increases determinism. The goal: every standard that CAN be mechanically checked eventually becomes a hook.

## Multi-machine setup

1. All machines clone the same repo
2. Set `MACHINE_ID` environment variable on each machine
3. Add `owns:` patterns to tasks in tasks.md
4. Machines auto-coordinate via git push/pull

See the Multi-Machine Coordination section in `.claude/rules/playbook.md` for the full protocol.

## Dashboard

Monitor your harness state with the built-in web dashboard:

```bash
python dashboard.py /path/to/your/project
# Open http://localhost:5000
```

Shows tasks, decisions, evaluator log, standards, and multi-machine status. Auto-refreshes every 15 seconds.

## Inspired by

- [Harness Engineering](https://openai.com/index/harness-engineering/) (OpenAI) — repository as system of record, golden principles, GC loops
- [Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) (Anthropic) — generator-evaluator separation, criteria calibration
- [autoresearch](https://github.com/karpathy/autoresearch) (Karpathy) — minimal file-driven agent loop
- [Building a C Compiler](https://www.anthropic.com/engineering/building-c-compiler) (Carlini) — multi-agent parallel development at scale

## License

MIT
