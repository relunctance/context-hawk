# CLI 工具文档 · context-hawk

---

## 安装

将脚本路径加入系统 PATH，或使用完整路径：

```bash
chmod +x ~/.openclaw/workspace/skills/context-hawk/scripts/hawk
ln -s ~/.openclaw/workspace/skills/context-hawk/scripts/hawk /usr/local/bin/hawk
```

---

## 命令总览

```
hawk <command> [options]

Commands:
  hawk init                  初始化分层记忆结构
  hawk status                查看当前状态
  hawk compress <target> [strategy]   压缩记忆
  hawk split [--by-project|--by-topic] 分流记忆
  hawk alert on|off|set <n>  报警开关
  hawk search <query>         搜索所有记忆层
  hawk promote [--from <file>] 晋升内容
  hawk archive [--days <n>]   归档旧内容
```

---

## hawk init

初始化分层记忆目录结构。

```bash
hawk init [--force]
```

**功能**：
1. 创建 `memory/` 目录结构
2. 将现有 `MEMORY.md` 迁移到 `memory/month.md`
3. 创建空白的 `today.md`、`week.md`
4. 创建 `archive/` 目录
5. 创建 `.hawk-config` 配置文件

**选项**：
- `--force`：覆盖已存在的结构（会备份原文件）

---

## hawk status

查看当前上下文使用情况。

```bash
hawk status [--json]
```

**输出示例**（普通格式）：
```
[Context-Hawk] 上下文状态

  今日加载：   today.md    12行
  本周加载：   week.md     34行
  月度归档：   month.md    78行
  历史归档：   archive/    3文件（不计入）

  上下文总量：  124行
  估计占比：    41%

  状态：✅ 正常
  报警：🔔 开启（阈值60%）
```

**输出示例**（JSON格式）：
```bash
hawk status --json
```
```json
{
  "today": {"file": "today.md", "lines": 12},
  "week": {"file": "week.md", "lines": 34},
  "month": {"file": "month.md", "lines": 78},
  "archive_files": 3,
  "total_lines": 124,
  "context_percent": 41,
  "status": "normal",
  "alert_enabled": true,
  "threshold": 60
}
```

---

## hawk compress

压缩记忆文件。

```bash
hawk compress <target> [strategy] [--lines <start-end>]
```

**参数**：
- `target`：
  - `today` - today.md
  - `week` - week.md
  - `month` - month.md
  - `all` - 所有层
- `strategy`：
  - `summarize` - 摘要（默认）
  - `extract` - 抽取
  - `delete` - 删除
  - `promote` - 晋升
  - `archive` - 归档

**选项**：
- `--lines <start-end>`：只压缩指定行范围（如 `--lines 5-50`）
- `--dry-run`：预览压缩效果，不实际修改

**示例**：
```bash
hawk compress today summarize          # 压缩 today.md，使用摘要策略
hawk compress all summarize --dry-run # 预览所有文件的摘要效果
hawk compress week extract --lines 10-60  # 只压缩 week.md 第10-60行
hawk compress month archive           # 归档 month.md
```

---

## hawk alert

管理报警系统。

```bash
hawk alert <action>
```

**Actions**：
- `on` - 开启报警
- `off` - 关闭报警
- `set <n>` - 设置阈值（0-100）
- `status` - 查看当前配置
- `test` - 触发一次测试报警

**示例**：
```bash
hawk alert on          # 开启报警
hawk alert set 70      # 设置阈值为70%
hawk alert status      # 查看配置
```

---

## hawk split

按项目或话题分流记忆。

```bash
hawk split <mode>
```

**Modes**：
- `--by-project`：按项目拆分（qujingskills/feedback/其他）
- `--by-topic`：按话题拆分（团队规范/用户偏好/项目状态）

**示例**：
```bash
hawk split --by-project
```

**交互**：
```
[Context-Hawk] 分流模式：按项目

  识别到以下项目：
  1. qujingskills (23条记录)
  2. feedback (8条记录)
  3. 其他 (5条记录)

  [1] 全部确认分流
  [2] 手动选择
  [3] 取消
```

---

## hawk search

搜索所有记忆层。

```bash
hawk search <query> [--layer <layer>] [--json]
```

**参数**：
- `--layer`：限定搜索层（today/week/month/archive）
- `--json`：JSON格式输出

---

## hawk promote

晋升分散的learnings到主题文件。

```bash
hawk promote [--from <file>] [--to <file>]
```

---

## hawk archive

归档超过指定天数的记忆。

```bash
hawk archive [--days <n>]
```

默认归档超过30天的内容。
