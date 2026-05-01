# Unified Credential Chain P0 Plan — 2026-05-01

Status: `in_progress`
Owner: ai-lib ecosystem
Scope: ai-protocol, ai-lib-rust, ai-lib-python, ai-lib-ts, ai-lib-go, ai-lib-wasm, first downstream consumer ZeroSpider

## Background

ZeroSpider's ai-lib migration exposed a platform-level gap: ai-protocol can describe providers and models, but the runtimes do not yet expose a consistent credential resolution contract. Without a central hosted platform, every agent application would otherwise reimplement API-key discovery, keyring use, configuration overrides, and provider availability checks.

This P0 turns credential resolution into ai-lib infrastructure rather than application glue.

## Intent

ai-lib applications should express a logical target such as `openai/gpt-5.2`. The runtime should resolve:

1. which provider manifest applies,
2. which credentials are required,
3. where credentials may be read from,
4. whether the provider/model is available on this machine, and
5. how to attach the resolved credential to transport requests without leaking secrets.

Agent applications such as ZeroSpider should not hardcode provider-specific API-key names except as temporary compatibility shims.

## Architecture Principles

- [ARCH-001] Protocol-driven design: credential requirements come from manifests, not runtime match tables.
- [ARCH-003] Cross-runtime consistency: Rust, Python, TypeScript, Go, and WASM expose equivalent semantics even if platform integrations differ.
- E/P separation: core execution performs deterministic credential lookup and request attachment; strategy/policy layers may add credential brokers, rotation, OAuth, and enterprise secret-manager integrations.
- Secure by default: never log credential values; diagnostics mention credential source kind and env var names only.

## Credential Chain Contract

Recommended default resolution order:

1. **Explicit override**: application-supplied credential for this client/model/provider.
2. **Manifest env**: `endpoint.auth.token_env`, top-level `auth.token_env`, or `auth.key_env` as declared by the manifest.
3. **Conventional env**: `{PROVIDER_ID_UPPER}_API_KEY` for compatibility when manifests are incomplete.
4. **Runtime keyring**: platform credential store when available and enabled.
5. **External resolver plugin**: optional hook for Vault, 1Password, cloud secret managers, local credential brokers, or OAuth/token refresh providers.

Resolution returns metadata, not just a string:

- `status`: `available`, `missing`, `unsupported`, or `error`
- `source_kind`: `explicit`, `manifest_env`, `conventional_env`, `keyring`, `external`, or `none`
- `source_name`: env var name / keyring service label / resolver id, never the value
- `required`: credential names derived from manifest
- `redacted_hint`: human-safe message for CLI/wizard/doctor

## Runtime Deliverables

## Current Runtime Audit Snapshot

| Runtime | Current state | Primary gap |
|---------|---------------|-------------|
| Rust | Main HTTP transport reads `{PROVIDER_ID}_API_KEY`, then keyring. Satellite clients use fixed env fallbacks. | Manifest `token_env` / `key_env` is not used; no explicit credential override on `AiClientBuilder`; debug logging exposes key material. |
| Python | `transport/auth.py` already has explicit -> manifest `auth.token_env` -> conventional env -> optional keyring. | V2 `endpoint.auth` and satellite clients still need parity; diagnostics should expose redacted source metadata consistently. |
| TypeScript | Main transport reads TS-internal `auth.env_var` or `{ID}_API_KEY` / `AI_API_KEY`; public headers can be overwritten by resolved auth. | Shipped protocol uses `token_env`, not `env_var`; no first-class credential override; `ClientOptions` does not forward all auth-relevant options. |
| Go | `WithAPIKey` is the only built-in secret source; manifest controls header name/prefix only. | V1 `token_env` is not decoded; no env/keyring chain; no availability diagnostics. |
| WASM | Current WASM surface has no credential I/O. | Must define explicit/host-supplied credential boundary and forbid implicit env/keyring assumptions in minimal WASM. |

