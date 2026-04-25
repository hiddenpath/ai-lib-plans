# ZeroSpider — ai-lib 迁移未完成任务（Task 队列）

与 `ZEROSPIDER_AI_LIB_MIGRATION_PLAN.md` 对齐。每条 task 的 **完成定义** 均包含：自动化测试、对 `ailib-official/zerospider` 的 **PR 打开 + `main` 合并**、以及在本文件中回填 PR 链接与 merge commit。

| ID | 文件 | 状态 | 依赖 | 对应计划 Phase / PR |
|----|------|------|------|----------------------|
| ZS-ML-001 | [tasks/ZS-ML-001-default-features-ci-alignment.yaml](./tasks/ZS-ML-001-default-features-ci-alignment.yaml) | `completed` | — | [PR #12](https://github.com/ailib-official/zerospider/pull/12) (`db21bfd`) — PR4/Phase3 + CI |
| ZS-ML-002 | [tasks/ZS-ML-002-contributing-ai-protocol.yaml](./tasks/ZS-ML-002-contributing-ai-protocol.yaml) | `completed` | — | [PR #11](https://github.com/ailib-official/zerospider/pull/11) (`5e0925d`) — PR1/Phase0 |
| ZS-ML-003 | [tasks/ZS-ML-003-config-logical-model-examples.yaml](./tasks/ZS-ML-003-config-logical-model-examples.yaml) | `in_progress` | — | 计划 PR3/Phase2 配置与示例补全 |
| ZS-ML-004 | [tasks/ZS-ML-004-routing-mvp-metrics-optional.yaml](./tasks/ZS-ML-004-routing-mvp-metrics-optional.yaml) | `open` | 建议 ZS-ML-001 后 | 计划 PR5/Phase4 |
| ZS-ML-005 | [tasks/ZS-ML-005-legacy-removal-migration-guide.yaml](./tasks/ZS-ML-005-legacy-removal-migration-guide.yaml) | `open` | ZS-ML-001 | 计划 PR6/Phase5 |
| ZS-ML-006 | [tasks/ZS-ML-006-wizard-security-docs.yaml](./tasks/ZS-ML-006-wizard-security-docs.yaml) | `open` | 可与 ZS-ML-002 并行 | 计划 PR7/Phase6 |

**执行约定**

1. 每个 task 独立分支 `feat/zs-ml-NNN-<short-slug>`，一个 PR 对应一个 task（除非显式 `allows_batch`）。
2. 合并到 `main` 后，将 YAML 中 `pr.url`、`pr.merge_commit`、`status: completed` 与 `testing.evidence` 补全。
3. `executor_name` / `executor_terminal` 在任务开始与标记完成时必填（见仓库 `.cursor/rules/task-executor-terminal.mdc`）。

**进度摘要**

- **ZS-ML-001** 已合并：[PR #12](https://github.com/ailib-official/zerospider/pull/12) / `db21bfd`（**ZS-ML-005** 的前置依赖已满足）。
- **ZS-ML-002** 已合并：[PR #11](https://github.com/ailib-official/zerospider/pull/11) / `5e0925d`。
- **进行中**：[ZS-ML-003](./tasks/ZS-ML-003-config-logical-model-examples.yaml)（Phase2 配置示例 + 反序列化回归测试）；分支 `feat/zs-ml-003-config-model-examples`（合并后回填 `pr.url` / `merge_commit`）。
