# 结构化记忆格式 · Structured Memory Format

---

## JSON Schema

每条记忆的结构：

```json
{
  "id": "mem_<date>_<seq>",
  "type": "task|knowledge|conversation|document|preference|decision",
  "content": "原始完整内容",
  "summary": "一句话摘要（AI生成）",
  "importance": 0.85,
  "confidence": 0.9,
  "tier": "working|short|long|archive",
  "category": "profile|preference|entity|event|case|pattern",
  "created_at": "2026-03-28T10:00:00+08:00",
  "last_accessed_at": "2026-03-28T10:30:00+08:00",
  "access_count": 3,
  "decay_score": 0.92,
  "expires_at": null,
  "metadata": {
    "source": "conversation|document|extraction",
    "scope": "global|project-name",
    "l0_abstract": "一句话",
    "l1_overview": "段落摘要",
    "l2_content": "完整内容",
    "tier_history": ["working", "short"],
    "tags": ["laravel", "规范"]
  }
}
```

---

## Type 字段说明

| type | 说明 | 示例 |
|------|------|------|
| `task` | 任务目标 | "完成订单模块开发" |
| `knowledge` | 技术知识 | "Laravel事务用DB::transaction()" |
| `conversation` | 对话摘要 | "讨论了架构方案" |
| `document` | 文档片段 | "README内容摘要" |
| `preference` | 用户偏好 | "老周喜欢简洁直接的回复" |
| `decision` | 决策结论 | "决定不拆分Skill" |

---

## Category 字段说明（基于 memory-lancedb-pro）

| category | 说明 | 提取要求 |
|---------|------|---------|
| `profile` | 用户/Agent画像 | 偏好、习惯、风格 |
| `preference` | 明确偏好 | 具体要求、规范 |
| `entity` | 实体/对象 | 项目、模块、术语 |
| `event` | 事件/时间点 | 会议、决策、时间线 |
| `case` | 案例/问题 | bug、错误、解决方案 |
| `pattern` | 模式/规范 | 反复出现的模式 |

---

## 重要度评分规则

### AI 评分标准

每条记忆创建时，AI 自动评分：

```markdown
评分手册：
- 1.0：架构决策、团队红线、安全规范
- 0.9：错误教训、核心产出、合同级约定
- 0.8：重要任务、用户明确偏好、项目规范
- 0.7：技术知识、设计模式、经验总结
- 0.6：对话结论、非关键事实
- 0.5：讨论过程、探索性内容
- 0.3：闲聊、无关紧要的确认
- 0.1：问候、废话
```

### 晋升规则

```
working → short：创建后24小时未访问
short → long：access_count ≥ 5 且 importance ≥ 0.7
short → archive：decay_score < 0.15
long → archive：超过90天未访问
working → long：直接晋升（importance ≥ 0.9）
```

### 衰减公式

```python
decay_score = exp(-(age_days / half_life) ** beta)

# 例：30天半衰期，beta=1.0
# 30天后：e^(-1) ≈ 0.368
# 60天后：e^(-2) ≈ 0.135
```

---

## L0/L1/L2 分层存储（基于 memory-lancedb-pro）

每条记忆的 content 在存储时自动分层：

| Layer | 内容 | 用途 |
|-------|------|------|
| L0 | 一句话索引 | 快速检索 |
| L1 | 段落摘要 | 一般展示 |
| L2 | 完整内容 | 深度分析 |

```json
{
  "metadata": {
    "l0_abstract": "老周希望Skill简洁",
    "l1_overview": "老周偏好简洁直接的沟通风格，不喜欢冗长的解释",
    "l2_content": "完整对话内容..."
  }
}
```

---

## 自动去重

提取时与 LanceDB 中已有记忆对比：

1. **向量相似度** > 0.85 → 合并（merge）
2. **向量相似度** > 0.7 → 支持（support，追加证据）
3. **向量相似度** < 0.7 → 新建（create）
4. **完全重复** → 跳过（skip）

---

## 存取控制

- **workspace 边界**：USER.md / SOUL.md 等文件内容不进入 LanceDB（由 workspace-boundary.ts 控制）
- **scope 隔离**：按项目/用户分离记忆，互不污染
- **过期自动清理**：expire_at 到达后自动删除
