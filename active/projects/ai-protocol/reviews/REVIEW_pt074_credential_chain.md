# PT-074 Review: Unified Credential Chain (Rust Reference Implementation)

> **Reviewer:** Spider @ 2026-05-01
> **Target:** `feat/pt-074-rust-credential-chain` (da8054a)
> **Scope:** Rust reference implementation — code quality, correctness, safety, extensibility

---

## Summary

The PR introduces a unified `CredentialResolver` module (`credentials.rs`) that cleans up the previous ad-hoc API key logic scattered in `transport/http.rs`. The architecture follows the specified 5-step precedence chain (Explicit → ManifestEnv → ConventionalEnv → Keyring → None). The code compiles, all 100 tests pass, and the design direction is correct.

However, there are **medium-to-high priority issues** that should be resolved before merging. The main concerns center around **unconditional platform dependency (keyring)** and **ambiguous priority semantics between endpoint.auth and top-level auth**.

---

## Issues

### 🔴 Issue 1: `keyring` is an unconditional hard dependency

| File | Line | Code |
|------|------|------|
| `crates/ai-lib-core/Cargo.toml` | 55 | `keyring = "2.0"` |
| `crates/ai-lib-core/src/credentials.rs` | 6 | `use keyring::Entry;` |

**Problem:**
`keyring = "2.0"` is a normal dependency under `[target.'cfg(not(target_arch = "wasm32"))'.dependencies]`. It's NOT behind a feature flag. This means every non-WASM build unconditionally pulls in:

- `linux-keyutils` (Linux kernel keyring, requires appropriate syscall access)
- `secret-service` (libsecret/D-Bus — needs running D-Bus session)
- `security-framework` (macOS)
- `windows-sys` (Windows)

For **containers**, **CI runners**, **headless servers**, and **minimal embedded systems**, this will either:
- Compile with unnecessary native deps (larger build times, binary size bloat)
- Fail at runtime when the platform can't open a keyring session (e.g., Docker containers without D-Bus)
- Trigger linker errors on minimal systems (e.g., Alpine Linux without libsecret-dev)

**Note:** This problem predates PT-074 (main branch already had keyring unconditional in both `ai-lib-core` and `ai-lib-rust`). But PT-074 moves the keyring reach from a single function in `http.rs` into a dedicated module with a named `keyring_value()` — making it more visible and intentional. This is the right time to fix it.

**Demand:**
Make `keyring` an **opt-in feature flag**:
- Move to `[features]` as `keyring = ["dep:keyring"]` 
- Guard `keyring_value()` with `#[cfg(feature = "keyring")]`
- When feature is absent, simply skip the keyring step in `resolve_credential()`

---

### 🔴 Issue 2: `endpoint.auth` vs top-level `auth` — priority is implicit and undocumented

| File | Function |
|------|----------|
| `crates/ai-lib-core/src/credentials.rs` | `primary_auth()` & `required_envs()` |

```rust
pub fn primary_auth(manifest: &ProtocolManifest) -> Option<&AuthConfig> {
    manifest.endpoint.auth.as_ref().or(manifest.auth.as_ref())
}

pub fn required_envs(manifest: &ProtocolManifest) -> Vec<String> {
    for auth in [manifest.endpoint.auth.as_ref(), manifest.auth.as_ref()]
        .into_iter().flatten()
    {
        if let Some(env) = auth.token_env.as_ref().or(auth.key_env.as_ref()) { ... }
    }
}
```

**Problem:**
Both `primary_auth()` and `required_envs()` iterate/check both fields, but their semantics diverge:

- `primary_auth()`: `endpoint.auth` wins (short-circuits `.or()`)
- `required_envs()`: collects from **both** and deduplicates

If a V2 manifest defines **different** credentials at both levels (e.g., `endpoint.auth.token_env = "OPENAI_API_KEY"` and `manifest.auth.token_env = "LEGACY_KEY"`), then:
- `required_envs()` returns `["LEGACY_KEY", "OPENAI_API_KEY"]`
- `primary_auth()` returns `endpoint.auth`
- `resolve_credential()` reads from `required_envs()` but `apply_auth()` uses `primary_auth()` structure (auth_type/header_name)

This means the **auth attachment format** comes from `endpoint.auth`, but the **env variable** tried could come from either. This inconsistency is subtle and hard to debug.

**Demand:**
- **Remove top-level `auth` from `required_envs()`** — only scan the winning `primary_auth()` for env vars
- This makes credential resolution deterministic: one auth config → one set of env vars → one authentication method
- Document this choice clearly in CHANGELOG (the V2 schema puts auth inside endpoint, V1 compatibility is handled by `primary_auth()` fallback already)

Alternative if both must be scanned: at least assert/log a warning when both are present with different `env` values.

---

### 🟡 Issue 3: `conventional_envs()` generates duplicates when provider_id has no hyphens

| File | Function |
|------|----------|
| `credentials.rs` | `conventional_envs()` |

