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

**执行约定**

1. 每个 task 独立分支 `feat/zs-ml-NNN-<short-slug>`，一个 PR 对应一个 task（除非显式 `allows_batch`）。
2. 合并到 `main` 后，将 YAML 中 `pr.url`、`pr.merge_commit`、`status: completed` 与 `testing.evidence` 补全。
3. `executor_name` / `executor_terminal` 在任务开始与标记完成时必填（见仓库 `.cursor/rules/task-executor-terminal.mdc`）。

**进度摘要**

- **ZS-ML-001** — [PR #12](https://github.com/ailib-official/zerospider/pull/12) / `db21bfd`。
- **ZS-ML-002** — [PR #11](https://github.com/ailib-official/zerospider/pull/11) / `5e0925d`。
- **ZS-ML-003 … ZS-ML-006** — 合并于 [PR #14](https://github.com/ailib-official/zerospider/pull/14) / merge commit `aa3214a`（组合 PR；各 task 见对应 YAML `completion_notes`）。
