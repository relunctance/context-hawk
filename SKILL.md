---
name: context-hawk
description: |
  Context memory manager for AI agents. 当用户提到"记忆太大"、"MEMORY.md过大"、"上下文爆了"、"压缩记忆"、"分层记忆"、"memory管理"时激活。
  
  功能：
  (1) 分层记忆：today/week/month/archive 四层分流
  (2) 自动压缩：多种策略（摘要/抽取/删除/晋升/归档）
  (3) 报警系统：上下文超阈值时提醒，可开关
  (4) 项目分流：按话题/项目拆分记忆文件
  (5) CLI工具：context-hawk 命令行管理记忆

  触发词：压缩记忆/MEMORY太大/记忆分流/上下文报警/分层记忆
---

# Context-Hawk · 上下文守护者

AI 记忆的守门人。防止上下文膨胀、记忆混乱、检索困难。

---

## 核心能力

### 1. 分层记忆（自动）

```
MEMORY.md  ←─── 长期记忆（最终归档地）
memory/
├── today.md      ←─── 今日新增（每次对话追加）
├── week.md       ←─── 本周摘要（周五自动合并）
├── month.md      ←─── 本月里程碑（每月自动归档）
└── archive/      ←─── 历史归档（可备查，不加载）
```

**启动规则**：每次启动只加载 `today.md` + `week.md` + `MEMORY.md`（如果存在）。

**搜索规则**：使用 `memory_search` 语义搜索所有层，需要时加载 archive。

---

### 2. 压缩策略（5种）

| 策略 | 适用场景 | 效果 |
|------|---------|------|
| `summarize` | 过程冗长、结论清晰 | 500行 → 30行摘要 |
| `extract` | 事实/决策/清单类内容 | 保留核心，删除噪声 |
| `delete` | 临时/调试/过时内容 | 完全删除 |
| `promote` | 值得保留的learnings | 晋升到对应项目文件 |
| `archive` | 超过一个月的内容 | 移入 archive/，不改内容 |

---

### 3. 报警系统（可开关）

- **默认阈值**：上下文超过 60% 时开启提示
- **显示方式**：每次回答时附带 `[上下文: 63% / 80%]`
- **开关命令**：
  - 开启：`/hawk-alert on`
  - 关闭：`/hawk-alert off`
  - 设置阈值：`/hawk-alert set 70`

---

### 4. 项目分流

按话题/项目拆分成独立文件：

```
memory/
├── qujingskills.md     ← Skill 研发相关
├── 老周偏好.md          ← 沟通习惯、个人偏好
├── 项目状态.md          ← 当前项目进度
└── 团队规范.md          ← 四个 Agent 配置
```

所有文件通过 `memory_search` 统一检索，按需加载。

---

## 使用方式

### 初始化（首次使用）

```
/hawk init
```

创建完整目录结构，自动把现有 MEMORY.md 迁移到 `memory/month.md`。

---

### 查看状态

```
/hawk status
```

输出：
```
[Context-Hawk] 上下文: 58% / 80%
  today.md     12行  (今日新增)
  week.md      34行  (本周汇总)
  archive/      3文件 (不计入上下文)
  memory/总行数  156行
```

---

### 压缩记忆

```
/hawk compress          ← 交互式（选择策略和范围）
/hawk compress summarize today.md   ← 对今日使用summarize策略
/hawk compress all summarize        ← 对所有层使用summarize策略
```

**压缩前必须确认**：
```
[Context-Hawk] 确认压缩
  范围：today.md (12行)
  策略：summarize（摘要）
  操作：保留结论，删除过程

  选项：
    [1] 全部压缩
    [2] 只压缩某个部分（输入行范围，如 5-20）
    [3] 取消

  请选择 [1/2/3]：
```

用户选择后执行。如果用户选部分压缩，让用户输入具体行范围。

---

### 报警开关

```
/hawk-alert on          ← 开启报警（默认60%阈值）
/hawk-alert off         ← 关闭报警
/hawk-alert set 70     ← 设置阈值为70%
```

---

### 项目分流

```
/hawk split             ← 交互式分流
/hawk split --by-project   ← 按项目分
/hawk split --by-topic     ← 按话题分
```

---

## 压缩策略选择指南

**让 Agent 智能判断**：

1. 读取目标文件内容
2. 分析内容类型（过程/结论/事实/清单/临时）
3. 推荐最优策略，给出理由
4. 用户确认后执行

**自动判断规则**：
- 有"总结/结论/决定"关键词 → `summarize`
- 有具体数值/日期/人名 → `extract`
- 有"临时/temp/debug/测试" → `delete`
- 有learnings/checklist类 → `promote`
- 日期超过30天 → `archive`

---

## 报警信息格式

每次回答时附带（当上下文 > 阈值）：

```
[🦅 Context: 67% / 80%] 记忆较满，建议压缩 today.md（使用 summarize）
```

当上下文 > 80%：
```
[🦅⚠️ Context: 84% / 80%] 上下文紧张！请立即运行 /hawk compress
```

---

## 参考文档

| 文档 | 用途 |
|------|------|
| [references/memory-system.md](references/memory-system.md) | 分层记忆完整说明 |
| [references/compression-strategies.md](references/compression-strategies.md) | 5种压缩策略详解 |
| [references/alerting.md](references/alerting.md) | 报警系统配置 |
| [references/cli.md](references/cli.md) | CLI工具完整文档 |
| [references/split-patterns.md](references/split-patterns.md) | 项目分流模式 |

---

## 初始文件

Skill 初始化后，以下文件应已存在：

```
~/.openclaw/workspace/memory/
├── today.md      （今日新增）
├── week.md       （本周汇总）
├── month.md      （本月里程碑）
└── archive/     （历史归档目录）
```

如不存在，运行 `/hawk init` 初始化。
