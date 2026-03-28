# 项目分流模式 · Split Patterns

---

## 两种分流模式

### 模式1: 按项目分流

每个项目一个独立文件：

```
memory/
├── qujingskills.md     ← qujin-laravel-team Skill 相关
├── feedback.md        ← feedback 反馈模块
├── laravel.md         ← Laravel 框架学习
└── 通用.md            ← 跨项目的通用内容
```

**适用场景**：多项目并行，每个项目有独立的里程碑和规范。

---

### 模式2: 按话题分流

按内容类型分流：

```
memory/
├── 团队规范.md         ← 四个 Agent 配置/协作规范
├── 用户偏好.md         ← 老周的沟通习惯/偏好
├── 项目状态.md         ← 当前所有项目的进度
├── 技术积累.md         ← 学到的技术经验
└── 待办事项.md         ← 跨项目的待办
```

**适用场景**：项目单一但内容多样，需要快速检索特定类型信息。

---

## 分流规则

### 判断标准

| 内容类型 | → 分流到 |
|---------|---------|
| Skill研发/规范/文档 | `qujingskills.md` |
| 具体项目进度/里程碑 | `项目状态.md` |
| 老周的偏好/习惯/要求 | `用户偏好.md` |
| 团队协作规范/Agent配置 | `团队规范.md` |
| 技术经验/最佳实践 | `技术积累.md` |
| 跨项目的TODO | `待办事项.md` |

### 重复内容处理

分流时发现重复记录：
1. 保留最新一份
2. 旧记录标记 `[已迁移至 xxx.md]`
3. 汇总表记录迁移历史

---

## 分流执行流程

```
1. /hawk split --by-project
2. 扫描所有记忆文件
3. 识别内容主题（AI判断）
4. 显示分流预览
5. 用户确认
6. 执行分流
7. 更新 memory_search 索引
```

---

## 晋升到更高层

分流后，内容仍可能被进一步晋升：

- `today.md` → `week.md`（周五合并）
- `week.md` → `month.md`（每月归档）
- `month.md` → `archive/`（超过3个月）

---

## 分流后的搜索

`memory_search` 跨所有分流文件检索：

```
[memory/qujingskills.md] - qujin-laravel-team Skill v2已完成
[memory/项目状态.md]     - feedback PR#1等待review
[memory/用户偏好.md]     - 老周喜欢简洁直接的回复
```

---

## 分流配置文件

`.hawk-split-config` 记录分流规则：

```json
{
  "mode": "by-project",
  "files": {
    "qujingskills.md": ["skill", "研发", "规范", "qujin"],
    "feedback.md": ["feedback", "反馈", "pr"],
    "laravel.md": ["laravel", "php", "框架"]
  },
  "default_file": "通用.md",
  "last_split": "2026-03-28T12:00:00+08:00"
}
```
