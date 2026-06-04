# Prism — AI Protocol Gateway (P-layer)

> **Type**: P-layer product; **library** = A-band open (`prism-core`); **shell** = C-band commercial (Eos / Enterprise / future gateway)
> **Status**: Phase 1 in progress (library ahead of product HTTP)
> **Repos**:
> - `hiddenpath/eos` — `crates/prism-core` (A-band, Apache-2.0) + `eos-server` (C-band product shell, live at eos.ailib.info)
> - `ailib-official/prism-core` — future publish target (crates.io)
> - `ailib-official/ai-lib-gateway` — placeholder product repo; Phase 1 HTTP may land in **eos-server** or here (decision: evolve eos-server first)
> **Plan review**: 2026-06-04 strict audit (plan vs code alignment)

## Product Matrix Position

| | To B | To C |
|---|---|---|
| **Prism** | ① Prism Enterprise | ② Prism |
| **Eos**  | — | **⑤ Eos（逸思）** — 详见 `projects/eos/brand-rationale.md` |

## Key Decisions (Confirmed 2026-04-25, revised 2026-06-04)

- **D2**: Enterprise + Prism share codebase, `--features enterprise` (Rust feature flag)
- **D3**: Phase 2 billing = pay-per-use + margin; Phase 3 = free-tier + overage
- **D5**: Phase 2 Enterprise + Vela Pro bundled; Phase 3 split
- **D6 (2026-06-04)**: Phase 1 provider path = **prism-core libcurl** → Provider APIs; **not** ai-lib-core ExecutionPipeline (optional Phase 1.x / Phase 2 migration)
- **D7 (2026-06-04)**: Task tracking uses `scope: library | product`; library tasks may complete before HTTP/product acceptance

## Architecture (Phase 1 actual)

```
User → Gateway shell (Axum: eos-server today, api.prism.ailib.info target)
         → prism-core (A-band: proxy, key-pool, router, usage, admin logic)
         → libcurl → Provider APIs
```

Phase 2+ optional path: integrate ai-lib-core ProtocolLoader / ExecutionMetadata (does **not** block Phase 1; no hard dependency on PT-073).

## Three-Zone Alignment (revised 2026-06-04)

| Component | Band | License | Repo |
|-----------|------|---------|------|
| prism-core (proxy, key-pool, router, usage, admin **logic**) | **A** | Apache-2.0 | eos → ailib-official/prism-core |
| Gateway shell (routing policy UI, compliance filter, deploy config) | **C** | Proprietary | hiddenpath/eos (eos-server) |
| Prism SDK (client) | A | Apache-2.0 | ailib-official (future) |
| ai-lib-core (optional Phase 2+ integration) | A | Apache-2.0 | ailib-official/ai-lib-rust |

## Phase Roadmap

- **Phase 1** (3 weeks): OpenAI-compatible API + Key pool + Basic routing + 5 P0 Providers
- **Phase 2** (6-8 weeks): Smart routing + BYOK + Billing + Enterprise MVP
- **Phase 3** (3-6 months): Multi-modal + Local payments + SLA + Compliance templates

## Hot Products (Marketing Focus)

- Phase 1: "5-Provider free gateway" + WASM protocol demo
- Phase 2: BYOK mode + Smart routing "auto" mode
- Phase 3: Multi-modal aggregation API + Compliance template packs

## Phase 1 Tasks

| ID | Title | Scope | Status | Depends On |
|----|-------|-------|--------|------------|
| PR-P1-002-LIB | Core proxy library (libcurl sync + stream) | library | **completed** | — |
| PR-P1-003 | Key pool scheduling | library | **completed** | PR-P1-002-LIB |
| PR-P1-004 | Usage tracking (SQLite + Pricer) | library | **completed** | PR-P1-002-LIB |
| PR-P1-005 | Fallback routing | library | **completed** | PR-P1-002-LIB, PR-P1-003 |
| PR-P1-001 | Gateway shell: Axum + TOML config + `/health` | product | open | — |
| PR-P1-002 | OpenAI `/v1/*` HTTP + auth middleware | product | open | PR-P1-001 |
| PR-P1-009 | TOML `config.toml` loader (ConfigProvider) | library | open | — |
| PR-P1-010 | Anthropic Messages API adapter | library | open | PR-P1-002-LIB |
| PR-P1-011 | Quota enforcement (daily/monthly tokens) | library | open | PR-P1-004 |
| PR-P1-014 | Admin HTTP routes `/admin/*` | product | open | PR-P1-001, PR-P1-003, PR-P1-004 |
| PR-P1-006 | Docker + Caddy + api.prism.ailib.info | product | open | PR-P1-002 |
| PR-P1-013 | DNS for api.prism.ailib.info | product | open | PR-P1-006 |
| PR-P1-008 | 5 P0 Providers E2E verification | product | open | PR-P1-002, PR-P1-003, PR-P1-005 |
| PR-P1-012 | prism-core crates.io publish | library | open | PR-P1-008 |
| PR-P1-016 | VelaClaw → prism-core incremental migration | product | open | PR-P1-002-LIB |

## Wave 2 Tasks (Productization Prelude)

| ID | Title | Priority | Depends On |
|----|-------|----------|------------|
| PR-PP-001 | Pack contract draft (JSON Schema + example) | P2 | PR-P1-008 |
| PR-PP-002 | Minimal cost routing example (not production SLA) | P2 | PR-P1-005, PR-P1-008 |
| PR-PP-003 | Constitution rules extraction (BIZ-001~005) | P1 | PR-P1-005 (align zones first) |

## Gates

- Phase 1 does **not** block on PT-073 (prism-core has no ai-lib-core dependency today)
- Phase 2 smart routing + Contact-dependent features **are** gated by PT-073
- PR-PP-003 blocked on updating BIZ-002 / project zone tables to match prism-core A-band reality
