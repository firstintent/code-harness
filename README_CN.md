# code-harness

**简体中文** | [English](README.md)

---

基于文件驱动的 Claude Code 控制面板。用于构建大规模无人值守自主开发系统，确保代码质量，支持异步人工决策和多机协调 —— 零自定义软件。

## 功能特性

code-harness 是一组配置文件，能将 Claude Code 变为具备内建质量管控的自主开发系统。它利用 Claude Code 的原生机制（hooks、subagents、rules、channels）实现：

- **防止代码漂移** —— 通过 hooks 机械化执行架构约束
- **自动评估每次变更** —— Stop hook 在每个任务完成后触发独立评估器
- **积累判断力** —— 拒绝信号自动转化为永久质量标准
- **无人值守运行** —— 需要人工决策的事项排队写入文件，Claude 继续处理其他任务
- **多机扩展** —— 基于 git 的任务认领与文件所有权管理

## 工作原理

```
Claude Code (执行) ← .claude/harness/ + .claude/rules/ (标准)
         ↓                        ↑
    Stop hook          人工拒绝信号
         ↓                        ↑
  评估器子代理 → .harness/log.tsv
```

系统具备三层防漂移机制：

1. **PreToolUse hooks** —— 硬约束，违反约束的代码无法写入
2. **Stop hook 评估器** —— 每个任务完成后对照规则检查，发现问题强制修复
3. **人工拒绝信号** —— 评估器遗漏的问题，由人工修正后转化为新规则

## 快速开始

### 1. 安装

```bash
# 一键安装（自动下载并安装）
curl -sSL https://raw.githubusercontent.com/firstintent/code-harness/main/install.sh | bash -s -- /path/to/your/project

# 含 Dashboard
curl -sSL https://raw.githubusercontent.com/firstintent/code-harness/main/install.sh | bash -s -- --dashboard /path/to/your/project

# 或先克隆，再本地安装
git clone https://github.com/firstintent/code-harness.git
./code-harness/install.sh /path/to/your/project
```

选项：`--force` 覆盖所有文件，`--dashboard` 同时安装 Web 仪表盘。

### 2. 为你的项目定制

编辑以下文件：

- `.claude/hooks/protect-arch.sh` —— 添加你的架构规则
- `.claude/rules/api-quality.md` —— 调整路径和 API 标准
- `.claude/rules/frontend-quality.md` —— 调整路径和前端标准
- `.harness/architecture.md` —— 描述你的项目结构

或者让 Claude 来做：

```
> 阅读代码库并更新 .harness/architecture.md，
> 然后调整 .claude/hooks/protect-arch.sh 以匹配架构。
```

### 3. 开始使用

```bash
cd your-project
claude
```

```
> 阅读 .harness/tasks.md 并按顺序执行任务。
```

就这么简单。hooks 会自动处理其余一切。

### 4. 版本更新

```bash
# 只更新框架文件（你的自定义内容不受影响）
curl -sSL https://raw.githubusercontent.com/firstintent/code-harness/main/install.sh | bash -s -- --update

# 查看当前版本
cat .claude/harness/VERSION
```

## 文件结构

```
your-project/
├── CLAUDE.md                              # 入口文件
├── .claude/
│   ├── settings.json                      # Hooks 配置
│   ├── harness/          ← 框架目录（--update 更新，勿手动编辑）
│   │   ├── VERSION                        # 已安装版本号
│   │   ├── evaluator.md                   # QA 评估器子代理
│   │   ├── playbook.md                    # 工作流指南
│   │   ├── base-standards.md              # 全局质量标准
│   │   └── check-ownership.sh             # 多机文件所有权
│   ├── hooks/            ← 你的目录（--update 不会触碰）
│   │   └── protect-arch.sh                # 你的架构约束
│   └── rules/            ← 你的目录（--update 不会触碰）
│       ├── api-quality.md                 # 你的 API 标准
│       └── frontend-quality.md            # 你的前端标准
│
└── .harness/             ← 你的目录（--update 不会触碰）
    ├── tasks.md                           # 任务列表 + 认领状态
    ├── decisions.md                       # 决策队列（异步人工）
    ├── learned.md                         # 跨会话知识
    ├── inbox.md                           # 新标准暂存区
    ├── log.tsv                            # 评估器历史记录
    └── architecture.md                    # 项目架构图
```

