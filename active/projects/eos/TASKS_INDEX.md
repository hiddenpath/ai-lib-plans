# Eos（逸思）— To C AI 服务平台任务索引

> 对应项目根 `active/projects/eos/`

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| EOS-P0-001 | [tasks/EOS-P0-001-prelaunch-hardening.yaml](./tasks/EOS-P0-001-prelaunch-hardening.yaml) | `pending` | 公网/生产部署前 | **上线闸门**：R1–R6、R8–R9 已完成；**R7**（prism-core panic 审计）仍为 go-live 前建议项 |
| EOS-P1-001 | [tasks/EOS-P1-001-minimal-chat-platform.yaml](./tasks/EOS-P1-001-minimal-chat-platform.yaml) | `completed` | — | Phase 1 最小闭环已交付（含 D4 E2E + CI） |
| EOS-P2-001 | [tasks/EOS-P2-001-context-strategy-browser.yaml](./tasks/EOS-P2-001-context-strategy-browser.yaml) | `pending` | PT-075、ALR-P2-001 | Phase 2 预备：**浏览器 SKU** 上下文镜像 + artifact + 确定性组装接上 WASM `build_request`（见 CONTEXT_STRATEGY_BOUNDARY.md） |
| EOS-DPL-001 | [EOS_DEPLOY_PLAN.md](./EOS_DEPLOY_PLAN.md) | `ready` | 香港云服务器就绪 | 部署实施计划（5 块分片），2026-05-11 先生确认上线策略 |
| EOS-ARCH-001 | [tasks/EOS-ARCH-001-compliance-regional-routing.yaml](./tasks/EOS-ARCH-001-compliance-regional-routing.yaml) | `completed` | — | **区域合规路由架构决策**：选定双入口隔离方案（zh-cn/global），manifest region 字段，E/P 层职责切割 |

## 上线前专项（Pre-launch）

与功能清单分离、**面向公网部署前必须验收**的事项已全部落入 **EOS-P0-001**，避免与 Phase 1 开发任务混排后遗漏。

## 里程碑

| 里程碑 | 时间 | 状态 |
|--------|------|:----:|
| M1: Chat Works（聊天+流式+多模型） | Week 1 末 | ✅ |
| M2: Feature Complete（功能面板完整） | Week 2 末 | ✅ |
| M3: Live（eos.ailib.info 上线） | Week 3 末 | ⏳ DNS/TLS 已就绪；**EOS-P0-R7** 审计与生产密钥轮换为剩余闸门 |

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
