# VelaClaw → Prism 迁移阶段（PR-P1-016）

> **范围**: 消费者从直连 provider 迁到 prism-core / Prism Gateway HTTP。  
> **不变**: 不改 Eos `/api/proxy`；香港 Eos 机 ≠ Prism 生产。

## 阶段与 feature 映射

| 阶段 | 能力 | prism-core feature | HTTP 面 | 验收 |
|------|------|-------------------|---------|------|
| **0** 现状 | Vela 直连 provider SDK/HTTP | — | — | 基线 |
| **1** Proxy | OpenAI `/v1/chat/completions` 经 Gateway | default + proxy | `ai-lib-gateway` | smoke 脚本 3 家 + 手动 curl |
| **2** Key pool | 多 key 轮转、429 冷却 | `key-pool` | `/admin/keys` | admin 列表 + 429 场景 |
| **3** Router | fallback + health | `router` | `/admin/health` | 主备切换脚本 |
| **4** Full | auth + usage + quota | `full` | `/admin/*` + usage | 用量入库、配额拒绝 |

## Stage 1 集成要点（当前目标）

- **Endpoint**: `PRISM_API_BASE`（本地 `http://127.0.0.1:8080`，生产 `https://api.prism.ailib.info` — P1-C）
- **Auth**: `Authorization: Bearer $PRISM_GATEWAY_API_KEY`
- **Wire format**: OpenAI-compatible JSON + SSE（与 PR-P1-002 一致）
- **BYOK**: provider key 仍在 Gateway 侧 env/TOML，Vela 不持有 provider secret

## 阻塞与依赖

| 项 | 状态 |
|----|------|
| P1-B Gateway `/v1/*` | ✅ merged |
| P1-B smoke 脚本 | ✅ PR #4 |
| Anthropic/Qwen gateway 接线 | ⏳ planned |
| P1-C 生产 DNS/TLS | ⏳ 邮件 checklist |

## Owner sign-off（Stage 1）

- [ ] Vela 配置项 `PRISM_API_BASE` + gateway bearer documented
- [ ] 本地：`cargo run` gateway + smoke 绿
- [ ] 生产：P1-C 后外网 curl `/health`
