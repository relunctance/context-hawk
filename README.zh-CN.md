# 🦅 Context-Hawk

> **AI 上下文记忆守护者** — 停止丢失追踪，开始记住重要的事情。

*给任何 AI agent 一个真正有效的记忆——跨 session、跨主题、跨时间。*

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![OpenClaw Compatible](https://img.shields.io/badge/OpenClaw-2026.3%2B-brightgreen)](https://github.com/openclaw/openclaw)
[![ClawHub](https://img.shields.io/badge/ClawHub-context--hawk-blue)](https://clawhub.com)

**English** | [中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Français](README.fr.md) | [Español](README.es.md) | [Deutsch](README.de.md) | [Italiano](README.it.md) | [Русский](README.ru.md) | [Português (Brasil)](README.pt-BR.md)

---

## 它做什么？

大多数 AI agent 都有**健忘症** — 每个新 session 从零开始。Context-Hawk 用一个生产级的记忆管理系统解决这个问题，自动捕捉重要的事情，让噪音消散，在正确的时间召回正确的记忆。

**没有 Context-Hawk：**
> "我已经告诉过你了 — 我喜欢简洁的回复！"
>（下一个 session，agent 又忘记了）

**有了 Context-Hawk：**
>（从 session 1 默默应用您的沟通偏好）
> ✅ 每次都交付简洁、直接的回复

---

## 😰 痛点 & 解决方案

| 痛点 | 影响 | Context-Hawk 解决方案 |
|------|------|----------------------|
| **AI 每个 session 都失忆** | 用户需要反复说同样的事 | 四层记忆衰减 — 重要内容自动保持 |
| **长时间任务重启后丢失** | 工作白费，上下文全没了 | `hawk resume` — 任务状态跨重启持久化 |
| **上下文膨胀** | Token 费用飙升，响应变慢 | 5 种注入策略 + 5 种压缩策略 |
| **记忆噪音** | 重要信息被淹没在聊天历史里 | AI 重要性评分 — 自动丢弃低价值内容 |
| **偏好被遗忘** | 用户每次都要重新解释规则 | 重要性 ≥ 0.9 = 永久记忆 |

**核心价值：** Context-Hawk 给你的 AI agent 装上一个真正管用的记忆——不是什么都记，而是智能地保留重要的，忘掉不重要的。

---

## ✨ 10 个核心功能

| # | 功能 | 说明 |
|---|---------|-------|
| 1 | **任务状态持久化** | `hawk resume` — 保存任务状态，重启后继续 |
| 2 | **四层记忆** | Working → Short → Long → Archive，带 Weibull 衰减 |
| 3 | **结构化 JSON** | 重要性评分（0-10）、类别、层级、L0/L1/L2 分层 |
| 4 | **AI 重要性评分** | 自动评分记忆，丢弃低价值内容 |
| 5 | **5 种注入策略** | A(高重要性) / B(任务相关) / C(最近) / D(Top5) / E(完整) |
| 6 | **5 种压缩策略** | summarize / extract / delete / promote / archive |
| 7 | **自我反思** | 检查任务清晰度、缺失信息、循环检测 |
| 8 | **LanceDB 向量搜索** | 可选 — 混合向量 + BM25 检索，支持 sentence-transformers 本地向量 |
| 9 | **纯记忆备份** | 无需 LanceDB，JSONL 文件持久化 |
| 10 | **自动去重** | SimHash 去重，移除重复记忆 |
| 11 | **MMR 召回** | 最大边缘相关性，多样性召回不重复 |

---

## 🚀 快速安装

```bash
# 一键安装（推荐）
bash <(curl -fsSL https://raw.githubusercontent.com/relunctance/context-hawk/master/install.sh)

# 或直接用 pip
pip install context-hawk

# 安装全部功能（含 sentence-transformers）
pip install "context-hawk[all]"
```

---

## 🏗️ 架构

```
┌──────────────────────────────────────────────────────────────┐
│                      Context-Hawk                              │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Working Memory  ←── 当前 session（最近 5-10 轮对话）       │
│       ↓ Weibull 衰减                                         │
│  Short-term      ←── 24 小时内容，已摘要                    │
│       ↓ access_count ≥ 10 + 重要性 ≥ 0.7                  │
│  Long-term       ←── 永久知识，向量索引                      │
│       ↓ >90 天或 decay_score < 0.15                         │
│  Archive          ←── 历史，按需加载                        │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│  Task State Memory  ←── 跨重启持久化（关键！）              │
│  - 当前任务 / 下一步 / 进度 / 输出                          │
├──────────────────────────────────────────────────────────────┤
│  注入引擎       ←── 策略 A/B/C/D/E 决定召回方式             │
│  自我反思        ←── 每个回答都检查上下文                    │
│  自动触发        ←── 每 10 轮（可配置）                   │
└──────────────────────────────────────────────────────────────┘
```

---

## 📦 任务状态记忆（最有价值的功能）

即使重启、断电或 session 切换后，Context-Hawk 也能从中断处精确继续。

```json
// memory/.hawk/task_state.jsonl
{
  "task_id": "task_20260329_001",
  "description": "完成 API 文档",
  "status": "in_progress",
  "progress": 65,
  "next_steps": ["审查架构模板", "向用户汇报"],
  "outputs": ["SKILL.md", "constitution.md"],
  "constraints": ["覆盖率必须达到 98%", "API 必须版本化"],
  "resumed_count": 3
}
```

```bash
hawk task "完成文档"        # 创建任务
hawk task --step 1 done  # 标记步骤完成
hawk resume               # 重启后继续 ← 核心功能！
```

---

## 🧠 结构化记忆

```json
{
  "id": "mem_20260329_001",
  "type": "task|knowledge|conversation|document|preference|decision",
  "content": "完整原始内容",
  "summary": "一行摘要",
  "importance": 0.85,
  "tier": "working|short|long|archive",
  "created_at": "2026-03-29T00:00:00+08:00",
  "access_count": 3,
  "decay_score": 0.92
}
```

### 重要性评分

| 分数 | 类型 | 行动 |
|-------|------|------|
| 0.9-1.0 | 决策/规则/错误 | 永久，最慢衰减 |
| 0.7-0.9 | 任务/偏好/知识 | 长期记忆 |
| 0.4-0.7 | 对话/讨论 | 短期，衰减至归档 |
| 0.0-0.4 | 聊天/问候 | **丢弃，永不存储** |

---

## 🎯 5 种上下文注入策略

| 策略 | 触发条件 | 节省 |
|------|---------|------|
| **A: 高重要性** | `重要性 ≥ 0.7` | 60-70% |
| **B: 任务相关** | 范围匹配 | 30-40% ← 默认 |
| **C: 最近** | 最近 10 轮 | 50% |
| **D: Top5 召回** | `access_count` Top 5 | 70% |
| **E: 完整** | 无过滤 | 100% |

---

## 🔍 MMR — 多样性召回

**MMR（最大边缘相关性）** 解决"相似记忆挤占多样化记忆"的问题。

传统向量搜索只返回最相似的，但可能全是同一主题。MMR 平衡相关性和多样性：

```
MMR = λ × 相关性(q, doc) − (1−λ) × 最大相似度(doc, 已选文档)

λ = 0.7：70% 相关性 + 30% 多样性
```

**用法：**
```python
from hawk.similarity import MMR

mmr = MMR(lambda_param=0.7)
selected = mmr.select(query_vector, candidate_vectors, top_k=5)
```

---

## 🧬 SimHash — 自动去重

**SimHash** 通过海明距离快速判断两段记忆是否重复。

- 计算每条记忆的 64 位指纹
- 两段记忆海明距离 < 3 则认为重复
- O(1) 比较，无需两两向量搜索

**工作原理：**
```
文本 → 分词 → 每个词 MD5 hash → 向量相加 → 生成指纹
```

**用法：**
```python
from hawk.similarity import SimHash

sh = SimHash()
if sh.is_duplicate(new_text, existing_text, threshold=3):
    print("重复，跳过存储")
else:
    print("新内容，存储")
```

---

## 🗜️ 5 种压缩策略

`summarize` · `extract` · `delete` · `promote` · `archive`

### 策略概览

| 策略 | 触发条件 | 动作 |
|------|---------|------|
| **summarize** | 文本超过500字符 | 调用 LLM 压缩成简洁摘要 |
| **extract** | 任意记忆 | 从内容提取关键实体和事实 |
| **delete** | importance < 0.3 且空闲 > 7天 | 永久删除 |
| **promote** | importance ≥ 0.7 且 access ≥ 5 | short → long 升级 |
| **archive** | 各层超时 | 移入 archive 层 |

### 使用方式

```python
from hawk.compression import MemoryCompressor

mc = MemoryCompressor()

# 单条操作
mc.summarize("mem_xxx")   # 压缩成长摘要
mc.extract("mem_xxx")     # 提取关键事实
mc.promote("mem_xxx")     # 升级为长期记忆
mc.archive("mem_xxx")     # 归档

# 批量
mc.compress_all("archive")  # 归档所有超时记忆
mc.compress_all("delete")   # 删除所有候选

# 诊断报告
report = mc.audit()
print(report["candidates"])
# {'to_summarize': [...], 'to_delete': [...], 'to_promote': [...], 'to_archive': [...]}
```

### 阈值配置

| 规则 | 阈值 |
|------|------|
| 升级重要度 | ≥ 0.7 |
| 升级访问次数 | ≥ 5 |
| 删除重要度 | < 0.3 |
| 删除空闲时间 | > 7 天 |
| 归档 working | > 24 小时 |
| 归档 short | > 30 天 |
| 归档 long | > 90 天 |

---

## 🔔 4 级警报系统

| 等级 | 阈值 | 行动 |
|-------|---------|------|
| ✅ Normal | < 60% | 安静 |
| 🟡 Watch | 60-79% | 建议压缩 |
| 🔴 Critical | 80-94% | 暂停自动写入，强制建议 |
| 🚨 Danger | ≥ 95% | 阻止写入，必须压缩 |

---

## 🚀 快速开始

```bash
# 一键安装（推荐，自动装好所有依赖）
bash <(curl -fsSL https://raw.githubusercontent.com/relunctance/hawk-bridge/master/install.sh)

# 启用技能
openclaw skills install ./context-hawk.skill

# 初始化
hawk init

# 核心命令
hawk task "我的任务"    # 创建任务
hawk resume             # 继续上次任务 ← 最重要
hawk status            # 查看上下文使用情况
hawk compress          # 压缩记忆
hawk strategy B        # 切换到任务相关模式
hawk introspect         # 自我反思报告
```

---

## 🔑 Jina API Key（语义搜索必需）

Context-Hawk 使用 **Jina AI** 生成向量嵌入。Jina 提供**免费额度**，足够个人使用。

### 获取免费 Jina API Key

1. **注册** https://jina.ai/（免费，无需信用卡）
2. **进入** https://jina.ai/settings/（Settings → API Keys）
3. **创建**新 API Key（点击 "Create API Key"）
4. **复制** Key（以 `jina_` 开头）

### 配置

```bash
# 安装脚本会自动询问，或手动配置：
mkdir -p ~/.hawk
cat > ~/.hawk/config.json << 'EOF'
{
  "openai_api_key": "jina_你的KEY",
  "embedding_model": "jina-embeddings-v3",
  "embedding_dimensions": 1024
}
EOF
```

> **为什么用 `openai_api_key` 字段？** Jina AI 采用 OpenAI 兼容 API 格式，所以复用该字段。

### 免费额度

| | 免费版 |
|--|--------|
| Embedding | 每月 100 万 tokens |
| Reranker | 每月 1 万 tokens |
| 够用吗 | ✅ 足够个人使用 |

---

## 自动触发：每 N 轮

每 **10 轮**（默认，可配置），Context-Hawk 自动：

1. 检查上下文水位
2. 评估记忆重要性
3. 向用户报告状态
4. 需要时建议压缩

```bash
# 配置（memory/.hawk/config.json）
{
  "auto_check_rounds": 10,          # 每 N 轮检查
  "keep_recent": 5,                 # 保留最近 N 轮
  "auto_compress_threshold": 70      # 超过 70% 时压缩
}
```

---

## 文件结构

```
context-hawk/
├── SKILL.md
├── README.md
├── LICENSE
├── scripts/
│   └── hawk               # Python CLI 工具
└── references/
    ├── memory-system.md           # 4层架构
    ├── structured-memory.md      # 记忆格式和重要性
    ├── task-state.md           # 任务状态持久化
    ├── injection-strategies.md  # 5种注入策略
    ├── compression-strategies.md # 5种压缩策略
    ├── alerting.md             # 警报系统
    ├── self-introspection.md   # 自我反思
    ├── lancedb-integration.md  # LanceDB 集成
    └── cli.md                  # CLI 参考
```

---

## 🔌 技术规格

- **持久化**: JSONL 本地文件，无需数据库
- **向量搜索**: LanceDB（可选）+ sentence-transformers 本地向量，自动回退到文件
- **跨 Agent**: 通用，无业务逻辑，适用于任何 AI agent
- **零配置**: 开箱即用，智能默认值
- **可扩展**: 自定义注入策略、压缩策略、评分规则

---

## 授权

MIT — 免费使用、修改与分发。
