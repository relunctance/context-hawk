# 🦅 Context-Hawk

> **AI 上下文记忆守护者** — 让 AI 记得住、不丢失、不迷茫。

*给任意 AI Agent 装上一个真正能用的记忆 — 跨会话、跨话题、跨时间。*

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![OpenClaw Compatible](https://img.shields.io/badge/OpenClaw-2026.3%2B-brightgreen)](https://github.com/openclaw/openclaw)
[![English README](https://img.shields.io/badge/README-English-blue)](README.md)

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
| 1 | **任务状态记忆** | `hawk resume` — 持久化，重启后继续执行 | 🆕 核心 |
| 2 | **四层记忆架构** | Working → Short → Long → Archive + Weibull 衰减 | ✅ |
| 3 | **结构化 JSON 记忆** | importance/category/tier/l0_abstract | ✅ |
| 4 | **AI 重要度评分** | 自动打分，低价值内容直接丢弃 | ✅ |
| 5 | **5 种注入策略** | A高重要度/B任务相关/C最近/D Top5/E全部 | ✅ |
| 6 | **5 种压缩策略** | summarize/extract/delete/promote/archive | ✅ |
| 7 | **自省机制** | 自动判断缺什么信息/是否卡住 | ✅ |
| 8 | **LanceDB 向量检索** | 可选，向量+BM25 混合检索 | ✅ |
| 9 | **纯内存降级** | 无 LanceDB 时自动切换文件模式 | ✅ |
| 10 | **自动去重+合并** | 重复内容自动合并，上下文不膨胀 | ✅ |

---

## 🏗️ 系统架构

```
┌────────────────────────────────────────────────────────────┐
│                      Context-Hawk                           │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Working Memory  ←── 当前会话（最近 5-10 轮）               │
│       ↓ Weibull 衰减                                       │
│  Short-term      ←── 24h 内内容，摘要形式                  │
│       ↓ access_count ≥ 10 + importance ≥ 0.7              │
│  Long-term       ←── 永久知识，向量索引                    │
│       ↓ 超过 90 天或 decay_score < 0.15                   │
│  Archive          ←── 历史归档，按需召回                    │
│                                                            │
├────────────────────────────────────────────────────────────┤
│  Task State Memory  ←── 持久化，重启不丢（核心能力！）      │
│  - 当前任务 / 下一步 / 完成度 / 产出物 / 约束             │
├────────────────────────────────────────────────────────────┤
│  Injection Engine  ←── 策略 A/B/C/D/E 决定召回哪些记忆      │
│  Self-Introspection ←── 每次回答前自省                    │
└────────────────────────────────────────────────────────────┘
```

---

## 📦 任务状态记忆（核心能力）

**这是最有价值的 Feature。** 即使 Agent 重启、断电、切换会话，也能从断点继续。

```json
// memory/.hawk/task_state.jsonl
{
  "task_id": "task_20260329_001",
  "description": "完成 qujin-laravel-team Skill 文档",
  "status": "in_progress",
  "progress": 65,
  "next_steps": [
    "review 唐僧方案模板",
    "向老周汇报进度"
  ],
  "outputs": [
    "SKILL.md",
    "constitution.md",
    "architect.md"
  ],
  "constraints": [
    "覆盖率需达 98%",
    "API 需版本化"
  ],
  "resumed_count": 3
}
```

```bash
hawk task "完成 Skill 文档"  # 创建任务
hawk task --step 1 done     # 标记步骤完成
hawk resume                # 重启后恢复 ← 核心！
```

---

## 🧠 结构化记忆格式

```json
{
  "id": "mem_20260329_001",
  "type": "task|knowledge|conversation|document|preference|decision",
  "content": "完整原文内容",
  "summary": "一句话摘要",
  "importance": 0.85,
  "confidence": 0.9,
  "tier": "working|short|long|archive",
  "category": "profile|preference|entity|event|case|pattern",
  "created_at": "2026-03-29T00:00:00+08:00",
  "access_count": 3,
  "decay_score": 0.92,
  "metadata": {
    "l0_abstract": "一句话索引",
    "l1_overview": "段落摘要",
    "l2_content": "完整内容",
    "scope": "global|project-name"
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

## 🎯 5 种上下文注入策略

| 策略 | 触发 | 节省 |
|------|------|------|
| **A: 高重要度** | `importance ≥ 0.7` | 60-70% |
| **B: 任务相关** | scope 匹配 | 30-40% ← 默认 |
| **C: 最近对话** | 最近 10 轮 | 50% |
| **D: Top5 召回** | `access_count` Top5 | 70% |
| **E: 全部召回** | 无过滤 | 100% |

```bash
hawk strategy A   # 高重要度模式
hawk strategy B   # 任务相关（默认）
hawk strategy     # 查看当前
```

---

## 🗜️ 5 种压缩策略

| 策略 | 适用 | 效果 |
|------|------|------|
| `summarize` | 过程冗长、结论清晰 | 500行 → 30行 |
| `extract` | 事实/决策/清单类 | 保留核心事实 |
| `delete` | 临时/调试/过时 | 完全删除 |
| `promote` | learnings 类内容 | 聚合到主题文件 |
| `archive` | 超过 30 天 | 移入 archive 层 |

```bash
hawk compress today summarize  # 压缩 today.md
hawk compress                  # 交互式（确认后再执行）
```

---

## 🔔 四级报警系统

| 等级 | 阈值 | 自动防御 |
|------|------|---------|
| ✅ 正常 | < 60% | 无 |
| 🟡 关注 | 60-79% | 提示压缩建议 |
| 🔴 严重 | 80-94% | 暂停自动写入，强制提示 |
| 🚨 危险 | ≥ 95% | 阻止写入，必须压缩 |

```bash
hawk alert on     # 开启
hawk alert off    # 关闭
hawk alert set 70 # 自定义阈值
```

---

## 🚀 快速开始

```bash
# 1. 安装 LanceDB 记忆插件（推荐）
openclaw plugins install memory-lancedb-pro@beta

# 2. 激活 Skill
openclaw skills install ./context-hawk.skill

# 3. 初始化
hawk init

# 4. 开始一个任务
hawk task "完成 API 文档"

# 5. 重启后继续
hawk resume
```

---

## CLI 命令

```bash
hawk init              # 初始化记忆结构
hawk status           # 查看上下文状态
hawk task ["描述"]    # 创建/管理任务
hawk resume           # 恢复最后任务 ← 最核心！
hawk compress         # 压缩记忆（交互式）
hawk strategy [A-E]  # 切换注入策略
hawk introspect       # 自省报告
hawk search <query>   # 混合检索（向量+全文）
hawk alert on|off     # 开关报警
hawk backup           # 备份
```

---

## 📂 文件结构

```
context-hawk/
├── SKILL.md
├── README.md              # English (default)
├── README_zh.md           # 中文版
├── LICENSE
├── scripts/
│   └── hawk               # Python CLI 工具
└── references/
    ├── memory-system.md           # 四层架构
    ├── structured-memory.md      # 结构化记忆格式
    ├── task-state.md            # 任务状态记忆
    ├── injection-strategies.md   # 5 种注入策略
    ├── compression-strategies.md   # 5 种压缩策略
    ├── alerting.md               # 报警系统
    ├── self-introspection.md    # 自省机制
    ├── lancedb-integration.md   # LanceDB 集成
    └── cli.md                   # CLI 文档
```

---

## 🔌 技术特性

- **持久化**：JSONL 本地文件，无需数据库
- **向量检索**：LanceDB（可选），无则自动降级文件模式
- **跨 Agent**：通用，无业务侵入，任意 Agent 均可使用
- **零配置**：安装即用，默认值已优化
- **可扩展**：支持自定义注入策略、压缩策略、评分规则

---

## 许可证

MIT — 可自由使用、修改、分发。
