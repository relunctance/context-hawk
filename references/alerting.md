# 报警系统 · Alerting System

---

## 概述

Context-Hawk 持续监控上下文使用量，当超过阈值时在每次回答中附带提醒。

---

## 配置项

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `hawk_alert_enabled` | `true` | 报警开关 |
| `hawk_alert_threshold` | `60` | 报警阈值（%） |
| `hawk_critical_threshold` | `80` | 严重报警阈值（%） |
| `hawk_check_interval` | `每次回答前` | 检查频率 |

---

## 报警等级

### 正常（< 60%）
不显示任何标记。

### 关注（60-79%）
```
[🦅 Context: 67% / 80%] 记忆较满，建议压缩 today.md
```

### 严重（≥ 80%）
```
[🦅⚠️ Context: 84% / 80%] 上下文紧张！请立即运行 /hawk compress
```

### 危险（≥ 95%）
```
[🦅🚨 Context: 97% / 80%] 上下文即将溢出！请先压缩 /hawk compress 再继续
```

---

## 开关命令

```
/hawk-alert on          开启报警（使用默认60%阈值）
/hawk-alert off         关闭报警
/hawk-alert set 70     设置阈值为70%
/hawk-alert status     查看当前配置
```

---

## 报警内容

每次回答时，检查上下文量并附加：

```markdown
[🦅 Context: 63% / 80%]
  today.md:  45行
  week.md:   89行  
  未压缩风险: today.md 超过100行
```

---

## 与压缩的联动

当上下文超过 80% 时：
1. 强制提示压缩
2. 提供快速压缩建议
3. 阻止新的非必要上下文写入（today.md 暂停自动追加）

---

## 持久化配置

报警配置保存在 `memory/.hawk-config`：

```json
{
  "alert_enabled": true,
  "alert_threshold": 60,
  "critical_threshold": 80,
  "last_check": "2026-03-28T12:00:00+08:00",
  "last_compress": "2026-03-27T18:00:00+08:00"
}
```
