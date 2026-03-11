# GO-002 Cross-Runtime Gap Report (2026-03-10)

## Scope

对齐对象：`ai-lib-go` vs `ai-lib-rust` / `ai-lib-python` / `ai-lib-ts`，聚焦：

- 错误分类与 retry/fallback 语义
- 高级能力入口（mcp/computer_use/reasoning/video）
- 传输策略与 preflight 校验
- compliance 夹具执行一致性

## Converged In This Iteration

1. Error classification now supports dual channel:
   - HTTP status mapping (`E1001`~`E9999`)
   - provider error code/type override (e.g. `insufficient_quota -> E2002`)
2. Retry/fallback matrix parity hardened:
   - retryable: `E2001/E3001/E3002/E3003/E4001`
   - fallbackable: `E1002/E2001/E2002/E3001/E3002/E3003`
3. Advanced capability transport entries implemented in Go client:
   - `MCPListTools`, `MCPCallTool`
   - `ComputerUse`
   - `Reason`
   - `VideoGenerate`, `VideoGet`
4. Preflight checks added:
   - empty message input blocked
   - empty batch/job IDs blocked
   - endpoint path/method validation (`/` prefix + `GET/POST/DELETE`)
5. Contract tests expanded:
   - `pkg/ailib` unit tests for advanced capability routes and provider error mapping
   - `tests/compliance/advanced_capabilities_test.go`
6. Manifest-driven error classifier + fallback executor:
   - runtime now reads `error_classification` from loaded manifest
   - `FallbackClient` supports full `Client` method surface with sequential failover
7. Shared fixture expansion initiated:
   - added `07-advanced-capabilities` category under `ai-protocol/tests/compliance/cases`
   - expanded to a 16-case matrix across `mcp/computer_use/reasoning/video`:
     - capability_guard (4)
     - advanced_endpoint_mapping (4)
     - fallback_decision (4)
     - provider_mock_behavior (4)
   - Go/Rust/Python/TS runners now consume `capability_guard`, `advanced_endpoint_mapping`, `fallback_decision`, `provider_mock_behavior`
8. Go fallback policy upgraded:
   - sequential fallback retained
   - health tracking + circuit breaker added (`failure threshold`, `open duration`, `health snapshot`)

## Remaining Gaps

1. Provider-manifest-driven error classification still partial:
   - runtime can consume `error_classification` from loaded manifest
   - but legacy manifests with non-normalized shape still rely on hardcoded fallback mapping
2. Fallback execution semantics are available but still policy-light:
   - all methods can failover sequentially
   - provider ranking/health scoring/circuit-breaker policy is not implemented yet
3. Advanced capability shared fixtures now include provider-mock behavior assertions, but mock-source coverage is still limited:
   - current assertions are contract-shape focused
   - next: add multi-provider fixture variants and negative-case payload checks
4. Cross-runtime benchmark evidence not yet generated:
   - semantic parity is validated in functional tests
   - performance/latency parity report pending

## Next Actions (GO-002)

1. Extend fallback executor from Chat-only to stream + advanced capability flows.
2. Normalize and parse more provider manifest variants for error classification compatibility.
3. Propose/implement new shared compliance fixture sets for advanced capabilities in `ai-protocol`.
4. Produce machine-readable parity summary (pass/fail matrix + residual risk tags).

## Validation Snapshot

- `go test ./...` (ai-lib-go): pass
- compliance base categories (`01`~`06`): pass
- advanced capability contract tests: pass
- Rust: `cargo test --test compliance` pass
- Python: `pytest tests/compliance/test_compliance.py` pass
- TypeScript: `vitest run tests/advanced-capabilities.compliance.test.ts` pass

