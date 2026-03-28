# 项目分流模式 · Split Patterns v2

---

## 两种分流模式

### 模式1: 按项目分流

```
memory/
├── qujingskills.md     ← qujin-laravel-team Skill 相关
├── feedback.md        ← feedback 模块
├── context-hawk.md    ← context-hawk Skill
├── laravel.md         ← Laravel 框架学习
└── 通用.md            ← 跨项目通用内容
```

**适用**：多项目并行，每个项目有独立里程碑。

### 模式2: 按话题分流

```
memory/
├── 团队规范.md         ← Agent协作规范/配置
├── 用户偏好.md         ← 老周的沟通习惯/偏好
├── 项目状态.md         ← 当前所有项目的进度
├── 技术积累.md         ← 学到的技术经验/learnings
└── 待办事项.md         ← 跨项目待办
```

**适用**：项目单一但内容多样，需要快速检索特定类型。

---

## 分流执行

```
/hawk split --by-project
/hawk split --by-topic
```

交互流程：

```
[Context-Hawk] 分流模式：按项目

  扫描 memory/ 目录...

  识别到以下内容：
  ┌──────────────────────────────────────────┐
  │ qujingskills相关  23条  → qujingskills.md │
  │ feedback相关       8条   → feedback.md    │
  │ 其他               5条   → 通用.md       │
  └──────────────────────────────────────────┘

  [1] 全部确认分流
  [2] 手动调整
  [3] 取消
```

---

## 分流后的记忆结构

分流后，所有记忆同时存在于：
1. **分流文件**（human-readable）
2. **LanceDB**（vector searchable）

两者保持同步。

---

## 与 LanceDB 的对应

| 分流文件 | LanceDB 表 | 内容 |
|---------|-----------|------|
| qujingskills.md | longterm (scope=qujingskills) | Skill研发相关 |
| 用户偏好.md | longterm (category=preference) | 用户偏好 |
| 项目状态.md | shortterm (category=event) | 进度/里程碑 |
| 技术积累.md | longterm (category=pattern) | 技术经验 |
| 待办事项.md | working (category=task) | 任务 |

---

## 分流配置文件

`.hawk-split-config`：
```json
{
  "mode": "by-project",
  "files": {
    "qujingskills.md": ["skill", "研发", "规范", "agent"],
    "feedback.md": ["feedback", "pr", "issue"],
    "laravel.md": ["laravel", "php", "框架"]
  },
  "default_file": "通用.md",
  "last_split": "2026-03-29T00:00:00+08:00"
}
```
