# ZeroSpider — ai-lib 迁移未完成任务（Task 队列）

与 `ZEROSPIDER_AI_LIB_MIGRATION_PLAN.md` 对齐。每条 task 的 **完成定义** 均包含：自动化测试、对 `ailib-official/zerospider` 的 **PR 打开 + `main` 合并**、以及在本文件中回填 PR 链接与 merge commit。

| ID | 文件 | 状态 | 依赖 | 对应计划 Phase / PR |
|----|------|------|------|----------------------|
| ZS-ML-001 | [tasks/ZS-ML-001-default-features-ci-alignment.yaml](./tasks/ZS-ML-001-default-features-ci-alignment.yaml) | `open` | — | 计划 PR4/Phase3 + CI 矩阵（legacy 默认与测试策略） |
| ZS-ML-002 | [tasks/ZS-ML-002-contributing-ai-protocol.yaml](./tasks/ZS-ML-002-contributing-ai-protocol.yaml) | `in_progress` | — | 计划 PR1/Phase0 可选项 + 可审性 |
| ZS-ML-003 | [tasks/ZS-ML-003-config-logical-model-examples.yaml](./tasks/ZS-ML-003-config-logical-model-examples.yaml) | `open` | — | 计划 PR3/Phase2 配置与示例补全 |
| ZS-ML-004 | [tasks/ZS-ML-004-routing-mvp-metrics-optional.yaml](./tasks/ZS-ML-004-routing-mvp-metrics-optional.yaml) | `open` | 建议 ZS-ML-001 后 | 计划 PR5/Phase4 |
| ZS-ML-005 | [tasks/ZS-ML-005-legacy-removal-migration-guide.yaml](./tasks/ZS-ML-005-legacy-removal-migration-guide.yaml) | `open` | ZS-ML-001 | 计划 PR6/Phase5 |
| ZS-ML-006 | [tasks/ZS-ML-006-wizard-security-docs.yaml](./tasks/ZS-ML-006-wizard-security-docs.yaml) | `open` | 可与 ZS-ML-002 并行 | 计划 PR7/Phase6 |

**执行约定**

1. 每个 task 独立分支 `feat/zs-ml-NNN-<short-slug>`，一个 PR 对应一个 task（除非显式 `allows_batch`）。
2. 合并到 `main` 后，将 YAML 中 `pr.url`、`pr.merge_commit`、`status: completed` 与 `testing.evidence` 补全。
3. `executor_name` / `executor_terminal` 在任务开始与标记完成时必填（见仓库 `.cursor/rules/task-executor-terminal.mdc`）。

**ZS-ML-002 进展（与 GOV-001 对齐）**

- **正确定位**：`ailib-official/zerospider` 是公共 canonical 仓（**GOV-001**）；`hiddenpath` 侧为零 Spider 自 zeroclaw 迁出过程中的历史位置，**公共代码新开发不推 hiddenpath**（同规则：constitution/plans 等内部仓仍在 hiddenpath，与 runtime 公仓不同）。
- **落地方式**：本地 `git remote set-url origin https://github.com/ailib-official/zerospider.git`（或按 `ai-lib-plans` 中 `docs/governance/REMOTE_MIGRATION.md` 若存在），在 **`ailib-official/zerospider`** 上推送 `feat/zs-ml-002-contributing` 并开 **同组织同仓库** 的 PR（例如比较：<https://github.com/ailib-official/zerospider/compare/main...feat/zs-ml-002-contributing>，分支存在并推送后有效）。
- 合并到 `main` 后回填该 task 的 `pr.url` / `merge_commit` 并将状态标为 `completed`。
