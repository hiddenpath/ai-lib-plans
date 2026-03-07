# P1 Provider Expansion Wave Plan (2026-03-07)

## Objective

Define and lock a ranked P1 provider expansion wave beyond P0 baseline, with evidence-backed prioritization and deterministic onboarding sequence.

## Candidate Pool and Ranking

Scoring dimensions (1-5):
- Demand fit (ecosystem usage and expected request volume)
- Capability complement (fills modality/cost/latency gaps)
- Contract maturity (manifest and API stability)
- Runtime adaptation complexity (Rust/Python/TS delta cost)
- Operational risk (drift and release exposure)

Top P1 wave candidates:
1. Cohere
2. Moonshot
3. Zhipu
4. Jina

## Dependency Decomposition

For each provider onboarding:
1. `ai-protocol`: provider capability declaration and error/retry mapping
2. `ai-protocol-mock`: scenario template + failure injection
3. Runtimes: request/event/error/retry semantic alignment
4. `spiderswitch`: capability signal consumption validation
5. Docs/release: capability matrix and rollback note alignment

## Week Rhythm

- Week 1: candidate evidence verification and scoring freeze
- Week 2: dependency and sequencing lock
- Week 3: readiness review and execution gate handoff

## Risk Register

- Contract drift risk: provider API changes during integration
- Cross-runtime semantic divergence risk: inconsistent event/retry behavior
- Release collision risk: multi-provider merges causing mixed regressions

## Rollback Strategy

- Provider-level feature flags, default disabled
- Provider-by-provider rollback checklist:
  - disable provider feature flag
  - revert provider-specific mapping patch
  - rerun compliance subset for unaffected providers

## Outputs

- P1 provider ranking and onboarding wave
- Dependency map template for downstream execution
- Risk and rollback baseline for PT-019 completion
