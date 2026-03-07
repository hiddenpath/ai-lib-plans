# Project Memory — Durable Facts & Decisions

> Long-term memory for the ai-lib ecosystem. Curated facts that persist across sessions.
> See [memory/](memory/) for short-term daily logs. Flush important items here periodically.

**Last Updated**: 2026-03-07

---

## Architecture Decisions

### Protocol-Driven Design (ARCH-001)
- **Principle**: 一切逻辑皆算子，一切配置皆协议
- All provider logic is driven by YAML manifests in ai-protocol. Zero hardcoded provider code in runtimes.
- Adding a new provider = add manifest only, no runtime code changes.
- Runtimes: ai-lib-rust, ai-lib-python, ai-lib-ts load manifests via ProtocolLoader.

### Operator Pipeline (ARCH-002)
- Chat flow: decode → select → accumulate → fanout → map
- Streaming uses unified StreamingEvent system.
- Each capability (streaming, tools, multimodal) maps to operator modules.

### Cross-Runtime Consistency (ARCH-003)
- All runtimes must pass ai-protocol compliance tests.
- Message roles: system, user, assistant, tool (per standard_message_roles).
- Unified request/response format across Rust, Python, TypeScript.

### Multimodal Documentation Governance (ai-protocol)
- In multimodal survey/integration documents, separate verified facts from design assumptions explicitly.
- Mark evidence levels for key claims (official docs, implementation tests, assumptions) to keep conclusions reproducible.
- Use compliance-first as execution gate: feature planning must map to `ai-protocol/tests/compliance/` before large-scale runtime implementation.
- Keep protocol-driven boundaries clear: avoid provider-specific hardcoded runtime logic; prefer manifest/schema-driven behavior.
- Add rollback readiness to feature plans (feature flags, rollback triggers, and rollback steps) before enabling new multimodal capabilities.

### Generative Coverage Fullchain Plan (ai-protocol)
- For near-term expansion, use a v2-primary path with explicit v1 compatibility mapping.
- Execute in a P0 tiered provider set first (OpenAI/Anthropic/Gemini + DeepSeek/Qwen/Doubao), then expand in P1/P2.
- Treat ai-protocol-mock as a required parity layer for multimodal sync/stream/async behavior and failure injection.
- Require tri-runtime semantic alignment (Rust/Python/TS) before broad rollout; compliance matrix is the main readiness gate.
- Keep spiderswitch as capability-routing execution plane; strategy decisions remain in upper-layer applications.

### P1/P2 Expansion Governance (ai-protocol)
- P1 provider expansion uses evidence-scored wave planning; onboarding should be phased rather than parallel bulk integration.
- Video generation/editing must follow a normalized lifecycle and event contract before broad runtime rollout.
- Tri-runtime performance optimization is allowed only when semantic parity remains unchanged under compliance gates.
- Go/WASM runtime support should stay optional and disabled-by-default until MVP compliance subset is proven.
- Drift detection should run in report-only mode first, then gradually become a mandatory release gate.

### Implementation Supervision Mechanism (ai-protocol)
- PT-012/PT-013 should not stop at policy drafting; they must include weekly supervision cadence and escalation rules.
- Implementation supervision uses a fixed rhythm (Mon/Wed/Fri) with gate pass-rate, drift critical count, and rollback readiness as primary KPIs.
- If critical semantic drift remains unresolved beyond 48 hours, release progression must be suspended until closure evidence is recorded.

### P1/P2 Coding Execution Baseline (Wave 1)
- PT-015/023/024 moved from planning-only outputs to executable automation and service behavior.
- `ai-protocol-mock` now exposes async video generation polling semantics to support sync/stream/async transport coverage.
- `ai-protocol` includes runnable governance automation: `drift:check` (drift scan) and `release:gate` (go/no-go decision).
- Drift checks must tolerate legacy fixtures where applicable, while still enforcing P0 provider readiness coverage.
- Governance automation should be integrated as report-first gates before mandatory enforcement in CI.

### Multimodal Documentation Hardening Baseline (PT-011)
- Multimodal planning docs must use explicit evidence tags (`E1_OFFICIAL` to `E4_ASSUMPTION`) for key claims.
- Assumption entries require `UNVERIFIED` marking and planned verification path.
- Schema-gap entries must be classified as `supported` / `needs_schema_change` / `experimental`.
- Documentation governance should be coupled with execution supervision metrics, not maintained as standalone narrative artifacts.

### Runtime Routing Boundary (Spiderswitch)
- spiderswitch acts as a runtime routing capability layer, not a strategy engine.
- Routing strategy (business policy, cost weighting, tenant rules) stays in upper-layer applications.
- Runtime routing must consider both model capabilities and runtime capabilities.
- Runtime abstraction should be runtime-neutral and extensible beyond Python/Rust/TS (e.g., Go/WASM).
- Cross-runtime routing requires contract tests to guarantee same semantic behavior for equivalent inputs.

