# Short-Term Memory

> Daily append-only logs. Important items are flushed to [../MEMORY.md](../MEMORY.md).

---

## Layout

| Location | Purpose |
|----------|---------|
| `../active/standup/daily/YYYY-MM-DD.md` | Daily work logs (append-only) |
| `../MEMORY.md` | Long-term curated facts (flush target) |

---

## Flush Process

When context grows or sessions end, extract durable facts from standups into MEMORY.md:

1. **Review** recent files in `active/standup/daily/`
2. **Extract** architecture decisions, conventions, gotchas, learnings
3. **Append** to `MEMORY.md` under appropriate section (Architecture Decisions, Key Learnings, etc.)
4. **Keep** standup files as historical record; MEMORY.md is the compressed source of truth

### What to Flush

- ✅ Architecture decisions that affect multiple projects
- ✅ Cross-project conventions (naming, formats, error codes)
- ✅ Gotchas and workarounds discovered during implementation
- ✅ Constitution rule references that are frequently needed

### What to Skip

- ❌ One-off task completion notes
- ❌ Transient blockers (already resolved)
- ❌ Highly specific implementation details (use code comments instead)

---

## For AI Agents

Use `memory_get` or `memory_search` (see memory-skill) to recall from:
- `MEMORY.md` — durable facts
- `active/standup/daily/*.md` — recent context
