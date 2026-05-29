# Eos（逸思）— To C AI 服务平台任务索引

> 对应项目根 `active/projects/eos/`

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| EOS-P0-001 | [tasks/EOS-P0-001-prelaunch-hardening.yaml](./tasks/EOS-P0-001-prelaunch-hardening.yaml) | `completed` | — | **上线闸门**：全部 R1–R9 已完成。PR #3 (1271ef0f) 关闭 R7（panic audit），R5(E2E) 前期已关闭 |
| EOS-P1-001 | [tasks/EOS-P1-001-minimal-chat-platform.yaml](./tasks/EOS-P1-001-minimal-chat-platform.yaml) | `completed` | — | Phase 1 最小闭环已交付；2026-05-17~28 追加 PR #1 Gemini、PR #2 NVIDIA/流式修复与 post-merge E2E |
| EOS-P2-001 | [tasks/EOS-P2-001-context-strategy-browser.yaml](./tasks/EOS-P2-001-context-strategy-browser.yaml) | `pending` | PT-075、ALR-P2-001 | Phase 2 预备：**浏览器 SKU** 上下文镜像 + artifact + 确定性组装接上 WASM `build_request`（见 CONTEXT_STRATEGY_BOUNDARY.md）；**R3 `/api/models` capacity 字段已完成**（PR #3 2026-05-29）；R1 已落地 spec |
| EOS-DPL-001 | [EOS_DEPLOY_PLAN.md](./EOS_DEPLOY_PLAN.md) | `completed` | — | 香港 VPS + Caddy TLS + `deploy_eos.sh`；生产 `https://eos.ailib.info` 已确认 `main@299575a`（2026-05-28） |
| EOS-ARCH-001 | [tasks/EOS-ARCH-001-compliance-regional-routing.yaml](./tasks/EOS-ARCH-001-compliance-regional-routing.yaml) | `completed` | — | **决策记录已完成**（方案 B）；执行块 R2–R5 仍 pending，见任务 YAML |

## 上线前专项（Pre-launch）

与功能清单分离、**面向公网部署前必须验收**的事项已全部落入 **EOS-P0-001**，避免与 Phase 1 开发任务混排后遗漏。

## 里程碑

| 里程碑 | 时间 | 状态 |
|--------|------|:----:|
| M1: Chat Works（聊天+流式+多模型） | Week 1 末 | ✅ |
| M2: Feature Complete（功能面板完整） | Week 2 末 | ✅ |
| M3: Live（eos.ailib.info 上线） | Week 3 末 | ✅ 已上线；生产已确认 `main@299575a`（alex，2026-05-28）；**EOS-P0-R7**、密钥轮换仍为跟进项 |

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
