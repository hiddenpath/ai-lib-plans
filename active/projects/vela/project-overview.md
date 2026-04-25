# Vela — AI Navigation Client (A-layer)

> **Type**: Dual product — A-band open (Vela) + C-band premium (Vela Pro)
> **Status**: Phase 1 planning (minimal UI)
> **Repo**: `ailib-official/vela` (to be created)
> **Architecture**: A-layer in S=(A,P,E), client-side navigation + routing
> **Plan Source**: PRODUCT_PLAN_v2.md

## Product Matrix Position

| | To B | To C |
|---|---|---|
| **Vela** | ③ Vela Pro | ④ Vela |

## Key Decisions (Confirmed 2026-04-25)

- **D1**: Phase 1 Vela To C = minimal demo UI (verify Prism API), not consumer-grade
- **D4**: WASM routing = Phase 2 enhancement, not Phase 1 core
- **D5**: Phase 2 Vela Pro bundled with Prism Enterprise; Phase 3 split

## Architecture

```
Vela (client-side)
├── Chat UI (A-band, open)
├── Local History (IndexedDB, A-band)
├── WASM Routing Decision (A-band basic / C-band advanced)
├── E2E Encrypted Sync Client (B-band, self-host / C-band Prism-hosted)
└── Prism SDK → Prism API
```

## Three-Zone Alignment

| Component | Band | License |
|-----------|------|---------|
| Vela chat UI core | A | Apache-2.0 |
| Local history (IndexedDB) | A | Apache-2.0 |
| WASM routing basic | A | Apache-2.0 |
| Prism SDK client | A | Apache-2.0 |
| E2E sync client implementation | B | Apache-2.0 (no SLA) |
| Advanced WASM routing | C | Proprietary |
| E2E sync service (Prism-hosted) | C | Proprietary |
| Compliance templates | C | Proprietary |

## Phase Roadmap

- **Phase 1** (3 weeks): Minimal chat UI + local history + Prism SDK integration (20% effort)
- **Phase 2** (6-8 weeks): Smart recommendations + model comparison + E2E sync + WASM routing
- **Phase 3** (3-6 months): Multi-device roaming + advanced analytics + subscription

## Hot Products (Marketing Focus)

- Phase 1: prism-sdk npm package (one-line integration)
- Phase 2: Vela side-by-side model comparison + WASM routing demo
- Phase 3: Privacy-first AI client with zero-knowledge sync

## Phase 1 Tasks

| ID | Title | Priority | Depends On |
|----|-------|----------|------------|
| PR-V1-001 | Vela Web skeleton (chat UI + Prism SDK) | P1 | PR-P1-006 |
| PR-V1-002 | Local conversation history (IndexedDB + export) | P1 | PR-V1-001 |
| PR-V1-003 | Provider/model navigation UI | P2 | PR-V1-001 |

## Dependencies

- Phase 1: Requires Prism API to be live (or mock for early dev)
- Phase 2: Requires Prism Phase 2 billing + smart routing
- WASM routing: Requires ailib-wasm-test v0.2.0
