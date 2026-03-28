# 上下文注入策略 · Context Injection Strategies

---

## 策略概览

当前上下文 = `today.md` + `week.md` + `注入记忆`

注入记忆由策略决定，不同策略下召回的记忆不同。

---

## 策略 A：高重要度模式

**触发**：`/hawk strategy A`

**逻辑**：只注入 `importance ≥ 0.7` 的记忆

```
适用：上下文极度紧张（>80%）
效果：节省约 60-70% token
```

注入内容示例：
```
[重要记忆]
- 老周的沟通偏好：简洁直接，不喜欢废话 (importance: 0.9)
- 四层架构红线：Controller→Logic→Dao→Model，禁止跨层 (importance: 0.95)
- 测试覆盖率标准：≥ 98% (importance: 0.9)
```

---

## 策略 B：任务相关模式（默认）

**触发**：`/hawk strategy B`

**逻辑**：只注入 `metadata.scope` 或 `metadata.tags` 与当前任务匹配的记忆

```
适用：日常开发迭代
效果：节省约 30-40% token
```

注入内容示例：
```
[任务相关记忆]
- 当前项目：qujin-laravel-team
- 相关记忆：
  * 电商模块DAO查询模式已完成 (task: qujin-laravel-team)
  * 白龙反馈：覆盖率需达98% (task: qujin-laravel-team)
```

---

## 策略 C：最近对话模式

**触发**：`/hawk strategy C`

**逻辑**：只注入最近 10 轮对话中产生的记忆，按时间倒序

```
适用：快速迭代、短期任务
效果：节省约 50% token
```

---

## 策略 D：Top5 召回模式

**触发**：`/hawk strategy D`

**逻辑**：长期记忆只召回 `access_count` 最高的 5 条

```
适用：上下文轻量模式
效果：节省约 70% token
```

---

## 策略 E：全部召回模式

**触发**：`/hawk strategy E`

**逻辑**：不过滤，全部召回（向量相似度 Top20）

```
适用：深度分析、代码审查
注意：上下文占用大，不建议日常使用
```

---

## 策略切换命令

```bash
/hawk strategy A     # 高重要度
/hawk strategy B     # 任务相关（默认）
/hawk strategy C     # 最近对话
/hawk strategy D     # Top5召回
/hawk strategy E     # 全部召回
/hawk strategy       # 查看当前策略
```

---

## 动态注入流程

每次回答前：

```
1. 获取当前上下文量
2. 检查当前策略
3. 按策略从 LanceDB 召回记忆
4. 合并到上下文
5. 如果超过阈值 → 提示压缩
```

---

## 强制注入（不受策略影响）

以下类型不受策略限制，强制注入：

- 当前任务描述（task）
- 用户明确指定的偏好（preference importance ≥ 0.8）
- 团队红线/规范（decision importance ≥ 0.9）

---

## 噪声过滤

以下内容不存入记忆：

- 问候语（"你好"/"Hi"）
- 重复确认（"好的"/"OK"/"收到"）
- 调试日志
- 平台信封元数据（sender_id/message_id等）
