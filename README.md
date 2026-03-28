# 🦅 Context-Hawk

> **AI Context Memory Guardian** — Stop losing track, start remembering what matters.

*Give any AI agent a memory that actually works — across sessions, across topics, across time.*

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![OpenClaw Compatible](https://img.shields.io/badge/OpenClaw-2026.3%2B-brightgreen)](https://github.com/openclaw/openclaw)
[![ClawHub](https://img.shields.io/badge/ClawHub-context--hawk-blue)](https://clawhub.com)

---

## What does it do?

Most AI agents suffer from **amnesia** — every new session starts from zero. Context-Hawk solves this with a production-grade memory management system that automatically captures what matters, lets noise fade away, and recalls the right memory at the right time.

**Without Context-Hawk:**
> "I already told you — I prefer concise replies!"
> (next session, the agent forgets again)

**With Context-Hawk:**
> (silently applies your communication preferences from session 1)
> ✅ Delivers concise, direct response every time

---

## ✨ 10 Core Features

| # | Feature | Description |
|---|---------|-------------|
| 1 | **Task State Memory** | `hawk resume` — persist task state, resume after restart |
| 2 | **4-Tier Memory** | Working → Short → Long → Archive with Weibull decay |
| 3 | **Structured JSON** | Importance scoring (0-10), category, tier, L0/L1/L2 layers |
| 4 | **AI Importance Scoring** | Auto-score memories, discard low-value content |
| 5 | **5 Injection Strategies** | A(high-imp) / B(task) / C(recent) / D(top5) / E(full) |
| 6 | **5 Compression Strategies** | summarize / extract / delete / promote / archive |
| 7 | **Self-Introspection** | Checks task clarity, missing info, loop detection |
| 8 | **LanceDB Vector Search** | Optional — hybrid vector + BM25 retrieval |
| 9 | **Pure-Memory Fallback** | Works without LanceDB, JSONL file persistence |
| 10 | **Auto-Dedup** | Merges duplicate memories automatically |

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     Context-Hawk                              │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Working Memory  ←── Current session (last 5-10 turns)      │
│       ↓ Weibull decay                                        │
│  Short-term      ←── 24h content, summarized                 │
│       ↓ access_count ≥ 10 + importance ≥ 0.7                │
│  Long-term       ←── Permanent knowledge, vector-indexed     │
│       ↓ >90 days or decay_score < 0.15                      │
│  Archive          ←── Historical, loaded on-demand            │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│  Task State Memory  ←── Persistent across restarts (key!)    │
│  - Current task / next steps / progress / outputs / blockers │
├──────────────────────────────────────────────────────────────┤
│  Injection Engine  ←── Strategy A/B/C/D/E decides recall   │
│  Self-Introspection ←── Checks every answer                  │
└──────────────────────────────────────────────────────────────┘
```

---

## 📦 Task State Memory (Core Feature)

**This is the most valuable feature.** Even after restart, power failure, or session switch, Context-Hawk resumes exactly where it left off.

```json
// memory/.hawk/task_state.jsonl
{
  "task_id": "task_20260329_001",
  "description": "Complete qujin-laravel-team Skill documentation",
  "status": "in_progress",
  "progress": 65,
  "next_steps": [
    "Review TangSeng's architecture template",
    "Report to LaoZhou"
  ],
  "outputs": [
    "SKILL.md",
    "constitution.md",
    "architect.md"
  ],
  "constraints": [
    "Coverage must reach 98%",
    "APIs must be versioned"
  ],
  "resumed_count": 3
}
```

```bash
hawk task "Complete the documentation"  # Create task
hawk task --step 1 done              # Mark step done
hawk resume                           # Resume after restart ← CORE
```

---

## 🧠 Structured Memory

```json
{
  "id": "mem_20260329_001",
  "type": "task|knowledge|conversation|document|preference|decision",
  "content": "Full original content",
  "summary": "One-line summary",
  "importance": 0.85,
  "confidence": 0.9,
  "tier": "working|short|long|archive",
  "category": "profile|preference|entity|event|case|pattern",
  "created_at": "2026-03-29T00:00:00+08:00",
  "access_count": 3,
  "decay_score": 0.92,
  "metadata": {
    "l0_abstract": "One-line index",
    "l1_overview": "Paragraph summary",
    "l2_content": "Full content",
    "scope": "global|project-name"
  }
}
```

---

## 🎯 5 Context Injection Strategies

| Strategy | Trigger | Saves |
|----------|---------|-------|
| **A: High-Importance** | `importance ≥ 0.7` | 60-70% |
| **B: Task-Related** | scope match | 30-40% ← default |
| **C: Recent** | last 10 turns | 50% |
| **D: Top5 Recall** | `access_count` Top5 | 70% |
| **E: Full** | no filter | 100% |

```bash
hawk strategy A   # High-importance mode
hawk strategy B   # Task-related (default)
hawk strategy     # View current
```

---

## 🗜️ 5 Compression Strategies

| Strategy | Best For | Effect |
|----------|----------|--------|
| `summarize` | Long process, clear conclusion | 500 lines → 30 |
| `extract` | Facts/decisions/lists | Keep core facts |
| `delete` | Temp/debug/outdated | Full delete |
| `promote` | learnings | Aggregate to topic file |
| `archive` | >30 days | Move to archive layer |

```bash
hawk compress today summarize     # Compress today.md
hawk compress                    # Interactive (confirm before any action)
```

---

## 🔔 4-Level Alert System

| Level | Threshold | Action |
|-------|-----------|--------|
| ✅ Normal | < 60% | No alert |
| 🟡 Watch | 60-79% | Suggest compression |
| 🔴 Critical | 80-94% | Pause auto-write, force suggest |
| 🚨 Danger | ≥ 95% | Block writes, must compress |

```bash
hawk alert on    # Enable alerts
hawk alert off   # Disable
hawk alert set 70  # Set threshold
```

---

## 🚀 Quick Start

```bash
# 1. Install LanceDB plugin (recommended)
openclaw plugins install memory-lancedb-pro@beta

# 2. Activate skill
openclaw skills install ./context-hawk.skill

# 3. Initialize
hawk init

# 4. Start a task
hawk task "Complete the API documentation"

# 5. Resume after restart
hawk resume
```

---

## CLI Commands

```bash
hawk init              # Initialize memory structure
hawk status           # View context usage
hawk task ["desc"]   # Create/manage task
hawk resume          # Resume last task ← most important!
hawk compress        # Compress memory (interactive)
hawk strategy [A-E] # Switch injection strategy
hawk introspect      # Self-introspection report
hawk search <query> # Hybrid search (vector + full-text)
hawk alert on|off    # Toggle alerts
hawk backup          # Backup LanceDB
```

---

## 📂 File Structure

```
context-hawk/
├── SKILL.md
├── README.md              # English (default)
├── README_zh.md           # 中文（中文版）
├── LICENSE
├── scripts/
│   └── hawk               # Python CLI tool
└── references/
    ├── memory-system.md           # 4-tier architecture
    ├── structured-memory.md      # Memory format & importance
    ├── task-state.md            # Task state persistence
    ├── injection-strategies.md   # 5 injection strategies
    ├── compression-strategies.md  # 5 compression strategies
    ├── alerting.md              # Alert system
    ├── self-introspection.md    # Self-introspection
    ├── lancedb-integration.md   # LanceDB integration
    └── cli.md                   # CLI documentation
```

---

## 🔌 Tech Specs

- **Persistence**: JSONL local files, no database required
- **Vector Search**: LanceDB (optional), auto-fallback to files
- **Cross-Agent**: Universal, no business logic, works with any AI agent
- **Zero-Config**: Works out-of-the-box with smart defaults
- **Extensible**: Custom injection strategies, compression policies, scoring rules

---

## License

MIT — free to use, modify, and distribute.
