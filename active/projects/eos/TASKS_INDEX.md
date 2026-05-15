# Eos（逸思）— To C AI 服务平台任务索引

> 对应项目根 `active/projects/eos/`

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| EOS-P0-001 | [tasks/EOS-P0-001-prelaunch-hardening.yaml](./tasks/EOS-P0-001-prelaunch-hardening.yaml) | `pending` | 公网/生产部署前 | **上线闸门**：R1–R4 已对代码标 completed；剩余 R5–R9（E2E / 许可证与 panic 审计 / endpoint 单一来源 / WASM 说明） |
| EOS-P1-001 | [tasks/EOS-P1-001-minimal-chat-platform.yaml](./tasks/EOS-P1-001-minimal-chat-platform.yaml) | `in_progress` | — | Phase 1 最小闭环：聊天 + 多模型 + Web Search + 文件上传 + 图像生成 |
| EOS-DPL-001 | [EOS_DEPLOY_PLAN.md](./EOS_DEPLOY_PLAN.md) | `ready` | 香港云服务器就绪 | 部署实施计划（5 块分片），2026-05-11 先生确认上线策略 |

## 上线前专项（Pre-launch）

与功能清单分离、**面向公网部署前必须验收**的事项已全部落入 **EOS-P0-001**，避免与 Phase 1 开发任务混排后遗漏。

## 里程碑

| 里程碑 | 时间 | 状态 |
|--------|------|:----:|
| M1: Chat Works（聊天+流式+多模型） | Week 1 末 | ✅ |
| M2: Feature Complete（功能面板完整） | Week 2 末 | ✅ F3–F6 已完成；未决：系统化 E2E（D4 / P0） |
| M3: Live（eos.ailib.info 上线） | Week 3 末 | ⏳ DNS 已就绪；TLS/生产收口与 **EOS-P0-001** 闸门仍为待验收项 |

## 依赖

- 香港云服务器（免备案）
- OpenAI + DeepSeek API Key
- Tavily Web Search 账号（免费）

## 相关文档

- `PHASE1_PLAN.md` — Phase 1 详细开发计划
- `EOS_DEPLOY_PLAN.md` — 部署与功能上线计划（v1.0, 2026-05-11）
- `project-overview.md` — 项目总览
- `brand-rationale.md` — 品牌命名决策记录
