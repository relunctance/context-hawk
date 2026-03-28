# LanceDB 集成 · memory-lancedb-pro Integration

---

## 架构概览

```
context-hawk
     ↓ 调用
memory-lancedb-pro（ LanceDB 向量库）
     ↓ 存储
~/.openclaw/memory-lancedb/
     ├── working.lance     (工作记忆)
     ├── shortterm.lance  (短期记忆)
     ├── longterm.lance   (长期记忆)
     └── archive.lance    (归档记忆)
```

---

## 安装 memory-lancedb-pro

### 方式一：openclaw CLI（推荐）

```bash
openclaw plugins install memory-lancedb-pro@beta
openclaw config validate
openclaw gateway restart
```

### 方式二：npm

```bash
npm i memory-lancedb-pro@beta
```

然后在 `openclaw.json` 中配置：

```json
{
  "plugins": {
    "slots": { "memory": "memory-lancedb-pro" },
    "entries": {
      "memory-lancedb-pro": {
        "enabled": true,
        "config": {
          "embedding": {
            "provider": "openai-compatible",
            "apiKey": "${OPENAI_API_KEY}",
            "model": "text-embedding-3-small"
          },
          "autoCapture": true,
          "autoRecall": true,
          "smartExtraction": true,
          "extractMinMessages": 2,
          "extractMaxChars": 8000
        }
      }
    }
  }
}
```

---

## context-hawk 与 memory-lancedb-pro 的协作

```
context-hawk（Agent层）
  ├─ /hawk compress     → 触发 memory-lancedb-pro 的压缩/归档
  ├─ /hawk strategy    → 控制 memory-lancedb-pro 的召回策略
  ├─ /hawk introspect  → 使用 memory-lancedb-pro 的自省能力
  └─ /hawk status      → 显示四层记忆状态

memory-lancedb-pro（存储层）
  ├─ 向量检索（Vector Search）
  ├─ BM25全文检索
  ├─ Weibull衰减
  ├─ 自动提取（Smart Extraction）
  └─ 三层晋升（Peripheral ↔ Working ↔ Core）
```

---

## 配置项对照

| context-hawk 配置 | memory-lancedb-pro 配置 | 说明 |
|-----------------|------------------------|------|
| 分层阈值 30天 | `decay.recencyHalfLifeDays: 30` | 短期记忆半衰期 |
| 分层阈值 90天 | `tier.peripheralAgeDays: 90` | 归档阈值 |
| 重要度阈值 0.7 | `tier.coreAccessThreshold: 10` | 晋升阈值 |
| 报警阈值 60% | - | context-hawk 独立配置 |
| Beta 衰减参数 | `decay.betaCore/Working/Peripheral` | 各层衰减参数 |

---

## 降级模式

当 memory-lancedb-pro 不可用时，context-hawk 自动切换到纯文件模式：

```
LanceDB 可用
  → 四层分层 + 向量检索 + Weibull衰减

LanceDB 不可用
  → memory/ 目录结构（today/week/month/archive）
  → 全文搜索（grep）
  → 手动衰减（无自动）
  → 覆盖率：90%（功能完整度）
```

降级后，所有 `/hawk` 命令正常工作，只是检索能力从向量搜索降级为关键词搜索。

---

## 手动触发提取

当 memory-lancedb-pro 安装后，对话会自动触发提取。也可以手动触发：

```bash
hawk extract --force    # 强制提取当前对话
hawk extract --dry-run  # 预览提取结果，不存入
```

---

## 召回测试

```bash
hawk recall "老周的沟通偏好"   # 测试召回
hawk recall "四层架构规范"    # 测试召回
hawk verify                    # 验证记忆一致性
```

---

## 备份与导出

```bash
hawk backup               # 备份 LanceDB 到压缩文件
hawk export --json       # 导出为 JSON
hawk import backup.zip   # 从备份恢复
```

---

## 环境变量

| 变量 | 说明 |
|------|------|
| `OPENAI_API_KEY` | 向量嵌入 API（可替换为 Jina/Gemini/Ollama） |
| `MEMORY_LANCEDB_DIR` | LanceDB 数据目录（默认 ~/.openclaw/memory-lancedb/） |
| `MEMORY_SCOPE` | 当前作用域（如项目名） |
