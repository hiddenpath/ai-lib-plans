# Vela — AI Navigation Client 任务索引

> 对应 `active/projects/vela/`  
> **与 Eos 区别**：Vela = A 层客户端（Prism SDK → `api.prism.ailib.info`）；Eos = To C 网站（`eos.ailib.info` → `/api/proxy`）。见 `eos/brand-rationale.md`。

## Phase 1

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| PR-V1-001 | [tasks/PR-V1-001-web-skeleton.yaml](./tasks/PR-V1-001-web-skeleton.yaml) | `in_progress` | PR-P1-006 ✅ | [vela](https://github.com/ailib-official/vela) `344d8e2` — SDK + web |
| PR-V1-002 | [tasks/PR-V1-002-local-history.yaml](./tasks/PR-V1-002-local-history.yaml) | `open` | PR-V1-001 | IndexedDB 本地历史 |
| PR-V1-003 | [tasks/PR-V1-003-provider-navigation-ui.yaml](./tasks/PR-V1-003-provider-navigation-ui.yaml) | `open` | PR-V1-001 | Provider/模型导航 UI |

## 决策记录

| 文档 | 内容 |
|------|------|
| [PR-V1-001-PREREQUISITES-ANALYSIS.md](./PR-V1-001-PREREQUISITES-ANALYSIS.md) | 前置分析（Spider）+ Cursor 决策确认 |
| [project-overview.md](./project-overview.md) | 产品矩阵、三区对齐、路线图 |

## 仓库

- **vela**: `ailib-official/vela` — pnpm monorepo (`packages/prism-sdk`, `apps/web`)
