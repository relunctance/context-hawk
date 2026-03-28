# Context-Hawk 🦅

> AI 上下文记忆守护者 — 分层记忆 / 自动压缩 / 报警系统 / 项目分流

**"上下文太满？让鹰来帮你盯着。"**

---

## 核心功能

### 🗂️ 分层记忆
```
memory/
├── today.md      ← 今日新增（每次对话追加）
├── week.md       ← 本周汇总（周五自动合并）
├── month.md      ← 月度归档（每月归档）
└── archive/     ← 历史归档（不计入上下文）
```
启动只加载 `today.md + week.md`，`memory_search` 跨层检索。

---

### 🗜️ 5种压缩策略

| 策略 | 适用场景 | 效果 |
|------|---------|------|
| `summarize` | 过程冗长、结论清晰 | 500行 → 30行 |
| `extract` | 事实/决策/清单类 | 保留核心 |
| `delete` | 临时/调试/过时内容 | 完全删除 |
| `promote` | learnings 类内容 | 聚合到主题文件 |
| `archive` | 超过30天 | 移入 archive/ |

---

### 🔔 报警系统

上下文超阈值时，每次回答附带提示：
```
[🦅 Context: 67% / 80%] 记忆较满，建议压缩 today.md
```

开关命令：
```bash
hawk alert on    # 开启
hawk alert off   # 关闭
hawk alert set 70 # 设置阈值
```

---

### 📦 项目分流

按话题/项目拆分记忆文件，`memory_search` 统一检索：
```
memory/
├── qujingskills.md   ← Skill 相关
├── 项目状态.md       ← 进度
└── 用户偏好.md      ← 沟通习惯
```

---

## 安装

### 方式一：安装 Skill（OpenClaw）

```bash
openclaw skills install ./context-hawk.skill
```

### 方式二：克隆仓库

```bash
git clone git@github.com:relunctance/context-hawk.git
```

### 安装 CLI 工具

```bash
chmod +x scripts/hawk
ln -s scripts/hawk /usr/local/bin/hawk
```

---

## 使用命令

```bash
hawk init              # 初始化分层结构
hawk status            # 查看上下文状态
hawk compress today summarize   # 压缩 today.md
hawk alert on          # 开启报警
hawk split --by-project # 按项目分流
```

---

## 文件结构

```
context-hawk/
├── SKILL.md
├── scripts/
│   └── hawk          # CLI工具
└── references/
    ├── memory-system.md           # 分层记忆说明
    ├── compression-strategies.md  # 5种压缩策略详解
    ├── alerting.md                # 报警系统
    ├── cli.md                     # CLI完整文档
    └── split-patterns.md          # 项目分流模式
```

---

## 发布信息

- **版本**: v1.0.0
- **作者**: 趣近团队
- **许可证**: MIT
