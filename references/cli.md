# CLI 工具文档 · context-hawk v2

---

## 安装

```bash
chmod +x ~/.openclaw/workspace/skills/context-hawk/scripts/hawk
ln -s ~/.openclaw/workspace/skills/context-hawk/scripts/hawk /usr/local/bin/hawk
```

---

## 命令总览

```
hawk <command> [options]

核心命令：
  hawk init                  初始化（含LanceDB初始化）
  hawk status               查看上下文状态
  hawk compress <target> [strategy]   压缩记忆
  hawk strategy <A|B|C|D|E>  切换注入策略
  hawk introspect [--json]    自省报告
  hawk search <query>        混合检索（向量+全文）
  hawk inject               手动触发上下文注入

LanceDB管理：
  hawk extract [--force]     触发记忆提取
  hawk recall <query>       测试召回
  hawk backup               备份向量库
  hawk export [--json]       导出记忆
  hawk import <file>        从备份恢复

报警：
  hawk alert on|off|set <n>  报警开关

分流：
  hawk split --by-project    按项目分流
  hawk split --by-topic      按话题分流
```

---

## hawk status

```bash
hawk status [--json]
```

```
[Context-Hawk] 上下文状态 v2

  今日加载：   today.md    12行
  本周加载：   week.md     34行
  上下文总量：   46行

  LanceDB 记忆层：
  ┌─────────────────────────────────────────┐
  │ Working Memory   23条  估计占比  8%     │
  │ Short-term      156条  估计占比  21%    │
  │ Long-term       89条   估计占比  12%     │
  │ Archive          412条  不计入上下文      │
  └─────────────────────────────────────────┘

  复合衰减分：  0.73（正常）
  当前注入策略：B（任务相关）
  状态：✅ 正常
  报警：🔔 开启（阈值60%）
```

---

## hawk compress

```bash
hawk compress <target> [strategy] [--lines <start-end>] [--dry-run]
```

```bash
hawk compress today summarize      # 摘要压缩
hawk compress week extract        # 抽取压缩
hawk compress all promote --dry-run  # 预览晋升
hawk compress month archive       # 归档
```

---

## hawk strategy

```bash
hawk strategy [A|B|C|D|E]
hawk strategy    # 查看当前策略
```

```
[Context-Hawk] 注入策略

  当前策略：B（任务相关模式）

  A - 高重要度  (importance ≥ 0.7)  节省60-70%token
  B - 任务相关  (scope匹配)          节省30-40%token  ← 当前
  C - 最近对话  (最近10轮)          节省50%token
  D - Top5召回  (access_count Top5) 节省70%token
  E - 全部召回  (无过滤)            100%token
```

---

## hawk introspect

```bash
hawk introspect
hawk introspect --deep
hawk introspect --json
```

```
[Context-Hawk] 自省报告

  1. 任务明确度：✅ 明确
     当前任务：更新 qujin-laravel-team Skill

  2. 信息完整性：✅ 完整
     需求：✅ 规范清晰
     技术方案：✅ 已有

  3. 上下文占用：✅ 正常
     当前：41% / 阈值：80%

  4. 卡点检测：✅ 无
     无重复失败，无死循环

  5. 记忆召回：💡 可召回 2 条相关
     - 老周的沟通偏好（importance: 0.9）
     - 四个Agent职责边界（importance: 0.85）
```

---

## hawk search（混合检索）

```bash
hawk search <query>
hawk search "老周的偏好" --json
```

```
[Context-Hawk] 混合检索

  查询：老周的偏好

  向量检索结果（Top3）：
  [1] 老周的沟通偏好（0.94）← Long-term
  [2] 悟空的开发风格（0.71）← Short-term
  [3] 技术选型偏好（0.68）← Short-term

  全文检索结果（Top3）：
  [1] USER.md - 老周偏好
  [2] 团队规范.md - 沟通要求
  [3] memory/week.md - 周汇总

  [R] 召回：老周的沟通偏好
```

---

## hawk recall（召回测试）

```bash
hawk recall "四层架构规范"
```

```
[Context-Hawk] 召回测试

  查询：四层架构规范

  召回记忆：
  ┌──────────────────────────────────────────────────┐
  │ [Core] 四层架构红线：Controller→Logic→Dao→Model   │
  │ importance: 0.95 | access_count: 23            │
  │ last_accessed: 2小时前                           │
  │ decay_score: 0.91                              │
  └──────────────────────────────────────────────────┘

  建议注入上下文：是（importance ≥ 0.8）
```

---

## hawk backup

```bash
hawk backup
hawk backup --output ~/backup_hawk.zip
```

```
[hawk] 备份完成
  路径：~/.openclaw/memory-lancedb-backup-20260328.tar.gz
  大小：2.3MB
  内容：working.lance + shortterm.lance + longterm.lance + archive.lance
```
