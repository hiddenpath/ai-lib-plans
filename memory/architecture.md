# Memory — Architecture & Product Decisions

> Extracted durable decisions. Complete chronological record: [`log.md`](./log.md)
> Loading strategy: [`INDEX.md`](./INDEX.md)

**Last updated**: 2026-06-21

---

## Core Principles

### Protocol-Driven (ARCH-001)
一切逻辑皆算子，一切配置皆协议。Adding a provider = manifest only, no runtime code.

### Operator Pipeline (ARCH-002)
Chat flow: decode → select → accumulate → fanout → map.

### Cross-Runtime Consistency (ARCH-003)
All runtimes (Rust/Python/TS/Go) pass ai-protocol compliance tests. Unified request/response format.

### E/P Separation
- **Core (E)**: types, error, protocol, drivers, transport, pipeline, client, mcp → compiles to WASM
- **Contact (P)**: routing, cache, batch, plugins, telemetry, guardrails → policy layer
- Contract: `ExecutionResult<T>` with `ExecutionMetadata`

→ Source: [`log.md` § Architecture Decisions](./log.md)

---

## Product Architecture

### Three-Brand System

| Brand | Role | Band | Form |
|-------|------|------|------|
| **Prism** | API Gateway platform | A (core) / C (product shell) | VPS service |
| **Eos** (逸思) | Consumer web platform | C (closed-source) | Hosted website |
| **Vela** | Client runtime platform | A (open) | Multi form-factor |

→ Source: [`log.md` § 2026-04-30](./log.md)

### Prism Architecture

- **prism-core** (A-band, Apache-2.0): proxy, key-pool, router, usage, admin, Anthropic adapter
  - Published: crates.io `prism-core-routing` v0.1.0
  - No dependency on ai-lib-core (Phase 2+ optional)
- **ai-lib-gateway** (C-band, closed): Axum HTTP shell, `/v1/*` OpenAI-compatible, `/admin/*`, Docker + Caddy
  - Production: `https://api.prism.ailib.info` (43.159.226.236, Path B1 with Eos Caddy)
- **Eos does NOT route through Prism** (Phase 1): Eos → eos-server (own proxy) → providers
  - Deferred: `EOS-REQ-P2-001` — Eos frontend switch to Prism API

→ Source: [`log.md` § 2026-06-04](./log.md)

### Vela Architecture

- **Phase 1**: Web SPA (React + Vite) + prism-sdk → Prism API
- **Phase 2**: WASM routing + model comparison + E2E sync
- **Phase 3**: Multi-device + subscription
- Repo: `ailib-official/vela` (pnpm monorepo: `packages/prism-sdk` + `apps/web`)
- PR-V1-001 completed — prism-sdk@0.1.0 npm, smoke OK 2026-06-21
- PR-V1-002 completed — IndexedDB history PR #4 `baa7f4a`

→ Source: [`log.md` § 2026-06-21](./log.md)

### Vela Long-Term Vision (Intent, not current plans)

| Phase | VelaClaw | Vela |
|-------|----------|------|
| **1 (now)** | Claw Rust agent product | Web client components |
| **2** | → reference implementation | → cross-form-factor platform |
| **3** | maintain reference | formalize (semver, contribution guide) |

Core intent: VelaClaw is NOT the only agent — anyone can build with ai-lib-ts/py/go. Vela is NOT just a web client — its chat UI, history, routing are reusable components for any agent. Prism is THE unified API backend.

→ Full detail: [`log.md` § 2026-06-21](./log.md)

### VelaClaw

- **Ecosystem**: Claw, Rust-only, desktop/CLI agent SKU
- **Execution (VL-ARCH-001)**: BYOK → AiClient直连；prism-core内嵌 for unknown providers + telemetry
- **NOT** default HTTP Gateway client (Vela Web client IS)
- Python/TS agents: use ai-lib-python / ai-lib-ts, NOT VelaClaw
- All EVO tasks complete: VL-EVO-001→002→003→004
- Crate layout (VL-RUST-001): `lib.rs` = module tree, `main.rs` = thin binary

→ Source: [`log.md` § 2026-06-09](./log.md)

### Eos

- **Position**: Independent To-C consumer website, browser-accessible, no login required (Phase 1)
- **Brand**: Eos（逸思）— Greek dawn goddess
- **Repo**: `hiddenpath/eos` (private, commercial), C-band closed-source
- **Architecture**: Caddy → eos-server (Axum proxy + libcurl) → xray (SOCKS) → providers
- **Production**: `https://eos.ailib.info` live since 2026-05-27
- **Regional compliance**: zh-cn vs global dual-stack routing (EOS-ARCH-R1~R5)
- **Phase 2**: User registration + cloud history sync (EOS-P2-001~003)
- **Future**: Long-term convergence to Prism API (EOS-REQ-P2-001, deferred)

→ Source: [`log.md` § 2026-05-09](./log.md), [`../active/projects/eos/project-overview.md`](../active/projects/eos/project-overview.md)

---

## Historical Compliance & Release Waves

Wave-1 through Wave-4 compliance matrix, release trains (v0.8.0–v0.8.4), and generative expansion (PT-036–PT-062) are archived in the complete log.

→ Source: [`log.md` § Architecture Decisions](./log.md)
