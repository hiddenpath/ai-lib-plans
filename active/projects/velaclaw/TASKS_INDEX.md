# ZeroSpider — ai-lib 迁移任务队列

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
| ZS-ML-016 | [tasks/ZS-ML-016-docs-wizard-deprecation-ux.yaml](./tasks/ZS-ML-016-docs-wizard-deprecation-ux.yaml) | `completed` | 015 | [PR #33](https://github.com/ailib-official/zerospider/pull/33) ([`2183171`](https://github.com/ailib-official/zerospider/commit/21831717d39b22f924e792dea18c72569590a2c0)) — 文档/向导/弃用信息终稿 |

**执行约定**

1. 每个 task 独立分支 `feat/zs-ml-NNN-<short-slug>`，一个 PR 对应一个 task（整改阶段严格执行）。
2. 合并到 `main` 后，将 YAML 中 `pr.url`、`pr.merge_commit`、`status: completed` 与 `testing.evidence` 补全。
3. `executor_name` / `executor_terminal` 在任务开始与标记完成时必填（见仓库 `.cursor/rules/task-executor-terminal.mdc`）。

**进度摘要**

- **基础阶段（ZS-ML-001 ~ 006）** — 已合入：PR #11 / `5e0925d`、PR #12 / `db21bfd`、PR #14 / `aa3214a`（ZS-ML-003~006 组合 PR）。
- **整改阶段（ZS-ML-007 ~ 010）** — 已完成并合入/回填：PR #19 (`a8f0392`)、PR #20 (`0148bdc`)、PR #21 (`6fe40cc`)；ZS-ML-010 为 plans-governance 直推回填任务。
- **Phase 7（ZS-ML-011 ~ 016）** — **已合入**：PR #31 / `83ff308`（011–014 组合 PR）；PR #32 / `bd15a62`（015 legacy 物理删除）；PR #33 / `2183171`（016 文档/向导/UX 终稿）。
- **更名阶段（ZS-RN-001 ~ 003）** — **已全部完成**（2026-05-13）：PR #38 / `36b9a5c`（001+002 原子合并）；GitHub 仓库已改名 `ailib-official/velaclaw`；外部引用审计已完成。

**审计参考**

- [AUDIT_2026-04-27.md](./AUDIT_2026-04-27.md) — Spider 审查端审计原文（建议 plan 状态回退）。
- [AUDIT_2026-04-27_ADDENDUM.md](./AUDIT_2026-04-27_ADDENDUM.md) — 开发侧基于 `main @ aa3214a` 的代码交叉核实，区分了真实缺口（C1–C10）与审计中误读的 6 项（F1–F6）。

## 更名阶段 — ZeroSpider → VelaClaw（2026-05-13 ✅ 已全部完成）

主计划：**[ZS-RENAME-001.md](./ZS-RENAME-001.md)**

前置条件：ZS-ML-001~016 全部 completed + 合入 main ✅

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| ZS-RN-001 | [tasks/ZS-RN-001-crate-name-and-code-rename.yaml](./tasks/ZS-RN-001-crate-name-and-code-rename.yaml) | `done` | — | Rust crate 名 zerospider → velaclaw + 全代码+CI；[PR #38](https://github.com/ailib-official/velaclaw/pull/38) (`36b9a5c`) |
| ZS-RN-002 | [tasks/ZS-RN-002-docs-and-firmware-rename.yaml](./tasks/ZS-RN-002-docs-and-firmware-rename.yaml) | `done` | ZS-RN-001 | 文档 + firmware + Docker + scripts 全量更名；与 ZS-RN-001 同 PR 原子合并 |
| ZS-RN-003 | [tasks/ZS-RN-003-repo-rename-and-external-refs.yaml](./tasks/ZS-RN-003-repo-rename-and-external-refs.yaml) | `done` | ZS-RN-001, ZS-RN-002 | GitHub 仓库改名 + 外部引用更新 + 最终审计；`zerospider`→`velaclaw`，plans 引用全更新 |

## Trial Readiness — Provider 集成与核心里程碑（2026-06-09 新增）

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|:----:|:----:|------|
| VL-TRIAL-001 | [tasks/VL-TRIAL-001-trial-readiness.yaml](./tasks/VL-TRIAL-001-trial-readiness.yaml) | `completed` | — | Trial — [PR #50](https://github.com/ailib-official/velaclaw/pull/50) + [ai-protocol #7](https://github.com/ailib-official/ai-protocol/pull/7); DeepSeek smoke ✓ |

## Phase EVO — 执行层演进（2026-06-09，VL-ARCH-001）

主计划：**[VELACLAW_PHASE_EVO_PLAN_2026-06.md](./VELACLAW_PHASE_EVO_PLAN_2026-06.md)**  
架构 ADR：**[VL-ARCH-001-execution-strategy-boundary.md](./VL-ARCH-001-execution-strategy-boundary.md)**

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|:----:|:----:|------|
| VL-EVO-001 | [tasks/VL-EVO-001-execution-handle.yaml](./tasks/VL-EVO-001-execution-handle.yaml) | `completed` | VL-TRIAL-001 | ExecutionHandle；策略/执行边界 → cursor — [PR #58](https://github.com/ailib-official/velaclaw/pull/58) (`e4ddf2a`) |
| VL-EVO-002 | [tasks/VL-EVO-002-embed-prism-router.yaml](./tasks/VL-EVO-002-embed-prism-router.yaml) | `completed` ✅ | VL-EVO-001 | 内嵌 prism-core router — PR #66 `a521ed2` |
| VL-EVO-003 | [tasks/VL-EVO-003-byok-telemetry.yaml](./tasks/VL-EVO-003-byok-telemetry.yaml) | `completed` ✅ | VL-EVO-001 | BYOK 调用记录遥测 — PR #65 `d5edb5d` |
| VL-EVO-004 | [tasks/VL-EVO-004-adapter-retirement.yaml](./tasks/VL-EVO-004-adapter-retirement.yaml) | `completed` ✅ | VL-EVO-001, 002 | ProtocolBackedProvider 执行逻辑退役 — PR #67 `02ce38c` |

**Prism 侧跟踪**：PR-P1-016 已修订为内嵌集成（见 `active/projects/prism/docs/VELACLAW_MIGRATION_STAGES.md`）。

## Web Chat UI — 本地控制面 + SPA（2026-06-10 新增，2026-06-11 优化）

主计划：**[VELACLAW_PHASE_UI_PLAN_2026-06.md](./VELACLAW_PHASE_UI_PLAN_2026-06.md)**  
决策记录：**[tasks/VL-UI-001-web-chat-ui-planning.yaml](./tasks/VL-UI-001-web-chat-ui-planning.yaml)**（Path 2 ✅）

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|:----:|:----:|------|
| VL-UI-001 | [tasks/VL-UI-001-web-chat-ui-planning.yaml](./tasks/VL-UI-001-web-chat-ui-planning.yaml) | `completed` | — | Path 1/2 分析；owner 确认 Path 2（自建前端） |
| VL-UI-002 | [tasks/VL-UI-002-web-chat-phase1.yaml](./tasks/VL-UI-002-web-chat-phase1.yaml) | `completed` | VL-UI-001 | **Phase 1a**：Local Control API — `/api/chat`、`/ws`、`/api/providers`；走 agent loop（VL-ARCH-001）；[PR #55](https://github.com/ailib-official/velaclaw/pull/55) (`7cb2528`) |
| VL-UI-005 | [tasks/VL-UI-005-web-chat-phase1-frontend.yaml](./tasks/VL-UI-005-web-chat-phase1-frontend.yaml) | `completed` | VL-UI-002 | **Phase 1b**：Svelte SPA @ `/chat` + rust-embed — [PR #56](https://github.com/ailib-official/velaclaw/pull/56) (`9ae13f6`) |
| VL-UI-003 | [tasks/VL-UI-003-web-chat-phase2.yaml](./tasks/VL-UI-003-web-chat-phase2.yaml) | `completed` | VL-UI-005 | **Phase 2**：会话持久化 + Memory + Config + onboard 向导 Web 化 — [PR #57](https://github.com/ailib-official/velaclaw/pull/57) (`bc09cb8`) |
| VL-UI-004 | [tasks/VL-UI-004-web-chat-phase3.yaml](./tasks/VL-UI-004-web-chat-phase3.yaml) | `completed` | VL-UI-003 | **Phase 3**：Cron + Tools + Tool Approval — [PR #63](https://github.com/ailib-official/velaclaw/pull/63) (`e5b61d9`) ✅ |

**与 EVO 并行**：VL-UI-002 可与 VL-EVO-001 并行；chat handler 在 ExecutionHandle 合入后切换实现，WS 合同不变。
