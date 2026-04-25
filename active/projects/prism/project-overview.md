# Prism — AI Protocol Gateway (P-layer)

> **Type**: Commercial product (C-band core)
> **Status**: Phase 1 planning
> **Repo**: `ailib-official/ai-lib-gateway` (to be created)
> **Architecture**: P-layer in S=(A,P,E), closed-source commercial gateway
> **Plan Source**: PRODUCT_PLAN_v2.md + ai_lib_gateway_phase1_plan.md v2.0

## Product Matrix Position

| | To B | To C |
|---|---|---|
| **Prism** | ① Prism Enterprise | ② Prism |

## Key Decisions (Confirmed 2026-04-25)

- **D2**: Enterprise + Prism share codebase, `--features enterprise` (Rust feature flag)
- **D3**: Phase 2 billing = pay-per-use + margin; Phase 3 = free-tier + overage
- **D5**: Phase 2 Enterprise + Vela Pro bundled; Phase 3 split

## Architecture

```
User → Prism (P-layer) → ai-lib-core (E-layer) → Provider APIs
         ↓
    Router / KeyPool / Pricer / Logger
    (closed-source C-band)
```

## Three-Zone Alignment

| Component | Band | License |
|-----------|------|---------|
| Prism routing engine | C | Proprietary |
| Key pool + scheduling | C | Proprietary |
| Pricer + billing | C | Proprietary |
| Admin API | C | Proprietary |
| Prism SDK (client) | A | Apache-2.0 |
| ai-lib-core dependency | A | Apache-2.0 |

## Phase Roadmap

- **Phase 1** (3 weeks): Core API + Key pool + Basic routing + 5 P0 Providers
- **Phase 2** (6-8 weeks): Smart routing + BYOK + Billing + Enterprise MVP
- **Phase 3** (3-6 months): Multi-modal + Local payments + SLA + Compliance templates

## Hot Products (Marketing Focus)

- Phase 1: "5-Provider free gateway" + WASM protocol demo
- Phase 2: BYOK mode + Smart routing "auto" mode
- Phase 3: Multi-modal aggregation API + Compliance template packs

## Phase 1 Tasks

| ID | Title | Priority | Depends On |
|----|-------|----------|------------|
| PR-P1-001 | Project skeleton (Axum + config + health) | P0 | — |
| PR-P1-002 | Core proxy (/v1/chat/completions sync + stream) | P0 | PR-P1-001 |
| PR-P1-003 | Key pool scheduling (rotate + cooldown + circuit-break) | P0 | PR-P1-002 |
| PR-P1-004 | Usage tracking (SQLite + Pricer) | P0 | PR-P1-002 |
| PR-P1-005 | Fallback routing (primary → secondary) | P0 | PR-P1-002, PR-P1-003 |
| PR-P1-006 | Docker deployment + Caddy TLS + api.prism.ailib.info | P0 | PR-P1-005 |
| PR-P1-007 | Admin API (keys/users/usage CRUD) | P1 | PR-P1-003, PR-P1-004 |
| PR-P1-008 | 5 P0 Providers integration verification | P0 | PR-P1-006 |

## Wave 2 Tasks (Productization Prelude)

| ID | Title | Priority | Depends On |
|----|-------|----------|------------|
| PR-PP-001 | Pack contract draft (JSON Schema + example) | P2 | PR-P1-008 |
| PR-PP-002 | Minimal cost routing example (not production SLA) | P2 | PR-P1-005, PR-P1-008 |
| PR-PP-003 | Constitution rules extraction (BIZ-001~005) | P1 | — |

## Gates

- Phase 1 does NOT block on PT-073 (uses published ai-lib-core v0.9.4)
- Phase 2 smart routing depends on Contact API stability (= PT-073 gate)
