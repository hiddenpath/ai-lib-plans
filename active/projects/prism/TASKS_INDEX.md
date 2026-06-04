# Prism（棱镜）— AI Protocol Gateway 任务索引

> 对应项目根 `active/projects/prism/`  
> **修订**: 2026-06-04 — library/product scope split（见 `project-overview.md`）

## Phase 1 — 库层（prism-core @ hiddenpath/eos）

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| PR-P1-002-LIB | [tasks/PR-P1-002-LIB-core-proxy-library.yaml](./tasks/PR-P1-002-LIB-core-proxy-library.yaml) | `completed` | — | libcurl proxy 库 |
| PR-P1-003 | [tasks/PR-P1-003-key-pool.yaml](./tasks/PR-P1-003-key-pool.yaml) | `completed` | PR-P1-002-LIB | Key pool |
| PR-P1-004 | [tasks/PR-P1-004-usage-tracking.yaml](./tasks/PR-P1-004-usage-tracking.yaml) | `completed` | PR-P1-002-LIB | Usage + Pricer |
| PR-P1-005 | [tasks/PR-P1-005-fallback-routing.yaml](./tasks/PR-P1-005-fallback-routing.yaml) | `completed` | PR-P1-002-LIB, PR-P1-003 | Fallback routing |
| PR-P1-007 | [tasks/PR-P1-007-admin-api.yaml](./tasks/PR-P1-007-admin-api.yaml) | `completed` | PR-P1-003, PR-P1-004 | AdminService 逻辑 |
| PR-P1-009 | [tasks/PR-P1-009-config-toml-loader.yaml](./tasks/PR-P1-009-config-toml-loader.yaml) | `open` | — | TOML config.toml |
| PR-P1-010 | [tasks/PR-P1-010-anthropic-adapter.yaml](./tasks/PR-P1-010-anthropic-adapter.yaml) | `open` | PR-P1-002-LIB | Anthropic Messages API |
| PR-P1-011 | [tasks/PR-P1-011-quota-enforcement.yaml](./tasks/PR-P1-011-quota-enforcement.yaml) | `open` | PR-P1-004 | Quota enforce |
| PR-P1-012 | [tasks/PR-P1-012-prism-core-crates-io.yaml](./tasks/PR-P1-012-prism-core-crates-io.yaml) | `open` | PR-P1-008 | crates.io 发布 |

## Phase 1 — 产品层（HTTP / 部署）

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| PR-P1-001 | [tasks/PR-P1-001-project-skeleton.yaml](./tasks/PR-P1-001-project-skeleton.yaml) | `open` | — | Gateway shell + /health + TOML 接线 |
| PR-P1-002 | [tasks/PR-P1-002-core-proxy.yaml](./tasks/PR-P1-002-core-proxy.yaml) | `open` | PR-P1-001 | OpenAI `/v1/*` HTTP |
| PR-P1-014 | [tasks/PR-P1-014-admin-http-routes.yaml](./tasks/PR-P1-014-admin-http-routes.yaml) | `open` | PR-P1-001, PR-P1-003, PR-P1-004 | `/admin/*` HTTP |
| PR-P1-006 | [tasks/PR-P1-006-docker-deployment.yaml](./tasks/PR-P1-006-docker-deployment.yaml) | `open` | PR-P1-002 | Docker + Caddy |
| PR-P1-013 | [tasks/PR-P1-013-prism-dns.yaml](./tasks/PR-P1-013-prism-dns.yaml) | `open` | PR-P1-006 | api.prism.ailib.info DNS |
| PR-P1-008 | [tasks/PR-P1-008-provider-verification.yaml](./tasks/PR-P1-008-provider-verification.yaml) | `open` | PR-P1-002, PR-P1-003, PR-P1-005 | 5 P0 E2E |
| PR-P1-016 | [tasks/PR-P1-016-velaclaw-prism-migration.yaml](./tasks/PR-P1-016-velaclaw-prism-migration.yaml) | `open` | PR-P1-002-LIB | VelaClaw 迁移 |

## Wave 2 产品化预备

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| PR-PP-001 | [tasks/PR-PP-001-pack-contract-draft.yaml](./tasks/PR-PP-001-pack-contract-draft.yaml) | `open` | PR-P1-008 | Pack contract |
| PR-PP-002 | [tasks/PR-PP-002-cost-routing-example.yaml](./tasks/PR-PP-002-cost-routing-example.yaml) | `open` | PR-P1-005, PR-P1-008 | Cost routing example |
| PR-PP-003 | [tasks/PR-PP-003-constitution-rules-extraction.yaml](./tasks/PR-PP-003-constitution-rules-extraction.yaml) | `in_progress` | PR-P1-005 | BIZ-001~005（先对齐 A/C band） |

## 里程碑

| 里程碑 | 验收标准 | 状态 |
|--------|---------|:----:|
| M1: Library core | prism-core `cargo test --features full` 45+ passed | ✅ |
| M2: Product API | `/v1/*` + admin HTTP + 5 provider E2E | ⏳ |
| M3: Production | api.prism.ailib.info + Docker + DNS | ⏳ |

## 依赖

- **prism-core**（path: hiddenpath/eos）；Phase 1 **不**要求 ai-lib-core
- ai-protocol manifests（5 P0 providers）
- Provider API keys；域名 api.prism.ailib.info

## 相关文档

- [project-overview.md](./project-overview.md)
- [NEAR_TERM_EXECUTION_2026-06-P1.md](./NEAR_TERM_EXECUTION_2026-06-P1.md) — **近期排期（P1）**；Eos proxy 不在范围内
- MEMORY.md § 2026-06-04 Prism Phase 1 计划对齐
