# PT-048 IOSPC Required Rehearsal + Rollback Baseline

## Objective

Verify iospc pilot can run under required gate and immediately fall back to report-only lane with reproducible command entrypoints.

## Script Entry Points

- Required:
  - `npm run gate:compliance-matrix:required`
- Rollback lane (report-only):
  - `npm run gate:compliance-matrix:report-only`

## Execution Result

- Required rehearsal: pass
  - Report: `d:/ai-protocol/reports/compliance-gates/compliance-gate-2026-03-17T15-33-50-422Z.json`
- Rollback lane rehearsal: pass
  - Report: `d:/ai-protocol/reports/compliance-gates/compliance-gate-2026-03-17T15-34-23-761Z.json`

## Conclusion

- iospc baseline remains stable under required-mode matrix.
- rollback-to-report-only path is now one-command and auditable.
