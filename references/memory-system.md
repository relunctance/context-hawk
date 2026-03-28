# 四层记忆架构 · Four-Tier Memory System

基于 memory-lancedb-pro 的 Weibull 衰减 + 三层晋升模型，增强为四层。

---

## 四层结构

```
┌─────────────────────────────────────────────────────┐
│  Layer 0: Working Memory（工作记忆）                    │
│  位置：内存 + LanceDB (working表)                     │
│  内容：最近5-10轮对话、当前任务                         │
│  上下文：完整注入                                      │
│  衰减：1天后降至 Layer 1                              │
│  晋升：access_count ≥ 5 → Layer 2                   │
├─────────────────────────────────────────────────────┤
│  Layer 1: Short-term Memory（短期记忆）                │
│  位置：LanceDB (shortterm表)                         │
│  内容：24小时对话、结构化摘要                           │
│  衰减：半衰期30天，beta=1.0                          │
│  晋升：access_count ≥ 10 + importance ≥ 0.7 → L2   │
│  降级：decay_score < 0.15 → Layer 3                │
├─────────────────────────────────────────────────────┤
│  Layer 2: Long-term Memory（长期记忆）                 │
│  位置：LanceDB (longterm表)                         │
│  内容：importance ≥ 0.7 的知识/决策/规范              │
│  衰减：半衰期90天，beta=0.6（最慢）                   │
│  降级：超过90天未访问 → Layer 3                       │
├─────────────────────────────────────────────────────┤
│  Layer 3: Archive Memory（归档记忆）                   │
│  位置：LanceDB (archive表)                          │
│  内容：decay_score < 0.15 或 > 90天的记忆             │
│  上下文：不主动加载                                    │
│  召回：通过 memory_search 按需加载                      │
└─────────────────────────────────────────────────────┘
```

---

## Weibull 衰减公式

```
decay_score = exp(-(age_days / half_life) ^ beta)

参数配置：
| 层级 | 半衰期 | Beta | 说明 |
|------|--------|------|------|
| Working | 1天 | 0.8 | 快速衰减 |
| Short-term | 30天 | 1.0 | 标准衰减 |
| Long-term | 90天 | 0.6 | 缓慢衰减 |
```

**复合衰减分** = (recency × 0.4) + (frequency × 0.3) + (importance × 0.3)

---

## 晋升规则

```
Working → Short-term
  触发：24小时未访问
  条件：decay_score > 0.5

Short-term → Long-term
  触发：access_count ≥ 10
  条件：importance ≥ 0.7

Any → Archive
  触发1：decay_score < 0.15
  触发2：超过90天未访问
```

---

## 记忆流向示意

```
对话 → 自动提取 → Working → [访问] → Short-term → [频繁访问] → Long-term
                   ↓ [30天]      ↓ [不访问]      ↓ [90天+]
                Short-term    Archive        Archive
```

---

## 与 memory-lancedb-pro 的对应关系

| context-hawk 层 | memory-lancedb-pro Tier | 说明 |
|---------------|----------------------|------|
| Working | Working | 活跃记忆 |
| Short-term | Peripheral | 次活跃记忆 |
| Long-term | Core | 高价值记忆 |
| Archive | Archived | 已衰减记忆 |

---

## 启动加载规则

每次启动时：

1. 加载 `memory/today.md`（今日文件层）
2. 加载 `memory/week.md`（本周文件层）
3. 从 Working Memory（LanceDB）加载 Top10
4. 从 Short-term Memory 加载 importance Top5
5. **不自动加载** Long-term 和 Archive（按需召回）

---

## 迁移现有结构

旧的 `MEMORY.md` → Layer 2（Long-term）
旧 `memory/today.md` → Layer 0（Working）
旧 `memory/week.md` → Layer 1（Short-term）
