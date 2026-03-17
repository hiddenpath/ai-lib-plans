# PT-043 Report-Evidence Gate Baseline (Report-Only)

## Scope

Run `report-evidence-gate` in report-only mode for current F/D artifacts and staged IOS capability profile evolution.

## Checklist Execution Result

Reference checklist:
- `d:/ai-protocol/work/report-governance-template-pack/checklists/report-evidence-gate.checklist.md`

### A. 文档分层检查

- [x] F 层与 D 层已分离
- [x] F 层仅保留事实结论
- [x] D 层含显式假设与验证路径

### B. 证据质量检查

- [x] 关键结论具备 Claim ID
- [x] 关键结论具备 E1~E4 等级
- [x] 关键结论优先使用 E1/E2（不足项已标注）
- [x] 项目内互证未作为唯一关键证据

### C. 一致性检查

- [x] 文档结论与当前 schema/manifests 对齐
- [x] 与 gate 样本结果一致
- [x] Implemented/Partially Implemented/Proposed 标签已执行

### D. 风险与回滚检查

- [x] 已记录证据盲区与时效风险
- [x] D 层具备回滚触发和回滚路径

### E. 产物归档

- [x] F 报告已归档（PT-041）
- [x] D 报告已归档（PT-042）
- [x] Evidence Matrix 已归档（PT-041/042）
- [x] report-only gate 记录已归档（本文）

## Evidence Snapshot

- Capability profile staged schema:
  - `d:/ai-protocol/schemas/v2/capability-profile.json`
- Boundary validation report (IOS phase):
  - `d:/ai-protocol/reports/report-evidence-gates/capability-profile-ios-boundary-2026-03-16T17-37-18-197Z.json`
- Full validation:
  - `npm run validate` => pass

## Fast Evolution Addendum (IOS staged rollout)

- Confirmed staged direction: prioritize I/O/S, delay P/C.
- Added compliance fixtures for protocol-loading:
  - `tests/compliance/fixtures/providers/mock-google-v2-ios.yaml` (valid)
  - `tests/compliance/fixtures/providers/mock-google-v2-ios-invalid-process.yaml` (invalid)
  - `tests/compliance/cases/01-protocol-loading/load-v2-capability-profile-ios.yaml`
- Updated `v2-alpha/spec.yaml` to explicitly document IOS-phase boundaries.

## Cross-Runtime Evidence Refresh (IOS fact boundary)

- Objective:
  - Upgrade IOS boundary evidence from "document-level/schema-level" to "cross-runtime executable fact".
- Runtime coverage:
  - Rust: `cargo test --test compliance compliance_protocol_loading` => pass
  - Python: `python -m pytest tests/compliance/test_compliance.py` => pass
  - TypeScript: `npm run test -- tests/protocol-loading.compliance.test.ts` => pass
- Matrix gate (report-only):
  - `node scripts/gate-compliance-matrix.js --report-only` => pass
  - Evidence artifact:
    - `d:/ai-protocol/reports/compliance-gates/compliance-gate-2026-03-16T18-04-32-634Z.json`
- Matrix gate (required):
  - `node scripts/gate-compliance-matrix.js` => pass
  - Evidence artifact:
    - `d:/ai-protocol/reports/compliance-gates/compliance-gate-2026-03-17T07-15-04-608Z.json`
- Boundary conclusion:
  - `load-012` (valid IOS capability_profile) is accepted consistently across runtimes.
  - `load-013` (IOS profile contains `process`) is rejected consistently across runtimes.
  - This confirms staged governance boundary: prioritize I/O/S; keep P/C deferred.

## Gate Conclusion

- Result: `Pass (report-only)`
- Open gaps:
  - Continue improving E1/E2 claim-level citation density for high-strength external statements.
  - Add follow-up boundary cases for contract-like references when P/C phase is enabled.
- Owners:
  - Governance owner: `@hiddenpath`
  - Execution owner: `codex`
