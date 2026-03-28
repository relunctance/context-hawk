# 🦅 Context-Hawk

> **AI Context Memory Guardian** — Stop losing track, start remembering what matters.

*Give any AI agent a memory that actually works — across sessions, across topics, across time.*

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![OpenClaw Compatible](https://img.shields.io/badge/OpenClaw-2026.3%2B-brightgreen)](https://github.com/openclaw/openclaw)

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

## ✨ Features

### 🗂️ Four-Tier Memory Architecture
```
Working → Short-term → Long-term → Archive
```
Automatic Weibull decay — important memories stay, noise fades naturally. Powered by LanceDB vector storage.

### 🧠 Structured Memory
Every memory is a structured JSON record with:
- **Importance score** (0.0-1.0) — AI auto-scored
- **Category** (task/knowledge/preference/decision)
- **Tier** (working/short/long/archive)
- **L0/L1/L2 layers** (index/summary/full)

### 🎯 Smart Context Injection
5 switchable strategies — pick how much memory enters the context:
| Strategy | Best for |
|----------|---------|
| **A: High-importance** | Critical context limits |
| **B: Task-related** | Focused development (default) |
| **C: Recent conversation** | Fast iteration |
| **D: Top5 recall** | Lightweight mode |
| **E: Full recall** | Deep analysis |

### 🗜️ 5 Compression Strategies
`summarize` · `extract` · `delete` · `promote` · `archive`
- AI recommends the best strategy before compression
- Partial compression (by line range or keyword) supported
- Confirms before any destructive action

### 🔔 Alert System
Four alert levels with automatic defense:
```
Normal (<60%) → Watch (60-79%) → Critical (80-94%) → Danger (≥95%)
```
Auto-pauses writes before context overflow.

### 🔍 Self-Introspection
Every answer checks:
- Is the task clear?
- Is any required information missing?
- Am I stuck in a loop?
- Should I recall relevant memories?

### 🔌 LanceDB Integration
Works with [memory-lancedb-pro](https://github.com/CortexReach/memory-lancedb-pro):
- Vector search + BM25 full-text
- Cross-encoder reranking
- Automatic importance scoring
- **No external database** — embedded single-file storage
- **Graceful degradation** — works in pure-memory mode without LanceDB

---

## Quick Start

### Install Skill

```bash
# Install memory-lancedb-pro (recommended)
openclaw plugins install memory-lancedb-pro@beta

# Activate Context-Hawk skill
openclaw skills install ./context-hawk.skill
```

### Install CLI Tool

```bash
chmod +x scripts/hawk
ln -s scripts/hawk /usr/local/bin/hawk
```

### Initialize

```bash
hawk init
```

---

## CLI Commands

```bash
hawk init              # Initialize memory structure
hawk status           # View context usage
hawk compress         # Compress memory (interactive)
hawk strategy A       # Switch to High-importance mode
hawk introspect       # Self-introspection report
hawk search <query>   # Hybrid search (vector + full-text)
hawk alert on         # Enable alerts
hawk backup          # Backup LanceDB
```

---

## Memory Structure

```
memory/
├── today.md      ← Today's new entries (appended every session)
├── week.md       ← Weekly summary (merged Fridays)
├── month.md      ← Monthly archive (compressed monthly)
└── archive/     ← Historical archives (not in context)
```

Plus LanceDB stores the vector embeddings for semantic search.

---

## File Structure

```
context-hawk/
├── SKILL.md
├── scripts/
│   └── hawk              # Python CLI tool
└── references/
    ├── memory-system.md           # Four-tier architecture
    ├── structured-memory.md      # Memory format & importance
    ├── injection-strategies.md   # 5 injection strategies
    ├── compression-strategies.md  # 5 compression strategies
    ├── alerting.md               # Alert system
    ├── self-introspection.md     # Self-introspection
    ├── lancedb-integration.md    # LanceDB integration
    └── cli.md                    # CLI documentation
```

---

## Requirements

- **OpenClaw 2026.3+**
- LanceDB (optional, graceful degradation)
- Python 3.8+ (for CLI tool)

---

## License

MIT — free to use, modify, and distribute.
