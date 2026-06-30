# PT-073g 修复计划（v1.0.0 准入）

<!-- AUDIT_META: dimension=REMEDIATION repo=cross-repo auditor=cursor date=2026-06-30 task=PT-073g status=final -->

> **来源**: [SUMMARY.md](./SUMMARY.md) 裁定 HOLD
> **用途**: 单一分派入口——每个修复任务对应一份 plans task YAML，QA-ID 全程可追溯
> **执行**: 由 maintainer 安排各仓落地；本 cloud agent 仅产出任务与报告（仅访问 `origin`，`lan` 推送需 LAN 节点）

---

## 1. 任务清单（已创建）

| 任务 | 仓库 | 覆盖 QA-ID | 严重度 | 文件 |
|------|------|-----------|--------|------|
| **ALT-QA-001** | ai-lib-ts | ts-001/002/003/004/005/006/007/008/009/012 | **P0×3** + P1×4 + P2×2 | `active/projects/ai-lib-ts/tasks/ALT-QA-001-v1-admission-fixes.yaml` |
| **PT-073h** | ai-protocol | protocol-001…014 | **P0候选×2** + P1×多 + P2×多 | `active/projects/ai-protocol/tasks/PT-073h-compliance-integrity-and-docs.yaml` |
| **GO-011** | ai-lib-go | go-001…013 | **P0候选×1** + P1×3 + P2×多 | `active/projects/ai-lib-go/tasks/GO-011-v1-admission-fixes.yaml` |
| **ALR-QA-001** | ai-lib-rust | rust-001…011 | P1×3 + P2×3 | `active/projects/ai-lib-rust/tasks/ALR-QA-001-v1-admission-fixes.yaml` |
| **ALP-QA-001** | ai-lib-python | python-001…013 | P1×4 + P2×2 | `active/projects/ai-lib-python/tasks/ALP-QA-001-v1-admission-fixes.yaml` |
| **EOS-QA-001** | eos（LAN） | 覆盖缺口补审 | TBD | `active/projects/eos/tasks/EOS-QA-001-d5d6-audit.yaml` |

> 覆盖核对：6 份任务覆盖 SUMMARY 全部 3 P0 + 3 P0候选 + 20 P1 + 16 P2 + eos 缺口。逐 QA-ID 映射见 §4。

---

## 2. 执行批次（建议顺序）

| 批次 | 任务/动作 | 解锁 |
|------|-----------|------|
| **1（解锁复审）** | ALT-QA-001-R1（P0 簇）；maintainer 裁定 PT-073h-R1/R2、GO-011-R1（P0 候选） | PT-073g 复审前置 |
| **2（合规可信度）** | 四运行时 CI pin ref（ALT-R3/ALR-R3/ALP-R3/GO-011-R3）；fixture fail-closed；合规自实现→调用生产代码；PT-073h-R3 | PT-073 §1 论断可信 |
| **3（正确性/安全）** | ALR-R1（传输 panic）；ALP-R2（并发）；GO-011-R1/R2（重试体/流式 usage）；ALT-R2（MOCK_HTTP_URL） | 行为正确 |
| **4（文档/版本/卫生）** | 各仓 CHANGELOG/README/版本；ALP-R5（DOC-002 清理）；ailib.info 版本矩阵；PT-073h-R5 | 对外一致 |
| **5（覆盖缺口）** | EOS-QA-001（LAN 执行 + 双推） | eos 缺口关闭 |
| **6（sign-off）** | MEMORY v1.0 决策记录；maintainer sign-off；PT-073g-R6 关闭 | PT-073 §6 release train |

---

## 3. 治理收口（LAN / maintainer 动作）

| 动作 | 说明 | 责任端 |
|------|------|--------|
| **plans 双推** | 本审查 PR 合并后，plans `main` 须 `git push lan main`（GOV-004 主，本 cloud agent 仅推 origin） | LAN 节点 |
| **eos 补审** | EOS-QA-001 在有 eos 访问权限的 LAN 节点执行 | LAN 节点 |
| **MEMORY 决策记录** | 在 `memory/log.md` + `architecture.md` 写入：v1.0 defer 理由 + PT-073g 裁定 + 3 P0候选定级（QA-memory-001） | maintainer |
| **P0 候选定级** | PT-073h-R1/R2、GO-011-R1 → P0 or P1+defer，写回 SUMMARY §1/§4.1 | maintainer |
| **PT-073g-R6 sign-off** | P0=0 + 候选已裁定 + eos 闭合 + MEMORY 记录后，签核解锁 §6 | maintainer |

---

## 4. QA-ID → 任务映射（可追溯性核对）

| 仓库 | QA-ID | 任务-子项 |
|------|-------|-----------|
| ts | 001,002,003 | ALT-QA-001-R1 |
| ts | 008,009 | ALT-QA-001-R2 |
| ts | 006 | ALT-QA-001-R3 |
| ts | 004,005,007,012 | ALT-QA-001-R4 |
| ts | 010,011 | （P2，见 D3-D4-ai-lib-ts backlog） |
| rust | 001,009 | ALR-QA-001-R1 |
| rust | 003,004,011 | ALR-QA-001-R2 |
| rust | 005 | ALR-QA-001-R3 |
| rust | 002,006,007,008,010,012 | ALR-QA-001-R4 |
| python | 004,005,006 | ALP-QA-001-R1 |
| python | 010 | ALP-QA-001-R2 |
| python | 007 | ALP-QA-001-R3 |
| python | 001,002,003,012,013 | ALP-QA-001-R4 |
| python | 008 | ALP-QA-001-R5 |
| python | 009,011 | ALP-QA-001-R6 |
| go | 006 | GO-011-R1 |
| go | 004 | GO-011-R2 |
| go | 008,009,010 | GO-011-R3 |
| go | 001,002,003,005,007,011,012,013 | GO-011-R4 |
| protocol | 006 | PT-073h-R1 |
| protocol | 005 | PT-073h-R2 |
| protocol | 003,004,010 | PT-073h-R3 |
| protocol | 001,002 | PT-073h-R4 |
| protocol | 007,008,009,011,012,013,014 | PT-073h-R5 |
| cross | velaclaw-001 | （GO 同源外，记 backlog；可随 ai-lib-rust 0.9.6 发版后 bump） |
| cross | ailibinfo-001 | 批次4（ailib.info 版本矩阵，随 sign-off） |
| cross | memory-001 | §3 治理收口（MEMORY 决策记录） |
| eos | （未审） | EOS-QA-001 |

---

## 5. 备注

- 任务 YAML 的 `assignee/executor_name/executor_terminal` 留空，待 maintainer 分派时按
  `task-executor-terminal` 规则回填。
- 所有修复在**各运行时仓**落地；plans 仅承载任务与证据。修复 PR 合并后回 PT-073g-R6 复审。
- 严重度以 SUMMARY 为准；P0 候选以 maintainer 裁定为准。
