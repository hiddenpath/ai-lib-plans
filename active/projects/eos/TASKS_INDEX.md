# Eos（逸思）— To C AI 服务平台任务索引

> 对应项目根 `active/projects/eos/`

| ID | 文件 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| EOS-P1-001 | [tasks/EOS-P1-001-minimal-chat-platform.yaml](./tasks/EOS-P1-001-minimal-chat-platform.yaml) | `pending` | Prism API 可用 | Phase 1 最小闭环：聊天 + 多模型 + Web Search + 文件上传 + 图像生成 |

## 里程碑

| 里程碑 | 时间 | 状态 |
|--------|------|:----:|
| M1: Chat Works（聊天+流式+多模型） | Week 1 末 | ⬜ |
| M2: Feature Complete（功能面板完整） | Week 2 末 | ⬜ |
| M3: Live（eos.ailib.info 上线） | Week 3 末 | ⬜ |

## 依赖

- Prism API 上线（或直连 Provider 降级方案）
- 5 个 P0 Provider 可用：OpenAI / Anthropic / Gemini / DeepSeek / Qwen
- `eos.ailib.info` 域名配置

## 相关文档

- `PHASE1_PLAN.md` — Phase 1 详细开发计划
- `project-overview.md` — 项目总览
- `brand-rationale.md` — 品牌命名决策记录
