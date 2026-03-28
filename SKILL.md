---
name: context-hawk
description: |
  Context-Hawk v2 — 上下文记忆守护者（增强版）。当用户提到"记忆太大"、"MEMORY管理"、"上下文压缩"、"分层记忆"、"lanceDB"、"memory-lancedb-pro"、"重要度评分"、"上下文注入策略"时激活。
  
  增强版新增：
  (1) 融合 memory-lancedb-pro 的 LanceDB 向量记忆能力
  (2) 四层架构（Working/Short/Long/Archive）+ Weibull衰减
  (3) 结构化记忆（JSON格式，可检索可执行）
  (4) 5种压缩策略 + 智能策略推荐
  (5) 自动重要度评分（AI判断）
  (6) 上下文注入策略（5种可切换）
  (7) 自省机制（自动判断缺什么信息）
  (8) 纯内存降级（无LanceDB时自动切换）

  触发词：压缩记忆/MEMORY太大/分层记忆/上下文报警/lanceDB/重要度/注入策略
---

# Context-Hawk v2 🦅 — 上下文记忆守护者（增强版）

> 基于 memory-lancedb-pro 的 LanceDB 向量记忆能力 + context-hawk 的压缩策略 / 报警系统 / 分层管理。
> 通用无业务侵入，可接入任意 Agent。

---

## 核心架构

```
┌─────────────────────────────────────────────────────────┐
│  Working Memory（工作记忆）                                │
│  - 最近5-10轮对话                                        │
│  - 当前任务/目标                                         │
│  - 完整注入上下文                                         │
├─────────────────────────────────────────────────────────┤
│  Short-term Memory（短期记忆）← LanceDB（Working表）      │
│  - 24小时内内容                                         │
│  - 结构化摘要，Weibull衰减                               │
│  - 向量检索召回                                          │
├─────────────────────────────────────────────────────────┤
│  Long-term Memory（长期记忆）← LanceDB（Longterm表）      │
│  - 永久保存，向量存储                                     │
│  - 重要度 ≥ 0.7 自动晋升                                │
│  - 跨会话知识沉淀                                        │
├─────────────────────────────────────────────────────────┤
│  Archive Memory（归档记忆）← LanceDB（Archive表）         │
│  - 超90天 / Weibull衰减至接近0                           │
│  - 压缩存储，不主动加载                                   │
│  - memory_search 按需召回                                 │
└─────────────────────────────────────────────────────────┘
```

---

## 结构化记忆格式

每条记忆均为 JSON 结构，存入 LanceDB：

```json
{
  "id": "mem_20260328_001",
  "type": "task|knowledge|conversation|document|preference|decision",
  "content": "完整内容",
  "summary": "一句话摘要",
  "importance": 0.85,
  "confidence": 0.9,
  "tier": "working|short|long|archive",
  "category": "profile|preference|entity|event|case|pattern",
  "created_at": "2026-03-28T10:00:00+08:00",
  "last_accessed_at": "2026-03-28T10:00:00+08:00",
  "access_count": 0,
  "decay_score": 1.0,
  "expires_at": null,
  "metadata": {
    "source": "conversation|document|extraction",
    "scope": "global|project-name|agent-name",
    "l0_abstract": "一句话概述",
    "l1_overview": "段落摘要",
    "l2_content": "完整内容"
  }
}
```

---

## 重要度评分规则

AI 自动为每条记忆打分（0.0 ~ 1.0）：

| 分值 | 类型 | 说明 |
|------|------|------|
| 0.9-1.0 | 决策/规范/错误/产出 | 永久保留，Weibull衰减最慢 |
| 0.7-0.9 | 任务/偏好/知识 | 长期记忆，晋升Long-term |
| 0.4-0.7 | 对话/讨论/事实 | 短期记忆，衰减后归档 |
| 0.0-0.4 | 闲聊/问候/废话 | 过滤，不存入 |