### Runtime Registry/Resolver Baseline (Spiderswitch Wave-1)
- Runtime execution path now supports explicit `runtime_id` routing with deterministic resolution order:
  request runtime_id -> state runtime_id -> default runtime.
- Runtime state semantics now include `runtime_epoch` and `runtime_epochs` to support multi-runtime coordination.
- `exit_switcher` supports scoped reset (`runtime` vs `all`) to avoid unnecessary global teardown.
- Capability schema is runtime-neutral and includes reserved runtime ids for Go/WASM future adapters.

### Release Baseline (Generative Fullchain, 2026-03-07)
- Release train closed with aligned matrix:
  - `ai-protocol v0.8.0`
  - `ai-lib-rust v0.9.0`
  - `ai-lib-python v0.8.0`
  - `ai-lib-ts v0.5.0`
- Release order and evidence confirmed as: capability closure -> cross-runtime consumption verification -> version bump/tag/release -> site docs alignment.
- `ailib.info` docs baseline now tracks release matrix updates as part of mandatory wrap-up, not optional post-processing.

### Wave-2 Execution Decision (PT-025~PT-030)
- Next phase starts immediately after release closure, focused on:
  - cross-repo manifest consumption gate normalization,
  - load-compliance hardening,
  - V2 manifest shape compatibility unification,
  - mock video lifecycle semantic expansion,
  - CI governance integration (`drift:check`/`release:gate`),
  - RC + rollback drill closure package.
- Governance remains staged (report-first), with escalation to required gates only after stability proof cycles.

---

## Cross-Project Conventions

### Documentation Language (DOC-001)
- **Code docs**: English; add one Chinese summary line at each module/file header
- **Scope**: All publicly published code (ai-protocol, ai-lib-*, ai-protocol-mock)
- **Internal docs**: Plans, reports, standups, explanations for maintainer — Chinese by default

### Message Roles (AI-Protocol v2)
- `system` — System instructions (feature_flags.system_messages)
- `user` — User input
- `assistant` — Model responses, including tool_calls
- `tool` — Tool result messages for multi-turn tool calling (requires tools capability)

### Provider Manifest Versions
- **v1**: Legacy format, 30+ providers
- **v2-alpha**: Three-ring concentric model (Ring 1 core, Ring 2 capabilities, Ring 3 extensions)

### Error Codes
- Standard codes: E1001–E9999 (see ai-protocol schemas/v2/errors.json)
- Minimum mappings: 400→invalid_request, 401→authentication, 429→rate_limited, 500→server_error

### Default Branch Naming (ARCH-004)
- Canonical default branch across ai-lib ecosystem repositories is `main`
- Docs/scripts/automation should target `main` and avoid using `master` as default branch name

### Internal Work Doc Privacy (DOC-002)
- Internal work documents (discussion/plan/report/solution/summary) must remain private
- Do not upload or push internal work artifacts to public ai-lib project repositories
- If leaked, remove immediately from public branch and add ignore safeguards

---

## Key Learnings & Gotchas

### Compliance Tests
- 45 tests total; target 100% pass. Current failures often due to V2 features not yet implemented.
- Mock server: ai-protocol-mock at port 4010 (configurable via MOCK_HTTP_URL).

### MCP Integration
- MCP tools bridge: tools/list, tools/call. Schema not fully finalized.
- Tool definition conversion between MCP and AI-Protocol format.

### Multimodal
- Vision, audio, video modalities declared in capabilities. Format conversions vary by provider (OpenAI base64/URL, Anthropic source, Gemini inline_data).

---

## Constitution Rule References

| Rule ID | Topic |
|---------|-------|
| DOC-001 | Code docs: English + Chinese module header |
| DOC-002 | Internal work docs must stay private |
| ARCH-001 | Protocol-driven design |
| ARCH-002 | Operator pipeline |
| ARCH-003 | Cross-runtime consistency |
| ARCH-004 | Default branch naming: `main` |
| RUST-001 | Error handling (Result) |
| RUST-002 | Async functions |
| PY-001 | Type hints |
| PY-002 | Async I/O |
| TS-001 | Strict mode |
| TS-002 | Type safety |
| TEST-001 | Compliance tests |

---

## Workspace Requirement

**ai-lib-constitution and ai-lib-plans must be workspace roots** when working on ai-lib projects.  
Each project has `.cursor/rules/ai-lib-constraint.mdc` to enforce loading SOUL, AGENTS, MEMORY before changes.

## Repository Layout

| Repo | Purpose |
|------|---------|
| ai-protocol | Spec, schemas, provider manifests |
| ai-lib-rust | Rust runtime |
| ai-lib-python | Python runtime |
| ai-lib-ts | TypeScript runtime |
| ai-protocol-mock | Mock server |
| spiderswitch | MCP-based model switching showcase |
| ai-lib-constitution | Rules for AI agents |
| ai-lib-plans | Tasks, standups, planning |
