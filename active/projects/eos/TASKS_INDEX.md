# Eos（逸思）— To C AI 服务平台任务索引

> 对应项目根 `active/projects/eos/`

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| EOS-P0-001 | [tasks/EOS-P0-001-prelaunch-hardening.yaml](./tasks/EOS-P0-001-prelaunch-hardening.yaml) | `completed` | — | 上线闸门 R1–R9 全部完成（R7 于 PR #3 关闭）；密钥轮换为运营跟进 |
| EOS-P1-001 | [tasks/EOS-P1-001-minimal-chat-platform.yaml](./tasks/EOS-P1-001-minimal-chat-platform.yaml) | `completed` | — | Phase 1 + PR #3 capacity；见 [TRANSFER_COMBO_EVAL.md](./TRANSFER_COMBO_EVAL.md) |
| EOS-P2-001 | [tasks/EOS-P2-001-context-strategy-browser.yaml](./tasks/EOS-P2-001-context-strategy-browser.yaml) | `completed` | PT-075、ALR-P2-001 | R1–R4 ✅ PR #4–#7；milestone **eos-phase2-context** done |
| EOS-P2-003 | [tasks/EOS-P2-003-e2e-cloud-sync.yaml](./tasks/EOS-P2-003-e2e-cloud-sync.yaml) | `completed` | — | ✅ R1–R3 PR #12 (5e805b5) — BIZ-004 E2E sync (ciphertext blobs only) |
| EOS-P2-005 | [tasks/EOS-P2-005-prism-integration.yaml](./tasks/EOS-P2-005-prism-integration.yaml) | `completed` ✅ | Prism P1-C ✅ | #19 `703a942` + #20 `3b1fd1c`；G0–G3 ops 门控 owner |
| EOS-P2-006 | [tasks/EOS-P2-006-feature-enhancements.yaml](./tasks/EOS-P2-006-feature-enhancements.yaml) | `open` | — | **Next** — PDF/多图/Anthropic/WASM fallback |
| EOS-DPL-001 | [EOS_DEPLOY_PLAN.md](./EOS_DEPLOY_PLAN.md) | `completed` | — | 香港 VPS + Caddy TLS + `deploy_eos.sh`；生产 `https://eos.ailib.info` 已确认 `main@299575a`（2026-05-28） |
| EOS-ARCH-001 | [tasks/EOS-ARCH-001-compliance-regional-routing.yaml](./tasks/EOS-ARCH-001-compliance-regional-routing.yaml) | `completed` | — | ✅ R1–R5 all completed: R3 ⏺ eos PR #9 (6a39ef4), R4 ⏺ eos PR #8 (19544d2), R5 ⏺ plans PR #6 (cc0f551) |
| EOS-CI-001 | [tasks/EOS-CI-001-ci-debt-cleanup.yaml](./tasks/EOS-CI-001-ci-debt-cleanup.yaml) | `completed` | — | #13 closed; fmt ee57a25 + compliance CI step |
| EOS-CX-001 | — | `planned` | EOS-P2-001 | **消息动态分层结构化** — Priority 标注、按层级裁剪组装、Layer 0–5 模型；详见 [CONTEXT_ARCHITECTURE_V2.md](./CONTEXT_ARCHITECTURE_V2.md) §3, §6 |
| EOS-CX-002 | — | `planned` | EOS-CX-001 | **外部文档化 & 对话归档** — 摘要文档生成、索引存储、检索召回、跨会话上下文继承；详见 [CONTEXT_ARCHITECTURE_V2.md](./CONTEXT_ARCHITECTURE_V2.md) §4, §6 |

## 上线前专项（Pre-launch）

与功能清单分离、**面向公网部署前必须验收**的事项已全部落入 **EOS-P0-001**，避免与 Phase 1 开发任务混排后遗漏。

## 里程碑

| 里程碑 | 时间 | 状态 |
|--------|------|:----:|
| M1: Chat Works（聊天+流式+多模型） | Week 1 末 | ✅ |
| M2: Feature Complete（功能面板完整） | Week 2 末 | ✅ |
| M3: Live（eos.ailib.info 上线） | Week 3 末 | ✅ 已上线；Phase 2 context milestone ✅ (PR #4–#7) |
| M4: Regional compliance（EOS-ARCH R1–R5） | 2026-06-02 | ✅ eos #8–#9 + plans #6 |
| M7: Sync（EOS-P2-003 E2E 密文） | Phase 2 Wave 2a | ✅ PR #12 (5e805b5) |
| M9: Prism-ready（EOS-P2-005 ADR + POC） | Phase 2 Wave 3 | ✅ #19 `703a942` + #20 `3b1fd1c` |
| M5: Context layering & external doc（EOS-CX-001/002） | Phase 2+ | ⏳ 远期架构规划中 |

## 依赖

- 香港云服务器（免备案）
- OpenAI + DeepSeek API Key
- Tavily Web Search 账号（免费）

## 相关文档

- `PHASE1_PLAN.md` — Phase 1 详细开发计划
- `EOS_DEPLOY_PLAN.md` — 部署与功能上线计划（v1.0, 2026-05-11）
- `project-overview.md` — 项目总览
- `brand-rationale.md` — 品牌命名决策记录
- `CONTEXT_STRATEGY_BOUNDARY.md` — 上下文策略层与浏览器 SKU 边界（2026-05-22）
- `CONTEXT_ARCHITECTURE_V2.md` — 上下文架构 Phase 2+：动态分层结构化 & 外部文档化（2026-06-02）
- `TRANSFER_COMBO_EVAL.md` — transfer.md 组合任务评估与 PR 切片（2026-05-29）
- `docs/EOS-P2-005-PRISM_INTEGRATION_ADR.md` — Prism 集成 ADR（R1 ✅）
- `docs/EOS-P2-005-POC-RUNBOOK.md` — R2 本地/CI POC 步骤
- `docs/EOS-P2-005-R3-PRODUCTION-RUNBOOK.md` — R3 生产灰度（门控）
- `docs/EOS-P2-005-R4-SMART-ROUTING-PLACEHOLDER.md` — R4 智能路由占位 ✅
