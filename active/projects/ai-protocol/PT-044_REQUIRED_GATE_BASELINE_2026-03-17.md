# PT-044 Required Gate Baseline (IOS)

## Objective

Promote IOS `protocol_loading` boundary from report-only evidence to required gate baseline.

## Execution

- Command:
  - `node scripts/gate-compliance-matrix.js`
- Result:
  - `pass` (required mode)
- Evidence:
  - `d:/ai-protocol/reports/compliance-gates/compliance-gate-2026-03-17T07-15-04-608Z.json`

## Check Summary

- `protocol-validate`: pass
- `rust-compliance`: pass
- `python-compliance`: pass
- `ts-compliance`: pass

## Boundary Confirmation

- `load-012` remains accepted across Rust/Python/TypeScript.
- `load-013` remains rejected across Rust/Python/TypeScript.
- IOS staged boundary is now validated under required gate, with rollback path retaining report-only mode.
