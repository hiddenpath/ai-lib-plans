# PT-046 Process/Contract Phase Readiness Draft

## Scope

Define staged readiness for enabling `process` and `contract` after IOS baseline has cross-runtime proof.

## Non-goals

- No immediate schema hard switch to require Process/Contract.
- No runtime-specific provider shortcuts.
- No CI hard-block promotion without report-first validation window.

## Assumptions and Validation

| Assumption | Validation Method | Pass Criteria | Rollback Trigger |
| --- | --- | --- | --- |
| Existing IOS behavior remains stable when P/C fields are absent | run existing compliance matrix | no regression in load-012~016 + existing suites | any cross-runtime mismatch |
| Adding `process`/`contract` as optional can be validated incrementally | add protocol_loading + boundary fixtures in report-only | 2 consecutive report-only cycles pass | failed cycle in any runtime |
| Runtime parsers can reject malformed P/C consistently | add negative fixture matrix and tri-runtime assertions | same pass/fail semantics across Rust/Python/TS | inconsistent rejection semantics |

## Entry Criteria (Phase Gate-In)

1. IOS required-mode gate remains green for 2 consecutive runs.
2. PT-045 negative boundary set remains green on full compliance matrix.
3. P/C draft schema diff reviewed with compatibility notes and migration examples.

## Exit Criteria (Phase Gate-Out)

1. Report-only P/C boundary matrix passes across Rust/Python/TS.
2. Required-mode gate passes after promotion rehearsal.
3. Rollback drill proves one-command downgrade to report-only path.

## Proposed Execution Sequence

1. Add optional `process`/`contract` draft branch schema behind report-first governance.
2. Add fixtures/cases for valid + invalid P/C payloads.
3. Align tri-runtime loaders/compliance checks.
4. Run `gate-compliance-matrix --report-only` and archive evidence.
5. Promote to required mode only after two clean cycles.

## Compatibility and Migration Notes

- `phase` stays explicit; IOS remains `ios_v1`.
- Future phase tag proposal: `iospc_v1` when P/C is activated.
- Existing IOS manifests remain valid without any modification.

## Rollback Matrix

| Scenario | Detection | Immediate Action | Recovery Target |
| --- | --- | --- | --- |
| P/C fixture failures in one runtime | matrix report failed | switch gate execution to `--report-only` | restore parity in 24h |
| Schema acceptance unexpectedly broadens | boundary case unexpectedly passes | revert schema commit and rerun validate | recover strict rejection behavior |
| CI disruption due required-mode promotion | blocking pipeline failures | revert required-mode config to report-only | re-run with archived evidence |

## Evidence Requirements Before Promotion

- `npm run validate` pass report
- one report-only compliance matrix report
- one required-mode compliance matrix report
- PT-046 completion note linking all artifacts
