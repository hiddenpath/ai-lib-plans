# Eos（逸思）— To C AI 服务平台任务索引

> 对应项目根 `active/projects/eos/`

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| EOS-P0-001 | [tasks/EOS-P0-001-prelaunch-hardening.yaml](./tasks/EOS-P0-001-prelaunch-hardening.yaml) | `completed` | — | 上线闸门 R1–R9 全部完成（R7 于 PR #3 关闭）；密钥轮换为运营跟进 |
| EOS-P1-001 | [tasks/EOS-P1-001-minimal-chat-platform.yaml](./tasks/EOS-P1-001-minimal-chat-platform.yaml) | `completed` | — | Phase 1 + PR #3 capacity；见 [TRANSFER_COMBO_EVAL.md](./TRANSFER_COMBO_EVAL.md) |
| EOS-P2-001 | [tasks/EOS-P2-001-context-strategy-browser.yaml](./tasks/EOS-P2-001-context-strategy-browser.yaml) | `pending` | PT-075、ALR-P2-001 | Phase 2 预备：**浏览器 SKU** 上下文镜像 + artifact + 确定性组装接上 WASM `build_request`（见 CONTEXT_STRATEGY_BOUNDARY.md） |
| EOS-DPL-001 | [EOS_DEPLOY_PLAN.md](./EOS_DEPLOY_PLAN.md) | `completed` | — | 香港 VPS + Caddy TLS + `deploy_eos.sh`；生产 `https://eos.ailib.info` 已确认 `main@299575a`（2026-05-28） |
| EOS-ARCH-001 | [tasks/EOS-ARCH-001-compliance-regional-routing.yaml](./tasks/EOS-ARCH-001-compliance-regional-routing.yaml) | `completed`（决策） | — | R2 **in_progress** — [ai-protocol PR #2](https://github.com/ailib-official/ai-protocol/pull/2) Phase 0–1 |

## 上线前专项（Pre-launch）

与功能清单分离、**面向公网部署前必须验收**的事项已全部落入 **EOS-P0-001**，避免与 Phase 1 开发任务混排后遗漏。

## 里程碑

| 里程碑 | 时间 | 状态 |
|--------|------|:----:|
| M1: Chat Works（聊天+流式+多模型） | Week 1 末 | ✅ |
| M2: Feature Complete（功能面板完整） | Week 2 末 | ✅ |
| M3: Live（eos.ailib.info 上线） | Week 3 末 | ✅ 已上线；PR #3 已合并（capacity + R7）；**EOS-ARCH-R2** 进行中 |

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
- `TRANSFER_COMBO_EVAL.md` — transfer.md 组合任务评估与 PR 切片（2026-05-29）
