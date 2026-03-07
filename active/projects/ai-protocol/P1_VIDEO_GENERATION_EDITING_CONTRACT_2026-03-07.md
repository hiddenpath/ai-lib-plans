# P1 Video Generation/Editing Semantic Contract (2026-03-07)

## Objective

Define a protocol-level semantic contract for full video generation/editing workflows across providers and runtimes.

## Unified Lifecycle Model

Normalized job states:
- `accepted`
- `queued`
- `running`
- `partial_output`
- `succeeded`
- `failed`
- `cancelled`
- `expired`

Required state transitions:
- `accepted -> queued|running`
- `running -> partial_output|succeeded|failed|cancelled`
- terminal: `succeeded|failed|cancelled|expired`

## Transport Modes

- Sync: immediate job completion for lightweight workflows
- Streaming: progress and chunk output events
- Async polling: job create + status polling + result retrieval

## Event Semantics (Minimum Payload)

- `VideoJobStarted`: `job_id`, `provider`, `model`, `started_at`
- `VideoProgress`: `job_id`, `percent`, `stage`, `eta_seconds?`
- `VideoChunk`: `job_id`, `chunk_index`, `content_type`, `uri|inline_ref`
- `VideoJobEnded`: `job_id`, `status`, `duration_ms`, `outputs`
- `VideoJobError`: `job_id`, `error_class`, `provider_error`, `retryable`

## Error and Retry Baseline

- Normalized classes: `invalid_request`, `rate_limited`, `overloaded`, `timeout`, `server_error`, `other`
- Retry guidance:
  - retryable: `rate_limited`, `overloaded`, `timeout`, transient `server_error`
  - non-retryable: `invalid_request`, validation failures

## v1 Compatibility/Downgrade

- v1 clients receive:
  - async polling only (no streaming events)
  - reduced status set (`running|succeeded|failed`)
  - text-based summary fallback when video payload unsupported

## Compliance Matrix Rows (to implement)

- provider x mode (sync/stream/poll) x failure (429/5xx/timeout/content-type)
- semantic checks:
  - state machine validity
  - event ordering
  - retry decision consistency

## Risk and Rollback

- Risk: provider lifecycle model mismatch
- Risk: event mapper conflict with existing stream pipelines
- Rollback:
  - disable video capability flags
  - fallback to text/image/audio path
  - keep prior stable release mapping as default

## Outputs

- video semantic contract baseline
- compliance row template
- rollback strategy for PT-020 completion
