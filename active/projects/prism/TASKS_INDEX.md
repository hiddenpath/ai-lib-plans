# Prism（棱镜）— AI Protocol Gateway 任务索引

> 对应项目根 `active/projects/prism/`

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| PR-P1-001 | [tasks/PR-P1-001-project-skeleton.yaml](./tasks/PR-P1-001-project-skeleton.yaml) | `open` | — | 项目骨架 (Axum + config + /health + Docker) |
| PR-P1-002 | [tasks/PR-P1-002-core-proxy.yaml](./tasks/PR-P1-002-core-proxy.yaml) | `open` | PR-P1-001 | Core proxy — /v1/chat/completions (sync + SSE) |
| PR-P1-003 | [tasks/PR-P1-003-key-pool.yaml](./tasks/PR-P1-003-key-pool.yaml) | `open` | PR-P1-002 | Key pool (rotate + cooldown + circuit breaker) |
| PR-P1-004 | [tasks/PR-P1-004-usage-tracking.yaml](./tasks/PR-P1-004-usage-tracking.yaml) | `open` | PR-P1-002 | Usage tracking (SQLite + Pricer) |
| PR-P1-005 | [tasks/PR-P1-005-fallback-routing.yaml](./tasks/PR-P1-005-fallback-routing.yaml) | `open` | PR-P1-002, PR-P1-003 | Fallback routing (primary → secondary) |
| PR-P1-006 | [tasks/PR-P1-006-docker-deployment.yaml](./tasks/PR-P1-006-docker-deployment.yaml) | `open` | PR-P1-005 | Docker + Caddy TLS + api.prism.ailib.info |
| PR-P1-007 | [tasks/PR-P1-007-admin-api.yaml](./tasks/PR-P1-007-admin-api.yaml) | `open` | PR-P1-003, PR-P1-004 | Admin API (keys/users/usage CRUD) |
| PR-P1-008 | [tasks/PR-P1-008-provider-verification.yaml](./tasks/PR-P1-008-provider-verification.yaml) | `open` | PR-P1-006 | 5 P0 Providers integration verification |

## Wave 2 产品化预备（P2）

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| PR-PP-001 | [tasks/PR-PP-001-pack-contract-draft.yaml](./tasks/PR-PP-001-pack-contract-draft.yaml) | `open` | PR-P1-008 | Pack contract draft (JSON Schema + example) |
| PR-PP-002 | [tasks/PR-PP-002-cost-routing-example.yaml](./tasks/PR-PP-002-cost-routing-example.yaml) | `open` | PR-P1-005, PR-P1-008 | Minimal cost routing example |
| PR-PP-003 | [tasks/PR-PP-003-constitution-rules-extraction.yaml](./tasks/PR-PP-003-constitution-rules-extraction.yaml) | `open` | — | Constitution rules extraction (BIZ-001~005) |

## 里程碑

| 里程碑 | 时间 | 验收标准 | 状态 |
|--------|------|---------|:----:|
| M1: Core Gateway | TBD | 5 P0 providers proxy-through, key pool in place, health OK | ⏳ |
| M2: Feature Complete | TBD | Fallback + usage tracking + admin API + Docker + domain live | ⏳ |
| M3: Product Launch | TBD | api.prism.ailib.info available, 5 providers verified | ⏳ |

## 依赖

- ai-lib-core v0.9.x (or published crates.io)
- ai-protocol manifests for 5 P0 providers
- Provider API keys (OpenAI, DeepSeek, Groq, NVIDIA, Anthropic)
- Domain: api.prism.ailib.info (DNS + Caddy TLS)

## 相关文档

- `project-overview.md` — Prism 项目总览
- 计划源: `ai_lib_gateway_phase1_plan.md v2.0`
