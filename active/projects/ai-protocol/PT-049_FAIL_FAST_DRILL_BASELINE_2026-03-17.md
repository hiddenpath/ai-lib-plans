# PT-049 Fail-Fast Drill Baseline

## Objective

Validate rollback governance behavior under deterministic failure injection:

- required lane must block
- report-only lane must pass while preserving failed evidence

## Drill Command

- `npm run rehearse:compliance:rollback`

## Injection Method

- Set `AI_LIB_TS_DIR` to non-existent directory to force `ts-compliance` failure in matrix gate.

## Outcome

- Required lane: blocked (`exit=1`)
  - `d:/ai-protocol/reports/compliance-gates/compliance-gate-2026-03-17T15-52-59-784Z.json`
- Report-only lane: pass (`exit=0`) with failed check preserved
  - `d:/ai-protocol/reports/compliance-gates/compliance-gate-2026-03-17T15-53-58-933Z.json`

Drill summary:
- `d:/ai-protocol/reports/rollback-rehearsals/compliance-rollback-rehearsal-2026-03-17T15-53-59-248Z.json`

## Conclusion

Rollback mechanism is executable and auditable:
- hard-block in required mode works
- evidence-preserving soft-pass in report-only mode works
