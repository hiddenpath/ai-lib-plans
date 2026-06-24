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
| PR-P1-009 | [tasks/PR-P1-009-config-toml-loader.yaml](./tasks/PR-P1-009-config-toml-loader.yaml) | `completed` | — | TOML config.toml |
| PR-P1-010 | [tasks/PR-P1-010-anthropic-adapter.yaml](./tasks/PR-P1-010-anthropic-adapter.yaml) | `completed` | PR-P1-002-LIB | Anthropic Messages API (JSON map; HTTP wire PR-P1-002) |
| PR-P1-011 | [tasks/PR-P1-011-quota-enforcement.yaml](./tasks/PR-P1-011-quota-enforcement.yaml) | `completed` | PR-P1-004 | Quota enforce |
| PR-P1-012 | [tasks/PR-P1-012-prism-core-crates-io.yaml](./tasks/PR-P1-012-prism-core-crates-io.yaml) | `completed` | PR-P1-008 | crates.io 发布 (prism-core-routing v0.1.0) |

## Phase 1 — 产品层（HTTP / 部署）

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| PR-P1-001 | [tasks/PR-P1-001-project-skeleton.yaml](./tasks/PR-P1-001-project-skeleton.yaml) | `completed` | — | Gateway shell + /health + TOML 接线 |
| PR-P1-002 | [tasks/PR-P1-002-core-proxy.yaml](./tasks/PR-P1-002-core-proxy.yaml) | `completed` | PR-P1-001 | OpenAI `/v1/*` HTTP |
| PR-P1-014 | [tasks/PR-P1-014-admin-http-routes.yaml](./tasks/PR-P1-014-admin-http-routes.yaml) | `completed` | PR-P1-001, PR-P1-003, PR-P1-004 | `/admin/*` HTTP |
| PR-P1-006 | [tasks/PR-P1-006-docker-deployment.yaml](./tasks/PR-P1-006-docker-deployment.yaml) | `completed` ✅ | PR-P1-002 | Docker + Caddy — PR #7 `b1b0b69` |
| PR-P1-013 | [tasks/PR-P1-013-prism-dns.yaml](./tasks/PR-P1-013-prism-dns.yaml) | `completed` ✅ | PR-P1-006 ✅ | api.prism.ailib.info DNS |
| PR-P1-008 | [tasks/PR-P1-008-provider-verification.yaml](./tasks/PR-P1-008-provider-verification.yaml) | `completed` | PR-P1-002, PR-P1-003, PR-P1-005 | 5 P0 smoke (P1-B local/CI) |
| PR-P1-016 | [tasks/PR-P1-016-velaclaw-prism-migration.yaml](./tasks/PR-P1-016-velaclaw-prism-migration.yaml) | `completed` | PR-P1-006 ✅, PR-V1-001 | VelaClaw 迁移 (VL-EVO-002/004 merged) |
| PR-P1-017 | [tasks/PR-P1-017-deploy-path-b1.yaml](./tasks/PR-P1-017-deploy-path-b1.yaml) | `completed` ✅ | PR-P1-013 ✅ | Path B1 deploy — [PR #9](https://github.com/hiddenpath/ai-lib-gateway/pull/9) `6ba2bbc`, prod live 2026-06-21 |

## Wave 2 产品化预备

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| PR-PP-001 | [tasks/PR-PP-001-pack-contract-draft.yaml](./tasks/PR-PP-001-pack-contract-draft.yaml) | `in_progress` | PR-P1-008 ✅ | Pack contract — ai-protocol [#10](https://github.com/ailib-official/ai-protocol/pull/10) |
| PR-PP-002 | [tasks/PR-PP-002-cost-routing-example.yaml](./tasks/PR-PP-002-cost-routing-example.yaml) | `completed` ✅ | PR-P1-005 ✅, PR-P1-008 ✅ | 成本路由 — eos [#14](https://github.com/hiddenpath/eos/pull/14) `7f72783` |
| PR-PP-003 | [tasks/PR-PP-003-constitution-rules-extraction.yaml](./tasks/PR-PP-003-constitution-rules-extraction.yaml) | `completed` ✅ | PR-P1-005 ✅ | BIZ-001~005 |

## Phase 2

> 计划：[PHASE2_PLAN.md](./PHASE2_PLAN.md) · 门控分析：[PRISM_P2_PT073_GATE_ANALYSIS_2026-06.md](./PRISM_P2_PT073_GATE_ANALYSIS_2026-06.md)

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| PR-P2-001 | [tasks/PR-P2-001-pricing-micro-usd.yaml](./tasks/PR-P2-001-pricing-micro-usd.yaml) | `completed` ✅ | PR-P1-004 ✅ | µUSD — eos [#15](https://github.com/hiddenpath/eos/pull/15) `40ab60e` |
| PR-P2-002 | [tasks/PR-P2-002-byok-mode.yaml](./tasks/PR-P2-002-byok-mode.yaml) | `completed` ✅ | PR-P1-003 ✅ | BYOK — eos [#17](https://github.com/hiddenpath/eos/pull/17) `8289bb5` + gateway [#12](https://github.com/hiddenpath/ai-lib-gateway/pull/12) |
| PR-P2-003 | [tasks/PR-P2-003-route-decide-http.yaml](./tasks/PR-P2-003-route-decide-http.yaml) | `completed` ✅ | PR-PP-002 | `POST /v1/route/decide` — gateway [#10](https://github.com/hiddenpath/ai-lib-gateway/pull/10) `753e129` |
| PR-P2-004 | [tasks/PR-P2-004-billing-pay-per-use.yaml](./tasks/PR-P2-004-billing-pay-per-use.yaml) | `completed` ✅ | PR-P2-001 ✅ | billing — eos [#16](https://github.com/hiddenpath/eos/pull/16) `64772ef` + gateway [#11](https://github.com/hiddenpath/ai-lib-gateway/pull/11) |
| PR-P2-005 | [tasks/PR-P2-005-smart-routing-ga.yaml](./tasks/PR-P2-005-smart-routing-ga.yaml) | `in_progress` | PR-P2-003 ✅, PR-P2-004 ✅ | 智能路由 GA |
| PR-P2-006 | [tasks/PR-P2-006-enterprise-mvp-placeholder.yaml](./tasks/PR-P2-006-enterprise-mvp-placeholder.yaml) | `completed` ✅ | PR-P2-004 ✅ | Enterprise 占位 — [design doc](./docs/PR-P2-006-ENTERPRISE_PLACEHOLDER.md) |

## 里程碑

| 里程碑 | 验收标准 | 状态 |
|--------|---------|:----:|
| M1: Library core | prism-core `cargo test --features full` 45+ passed | ✅ |
| M2: Product API | `/v1/*` + admin HTTP + 5 provider E2E — all merged | ✅ |
| M3: Production | api.prism.ailib.info + Docker + Caddy TLS — deployed 2026-06-21, 5 providers live | ✅ |

## 依赖

- **prism-core**（path: hiddenpath/eos）；Phase 1 **不**要求 ai-lib-core
- ai-protocol manifests（5 P0 providers）
- Provider API keys；域名 api.prism.ailib.info

## 相关文档

- [project-overview.md](./project-overview.md)
- [PHASE2_PLAN.md](./PHASE2_PLAN.md) — **Phase 2 排期**
- [PRISM_P2_PT073_GATE_ANALYSIS_2026-06.md](./PRISM_P2_PT073_GATE_ANALYSIS_2026-06.md) — 门控对照
- [docs/PR-PP-002-IMPLEMENTATION.md](./docs/PR-PP-002-IMPLEMENTATION.md) — 成本路由 + decide API
- [NEAR_TERM_EXECUTION_2026-06-P1.md](./NEAR_TERM_EXECUTION_2026-06-P1.md) — P1 排期（已完成）
- [../ai-protocol/PT-073-GAP-AUDIT_2026-06.md](../ai-protocol/PT-073-GAP-AUDIT_2026-06.md) — PT-073 差距审计
- MEMORY.md § 2026-06-04 Prism Phase 1 计划对齐
