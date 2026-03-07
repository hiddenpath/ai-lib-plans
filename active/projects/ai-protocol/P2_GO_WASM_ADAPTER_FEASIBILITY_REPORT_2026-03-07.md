# P2 Go/WASM Runtime Adapter Feasibility Report (2026-03-07)

## Objective

Assess feasibility and define adapter contracts for future Go/WASM runtime support.

## Adapter Boundary Contract (Draft)

Minimum adapter interface:
- protocol loader compatibility
- request compiler binding
- stream decoder/event mapper bridge
- error classification/retry policy resolver
- tool call normalization and transport hooks

## MVP Scope (Recommended)

- Go adapter MVP:
  - protocol loading
  - chat + streaming + error classification
  - compliance subset runner compatibility

- WASM adapter MVP:
  - lightweight inference orchestration only
  - async polling and limited streaming bridge
  - no full heavy multimedia path in first phase

## Non-goals (P2 initial)

- full parity for all multimodal/video paths
- production rollout without compliance subset pass
- bypassing existing protocol contracts

## Security/Operational Constraints

- WASM sandbox IO boundaries must be explicit
- token and secret handling must remain host-side
- transport and filesystem capabilities require explicit allowlist

## Decision

Recommend: **Proceed with phased feasibility-to-MVP track**  
Rationale:
- architecture compatibility is high
- risk is manageable with strict scope and compliance subset gates

## Risks

- WASM stream semantics mismatch
- adapter maintenance cost exceeds short-term value

## Rollback

- keep Go/WASM track disabled by default
- stop at feasibility stage if compliance subset cannot be met without semantic fork

## Outputs

- feasibility verdict
- MVP boundary and non-goals
- phased rollout control for PT-022 completion