```rust
pub fn conventional_envs(provider_id: &str) -> Vec<String> {
    let upper = provider_id.to_uppercase();
    let normalized = upper.replace('-', "_");
    let mut out = vec![format!("{normalized}_API_KEY")];
    let exact = format!("{upper}_API_KEY");
    if exact != out[0] { out.push(exact); }
    out
}
```

**Problem:** For `provider_id = "openai"`, `normalized == "OPENAI"` == `upper`, so the condition `exact != out[0]` is always false and only one entry is emitted. This **works correctly** but the logic is semantically confused:
- `normalized` is meant for providers like `deep-seek` → `DEEP_SEEK_API_KEY`
- `exact` is meant to also try `DEEPSEEK_API_KEY` (uppercase of raw id)
- But when there's no dash, `normalized == upper`, the second entry is completely pointless

The dedup at the end of `resolve_credential()` handles it harmlessly, but the intent is unclear to future readers.

**Suggestion:** Change to:

```rust
let normalized = provider_id.to_uppercase().replace('-', "_");
let mut out = vec![format!("{normalized}_API_KEY")];
if provider_id.contains('-') {
    out.push(format!("{}_API_KEY", provider_id.to_uppercase().replace('-', "")));
}
```

Or remove the second variant entirely — `{PROVIDER_ID}_API_KEY` with underscores is the de facto convention.

---

### 🟡 Issue 4: Missing test coverage for critical paths

**Currently tested (4 tests):**
- Explicit override wins
- Manifest env wins over conventional env
- Conventional env fallback
- Debug redaction

**Missing:**
- `resolve_credential(manifest, None)` when no env vars are set at all — should return `missing()` with correct required/conventional env lists
- `apply_auth()` with `None` secret — should return unmodified request (no auth header)
- `query_param` auth type — no test at all (used by providers like Replicate)
- `keyring` path — I understand this is hard to unit test, but at minimum a comment explaining how to validate it
- Dual-level auth (endpoint.auth vs top-level auth with different values) — the edge case from Issue 2

---

### 🟢 Issue 5: `apply_auth()` default branch behavior needs documentation

```rust
_ => {
    let header = auth.header_name.as_deref().unwrap_or("Authorization");
    let prefix = auth.prefix.as_deref().unwrap_or("Bearer");
    request.header(header, auth_header_value(prefix, secret))
}
```

The catch-all `_ =>` handles `"bearer"` and any unknown types. For `"bearer"` this generates `Authorization: Bearer <key>` which is correct. But for truly unknown types, silently emitting `Authorization: Bearer <key>` is incorrect — it should at minimum log a warning.

---

## Positive Observations

1. **E/P separation is respected.** The credential resolver is pure deterministic logic — no strategy, no caching, no P-layer concerns.
2. **`Debug` redaction is done properly.** The custom `Debug` impl for `ResolvedCredential` redacts secrets and is tested.
3. **`EndpointDefinition.auth` is a well-chosen addition.** V2 manifests specify auth inside the `endpoint` block (as seen in `schemas/v2/endpoint.json`), and the Rust config struct now matches the schema.
4. **`header` alias** (`#[serde(alias = "header")]`) correctly matches the V2 schema field name `header`, avoiding a mapping layer.
5. **Tests use `EnvGuard` pattern** to restore env vars after each test. Good hygiene.
6. **Log level is appropriate.** Resolved credentials log at `debug` level; missing credentials log at `warn` level. No secret leakage in logs.
7. **All 100 tests pass** on the branch, including the full core test suite.

---

## Recommendations (in priority order)

1. **Make `keyring` an optional feature** — this is the most impactful fix. Without it, every non-WASM build is coupled to D-Bus/libsecret.
2. **Disambiguate `endpoint.auth` vs top-level `auth`** — `required_envs()` should only scan the winning auth config to avoid inconsistent behavior.
3. **Add missing test coverage** — especially the `missing()` path, `query_param` flow, and dual-level auth.
4. **Simplify `conventional_envs()`** — remove the semantically empty second entry when there's no hyphen.
5. **Add a warning log** in `apply_auth()` catch-all when `auth_type` is unknown.

---

## Questions for the Author

1. **Why `keyring` as unconditional?** The old code in `http.rs` also had it unconditional — is there an intentional design reason (e.g., `keyring` v2 doesn't actually require D-Bus at compile time)?
2. **What's the runtime behavior on a Docker container without D-Bus?** Does `keyring::Entry::new()` fail gracefully or panic?
3. **Dual-level auth:** If someone writes a V2 manifest with `endpoint.auth` and a different top-level `auth`, what should happen? The current code is inconsistent between `primary_auth()` and `required_envs()`.
4. **`header_name` vs V2 schema's `header`:** The alias `#[serde(alias = "header")]` allows both — but on serialization it still writes `header_name`. Should serialization use `header` for V2 manifests?

---

*End of review report. Send to author for responses/fixes before merging.*
