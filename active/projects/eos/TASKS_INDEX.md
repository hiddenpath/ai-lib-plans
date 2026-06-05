# Eos（逸思）— To C AI 服务平台任务索引

> 对应项目根 `active/projects/eos/`  
> **修订**: 2026-06-04 — 补齐 Phase 2 产品任务清单 + Prism 协调

## Phase 1 & 预备（已完成）

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| EOS-P0-001 | [tasks/EOS-P0-001-prelaunch-hardening.yaml](./tasks/EOS-P0-001-prelaunch-hardening.yaml) | `completed` | — | 上线闸门 R1–R9 全部完成（R7 于 PR #3 关闭）；密钥轮换为运营跟进 |
| EOS-P1-001 | [tasks/EOS-P1-001-minimal-chat-platform.yaml](./tasks/EOS-P1-001-minimal-chat-platform.yaml) | `completed` | — | Phase 1 + PR #3 capacity；见 [TRANSFER_COMBO_EVAL.md](./TRANSFER_COMBO_EVAL.md) |
| EOS-P2-001 | [tasks/EOS-P2-001-context-strategy-browser.yaml](./tasks/EOS-P2-001-context-strategy-browser.yaml) | `completed` | PT-075、ALR-P2-001 | 上下文工程 prep；milestone **eos-phase2-context** ✅ |
| EOS-DPL-001 | [EOS_DEPLOY_PLAN.md](./EOS_DEPLOY_PLAN.md) | `completed` | — | 香港 VPS + Caddy TLS + `deploy_eos.sh`；生产 `https://eos.ailib.info` |
| EOS-ARCH-001 | [tasks/EOS-ARCH-001-compliance-regional-routing.yaml](./tasks/EOS-ARCH-001-compliance-regional-routing.yaml) | `completed` | — | 区域合规 R1–R5 ✅ |

## Phase 2 — 产品化（进行中 / 待启动）

| ID | 文件 | 状态 | 依赖 | Prism 协调 |
|----|------|------|------|------------|
| EOS-CI-001 | [tasks/EOS-CI-001-ci-debt-cleanup.yaml](./tasks/EOS-CI-001-ci-debt-cleanup.yaml) | `open` | — | 与 Prism P1 并行，独立 |
| EOS-P2-002 | [tasks/EOS-P2-002-user-identity-auth.yaml](./tasks/EOS-P2-002-user-identity-auth.yaml) | `completed` | EOS-CI-001（建议） | PR [#11](https://github.com/hiddenpath/eos/pull/11) merged `8a59be8`；lan/main 已同步 |
| EOS-P2-003 | [tasks/EOS-P2-003-cloud-history-sync.yaml](./tasks/EOS-P2-003-cloud-history-sync.yaml) | `open` | EOS-P2-002, EOS-P2-001 | 零知识 blob；协议可对齐 Vela |
| EOS-P2-004 | [tasks/EOS-P2-004-free-tier-quota.yaml](./tasks/EOS-P2-004-free-tier-quota.yaml) | `open` | EOS-P2-002, **PR-P1-011** ✅ | **PR-P1-014** 可选 |
| EOS-P2-005 | [tasks/EOS-P2-005-prism-integration.yaml](./tasks/EOS-P2-005-prism-integration.yaml) | `open` | **PR-P1-002**, **PR-P1-008** | 生产门控 **P1-C**；不改现网 `/api/proxy` |
| EOS-P2-006 | [tasks/EOS-P2-006-feature-enhancements.yaml](./tasks/EOS-P2-006-feature-enhancements.yaml) | `open` | — | 可并行；Anthropic 可复用 PR-P1-010 ✅ |

## Phase 2.5 — 上下文进阶（planned）

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| EOS-CX-001 | [tasks/EOS-CX-001-context-layering.yaml](./tasks/EOS-CX-001-context-layering.yaml) | `planned` | EOS-P2-001 | 消息 Priority 分层；见 [CONTEXT_ARCHITECTURE_V2.md](./CONTEXT_ARCHITECTURE_V2.md) |
| EOS-CX-002 | [tasks/EOS-CX-002-external-docs.yaml](./tasks/EOS-CX-002-external-docs.yaml) | `planned` | EOS-CX-001 | 外部文档化与跨会话召回 |

## 上线前专项（Pre-launch）

与功能清单分离、**面向公网部署前必须验收**的事项已全部落入 **EOS-P0-001**，避免与 Phase 1 开发任务混排后遗漏。

## 里程碑

| 里程碑 | 时间 | 状态 |
|--------|------|:----:|
| M1: Chat Works（聊天+流式+多模型） | Week 1 末 | ✅ |
| M2: Feature Complete（功能面板完整） | Week 2 末 | ✅ |
| M3: Live（eos.ailib.info 上线） | Week 3 末 | ✅ |
| M4: Regional compliance（EOS-ARCH） | 2026-06-02 | ✅ |
| M5: Context layering & external doc（CX-001/002） | Phase 2.5 | 📋 planned |
| **M6: Accounts**（EOS-P2-002） | Phase 2 Wave 1 | ✅ |
| **M7: Sync**（EOS-P2-003） | Phase 2 Wave 2 | ⏳ |
| **M8: Free tier**（EOS-P2-004） | Phase 2 Wave 2 | ⏳ |
| **M9: Prism-ready**（EOS-P2-005 ADR+POC） | 门控 Prism P1-B | ⏳ |
| **M10: Feature+**（EOS-P2-006） | Phase 2 并行 | ⏳ |

## Prism 协调摘要

详见 [NEAR_TERM_EXECUTION_2026-06-P2.md](./NEAR_TERM_EXECUTION_2026-06-P2.md) 与 [../prism/NEAR_TERM_EXECUTION_2026-06-P1.md](../prism/NEAR_TERM_EXECUTION_2026-06-P1.md)。

| 原则 | 说明 |
|------|------|
| P1 不改 Eos proxy | Prism 交付物不包含修改 `eos.ailib.info` `/api/proxy` |
| 库层复用 | 配额/usage 用 `prism-core`（PR-P1-011 ✅） |
| 集成门控 | EOS-P2-005 生产联调等 Prism P1-C |
| 需求槽位 | EOS-REQ-P2-001/002/003 见 P2 排期文档 |

## 依赖

- 香港云服务器（免备案）
- OpenAI + DeepSeek API Key
- Tavily Web Search 账号（免费）
- Phase 2 用户系统：DB（SQLite/Postgres 待 ADR）

## 相关文档

- `PHASE1_PLAN.md` — Phase 1 详细开发计划
- **`PHASE2_PLAN.md`** — Phase 2 产品化总计划（2026-06-04）
- **`NEAR_TERM_EXECUTION_2026-06-P2.md`** — Phase 2 排期与 Prism 协调
- `EOS_DEPLOY_PLAN.md` — Phase 1 部署计划（completed）
- `project-overview.md` — 项目总览
- `brand-rationale.md` — 品牌命名决策记录
- `CONTEXT_STRATEGY_BOUNDARY.md` — 上下文策略层边界
- `CONTEXT_ARCHITECTURE_V2.md` — 上下文 2.5 架构
- `TRANSFER_COMBO_EVAL.md` — transfer.md 组合任务评估
- `../prism/TASKS_INDEX.md` — Prism 任务真源
