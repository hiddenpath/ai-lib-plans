# Prism Enterprise MVP — Phase 2 Placeholder Design

> **Task**: PR-P2-006  
> **Status**: Draft placeholder (Phase 2 Wave 7)  
> **Scope**: Design only — no SSO or audit runtime in Phase 2

## 1. Purpose

Enterprise customers need identity federation (SSO) and tamper-evident audit trails. Phase 2 delivers **integration points and schemas** so Phase 3 can ship runtime without re-architecting gateway or prism-core boundaries.

**Non-goals (Phase 2)**:

- Full OIDC/SAML IdP integration
- Audit log storage / SIEM export
- `--features enterprise` binary in production

## 2. SSO integration points

### Recommended approach: OIDC first, SAML later

| Option | Phase 2 | Phase 3 | Notes |
|--------|---------|---------|-------|
| **OIDC** (Auth0, Okta, Azure AD) | Document callback URLs + JWT claims mapping | Implement middleware in ai-lib-gateway | Aligns with Bearer user keys (PR-P2-002) |
| **SAML 2.0** | Selection doc only | SP-initiated flow behind enterprise feature flag | Higher integration cost |

### Gateway hook (future)

```
Client → TLS → Caddy → ai-lib-gateway
                         ├─ /v1/*     (existing Bearer: platform | user API key)
                         └─ /auth/*   (Phase 3: OIDC callback, session cookie optional)
```

**Phase 2 contract**:

- `user_id` in usage/billing/BYOK remains the stable tenant principal.
- SSO maps `sub` / `email` → internal `user_id` via admin-provisioned mapping table (design TBD).
- No change to eos `/api/proxy` (Eos product boundary unchanged).

### Environment / config sketch (TOML, not implemented)

```toml
[enterprise.sso]
enabled = false
provider = "oidc"
issuer_url = "https://login.example.com/"
client_id = "${OIDC_CLIENT_ID}"
# client_secret via env only
```

## 3. Audit log schema (draft)

Audit events are **append-only** and linkable to usage via `request_id`.

```json
{
  "$schema": "prism-audit-event/v0",
  "event_id": "uuid",
  "timestamp": "2026-06-24T08:00:00Z",
  "request_id": "req_…",
  "actor": {
    "user_id": "usr_…",
    "auth_method": "bearer_user_key | platform | sso_oidc",
    "ip_hash": "sha256:…"
  },
  "action": "route.decide | chat.completion | admin.byok.create",
  "resource": {
    "provider_id": "deepseek",
    "model_id": "deepseek-chat",
    "route_optimize": "cost"
  },
  "outcome": "success | denied | error",
  "metadata": {}
}
```

### Correlation with usage records

| Usage field (`prism-core`) | Audit field | Link |
|----------------------------|-------------|------|
| `request_id` | `request_id` | 1:1 primary key |
| `user_id` | `actor.user_id` | Same principal |
| `provider_id` / `model_id` | `resource.*` | Route actually used |
| `cost_micro_usd` | optional `metadata.billed_micro_usd` | Post-billing enrichment |

Phase 2: document schema in plans; Phase 3: emit from gateway middleware after auth + after route decision.

## 4. `--features enterprise` boundary

| Component | Phase 2 | Phase 3 |
|-----------|---------|---------|
| **prism-core** (`hiddenpath/eos`) | No enterprise feature | Optional `enterprise` module: audit types, SSO claim parsers (no HTTP) |
| **ai-lib-gateway** | Docs + config stubs | `enterprise` feature: OIDC middleware, audit sink (stdout / webhook) |
| **eos-server** | Unchanged | May consume same audit types for operator UI |

**Rule**: Enterprise HTTP surface lives in **ai-lib-gateway** (C-band product shell), not in public `prism-core` crates.io API.

## 5. Phase 2 vs Phase 3 boundary

| Capability | Phase 2 (this doc) | Phase 3 |
|------------|-------------------|---------|
| SSO login UX | Design + OIDC selection | Runtime + session |
| Audit storage | JSON schema | SQLite / object store / export |
| Compliance packs | Referenced in Pack metadata | Signed pack registry |
| PT-073 Contact metadata | Soft dependency for smart routing | May enrich audit `resource` |

## 6. Acceptance mapping (PR-P2-006)

- [x] Design document in ai-lib-plans (`docs/PR-P2-006-ENTERPRISE_PLACEHOLDER.md`)
- [x] Audit events correlate with usage via `request_id`
- [x] Phase 2 / Phase 3 boundary explicit

## References

- PR-P2-002 BYOK user principal model
- PR-P2-004 billing / usage records
- PRODUCT_PLAN §4.2 Enterprise MVP
- PT-073 gap audit (loose coupling)
