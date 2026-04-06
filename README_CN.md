# code-harness

**简体中文** | [English](README.md)

质量优先的 Claude Code 控制面板。每次变更自动测试，异步人工决策，无人值守运行 —— 零自定义软件，不修改 CLAUDE.md。

## 设计理念

大多数 harness 系统在**流程**上过度投入（任务队列、认领协议、GC 循环），在**验证**上投入不足。code-harness 反过来：核心价值是每次变更都有可靠的质量信号，流程按需生长。

灵感来自 [autoresearch](https://github.com/karpathy/autoresearch)：跳过流程，不跳过检查。

## 功能

- **Stop hook 评估器** —— 每个任务完成后自动运行，先跑测试，再查规则
- **死循环检测** —— 发现 agent 卡住时强制跳过，写入决策队列
- **自动生成标准** —— 评估器首次运行时分析项目代码，生成项目专属规则
- **异步决策** —— 遇到需要人判断的问题写入文件，Claude 继续干活
- **不修改 CLAUDE.md** —— 通过 `.claude/rules/` 安装，Claude Code 自动加载

## 快速开始

```bash
# 安装
curl -sSL https://raw.githubusercontent.com/firstintent/code-harness/main/install.sh | bash -s -- /path/to/project

# 使用
cd your-project && claude
```

交互模式 —— 直接给 Claude 下需求，评估器自动运行。

无人值守 —— 说 `run unattended`，Claude 读取 `.harness/tasks.md` 循环执行。

## 安装内容

```
your-project/
├── .claude/
│   ├── settings.json              # Hooks：评估器 + 死循环检测 + compaction 恢复
│   ├── harness/    ← 框架（--update 整体替换）
│   │   ├── VERSION
│   │   ├── evaluator.md           # QA 子代理：测试 → 使用 → 规则
│   │   └── playbook.md            # 无人值守协议
│   └── rules/      ← 你的（--update 不触碰）
│       └── harness.md             # 入口（Claude Code 自动加载）
│
└── .harness/       ← 你的（--update 不触碰）
    ├── tasks.md                   # 任务列表
    └── decisions.md               # 异步决策队列
```

**按需生成的文件**（首次需要时由 Claude 创建）：
- `.claude/rules/project-standards.md` —— 从代码库自动生成
- `.harness/log.tsv` —— 评估器历史

## 工作原理

```
用户需求 或 tasks.md
         ↓
    Claude 实现
         ↓
    Stop hook 触发
    ┌────┴────┐
    │ 死循环  │ 卡住? → 写入 decisions.md，跳过任务
    │ 检测    │ 没卡? → 继续
    └────┬────┘
         ↓
    评估器子代理
     1. 跑测试
     2. 尝试使用功能
     3. 检查项目规则
         ↓
    通过 → 标记完成，下一个
    失败 → 修复，重新评估
```

## 使用方式

### 交互开发

```
> 给 Claude Code runtime 加订阅计费
```

Claude 评估复杂度，复杂任务先设计再实现，评估器自动检查。
遇到需要你判断的点，写入 `.harness/decisions.md`，继续推进。

### 无人值守过夜

```
> run unattended
```

第二天早上：任务完成，决策等你处理。

### 拒绝并改进

```
> reject: OAuth 没有处理 token 过期
```

Claude 从你的反馈生成项目专属标准，修复代码，重新评估。

### 更新

```bash
curl -sSL https://raw.githubusercontent.com/firstintent/code-harness/main/install.sh | bash -s -- --update
```

只替换 `.claude/harness/`。你的规则、任务、决策不受影响。

## 设计决策

**不预装质量标准。** 泛泛的规则（"无死代码""错误处理一致"）给了一种"已有质量管控"的错觉。评估器首次运行时从你的实际代码库生成项目专属标准。

**测试 > 规则 > Hook。** 能表达为测试的规则应该变成测试。标准生命周期：`规则（文字）→ 测试（机械）→ Hook（写入时阻断）`。

**不修改 CLAUDE.md。** `.claude/rules/*.md` 被 Claude Code 自动加载，不需要改动项目已有的 CLAUDE.md。

**多机协作是可选扩展。** 默认不安装，真正需要时再加。

**复杂度门槛。** 简单任务（有模式可循、<5 文件、<15 分钟）跳过计划/决策流程。质量检查永不跳过。

## 灵感来源

- [autoresearch](https://github.com/karpathy/autoresearch) (Karpathy) —— 极简文件驱动代理循环，每次实验都跑 val_bpb
- [Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) (Anthropic) —— 生成器-评估器分离
- [Harness Engineering](https://openai.com/index/harness-engineering/) (OpenAI) —— 仓库即系统记录
- [Building a C Compiler](https://www.anthropic.com/engineering/building-c-compiler) (Carlini) —— 多代理大规模并行开发

## 许可证

MIT
