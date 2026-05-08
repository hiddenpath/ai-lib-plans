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
| ZS-ML-007 | [tasks/ZS-ML-007-adapter-streaming-tool-completeness.yaml](./tasks/ZS-ML-007-adapter-streaming-tool-completeness.yaml) | `completed` | — | [PR #19](https://github.com/ailib-official/zerospider/pull/19) → main (`a8f0392`) — Phase1 整改 |
| ZS-ML-008 | [tasks/ZS-ML-008-ci-hardening-resilience-tests.yaml](./tasks/ZS-ML-008-ci-hardening-resilience-tests.yaml) | `completed` | ZS-ML-007 | [PR #20](https://github.com/ailib-official/zerospider/pull/20) → main (`0148bdc`) — 整改阶段：补 Phase4/5（`--no-default-features` 测试、双重重试边界证明、reliable×protocol 集成测试） |
| ZS-ML-009 | [tasks/ZS-ML-009-dead-feature-decision.yaml](./tasks/ZS-ML-009-dead-feature-decision.yaml) | `completed` | — | [PR #21](https://github.com/ailib-official/zerospider/pull/21) → main (`6fe40cc`) — 整改阶段：决定 ai-lib-rust `embeddings`/`batch`/`telemetry` feature 的 wire/remove 与 OTel 边界 |
| ZS-ML-010 | [tasks/ZS-ML-010-plan-reopen-and-design-notes.yaml](./tasks/ZS-ML-010-plan-reopen-and-design-notes.yaml) | `completed` | — | plans-governance closeout：plan 状态回退 + ZS-ML-006 deferred_items 回填 + addendum 归档 |
| ZS-ML-011 | [tasks/ZS-ML-011-canonical-remote-contributing.yaml](./tasks/ZS-ML-011-canonical-remote-contributing.yaml) | `completed` | — | [PR #31](https://github.com/ailib-official/zerospider/pull/31) (`83ff308`) — Phase 7 docs canonical remote |
| ZS-ML-012 | [tasks/ZS-ML-012-crates-io-0.9.6.yaml](./tasks/ZS-ML-012-crates-io-0.9.6.yaml) | `completed` | ZS-ML-011 | [PR #31](https://github.com/ailib-official/zerospider/pull/31) (`83ff308`) — Phase 7 crates.io 0.9.6 |
| ZS-ML-013 | [tasks/ZS-ML-013-ci-split-locked.yaml](./tasks/ZS-ML-013-ci-split-locked.yaml) | `completed` | ZS-ML-012 | [PR #31](https://github.com/ailib-official/zerospider/pull/31) (`83ff308`) — Phase 7 CI split |
| ZS-ML-014 | [tasks/ZS-ML-014-manifest-parity-fixture-test.yaml](./tasks/ZS-ML-014-manifest-parity-fixture-test.yaml) | `completed` | ZS-ML-013 | [PR #31](https://github.com/ailib-official/zerospider/pull/31) (`83ff308`) — Phase 7 parity test |

## Phase 7 — Legacy 物理退役 + semver 底座（2026-05-08 ~）

主计划：**[ZEROSPIDER_PHASE7_LEGACY_ELIMINATION_PLAN_2026-05-08.md](./ZEROSPIDER_PHASE7_LEGACY_ELIMINATION_PLAN_2026-05-08.md)**

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|

| ZS-ML-015 | [tasks/ZS-ML-015-remove-legacy-providers-implementation.yaml](./tasks/ZS-ML-015-remove-legacy-providers-implementation.yaml) | `completed` | 012, 014 | [PR #32](https://github.com/ailib-official/zerospider/pull/32) (`bd15a62`) — Phase 7 删除 legacy HTTP provider factory |
| ZS-ML-016 | [tasks/ZS-ML-016-docs-wizard-deprecation-ux.yaml](./tasks/ZS-ML-016-docs-wizard-deprecation-ux.yaml) | `in_progress (PR)` | 015 | [PR #33](https://github.com/ailib-official/zerospider/pull/33) — 文档/向导/弃用信息终稿 |

**执行约定**

1. 每个 task 独立分支 `feat/zs-ml-NNN-<short-slug>`，一个 PR 对应一个 task（整改阶段严格执行）。
2. 合并到 `main` 后，将 YAML 中 `pr.url`、`pr.merge_commit`、`status: completed` 与 `testing.evidence` 补全。
3. `executor_name` / `executor_terminal` 在任务开始与标记完成时必填（见仓库 `.cursor/rules/task-executor-terminal.mdc`）。

**进度摘要**

- **基础阶段（ZS-ML-001 ~ 006）** — 已合入：PR #11 / `5e0925d`、PR #12 / `db21bfd`、PR #14 / `aa3214a`（ZS-ML-003~006 组合 PR）。
- **整改阶段（ZS-ML-007 ~ 010）** — 已完成并合入/回填：PR #19 (`a8f0392`)、PR #20 (`0148bdc`)、PR #21 (`6fe40cc`)；ZS-ML-010 为 plans-governance 直推回填任务。
- **Phase 7（ZS-ML-011 ~ 016）** — **011–014 已合入**：PR #31 / `83ff308`（组合 PR，因跨依赖紧密获例外）；015 已合入：PR #32 / `bd15a62`（legacy 物理删除）；016 已开 PR #33（UX 终稿）。

**审计参考**

- [AUDIT_2026-04-27.md](./AUDIT_2026-04-27.md) — Spider 审查端审计原文（建议 plan 状态回退）。
- [AUDIT_2026-04-27_ADDENDUM.md](./AUDIT_2026-04-27_ADDENDUM.md) — 开发侧基于 `main @ aa3214a` 的代码交叉核实，区分了真实缺口（C1–C10）与审计中误读的 6 项（F1–F6）。
