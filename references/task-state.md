# 任务状态记忆 · Task State Memory

> **这是 Context-Hawk 最有价值的 Feature。** 让 AI Agent 即使重启、断电、切换会话，也能从断点继续。

---

## 解决的问题

| 痛点 | 解决 |
|------|------|
| Agent 重启后不知道上次做到哪了 | 任务状态持久化，重启后 `/hawk resume` |
| 任务做到一半换个 session 就忘了 | 每次任务变更自动更新 task_state.jsonl |
| 一直重复做同样的事 | `done_steps` 记录已完成步骤 |
| 空转不知道下一步是什么 | `next_steps` 明确下一步 |
| 任务完成后没有产出物记录 | `outputs` 记录所有产出物 |

---

## 数据结构

```json
{
  "task_id": "task_<date>_<seq>",
  "description": "完成 qujin-laravel-team Skill 文档",
  "status": "in_progress|pending|completed|blocked",
  "progress": 65,
  "priority": "high|medium|low",
  
  "steps": [
    {
      "id": 1,
      "description": "补充 backend-dev.md DAO 示例",
      "status": "completed",
      "done_at": "2026-03-29T00:15:00+08:00"
    },
    {
      "id": 2,
      "description": "review 唐僧方案模板",
      "status": "in_progress",
      "blocked_by": null
    },
    {
      "id": 3,
      "description": "向老周汇报进度",
      "status": "pending",
      "blocked_by": 2
    }
  ],
  
  "next_steps": [
    "补充 backend-dev.md 中的 DAO 查询示例",
    "review 唐僧方案模板",
    "向老周汇报进度"
  ],
  
  "outputs": [
    "SKILL.md 完成",
    "constitution.md 完成",
    "architect.md 完成"
  ],
  
  "constraints": [
    "覆盖率需达 98%",
    "API 需版本化"
  ],
  
  "blockers": [],
  
  "created_at": "2026-03-29T00:00:00+08:00",
  "updated_at": "2026-03-29T00:20:00+08:00",
  "resumed_count": 3,
  "last_agent": "main-session"
}
```

---

## 生命周期

```
hawk task "描述任务"      → 创建任务（pending）
hawk task --start        → 开始任务（in_progress）
hawk task --step 1 done  → 标记步骤完成
hawk task --next "下一步" → 添加下一步
hawk task --output "产出" → 记录产出物
hawk task --block "原因"  → 标记阻塞
hawk resume              → 恢复任务
hawk task --done         → 完成任务
```

---

## hawk task 命令

```bash
hawk task "完成 Skill 文档"           # 创建新任务
hawk task                              # 查看当前任务
hawk task --start                      # 开始/恢复任务
hawk task --step 1 done               # 标记第1步完成
hawk task --next "补充 README"        # 添加下一步
hawk task --output "SKILL.md 完成"    # 记录产出物
hawk task --block "缺少Token"        # 记录阻塞原因
hawk task --done                      # 完成任务
hawk task --abort                     # 放弃任务
hawk task --list                      # 列出所有任务
hawk resume                           # 恢复最后任务（最常用）
```

---

## hawk resume — 恢复任务

这是最核心的命令。即使完全重启，只要运行 `hawk resume`，Agent 就能：

```
[Context-Hawk] 任务恢复

  任务ID：task_20260329_001
  描述：完成 qujin-laravel-team Skill 文档
  进度：65%
  状态：in_progress

  已完成步骤（3/5）：
    ✅ 1. SKILL.md 完成
    ✅ 2. constitution.md 完成
    ✅ 3. architect.md 完成

  当前步骤：
    🔄 4. review 唐僧方案模板（进行中）

  待完成步骤：
    ⬜ 5. 向老周汇报进度

  约束条件：
    - 覆盖率需达 98%
    - API 需版本化

  产出物：
    - SKILL.md
    - constitution.md
    - architect.md

  [回车继续执行步骤4]
```

---

## 自动任务状态更新

以下情况会自动更新任务状态：

| 触发 | 自动操作 |
|------|---------|
| 创建新文件 | 记录到 `outputs` |
| 完成讨论确定决策 | 记录到 `outputs` |
| 运行测试失败 | 记录到 `blockers` |
| 用户提出新需求 | 更新 `next_steps` |
| 用户确认完成 | 更新 `progress = 100%` |

---

## 多任务管理

```bash
hawk task --list                    # 列出所有任务
hawk task --switch task_20260328_001  # 切换到另一个任务
hawk task --archive                 # 归档已完成任务
```

---

## 与其他功能的关系

```
Task State Memory
    │
    ├─── Self-Introspection → 读取当前任务，判断任务是否明确
    │
    ├─── Compression → 压缩时不压缩 task_state.jsonl
    │
    ├─── Injection Strategy → 当前任务自动召回（强制注入）
    │
    └─── Archive → 超过 30 天未完成的任务自动归档
```

---

## 文件存储

```
memory/.hawk/
├── config.json          # 配置
├── task_state.jsonl   # 任务状态（当前/所有任务）
├── memories.jsonl      # 结构化记忆
└── index.json         # 索引
```

`task_state.jsonl` 为 JSONL 格式（每行一个任务），方便追加和检索。
