# Memory Index — Per-Task Loading Strategy

> This file is the **first read** for any agent working on ai-lib ecosystem.
> It tells you which memory files to load based on your task. You do NOT need to read everything.

## File Map

| File | Size | Content | When to load |
|------|:----:|---------|-------------|
| `architecture.md` | ~120 lines | Product relationships, architectural principles, long-term vision | New features, architecture design, product decisions |
| `infrastructure.md` | ~130 lines | VPS access, SSH, deploy commands, CI config, LAN setup | Deployment, ops, CI changes, server access |
| `conventions.md` | ~80 lines | Naming rules, npm scope, toolchain, doc standards, rule index | Naming decisions, toolchain alignment, doc format questions |
| `log.md` | ~250 lines | Complete chronological decision history | Historical context, "why was this decided?", full audit trail |

## Task → Load

| Task type | Load |
|-----------|------|
| **Any task** | This INDEX.md (always) |
| **Prism / Prism gateway work** | `architecture.md` § Prism |
| **Vela / VelaClaw work** | `architecture.md` § Vela + § VelaClaw |
| **Eos work** | `architecture.md` § Eos + `infrastructure.md` § Eos Deploy |
| **New product / architecture** | `architecture.md` (full) + `conventions.md` (rule index) |
| **Deploy / CI / VPS** | `infrastructure.md` (full) |
| **npm publish / naming** | `conventions.md` § npm Scope |
| **Rust / toolchain** | `conventions.md` § Rust Toolchain |
| **Documentation** | `conventions.md` § Documentation |
| **Why was X decided?** | `log.md` + grep for the date/topic |
| **Creating new rule** | `conventions.md` § Constitution Rule Index |

## Governance Hierarchy (when in doubt)

```
ai-lib-constitution/rules/   ← highest authority (BIZ-*, ARCH-*, GOV-*)
  ↓
ai-lib-plans/memory/*.md     ← extracted durable decisions (this directory)
  ↓
ai-lib-plans/MEMORY.md       ← redirect pointer (read this file instead)
  ↓
ai-lib-plans/active/projects/<project>/project-overview.md  ← per-project truth
  ↓
ai-lib-plans/active/projects/<project>/tasks/*.yaml          ← task-level truth
```

## Quick Reference

**Prism production**: `https://api.prism.ailib.info` (43.159.226.236, Path B1)  
**Eos production**: `https://eos.ailib.info` (same VPS)  
**VPS SSH**: `ssh eos-hk` (key `~/.ssh/id_ed25519_eos_hk`)  
**npm scope**: `@ailib-official/*`  
**prism-sdk npm**: `@ailib-official/prism-sdk@0.1.0`  
**Default branch**: `main`  
**Private repos push**: `git push lan main` daily

---

> **For maintainers**: After making a durable decision, add it to the relevant file above AND append to `log.md`. Do NOT add new entries to `MEMORY.md` — it is now a redirect.
