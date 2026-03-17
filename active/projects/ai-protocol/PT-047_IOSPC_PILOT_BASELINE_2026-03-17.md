# PT-047 IOSPC Pilot Baseline

## Objective

Deliver substantive code change by introducing `iospc_v1` staged phase support with cross-runtime compliance alignment.

## Code Changes

- Schema:
  - `schemas/v2/capability-profile.json`
    - Added dual phase support: `ios_v1` and `iospc_v1`
    - Added conditional boundaries:
      - `ios_v1`: requires I/O/S and forbids P/C
      - `iospc_v1`: requires I/O/S and at least one of Process/Contract
    - Added `process` and `contract` property schemas
- Boundary script:
  - `scripts/validate-capability-profile-boundary.js`
    - Extended to staged boundary cases and iospc_v1 checks
- Compliance fixtures/cases:
  - Added iospc fixtures and cases `load-017`, `load-018`
- Runtime compliance alignment:
  - Python: `tests/compliance/test_compliance.py`
  - Rust: `tests/compliance.rs`
  - TypeScript: `tests/protocol-loading.compliance.test.ts`

## Validation

- `npm run validate:capability-profile` => pass
- `cargo test --test compliance compliance_protocol_loading` => pass
- `python -m pytest tests/compliance/test_compliance.py` => pass
- `npm run test -- tests/protocol-loading.compliance.test.ts` => pass
- `node scripts/gate-compliance-matrix.js --report-only` => pass

## Evidence

- `d:/ai-protocol/reports/report-evidence-gates/capability-profile-staged-boundary-2026-03-17T09-33-11-206Z.json`
- `d:/ai-protocol/reports/compliance-gates/compliance-gate-2026-03-17T09-39-31-808Z.json`
