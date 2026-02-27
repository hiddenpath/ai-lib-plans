# Project Memory — Durable Facts & Decisions

> Long-term memory for the ai-lib ecosystem. Curated facts that persist across sessions.
> See [memory/](memory/) for short-term daily logs. Flush important items here periodically.

**Last Updated**: 2026-02-27

---

## Architecture Decisions

### Protocol-Driven Design (ARCH-001)
- **Principle**: 一切逻辑皆算子，一切配置皆协议
- All provider logic is driven by YAML manifests in ai-protocol. Zero hardcoded provider code in runtimes.
- Adding a new provider = add manifest only, no runtime code changes.
- Runtimes: ai-lib-rust, ai-lib-python, ai-lib-ts load manifests via ProtocolLoader.

### Operator Pipeline (ARCH-002)
- Chat flow: decode → select → accumulate → fanout → map
- Streaming uses unified StreamingEvent system.
- Each capability (streaming, tools, multimodal) maps to operator modules.

### Cross-Runtime Consistency (ARCH-003)
- All runtimes must pass ai-protocol compliance tests.
- Message roles: system, user, assistant, tool (per standard_message_roles).
- Unified request/response format across Rust, Python, TypeScript.

---

## Cross-Project Conventions

### Documentation Language (DOC-001)
- **Code docs**: English; add one Chinese summary line at each module/file header
- **Scope**: All publicly published code (ai-protocol, ai-lib-*, ai-protocol-mock)
- **Internal docs**: Plans, reports, standups, explanations for maintainer — Chinese by default

### Message Roles (AI-Protocol v2)
- `system` — System instructions (feature_flags.system_messages)
- `user` — User input
- `assistant` — Model responses, including tool_calls
- `tool` — Tool result messages for multi-turn tool calling (requires tools capability)

### Provider Manifest Versions
- **v1**: Legacy format, 30+ providers
- **v2-alpha**: Three-ring concentric model (Ring 1 core, Ring 2 capabilities, Ring 3 extensions)

### Error Codes
- Standard codes: E1001–E9999 (see ai-protocol schemas/v2/errors.json)
- Minimum mappings: 400→invalid_request, 401→authentication, 429→rate_limited, 500→server_error

---

## Key Learnings & Gotchas

### Compliance Tests
- 45 tests total; target 100% pass. Current failures often due to V2 features not yet implemented.
- Mock server: ai-protocol-mock at port 4010 (configurable via MOCK_HTTP_URL).

### MCP Integration
- MCP tools bridge: tools/list, tools/call. Schema not fully finalized.
- Tool definition conversion between MCP and AI-Protocol format.

### Multimodal
- Vision, audio, video modalities declared in capabilities. Format conversions vary by provider (OpenAI base64/URL, Anthropic source, Gemini inline_data).

---

## Constitution Rule References

| Rule ID | Topic |
|---------|-------|
| DOC-001 | Code docs: English + Chinese module header |
| ARCH-001 | Protocol-driven design |
| ARCH-002 | Operator pipeline |
| ARCH-003 | Cross-runtime consistency |
| RUST-001 | Error handling (Result) |
| RUST-002 | Async functions |
| PY-001 | Type hints |
| PY-002 | Async I/O |
| TS-001 | Strict mode |
| TS-002 | Type safety |
| TEST-001 | Compliance tests |

---

## Repository Layout

| Repo | Purpose |
|------|---------|
| ai-protocol | Spec, schemas, provider manifests |
| ai-lib-rust | Rust runtime |
| ai-lib-python | Python runtime |
| ai-lib-ts | TypeScript runtime |
| ai-protocol-mock | Mock server |
| ai-lib-constitution | Rules for AI agents |
| ai-lib-plans | Tasks, standups, planning |
