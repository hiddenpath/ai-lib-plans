# PT-045 IOS Boundary Expansion Baseline

## Objective

Expand IOS negative boundary coverage to prevent false-positive acceptance before Process/Contract activation.

## Added Cases

- `load-014`: reject `capability_profile.contract`
- `load-015`: reject IOS profile with none of `inputs/outcomes/systems`
- `load-016`: reject non-object `capability_profile`

## Added Fixtures

- `tests/compliance/fixtures/providers/mock-google-v2-ios-invalid-contract.yaml`
- `tests/compliance/fixtures/providers/mock-google-v2-ios-invalid-empty-ios.yaml`
- `tests/compliance/fixtures/providers/mock-google-v2-ios-invalid-nonobject.yaml`

## Verification

- `npm run validate` (ai-protocol): pass
- `cargo test --test compliance compliance_protocol_loading` (ai-lib-rust): pass
- `python -m pytest tests/compliance/test_compliance.py` (ai-lib-python): pass
- `npm run test -- tests/protocol-loading.compliance.test.ts` (ai-lib-ts): pass
- `node scripts/gate-compliance-matrix.js --report-only`: pass

Evidence:
- `d:/ai-protocol/reports/compliance-gates/compliance-gate-2026-03-17T07-26-49-690Z.json`