The audit confirms PT-074-A must define fixtures before runtime implementation so each runtime converges on the same precedence and redaction semantics.

### Rust Reference Implementation

- Add a credential module in ai-lib-core (or equivalent execution crate) with:
  - `CredentialRequest { provider_id, model_id, manifest_auth }`
  - `CredentialValue` with redacted debug display
  - `CredentialSource` / `CredentialResolver` trait
  - default chain: explicit -> manifest env -> conventional env -> keyring
- Teach transport to use manifest auth configuration for header/query attachment instead of assuming bearer-only `{PROVIDER}_API_KEY`.
- Add availability API that returns provider/model credential status without making a network request.
- Keep WASM-compatible core path free of OS keyring dependency; keyring remains optional/native-only.

### Python / TypeScript / Go Parity

- Mirror the public contract names and semantics.
- Provide explicit override + manifest env + conventional env everywhere.
- Make keyring/external resolvers optional and platform-specific.
- Add compliance fixtures for required/missing/explicit/env precedence.

### WASM Package

- No implicit host env/keyring access in the minimal WASM surface.
- Expose host-supplied credential resolver/import or explicit credential injection.
- Ensure serialized diagnostics redact values and preserve source names.

## Protocol / Schema Deliverables

- Clarify that V2 provider manifests may declare auth under `endpoint.auth`; runtimes must inspect that shape.
- If top-level `auth` remains supported for V1/backcompat, define precedence between `endpoint.auth` and top-level `auth`.
- Add compliance fixtures covering:
  - `endpoint.auth.token_env`
  - top-level `auth.key_env`
  - provider with no auth
  - query-param/custom-header auth attachment
  - missing credential diagnostics

## Downstream ZeroSpider Gate

ZeroSpider may proceed with a thin compatibility layer only after the Rust reference has:

- explicit credential override,
- manifest env availability,
- safe missing-key diagnostics,
- no secret logging.

ZeroSpider should then:

- normalize `default_provider` + `default_model` into a logical model id,
- show ai-lib availability results in wizard/doctor,
- remove provider-specific credential tables from the protocol path.

## PR Slicing

1. PT-074-A: protocol contract + compliance fixtures.
2. PT-074-B: Rust reference implementation + WASM-safe surface.
3. PT-074-C: Python/TS/Go parity.
4. PT-074-D: ZeroSpider consumer integration and release smoke.
5. PT-074-E: docs, changelogs, release notes.

## Immediate Implementation Cut

Start with PT-074-A because it defines the shared semantics that every runtime must converge on:

- `ai-protocol`: add credential-chain compliance fixtures and clarify `endpoint.auth` vs top-level `auth` precedence.
- `ai-protocol-mock`: add deterministic auth expectations for bearer, custom-header, and query-param cases if the current mock cannot assert them.
- `ai-lib-rust`: consume the fixture first as a failing/reference test before adding the resolver implementation.
- `ZeroSpider`: wait for Rust reference API shape, then integrate as a downstream smoke rather than inventing a parallel credential table.

First PR acceptance:

- fixtures fail clearly on at least one current runtime before implementation,
- fixture names and expected diagnostics are language-neutral,
- no raw credential value appears in expected output,
- WASM case states explicitly that credentials are host-supplied, not implicitly read.

## Acceptance Criteria

- Four runtimes pass shared credential compliance fixtures.
- WASM exposes a host-supplied or explicit credential path and does not depend on OS env/keyring.
- At least one downstream app (ZeroSpider) can run in default ai-protocol mode using BYOK env credentials without `legacy-providers`.
- Missing credentials produce actionable, redacted diagnostics.
- No runtime logs raw credential values in normal or debug paths.

## Open Questions

- Whether explicit credentials belong in core client builders, contact-layer policy builders, or both.
- Whether keyring should be included in default native builds or behind optional features/extras.
- Whether OAuth refresh belongs in P/contact only or whether a minimal token-provider interface is allowed in core.
