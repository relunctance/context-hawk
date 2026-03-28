# 报警系统 · Alerting System v2

---

## 报警等级

| 等级 | 阈值 | 显示 | 说明 |
|------|------|------|------|
| ✅ 正常 | < 60% | 不显示 | - |
| 🟡 关注 | 60-79% | `[🦅 Context: 67% / 80%]` | 建议压缩 |
| 🔴 严重 | 80-94% | `[🦅⚠️ Context: 84% / 80%]` | 强制提示压缩 |
| 🚨 危险 | ≥ 95% | `[🦅🚨 Context: 97% / 80%]` | 阻止新内容写入 |

---

## 报警信息格式

**正常（无显示）**

**关注**：
```
[🦅 Context: 67% / 80%]
  today.md:  156行（建议压缩）
  LanceDB Working: 23条
  → /hawk compress today summarize
```

**严重**：
```
[🦅⚠️ Context: 84% / 80%] 🔴 上下文紧张
  最大块：today.md (156行)
  建议立即压缩，否则新内容将停止自动写入
  → /hawk compress today summarize
  → /hawk strategy A（切换到高重要度模式）
```

**危险**：
```
[🦅🚨 Context: 97% / 80%] 🚨 上下文即将溢出
  阻止自动写入，优先运行压缩命令
  → /hawk compress all summarize --force
```

---

## 报警配置

| 配置 | 默认值 | 说明 |
|------|--------|------|
| `hawk_alert_enabled` | `true` | 开关 |
| `hawk_alert_threshold` | `60` | 关注阈值（%） |
| `hawk_critical_threshold` | `80` | 严重阈值（%） |
| `hawk_danger_threshold` | `95` | 危险阈值（%） |

---

## 报警触发时的自动防御

当 context > 80% 时：

1. **暂停** today.md 自动追加（防止继续膨胀）
2. **提示** 压缩建议
3. **建议** 切换注入策略到 A（高重要度）
4. **提示** /hawk introspect 查看详情

当 context > 95% 时：

1. **完全阻止** 新的非必要内容追加
2. **强制提示** 必须压缩后才能继续
3. **提供** 紧急压缩命令：`/hawk compress all summarize --force`

---

## 报警配置持久化

`.hawk-config`：
```json
{
  "alert_enabled": true,
  "alert_threshold": 60,
  "critical_threshold": 80,
  "danger_threshold": 95,
  "current_strategy": "B",
  "last_check": "2026-03-29T00:00:00+08:00",
  "last_compress": "2026-03-28T18:00:00+08:00"
}
```

---

## 开关命令

```
/hawk-alert on          开启报警（使用默认60%阈值）
/hawk-alert off         关闭报警
/hawk-alert set 70     设置阈值为70%
/hawk-alert set 60 80 95  # 分别设置关注/严重/危险阈值
/hawk-alert status     查看当前配置
```
