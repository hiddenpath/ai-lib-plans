---
title: ZeroSpider AI-lib Migration Audit — Addendum (Dev-Side Cross-Check)
date: 2026-04-28
relates_to: AUDIT_2026-04-27.md
author: cursor-agent (dev-side)
purpose: |
  Cross-check the 2026-04-27 audit against the actual codebase at `main @ aa3214a` and
  separate confirmed gaps from factual misreadings, so the rectification plan
  (ZS-ML-007 ~ ZS-ML-010) targets real issues only.
---

# ZeroSpider Audit Addendum (2026-04-28)

This addendum is **not** a defence of the original audit — its conclusions on most
runtime gaps are valid. It corrects a small number of findings whose evidence
does not match the code on `main @ aa3214a`, so the rectification plan can be
scoped precisely.

## Confirmed Gaps (rectification required)

| # | Audit Item | Evidence in code | Severity |
|---|-----------|------------------|----------|
| C1 | Streaming `PartialToolCall` events silently dropped | `src/providers/protocol_adapter.rs` lines ~363–385: only `PartialContentDelta`, `ThinkingDelta`, `StreamEnd` handled; `Ok(_) => {}` swallows tool-call deltas | HIGH |
| C2 | No multi-turn tool conversation test | Only `test_convert_messages_tool_role_with_call_id` (single tool turn) | HIGH |
| C3 | No streaming integration test (with or without tools) | Search of `tests/` and `protocol_adapter.rs#tests` shows zero stream tests | HIGH |
| C4 | `ai-lib-rust` features `embeddings`, `batch`, `telemetry` declared but not wired | `Cargo.toml` line 147; no call sites grep-able in `src/` | MEDIUM |
| C5 | No explicit double-retry boundary unit test | `execute_chat_with_retry` documented in comment only; no test proving non-overlap with `[reliability]` | MEDIUM |
| C6 | CI runs `cargo check --no-default-features --features ai-protocol --lib` but **not `cargo test`** in the same configuration | `.github/workflows/ci.yml` line 46 | MEDIUM |
| C7 | `AiClient::metrics()` not wired to OTel pipeline | Zero references in `src/`; no decision documented | LOW–MEDIUM |
| C8 | Legacy code is **gated**, not **deleted** | `providers/` ~17.4k LoC retained behind `#[cfg(feature = "legacy-providers")]` | DESIGN CHOICE (see notes) |
| C9 | Embeddings/batch path through protocol adapter not implemented | No `embeddings` or `batch` call site in `protocol_adapter.rs` | LOW (deferable) |
| C10 | Wizard only warns; no interactive fix-up flow | `src/onboard/wizard.rs:30` is a one-shot warning | LOW |

## Audit Items That Misread the Codebase

| # | Audit Claim | Reality | Source |
|---|-------------|---------|--------|
| F1 | "`zerospider models` calls `providers::list_providers()` — protocol registry is not exposed through any CLI" | `zerospider models protocol-providers` and `zerospider models protocol-models` ARE wired; both call `protocol_registry::scan_protocol_root` and print availability | `src/main.rs` lines 637–647 (subcommand defs) and 972–1027 (impls) |
| F2 | "no runtime availability check that filters providers by 'all env vars set'" | `scan_protocol_root` already computes `available = required_envs.is_empty() \|\| required_envs.iter().all(env_nonempty)` and surfaces it in the `OK` column | `src/protocol_registry.rs` lines 142–158 |
| F3 | "no model override unit test" | Two tests exist: `effective_model_id_empty_override_is_provider_slash_model` and `effective_model_id_non_empty_override_wins` | `src/providers/protocol_adapter.rs` lines 432–442 |
| F4 | "no integration with ProtocolBackedProvider" for ReliableProvider fallback | `create_resilient_provider_with_options` builds the primary via `create_provider_with_url_and_options`, which routes `provider/model` ids to `ProtocolBackedProvider`; `model_fallbacks` is propagated to the wrapper. The chain works; what is missing is an **explicit test**, not the integration | `src/providers/mod.rs` lines 1278–1329 |
| F5 | "ProtocolBackedProvider only triggered when provider name contains `/`" framed as a defect | This is the documented design (logical model id = `provider/model`). Mapping bare `default_provider = "openai"` to a manifest is a separate **feature ask**, not a regression. The migration guide states that `provider/model` is the canonical entry. | `docs/migration-legacy-to-protocol.md`; `src/providers/mod.rs` lines 927–953 |
| F6 | "Phase 5 — completed (docs only)" implies zero progress on isolation | Code is **default-feature-excluded** behind `legacy-providers`. For default builds the legacy path is unreachable — that is functionally equivalent to removal for the default user. Final source-level deletion remains a follow-up but is not zero progress. | `Cargo.toml` features `legacy-providers`; `src/providers/mod.rs` line 1016 (`#[cfg(not(feature = "legacy-providers"))]` bail!) |

## Phase Status After Cross-Check

| Phase | Audit Verdict | After Cross-Check | Rectification |
|-------|---------------|-------------------|---------------|
| 0 | ✅ Complete | ✅ Complete | — |
| 1 | ❌ Not started | ⚠️ Partial (model-override tests done; streaming/tool-call paths incomplete) | ZS-ML-007 |
| 2 | ❌ Incomplete | ✅ Mostly complete (CLI + availability filter shipped); registry-vs-runtime cross-check optional | (no new task; close out via ZS-ML-010 notes) |
| 3 | ⚠️ Partial | ⚠️ Partial (design intent vs feature ask; no defect — feature gate verified) | (no new task; resolution via ZS-ML-010 design-note) |
| 4 | ❌ Incomplete | ⚠️ Partial (compile gate done; tests + metrics decision pending) | ZS-ML-008 |
| 5 | ❌ Not done | ⚠️ Functional removal via gating; full deletion deferred | ZS-ML-008 (CI test gate) + roadmap item |
| 6 | ⚠️ Partial | ⚠️ Partial (compat docs ✅; embeddings/wizard/metrics deferred) | ZS-ML-009 |

## Recommendation Summary

1. **Reopen** `ZEROSPIDER_AI_LIB_MIGRATION_PLAN.md` to `in_progress` (matches audit R1).
2. **Do not** create ZS-ML-{Phase 2 CLI} or ZS-ML-{model override test} tasks — those items are already in tree.
3. Create the four-task rectification queue:
   - **ZS-ML-007** — Adapter completeness: stream `PartialToolCall` + multi-turn tool tests + streaming integration test.
   - **ZS-ML-008** — CI hardening: `cargo test --no-default-features --features ai-protocol`; double-retry boundary test; ReliableProvider × ProtocolBackedProvider integration test.
   - **ZS-ML-009** — Dead-feature decision: wire or remove `ai-lib-rust` `embeddings` / `batch` / `telemetry` features.
   - **ZS-ML-010** — Plan reopen + ZS-ML-006 deferred-items backfill + design notes for F4/F5/F6 (clarify what is design vs gap).
4. Do **not** pursue legacy source deletion in this rectification round — keep it as a roadmap candidate after ZS-ML-007/008/009 land. Premature deletion conflicts with the "Reversibility + Rollback-First" engineering principle.

## Authoring Notes

- Cross-check performed by reading the listed file/line ranges directly; no test runs new in this addendum.
- Where the audit and code disagreed, the code (at `main @ aa3214a`) is treated as ground truth.
