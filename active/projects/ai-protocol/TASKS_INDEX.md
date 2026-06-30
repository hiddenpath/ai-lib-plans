# AI-Protocol — PT-073 v1.0 就绪门控任务索引

> Spider 扫描真源：本文件 + `tasks/PT-073*.yaml`。多仓库 PR 链在 **PR 列** 逐项列出 merge commit。
>
> **2026-06-29 说明：** PT-073f-R3 四 PR 由 Cursor 按序合并（#17 先于 runtime #3/#6/#7）；Spider 定时扫描仅见 **open** PR，已合并项需靠本索引回填。

| ID | 文件 | 状态 | PR / merge | 说明 |
|----|------|------|------------|------|
| PT-073 | [tasks/PT-073-core-compliance-proof-v1-rc.yaml](./tasks/PT-073-core-compliance-proof-v1-rc.yaml) | `in_progress` | §1–§5 ✅；§6 待 maintainer | v1.0.0 就绪证明（非自动发版） |
| PT-073a | [tasks/PT-073a-python-full-compliance-ci.yaml](./tasks/PT-073a-python-full-compliance-ci.yaml) | `completed` | [ai-lib-python #4](https://github.com/ailib-official/ai-lib-python/pull/4) `b30b831` | §1 Python full matrix |
| PT-073b | [tasks/PT-073b-typescript-full-compliance-ci.yaml](./tasks/PT-073b-typescript-full-compliance-ci.yaml) | `completed` | [ai-lib-ts #4](https://github.com/ailib-official/ai-lib-ts/pull/4) `324e67a` | §1 TS full matrix |
| PT-073c | [tasks/PT-073c-go-rust-compliance-evidence.yaml](./tasks/PT-073c-go-rust-compliance-evidence.yaml) | `completed` | [ai-lib-go #2](https://github.com/ailib-official/ai-lib-go/pull/2) `334ac74` | §1 Go + Rust §1 证据 |
| PT-073d | [tasks/PT-073d-migration-changelog.yaml](./tasks/PT-073d-migration-changelog.yaml) | `completed` | py [#5](https://github.com/ailib-official/ai-lib-python/pull/5) `f0fa875`; ts [#5](https://github.com/ailib-official/ai-lib-ts/pull/5) `0df05ee`; protocol [#15](https://github.com/ailib-official/ai-protocol/pull/15) `4db1f0b` | §4 CHANGELOG |
| PT-073e | [tasks/PT-073e-governance-gates-evidence.yaml](./tasks/PT-073e-governance-gates-evidence.yaml) | `completed` | [ai-protocol #15](https://github.com/ailib-official/ai-protocol/pull/15) `4db1f0b` | §5 drift/fullchain/rollback |
| PT-073f | [tasks/PT-073f-ep-separation-evidence.yaml](./tasks/PT-073f-ep-separation-evidence.yaml) | `completed` | 见下表 **PT-073f PR 链** | §3 E/P + ExecutionMetadata + contact |
| PT-073g | [tasks/PT-073g-cross-repo-quality-audit.yaml](./tasks/PT-073g-cross-repo-quality-audit.yaml) | `in_progress` | R6 remediation | §6 前 **质量审查**；R2–R5 ✅，R6 修复中 |
| PT-073h | [tasks/PT-073h-compliance-integrity-and-docs.yaml](./tasks/PT-073h-compliance-integrity-and-docs.yaml) | `in_progress` | [#18](https://github.com/ailib-official/ai-protocol/pull/18) `9c9613d` | PT-073g R1–R3 已合并；R4/R5 待办 |

## PT-073f PR 链（合并顺序）

| 序 | 仓库 | PR | merge commit | 合并时间 (UTC) |
|----|------|-----|--------------|----------------|
| 1 | ai-protocol | [#16](https://github.com/ailib-official/ai-protocol/pull/16) | `c805203` | 2026-06-29 — `--ts-root` EP 检查 |
| 2 | ai-lib-ts | [#6](https://github.com/ailib-official/ai-lib-ts/pull/6) | `955f795` | 2026-06-29 — TS pt073 EP CI |
| 3 | ai-protocol | [#17](https://github.com/ailib-official/ai-protocol/pull/17) | `65857ef` | 2026-06-29 — `--go-root` + metadata 样本 |
| 4 | ai-lib-go | [#3](https://github.com/ailib-official/ai-lib-go/pull/3) | `2cf42c6` | 2026-06-29T16:44:12Z |
| 5 | ai-lib-python | [#6](https://github.com/ailib-official/ai-lib-python/pull/6) | `c3f4d53` | 2026-06-29T16:44:17Z |
| 6 | ai-lib-ts | [#7](https://github.com/ailib-official/ai-lib-ts/pull/7) | `aa3f5fa` | 2026-06-29T16:44:22Z |

## 相关文档

- [PT-073-GAP-AUDIT_2026-06.md](./PT-073-GAP-AUDIT_2026-06.md)
- [QUALITY_AUDIT_PLAN_2026-06.md](./QUALITY_AUDIT_PLAN_2026-06.md)
- [templates/QUALITY_AUDIT_REPORT_TEMPLATE.md](./templates/QUALITY_AUDIT_REPORT_TEMPLATE.md)
- [PT-073g-SYNC_BASELINE.md](./PT-073g-SYNC_BASELINE.md) — 多端 commit 基线 + 同步脚本
- [PT-073g-CONFLICT-RUNBOOK.md](./PT-073g-CONFLICT-RUNBOOK.md) — GOV-002 冲突处理
- [docs/WAVE5_V1_GATE_CHECKLIST.md](https://github.com/ailib-official/ai-protocol/blob/main/docs/WAVE5_V1_GATE_CHECKLIST.md)（在 ai-protocol 仓库）
- [WAVE5_EP_SEPARATION_AND_V1_PLAN_2026-04-01.md](./WAVE5_EP_SEPARATION_AND_V1_PLAN_2026-04-01.md)
