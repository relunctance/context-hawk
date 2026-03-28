# 压缩策略详解 · Compression Strategies v2

---

## 5种策略总览

| 策略 | 命令 | 适用场景 | 压缩比 |
|------|------|---------|--------|
| `summarize` | `/hawk compress summarize` | 过程冗长、结论清晰 | 70-90% |
| `extract` | `/hawk compress extract` | 事实/决策/清单类 | 40-60% |
| `delete` | `/hawk compress delete` | 临时/调试/过时 | 100% |
| `promote` | `/hawk compress promote` | learnings/规范类 | 按需 |
| `archive` | `/hawk compress archive` | 超过30天 | 0%（只是移动） |

---

## 压缩前确认

所有压缩操作必须确认：

```
[Context-Hawk] 确认压缩
  范围：today.md（186行）
  策略：summarize（摘要）
  预计：从186行压缩至约28行

  请选择：
    [1] 全部压缩
    [2] 只压缩部分内容（输入行范围或关键词）
    [3] 取消
```

### 部分压缩交互

```
[Context-Hawk] 部分压缩

  today.md 共 186 行，当前内容摘要：
  [1-30]   老周提问关于 Skill 架构
  [31-80]   多轮讨论过程（冗长）
  [81-120]  最终决策结论
  [121-186] 后续细节

  请输入要压缩的范围（支持多种格式）：
    - 行范围：5-80
    - 关键词：输入 "Skill" 可定位包含的行
    - 类型：输入 "讨论" 可定位讨论类内容
```

---

## 智能策略推荐

压缩前自动分析并推荐：

```markdown
[Context-Hawk] 智能策略推荐

  文件：today.md (186行)

  内容分析（AI判断）：
  ┌──────────────────────────────────────────────────┐
  │ 30% 过程讨论   → summarize（节省~50行）            │
  │ 25% 具体代码   → extract（保留核心代码片段）        │
  │ 20% 决策结论   → promote（聚合到week.md）         │
  │ 15% 调试日志   → delete（完全删除）               │
  │ 10% 重要知识   → 保留                             │
  └──────────────────────────────────────────────────┘

  推荐组合：summarize + delete + promote

  预计效果：186行 → 45行（减少76%）

  [1] 执行推荐组合
  [2] 手动选择策略
  [3] 取消
```

---

## 策略1: summarize（摘要）

保留结论，删除过程。

```markdown
## 2026-03-28 Skill架构讨论

### 过程（压缩前 60行）
讨论是否拆分skill...
第一轮结论：不拆分，因为...
后来老周说...
又讨论了...
再后来...
最终决定：不拆分

### 结论（压缩后 8行）
- 决策：不拆分skill，电商作为 biz/examples/
- 原因：通用框架+业务示例是正确方向
```

---

## 策略2: extract（抽取）

从大量内容中抽取关键事实。

```markdown
## 团队规范（extract后）

### 核心事实
| Agent | 角色 | 核心职责 |
|-------|------|---------|
| 唐僧 | 架构师 | 技术方案、规范制定 |
| 悟空 | 后端 | Logic/Dao/Model |
| 八戒 | 前端 | Filament/Blade |
| 白龙 | 测试 | 测试用例，覆盖率≥98% |

### 关键规范（4条）
1. 四层架构禁止跨层
2. DTO+Enum强制使用
3. 测试覆盖率≥98%
4. API必须版本化
```

---

## 策略3: delete（删除）

彻底删除，需二次确认：

```
[Context-Hawk] ⚠️ 危险操作
  将删除：
  - today.md 第 15-28 行（调试日志）

  此操作不可逆，建议先 /hawk backup

  [1] 确认删除
  [2] 只删除第N行（N为奇数的行）
  [3] 取消
```

---

## 策略4: promote（晋升）

将分散的 learnings 聚合到主题文件：

```markdown
[Context-Hawk] promote 建议

  扫描到以下分散 learnings：

  today.md:42    → "老周喜欢简洁回复"（老周偏好）
  today.md:78    → "测试覆盖率要98%"（团队规范）
  week.md:15     → "skill要能复用"（技术积累）

  建议晋升到：
  - 老周偏好.md
  - 团队规范.md
  - 技术积累.md

  [1] 全部晋升
  [2] 选择性晋升
  [3] 取消
```

---

## 策略5: archive（归档）

将超期内容移入 archive 层（不删除）：

```markdown
[Context-Hawk] archive 建议

  以下内容超过30天，建议归档：

  - memory/month.md 中的2026-02内容
  - memory/week.md 中的第1-2周内容

  归档后：移入 memory/archive/2026-02/

  [1] 全部归档
  [2] 选择性归档
  [3] 取消
```

---

## 批量压缩

```bash
hawk compress all summarize     # 对所有层执行摘要
hawk compress --dry-run        # 预览不执行
hawk compress today delete "调试"  # 删除today.md中包含"调试"的行
```

---

## 压缩与记忆层级联动

压缩操作自动更新 LanceDB 中的衰减分：

- summarize（保留核心）：decay_score × 1.0
- extract（保留事实）：decay_score × 1.0
- promote（聚合）：重新计算 importance
- delete（删除）：decay_score → 0，触发清理
- archive（归档）：移入 archive 表
