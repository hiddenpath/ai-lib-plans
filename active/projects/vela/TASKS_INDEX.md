# Vela — AI Navigation Client 任务索引

> 对应 `active/projects/vela/`  
> **与 Eos 区别**：Vela = A 层客户端（Prism SDK → `api.prism.ailib.info`）；Eos = To C 网站（`eos.ailib.info` → `/api/proxy`）。见 `../eos/brand-rationale.md`。

## Phase 1

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| PR-V1-001 | [tasks/PR-V1-001-web-skeleton.yaml](./tasks/PR-V1-001-web-skeleton.yaml) | `completed` ✅ | PR-P1-006 ✅ | [vela](https://github.com/ailib-official/vela) prism-sdk@0.1.0 + smoke OK |
| PR-V1-002 | [tasks/PR-V1-002-local-history.yaml](./tasks/PR-V1-002-local-history.yaml) | `completed` ✅ | PR-V1-001 ✅ | [PR #4](https://github.com/ailib-official/vela/pull/4) `baa7f4a` IndexedDB |
| PR-V1-003 | [tasks/PR-V1-003-provider-navigation-ui.yaml](./tasks/PR-V1-003-provider-navigation-ui.yaml) | `completed` ✅ | PR-V1-001 ✅ | [PR #5](https://github.com/ailib-official/vela/pull/5) `8678a29` — Provider导航+模型切换 |

## Phase 2

> 计划：[PHASE2_PLAN.md](./PHASE2_PLAN.md)

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| PR-V2-001 | [tasks/PR-V2-001-model-comparison.yaml](./tasks/PR-V2-001-model-comparison.yaml) | `completed` ✅ | PR-V1-003 ✅ | [PR #6](https://github.com/ailib-official/vela/pull/6) `5354089` — 并排模型对比 UI |
| PR-V2-002 | [tasks/PR-V2-002-e2e-sync-client.yaml](./tasks/PR-V2-002-e2e-sync-client.yaml) | `in_progress` | PR-V1-002 ✅ | E2E 加密云同步客户端 |
| PR-V2-003 | [tasks/PR-V2-003-wasm-routing.yaml](./tasks/PR-V2-003-wasm-routing.yaml) | `open` | PR-V1-001 ✅ | WASM 基础路由 |
| PR-V2-004 | [tasks/PR-V2-004-smart-recommendations.yaml](./tasks/PR-V2-004-smart-recommendations.yaml) | `open` | PR-V2-003 | 智能推荐（门控 Prism P2） |

## 决策记录

| 文档 | 内容 |
|------|------|
| [PR-V1-001-PREREQUISITES-ANALYSIS.md](./PR-V1-001-PREREQUISITES-ANALYSIS.md) | 前置分析（Spider）+ Cursor 决策确认 |
| [PHASE2_PLAN.md](./PHASE2_PLAN.md) | Phase 2 范围、Wave 排期、Prism/Eos 协调 |
| [project-overview.md](./project-overview.md) | 产品矩阵、三区对齐、路线图 |

## 仓库

- **vela**: `ailib-official/vela` — pnpm monorepo (`packages/prism-sdk`, `apps/web`)
