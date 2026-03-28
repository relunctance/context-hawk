# 自省机制 · Self-Introspection

---

## 核心能力

每次回答前，context-hawk 自动检查：

1. **任务明确度**：当前任务是否清晰？
2. **信息完整性**：是否缺少必要信息？
3. **卡点检测**：是否陷入死循环？
4. **记忆对齐**：是否需要召回记忆来辅助？

---

## 自省检查清单

```markdown
[Context-Hawk] 自省检查

1. 任务明确度
   ✅ 任务描述清晰
   ⚠️  任务模糊，需要追问
   ❌  任务不明确，已阻塞

2. 信息完整性
   ✅ 需求/规范/步骤齐全
   ⚠️  缺少 [具体缺失项]
   ❌  严重缺少信息

3. 上下文占用
   📊 当前: 58% / 阈值: 80%
   ✅ 上下文充足
   ⚠️  上下文较满，建议压缩

4. 卡点检测
   ✅ 无卡点
   ⚠️  检测到重复失败，可能进入死循环
   ❌  已死循环，需要干预

5. 记忆召回建议
   💡 可召回相关记忆: 3条
   📎 最近相关: "老周的沟通偏好"
```

---

## 自省触发条件

| 触发条件 | 说明 |
|---------|------|
| 每次回答前（可选） | 低频，context < 40% |
| 每次回答前（默认） | context 40-60% |
| 每次回答前（强制） | context > 60% |
| 用户提问时 | 检测到模糊/缺失信息 |
| 连续重复失败 | 检测到死循环模式 |

---

## 自省输出格式

### 正常状态
```
[🦅 自省] ✅ 状态正常
  任务：完成 qujin-laravel-team Skill 文档
  上下文：41%
  建议：可继续
```

### 缺少信息
```
[🦅 自省] ⚠️ 缺少信息
  任务：实现订单支付模块
  缺少：
    ❌ 支付接口文档（唐僧未出方案）
    ❌ 第三方支付商户信息
  建议：
    → 向唐僧（架构师）请求技术方案
    → 补充支付接口文档
```

### 上下文紧张
```
[🦅 自省] 🔴 上下文紧张
  当前：78% / 阈值：80%
  最大块：today.md (156行)
  建议：
    → /hawk compress today summarize
    → /hawk strategy A（切换到高重要度模式）
```

### 死循环检测
```
[🦅 自省] 🚨 死循环警告
  检测：同一问题重复3次未解决
  问题：Laravel事务写法
  建议：
    → 查看 memory-longterm 中的 "事务规范" 记忆
    → 参考 qujin-laravel-team/constitution.md 第12条
```

---

## 自省配置

```json
{
  "introspection_enabled": true,
  "introspection_interval": "every_answer",  // every_answer / on_demand
  "loop_detection_threshold": 3,
  "info_gap_check": true,
  "context_threshold_forced_check": 60
}
```

---

## 自省命令

```bash
/hawk introspect        # 立即自省
/hawk introspect --json  # JSON格式输出
/hawk introspect --deep  # 深度自省（包含记忆召回测试）
```

---

## 与 memory-lancedb-pro 的协作

自省使用 memory-lancedb-pro 的检索能力：

1. 检测到任务模糊 → 从 Long-term 记忆召回相关知识
2. 检测到缺少规范 → 从 Archive 记忆召回历史规范
3. 检测到死循环 → 从 Case 记忆召回历史解决方案
4. 检测到重复失败 → 触发 self-improvement 写入
