# Memory — Conventions & Governance

> Naming rules, scope conventions, toolchain alignment, documentation standards.
> Complete chronological record: [`log.md`](./log.md)
> Loading strategy: [`INDEX.md`](./INDEX.md)

**Last updated**: 2026-06-21

---

## Repository Governance (GOV-001 v2)

- **Public code**: all on `ailib-official` org. `origin` = `ailib-official/<repo>`.
- **Internal-only**: `ai-lib-constitution`, `ai-lib-plans`, `papers` on `hiddenpath` (private).
- **hiddenpath public repos**: archived, read-only.
- **Canonical default branch**: `main` (ARCH-004).

## Repository Layout

| Repo | Purpose | Version |
|------|---------|---------|
| ai-protocol | Spec, schemas, manifests | v0.8.4 |
| ai-lib-rust | Rust runtime | v0.9.6 |
| ai-lib-python | Python runtime | v0.8.3 |
| ai-lib-ts | TypeScript runtime | v0.5.3 (`@ailib-official/ai-lib-ts`) |
| ai-lib-go | Go runtime | v0.6.0 |
| ai-protocol-mock | Mock server | v0.1.11 |
| spiderswitch | MCP model switching | v0.4.2 |
| ailib-wasm-test | Browser WASM demo | v0.1.0 |

## npm Scope

- **All npm packages**: `@ailib-official/*` scope
- **Token**: Automation, bypass_2FA, `@ailib-official` publish — GitHub secret `NPM_TOKEN` (never in git/plans)
- **Examples**: `@ailib-official/ai-lib-ts`, `@ailib-official/ai-protocol`, `@ailib-official/prism-sdk` (**v0.1.0**, 2026-06-21)
- **Publish CI repos**: `ailib-official/ai-lib-ts`, `ailib-official/ai-protocol`, `ailib-official/vela` (`packages/prism-sdk`)

### Publish `@ailib-official/prism-sdk`

Workflow: `ailib-official/vela` → `.github/workflows/publish-prism-sdk.yml`

| Trigger | Command |
|---------|---------|
| Tag | `git tag prism-sdk-v0.1.0 && git push origin prism-sdk-v0.1.0` |
| Manual | `gh workflow run publish-prism-sdk.yml --repo ailib-official/vela -f version=0.1.0` |

Prereq: `gh secret set NPM_TOKEN --repo ailib-official/vela`. Verify: `npm view @ailib-official/prism-sdk version`

## Rust Toolchain

- Eos `[workspace.package] rust-version` must align with `Dockerfile` `ARG RUST_IMAGE`.
- Other Rust repos: not required to match Eos MSRV, but check after dep upgrades.
- Check three places before merge: `Cargo.toml` rust-version, Dockerfile/CI Rust version, `cargo build --locked`.

→ Source: [`log.md` § Rust toolchain](./log.md)

## Versioning

- Pre-v1.0: patch increment only (0.x.y → 0.x.y+1). No minor bumps without maintainer approval.
- v1.0 requires explicit maintainer decision + PT-073 gate.
- Post-v1.0: SemVer — 1.x carries backward compatibility obligation.

## Documentation (DOC-001)

- **Code docs**: English. Add one Chinese summary line at module/file header.
- **Internal docs** (plans, reports, standups): Chinese by default.
- **Private docs** (DOC-002): Internal work docs must NOT be pushed to public repos.

## Protocol Conventions

- **Message roles**: system, user, assistant, tool (per ai-protocol v2).
- **Provider manifests**: v1 (legacy, 30+ providers) / v2-alpha (three-ring model).
- **Error codes**: E1001–E9999; minimum mappings: 400→invalid_request, 401→authentication, 429→rate_limited, 500→server_error.

## Constitution Rule Index

| Rule | Topic |
|------|-------|
| ARCH-001 | Protocol-driven design |
| ARCH-002 | Operator pipeline |
| ARCH-003 | Cross-runtime consistency |
| ARCH-004 | Default branch: `main` |
| ARCH-005 | Manifest public authority |
| BIZ-001 | Product matrix (2×2) |
| BIZ-002 | Three-zone boundary (A/B/C) |
| BIZ-003 | Enterprise codebase |
| BIZ-004 | Privacy-first architecture |
| BIZ-005 | Phase gate discipline |
| DOC-001 | Code docs: EN + CN header |
| DOC-002 | Internal docs stay private |
| GOV-001 | Canonical remote (ailib-official) |
| GOV-002 | Merge conflict resolution |
| GOV-004 | LAN git dual-remote (trial) |
| GOV-005 | LAN infrastructure |
| RUST-001 | Error handling (Result) |
| TS-001 | Strict mode |
| TS-002 | Type safety |
| PY-001 | Type hints |
| PY-002 | Async I/O |

→ Full texts: `ai-lib-constitution/rules/`
