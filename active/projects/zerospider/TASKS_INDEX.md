# ZeroSpider — ai-lib 迁移未完成任务（Task 队列）

与 `ZEROSPIDER_AI_LIB_MIGRATION_PLAN.md` 对齐。每条 task 的 **完成定义** 均包含：自动化测试、对 `ailib-official/zerospider` 的 **PR 打开 + `main` 合并**、以及在本文件中回填 PR 链接与 merge commit。

| ID | 文件 | 状态 | 依赖 | 对应计划 Phase / PR |
|----|------|------|------|----------------------|
| ZS-ML-001 | [tasks/ZS-ML-001-default-features-ci-alignment.yaml](./tasks/ZS-ML-001-default-features-ci-alignment.yaml) | `completed` | — | [PR #12](https://github.com/ailib-official/zerospider/pull/12) (`db21bfd`) — PR4/Phase3 + CI |
| ZS-ML-002 | [tasks/ZS-ML-002-contributing-ai-protocol.yaml](./tasks/ZS-ML-002-contributing-ai-protocol.yaml) | `completed` | — | [PR #11](https://github.com/ailib-official/zerospider/pull/11) (`5e0925d`) — PR1/Phase0 |
| ZS-ML-003 | [tasks/ZS-ML-003-config-logical-model-examples.yaml](./tasks/ZS-ML-003-config-logical-model-examples.yaml) | `completed` | — | [PR #14](https://github.com/ailib-official/zerospider/pull/14) (`aa3214a`) — Phase2（与 004–006 同 PR 合并） |
| ZS-ML-004 | [tasks/ZS-ML-004-routing-mvp-metrics-optional.yaml](./tasks/ZS-ML-004-routing-mvp-metrics-optional.yaml) | `completed` | 建议 ZS-ML-001 后 | [PR #14](https://github.com/ailib-official/zerospider/pull/14) (`aa3214a`) — Phase4 compile gate |
| ZS-ML-005 | [tasks/ZS-ML-005-legacy-removal-migration-guide.yaml](./tasks/ZS-ML-005-legacy-removal-migration-guide.yaml) | `completed` | ZS-ML-001 | [PR #14](https://github.com/ailib-official/zerospider/pull/14) (`aa3214a`) — Phase5 迁移文档 + 门控说明 |
| ZS-ML-006 | [tasks/ZS-ML-006-wizard-security-docs.yaml](./tasks/ZS-ML-006-wizard-security-docs.yaml) | `completed` | 可与 ZS-ML-002 并行 | [PR #14](https://github.com/ailib-official/zerospider/pull/14) (`aa3214a`) — Phase6 向导/兼容窗口 |
| ZS-ML-007 | [tasks/ZS-ML-007-adapter-streaming-tool-completeness.yaml](./tasks/ZS-ML-007-adapter-streaming-tool-completeness.yaml) | `todo` | — | 整改阶段：补 Phase1（流式 `PartialToolCall`、多轮工具会话、流式集成测试） |
| ZS-ML-008 | [tasks/ZS-ML-008-ci-hardening-resilience-tests.yaml](./tasks/ZS-ML-008-ci-hardening-resilience-tests.yaml) | `todo` | ZS-ML-007 | 整改阶段：补 Phase4/5（`--no-default-features` 测试、双重重试边界证明、reliable×protocol 集成测试） |
| ZS-ML-009 | [tasks/ZS-ML-009-dead-feature-decision.yaml](./tasks/ZS-ML-009-dead-feature-decision.yaml) | `todo` | — | 整改阶段：决定 ai-lib-rust `embeddings`/`batch`/`telemetry` feature 的 wire/remove 与 OTel 边界 |
| ZS-ML-010 | [tasks/ZS-ML-010-plan-reopen-and-design-notes.yaml](./tasks/ZS-ML-010-plan-reopen-and-design-notes.yaml) | `in_progress` | — | 整改阶段：plan 状态回退 + ZS-ML-006 deferred_items 回填 + addendum 归档 |

**执行约定**

1. 每个 task 独立分支 `feat/zs-ml-NNN-<short-slug>`，一个 PR 对应一个 task（整改阶段严格执行）。
2. 合并到 `main` 后，将 YAML 中 `pr.url`、`pr.merge_commit`、`status: completed` 与 `testing.evidence` 补全。
3. `executor_name` / `executor_terminal` 在任务开始与标记完成时必填（见仓库 `.cursor/rules/task-executor-terminal.mdc`）。

**进度摘要**

- **基础阶段（ZS-ML-001 ~ 006）** — 已合入：PR #11 / `5e0925d`、PR #12 / `db21bfd`、PR #14 / `aa3214a`（ZS-ML-003~006 组合 PR）。
- **整改阶段（ZS-ML-007 ~ 010）** — 由 [`AUDIT_2026-04-27.md`](./AUDIT_2026-04-27.md) 与 [`AUDIT_2026-04-27_ADDENDUM.md`](./AUDIT_2026-04-27_ADDENDUM.md) 派生；推荐执行顺序：010（plan 文档）→ 007（流式）→ 008（CI/测试）→ 009（feature 决策）。

**审计参考**

- [AUDIT_2026-04-27.md](./AUDIT_2026-04-27.md) — Spider 审查端审计原文（建议 plan 状态回退）。
- [AUDIT_2026-04-27_ADDENDUM.md](./AUDIT_2026-04-27_ADDENDUM.md) — 开发侧基于 `main @ aa3214a` 的代码交叉核实，区分了真实缺口（C1–C10）与审计中误读的 6 项（F1–F6）。
