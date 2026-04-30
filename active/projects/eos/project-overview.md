# Eos（逸思）— To C AI 服务平台

> **Type**: Consumer web platform (to-C, browser-accessible)
> **Status**: Phase 1 planning
> **Repo**: `ailib-official/eos` (to be created, forked from `ailib-official/ailib-wasm-test`)
> **Architecture**: WASM (wasm-bindgen) + Axum backend proxy + static frontend (forked from ailib-wasm-test)
> **Brand File**: `active/projects/eos/brand-rationale.md`
> **Phase 1 Plan**: `active/projects/eos/PHASE1_PLAN.md`

## Product Matrix Position

| | To B | To C |
|---|---|---|
| **Prism** | ① Prism Enterprise | ② Prism (developer API) |
| **Vela** | ③ Vela Pro | ④ Vela (client-side app) |
| **Eos**  | — | **⑤ Eos（逸思）** — 独立的 To C 消费者网站，浏览即用 |

## Key Decisions (Confirmed 2026-04-30)

- **E1**: Eos 为独立 To C 品牌，与 Vela 客户端侧定位区分
- **E2**: Phase 1 聚焦最小闭环：聊天 + 多模型 + 功能面板，不做用户系统
- **E3**: 技术栈优先 HTMX + Alpine.js（最小前端依赖）
- **E4**: 域名 `eos.ailib.info`，与 Prism 同子域名策略

## Architecture

```
User Browser (WASM executes build_chat_request)
    ↓ (HTTPS)
Eos Backend Proxy (Axum, forked from ailib-wasm-test crates/server)
    ├── /api/proxy         (non-streaming)
    ├── /api/proxy/stream  (SSE streaming)
    ├── /api/models        (model list)
    ├── /api/web-search    (search integration)
    ├── /api/upload        (file upload)
    ├── /api/images/generations (image generation)
    ├── /health
    └── / → static files (Eos UI)
         │
         ▼ (libcurl)
Provider APIs (OpenAI / DeepSeek / Anthropic / Groq / NVIDIA / ...)
```

## Three-Zone Alignment

| Component | Band | License |
|-----------|------|---------|
| Eos frontend | A | Apache-2.0 |
| Eos backend proxy | A | Apache-2.0 |
| Eos integration tests | A | Apache-2.0 |

## Phase Roadmap

- **Phase 1** (3 weeks): Minimal viable platform (chat + multi-model + Web Search + file/image)
- **Phase 2** (TBD): User registration + cloud history sync + free tier
- **Phase 3** (TBD): Subscription + smart recommendation + China payments

## Dependencies

- Phase 1: Prism API live (or mock); Provider API keys
- Phase 1: `eos.ailib.info` domain configured