**自动晋升规则**：
- `access_count ≥ 10` + `importance ≥ 0.7` → 晋升 Core Long-term
- `decay_score < 0.2` → 移入 Archive
- 超过 `90天` → 强制 Archive

---

## Weibull 衰减模型

基于 memory-lancedb-pro 的 Weibull 衰减：

```
decay_score = exp(-(age_days / half_life)^beta)
```

| 层级 | 半衰期 | Beta |
|------|--------|------|
| Working | 1天 | 0.8 |
| Short-term | 30天 | 1.0 |
| Long-term | 90天 | 0.6 |
| Archive | - | - |

---

## 上下文注入策略（5种可切换）

用户可随时切换，命令：`/hawk strategy <A|B|C|D|E>`

| 策略 | 说明 | 适用场景 |
|------|------|---------|
| **A: 高重要度** | 只带 importance ≥ 0.7 的记忆 | 上下文非常紧张 |
| **B: 任务相关** | 只带当前任务标签相关的记忆 | 专注开发 |
| **C: 最近对话** | 只带最近 10 轮的记忆 | 快速迭代 |
| **D: Top5 召回** | 长期记忆只召回 Top5 条 | 轻量模式 |
| **E: 全部召回** | 无过滤，完整召回 | 深度分析 |

**默认策略**：B（任务相关）

---

## 5种压缩策略

| 策略 | 适用场景 | 效果 |
|------|---------|------|
| `summarize` | 过程冗长、结论清晰 | 500行 → 30行 |
| `extract` | 事实/决策/清单类 | 保留核心事实 |
| `delete` | 临时/调试/过时 | 完全删除 |
| `promote` | learnings类内容 | 聚合到主题文件 |
| `archive` | 超过30天 | 移入archive表 |

**压缩前必须确认**：全部 / 部分（用户选择行范围）

---

## 自省机制

每次回答前自动检查：

```
[Context-Hawk] 自省报告
  任务明确度：✅ 明确
  缺少信息：❌ 需求文档、❌ 技术方案
  卡点检测：✅ 无
  建议：补充 README.md 中的项目背景
```

自省判断：
- 当前任务是否明确
- 是否缺少需求/规范/步骤
- 是否处于死循环/空转
- 是否有未解决的阻塞

---

## 报警系统

- **默认阈值**：60% 开启提示，80% 严重报警
- **显示**：`[🦅 Context: 63% / 80%]`
- **开关**：`/hawk-alert on/off/set 70`

---

## LanceDB 降级方案

```
LanceDB 可用 → 持久化向量存储 + 混合检索
LanceDB 不可用 → 纯内存模式（纯Python dict）
功能完整度：100% → 90%（无向量检索，降级为全文搜索）
```

---

## CLI 命令

```bash
hawk init              # 初始化（含LanceDB初始化）
hawk status           # 上下文状态 + LanceDB状态
hawk compress         # 压缩（交互式策略选择）
hawk compress today summarize  # 指定压缩
hawk strategy A      # 切换注入策略
hawk introspect      # 自省报告
hawk search <query>  # 混合检索
hawk alert on/off    # 报警开关
hawk inject          # 手动触发上下文注入
```

---

## 参考文档

| 文档 | 用途 |
|------|------|
| [references/memory-system.md](references/memory-system.md) | 四层架构 + LanceDB集成 |
| [references/structured-memory.md](references/structured-memory.md) | 结构化记忆格式 + 重要度规则 |
| [references/injection-strategies.md](references/injection-strategies.md) | 5种注入策略详解 |
| [references/compression-strategies.md](references/compression-strategies.md) | 5种压缩策略 |
| [references/alerting.md](references/alerting.md) | 报警系统 |
| [references/self-introspection.md](references/self-introspection.md) | 自省机制 |
| [references/cli.md](references/cli.md) | CLI完整文档 |
| [references/lancedb-integration.md](references/lancedb-integration.md) | LanceDB/memory-lancedb-pro集成 |
| [references/split-patterns.md](references/split-patterns.md) | 项目分流模式 |