### 文件归属

| 目录 | 归属 | `--update` 行为 | 用途 |
|------|------|----------------|------|
| `.claude/harness/` | 框架 | **整体替换** | 勿编辑 —— 更新时会被覆盖 |
| `.claude/hooks/` | 你 | 不触碰 | 你的项目架构约束 |
| `.claude/rules/` | 你 | 不触碰 | 你的项目质量标准 |
| `.harness/` | 你 | 不触碰 | 任务、决策、日志、知识库 |
| `CLAUDE.md` | 框架 | **替换** | 项目特有指令放 `CLAUDE.local.md` |
| `dashboard.py` | 框架 | 带 `--dashboard` 时替换 | 勿编辑 |

## 使用场景

### 日常开发（单机）

```
> 实现带邮箱验证的用户注册功能
```

Claude 实现 → Stop hook 触发评估器 → 评估器检查规则 → 修复问题 → 完成。

### 拒绝并改进

```
> reject: OAuth 没有处理 token 过期
```

Claude 提出新标准 → 你审批 → 加入规则 → 未来所有 OAuth 代码都会据此检查。

### 无人值守过夜运行

```
> 阅读 .harness/tasks.md。执行所有任务。
> 遇到需要人工决策的问题，写入 decisions.md 然后继续下一个任务。
> 不要停下来。
```

第二天早上：8 个任务完成，3 个决策等你处理。

### 多机并行开发

在每台机器上：

```bash
export MACHINE_ID=A  # 其他机器设为 B、C
claude
```

```
> 你是机器 $MACHINE_ID。遵循 playbook 中的多机协议。
> 从 .harness/tasks.md 认领并执行任务。
```

### 配合 Telegram 远程控制

```bash
# 一次性配置
/plugin install telegram@claude-plugins-official
/telegram:configure <bot-token>

# 启动并接入频道
claude --channels plugin:telegram@claude-plugins-official
```

现在你可以通过手机发送任务、接收通知、回复决策。

### GC（垃圾回收）

```
> 执行一次 GC
```

Claude 分析 log.tsv，审查 inbox.md，扫描代码漂移，汇报需要关注的事项。

## 执行模式

| 模式 | 适用场景 | 工作方式 |
|------|---------|---------|
| `single` | 默认，大多数任务 | 单会话 + 自动评估 |
| `parallel` | 独立子任务，每个 < 15 分钟 | 子代理并行执行 |
| `team` | 子任务 > 30 分钟或需要交叉通信 | 独立会话的代理团队 |
| `swarm` | 批量同类任务，完全独立 | 多个无头 `claude -p` 并行 |

在 tasks.md 中标记任务：`[mode: parallel]`、`[mode: team]` 等。

## 标准生命周期

```
自动记忆 → inbox.md 草案 → rules/*.md 标准 → hooks/ 机械化检查
```

每次晋升都提高确定性。最终目标：所有能被机械化检查的标准都成为 hook。

## 多机部署

1. 所有机器克隆同一个仓库
2. 每台机器设置 `MACHINE_ID` 环境变量
3. 在 tasks.md 的任务中添加 `owns:` 模式
4. 机器间通过 git push/pull 自动协调

完整协议参见 `.claude/harness/playbook.md` 中的多机协调章节。

## 仪表盘

使用内置 Web 仪表盘监控 harness 状态：

```bash
python dashboard.py /path/to/your/project
# 打开 http://localhost:5000
```

展示任务、决策、评估日志、标准和多机状态。每 15 秒自动刷新。

## 灵感来源

- [Harness Engineering](https://openai.com/index/harness-engineering/) (OpenAI) —— 仓库即系统记录，黄金原则，GC 循环
- [Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) (Anthropic) —— 生成器-评估器分离，标准校准
- [autoresearch](https://github.com/karpathy/autoresearch) (Karpathy) —— 极简文件驱动代理循环
- [Building a C Compiler](https://www.anthropic.com/engineering/building-c-compiler) (Carlini) —— 多代理大规模并行开发

## 许可证

MIT
