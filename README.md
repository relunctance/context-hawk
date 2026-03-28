# 🦅 Context-Hawk

> **AI 上下文记忆守护者** — 让 AI 记得住、不丢失、不迷茫。

*Give any AI agent a memory that actually works — across sessions, across topics, across time.*

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![OpenClaw Compatible](https://img.shields.io/badge/OpenClaw-2026.3%2B-brightgreen)](https://github.com/openclaw/openclaw)
[![ClawHub](https://img.shields.io/badge/ClawHub-context--hawk-blue)](https://clawhub.com)

---

[English](#english) | [中文说明](#中文)

---

## 🌍 一句话定位

> **企业级通用上下文记忆引擎** — 从"简单裁剪工具"升级为"真正的 AI 记忆伙伴"。
>
> 更轻、更强、不爆 token、不丢信息、不忘任务、可检索、可持久化、可嵌入任意 Agent。

---

## ✨ 十大核心能力

| # | 能力 | 说明 | 状态 |
|---|------|------|------|
| 1 | **任务状态记忆** | 即使重启也能从断点继续，不空转 | 🆕 核心 |
| 2 | **结构化 JSON 记忆** | 可检索/可过滤/可排序/可注入 | ✅ 完整 |
| 3 | **四层记忆架构** | Working → Short → Long → Archive | ✅ 完整 |
| 4 | **AI 重要度评分** | 自动打分，低价值内容直接丢弃 | ✅ 完整 |
| 5 | **智能上下文注入** | 5 种策略可切换，动态控制 token | ✅ 完整 |
| 6 | **自省机制** | 自动判断缺什么信息/是否卡住 | ✅ 完整 |
| 7 | **自动去重+合并** | 重复内容自动合并，上下文不膨胀 | ✅ 完整 |
| 8 | **无数据库持久化** | JSONL 本地存储，重启不丢 | ✅ 完整 |
| 9 | **LanceDB 向量检索** | 可选，向量+BM25 混合检索 | ✅ 完整 |
| 10 | **纯内存降级** | 无 LanceDB 时自动切换文件模式 | ✅ 完整 |

---

## 🏗️ 系统架构

```
┌────────────────────────────────────────────────────────────┐
│                      Context-Hawk                           │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Working Memory  ←── 当前会话（最近 5-10 轮）               │
│       ↓ Weibull衰减                                       │
│  Short-term      ←── 24h 内内容，摘要形式                  │
│       ↓ access_count ≥ 10 + importance ≥ 0.7              │
│  Long-term       ←── 永久知识，向量索引                    │
│       ↓ 超过 90 天或 decay_score < 0.15                   │
│  Archive          ←── 历史归档，按需召回                    │
│                                                            │
├────────────────────────────────────────────────────────────┤
│  Task State Memory  ←── 当前任务状态（持久化，重启不丢）      │
│  - 当前任务 / 下一步 / 完成度 / 产出物 / 约束               │
├────────────────────────────────────────────────────────────┤
│  Injection Engine  ←── 策略 A/B/C/D/E 决定召回哪些记忆      │
│  Self-Introspection ←── 每次回答前自省                     │
└────────────────────────────────────────────────────────────┘
```

---

## 📦 任务状态记忆（核心能力）

**这是最有价值的feature。** 即使 Agent 重启、断电、切换会话，也能从断点继续。

```json
// .hawk/task_state.jsonl
{
  "task_id": "task_20260329_001",
  "description": "完成 qujin-laravel-team Skill 文档",
  "status": "in_progress",
  "progress": 65,
  "next_steps": [
    "补充 backend-dev.md 中的 DAO 查询示例",
    "review 唐僧方案模板",
    "向老周汇报进度"
  ],
  "outputs": [
    "SKILL.md 完成",
    "constitution.md 完成"
  ],
  "constraints": [
    "覆盖率需达 98%",
    "API 需版本化"
  ],
  "created_at": "2026-03-29T00:00:00+08:00",
  "updated_at": "2026-03-29T00:20:00+08:00",
  "resumed_count": 3
}
```

**解决的问题**：
- ❌ "重启后不知道上次做到哪了"
- ❌ "任务做到一半，换个 session 就忘了"
- ❌ "一直重复做同样的事"
- ✅ 重启后：`/hawk resume` 恢复任务状态，继续执行

---

## 🧠 结构化记忆格式

```json
{
  "id": "mem_20260329_001",
  "type": "task|knowledge|conversation|document|preference|decision",
  "content": "完整原文内容",
  "summary": "一句话摘要",
  "tokens": 120,
  "importance": 0.85,
  "confidence": 0.9,
  "tier": "working|short|long|archive",
  "category": "profile|preference|entity|event|case|pattern",
  "created_at": "2026-03-29T00:00:00+08:00",
  "last_accessed_at": "2026-03-29T00:20:00+08:00",
  "access_count": 3,
  "decay_score": 0.92,
  "expires_at": null,
  "metadata": {
    "l0_abstract": "一句话索引",
    "l1_overview": "段落摘要",
    "l2_content": "完整内容",
    "scope": "global|project-name",
    "tags": ["laravel", "规范"]
  }
}
```

### 重要度评分规则

| 分值 | 类型 | 处理 |
|------|------|------|
| 0.9-1.0 | 决策/规范/错误 | 永久保留，最慢衰减 |
| 0.7-0.9 | 任务/偏好/知识 | 长期记忆 |
| 0.4-0.7 | 对话/讨论 | 短期记忆，衰减后归档 |
| 0.0-0.4 | 闲聊/问候/废话 | **直接丢弃，不进记忆** |

---

## 🎯 上下文注入策略（5种）

```bash
/hawk strategy A   # 高重要度：importance ≥ 0.7  | 节省 60-70% token
/hawk strategy B   # 任务相关：scope 匹配         | 节省 30-40% token  ← 默认
/hawk strategy C   # 最近对话：最近 10 轮          | 节省 50% token
/hawk strategy D   # Top5 召回：access_count Top5   | 节省 70% token
/hawk strategy E   # 全部召回：无过滤              | 100% token
```

**动态切换**：当 token 紧张时，自动建议切换到更严格的策略。

---

## 🗜️ 5种压缩策略

| 策略 | 适用 | 效果 |
|------|------|------|
| `summarize` | 过程冗长、结论清晰 | 500行 → 30行 |
| `extract` | 事实/决策/清单类 | 保留核心事实 |
| `delete` | 临时/调试/过时 | 完全删除 |
| `promote` | learnings 类内容 | 聚合到主题文件 |
| `archive` | 超过 30 天 | 移入 archive 层 |

**压缩前必须确认**：
```
[Context-Hawk] 确认压缩
  范围：today.md (186行)
  策略：summarize

  [1] 全部压缩
  [2] 只压缩部分（输入行范围或关键词）
  [3] 取消
```

---

## 🔔 报警系统（四级）

| 等级 | 阈值 | 自动防御 |
|------|------|---------|
| ✅ 正常 | < 60% | 无 |
| 🟡 关注 | 60-79% | 提示压缩建议 |
| 🔴 严重 | 80-94% | 暂停自动写入，强制提示 |
| 🚨 危险 | ≥ 95% | 阻止写入，必须压缩 |

```bash
/hawk-alert on     # 开启
/hawk-alert off    # 关闭
/hawk-alert set 70 # 自定义阈值
```

---

## 🔍 自省机制

每次回答前自动检查：

```markdown
[🦅 自省]
  任务明确度：✅ 明确
  缺少信息：❌ 需求文档
  卡点检测：✅ 无
  建议：补充 README.md
```

---

## 📁 记忆目录结构

```
memory/
├── today.md      ← 今日新增（每次对话追加）
├── week.md       ← 本周汇总（周五合并）
├── month.md      ← 月度归档（每月归档）
├── archive/     ← 历史归档（不主动加载）
└── .hawk/       ← 内部数据
    ├── config.json      ← 配置
    ├── task_state.jsonl ← 任务状态（持久化）
    ├── memories.jsonl   ← 结构化记忆
    └── index.json      ← 索引
```

---

## 🚀 快速开始

### 安装

```bash
# 1. 安装 LanceDB 记忆插件（推荐）
openclaw plugins install memory-lancedb-pro@beta

# 2. 激活 Skill
openclaw skills install ./context-hawk.skill

# 3. 初始化
hawk init
```

### CLI 命令

```bash
hawk init              # 初始化
hawk status           # 查看上下文状态
hawk resume           # 恢复任务状态（核心！）
hawk task "描述任务"  # 记录当前任务
hawk compress         # 压缩（交互式）
hawk strategy B       # 切换注入策略
hawk introspect       # 自省报告
hawk search <query>   # 混合检索
hawk alert on         # 开启报警
hawk backup           # 备份
```

---

## 📂 文件结构

```
context-hawk/
├── SKILL.md
├── scripts/
│   └── hawk              # Python CLI
└── references/
    ├── memory-system.md           # 四层架构
    ├── structured-memory.md      # 结构化记忆
    ├── injection-strategies.md   # 5种注入策略
    ├── compression-strategies.md   # 5种压缩策略
    ├── alerting.md               # 报警系统
    ├── self-introspection.md     # 自省机制
    ├── lancedb-integration.md   # LanceDB集成
    ├── task-state.md            # 🆕 任务状态记忆
    └── cli.md                   # CLI文档
```

---

## 🔌 技术特性

- **持久化**：JSONL 本地文件，无需数据库
- **向量检索**：LanceDB（可选），无则自动降级文件模式
- **跨 Agent**：通用，无业务侵入，任意 Agent 均可使用
- **零配置**：安装即用，默认值已优化
- **可扩展**：支持自定义注入策略、压缩策略、评分规则

---

## 🛡️ 许可证

MIT — 可自由使用、修改、分发。

---

---

## English

### What is Context-Hawk?

Context-Hawk is a **production-grade AI context memory engine** that gives any AI agent human-like memory capabilities:

- **Task State Memory** — resume from where you left off, even after restart
- **4-tier memory** with Weibull decay
- **Structured JSON memories** with importance scoring
- **5 context injection strategies** — dynamically control token usage
- **Self-introspection** — knows when it's missing information
- **No database required** — JSONL persistence, LanceDB optional

### Quick Start

```bash
openclaw plugins install memory-lancedb-pro@beta
openclaw skills install ./context-hawk.skill
hawk init
hawk task "Complete the API documentation"
hawk status
```

### Key Commands

```bash
hawk task "description"   # Start a new task
hawk resume              # Resume last task (after restart!)
hawk compress            # Compress memory
hawk strategy A         # Switch to high-importance mode
hawk introspect          # Self-introspection report
hawk search "query"     # Hybrid search
```

### Architecture

```
Working → Short-term → Long-term → Archive
    ↑ Weibull decay, importance scoring
Task State Memory ← Persistent across restarts
Injection Engine ← 5 strategies (A/B/C/D/E)
Self-Introspection ← Every answer checks context
```

### Requirements

- OpenClaw 2026.3+
- LanceDB (optional, graceful degradation)
- Python 3.8+ (for CLI)
