# 分层记忆系统 · Memory Layer System

---

## 设计原则

**近因优先**：最近的记忆最容易被检索，权重最高。
**按需加载**：不把所有文件都塞进上下文，只加载需要的。
**可追溯**：历史内容不删除，只归档，备查。

---

## 四层结构

### Layer 1: today.md（每日新增）

**内容**：今天的对话中产生的重要信息
- 决策结论
- 新发现
- 用户偏好
- 待办事项

**格式**：
```markdown
## 2026-03-28

### 决策
- qujin-laravel-team Skill v2 已完成，推送 GitHub

### 用户偏好
- 老周喜欢简洁直接的回复

### 待办
- [ ] 飞书 agent 需要加载 qujingskills Skill
```

**规则**：
- 每次对话结束时自动追加
- 不重复已记录内容
- 超过 100 行时触发压缩提示

---

### Layer 2: week.md（本周汇总）

**内容**：周五自动从 today.md 合并本周重要内容
- 本周关键决策
- 项目里程碑
- 重要变更

**合并时机**：
- 每周五（可配置）
- 当 today.md 超过 200 行时强制合并

**格式**：
```markdown
## 2026-W13 周汇总

### 重要决策
- 3/28: 确定 qujin-laravel-team Skill 架构（通用业务版）
- 3/28: 覆盖率标准提升至 98%

### 项目状态
- qujingskills: 已发布 v1.0
- feedback 模块: PR 已提交

### 待处理
- 飞书 agent 配置（待老周确认）
```

---

### Layer 3: month.md（月度归档）

**内容**：每月初从 week.md 合并上月里程碑
- 月度成就
- 重大架构决策
- 团队规范变更

**格式**：
```markdown
# 2026-03 月度归档

## 重大决策
- 3月: 建立趣近团队四 Agent 协作规范

## 项目里程碑
- qujin-laravel-team Skill: v1.0 完成
- feedback 模块: 后端完成，PR #1

## 规范沉淀
- 四层架构：Controller→Logic→Dao→Model
- 覆盖率标准：≥98%
```

---

### Layer 4: archive/（历史归档）

**内容**：超过30天的内容移动到这里
- 不自动删除
- 通过 `memory_search` 可检索
- 不计入上下文

**格式**：保留原始内容，不做修改

```
archive/
├── 2026-02/          ← 按月份分子目录
│   ├── week-1.md
│   └── week-2.md
└── 2026-01/
    └── ...
```

---

## 启动加载规则

每次启动（读取 BOOTSTRAP.md 时）：

1. 读取 `memory/today.md`（今日）
2. 读取 `memory/week.md`（本周）
3. 检查 `memory/month.md` 是否存在
4. **不自动加载** archive/ 内容（按需加载）
5. 执行 `memory_search` 扫描 archive/ 时加载

---

## 迁移现有 MEMORY.md

如果已有 MEMORY.md，运行 `/hawk init` 会：

1. 将现有 MEMORY.md 内容按日期标记归档到 `memory/month.md`
2. 清空 MEMORY.md，写入指向新结构的说明
3. 创建 `memory/today.md` 和 `memory/week.md`

---

## 与 memory_search 的关系

`memory_search` 语义搜索**所有层**，包括 archive/。

搜索结果会标注来源：
```
[memory/today.md]  - 今天: 老周喜欢简洁回复
[memory/week.md]   - 本周: qujin-laravel-team v2已完成
[archive/2026-02/] - 历史: 团队规范v1
```

根据搜索结果，决定是否将 archive/ 内容晋升到更高层。
