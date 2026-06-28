# Eos（逸思）— To C AI 服务平台

> **Type**: Consumer web platform (to-C, browser-accessible)
> **Status**: Phase 1 **completed**；**已 go-live** — `https://eos.ailib.info`（2026-05-27，hiddenpath/eos PR #2）；post-go-live 建议项：**EOS-P0-R7** panic 审计、生产镜像追平 `main`、密钥轮换
> **Repo**: `hiddenpath/eos`（私有产品仓；公开镜像策略见治理文档 GOV-001）
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
- **Phase 2** (TBD): User registration + cloud history sync + free tier — **并行工程预备**：浏览器侧会话镜像与确定性上下文组装见 `CONTEXT_STRATEGY_BOUNDARY.md`、任务 **EOS-P2-001**；上游 **`PT-075` → `ALR-P2-001`**（见根 `MEMORY.md` 2026-05-22）。**文档上传**：`EOS-P2-006-R1` 为权宜 `pdf_extract`；终态见 **`active/document-capability-routing.md`** → **EOS-P2-007**。
- **Phase 3** (TBD): Subscription + smart recommendation + China payments

## Dependencies

- Phase 1: Prism API live (or mock); Provider API keys
- Phase 1: `eos.ailib.info` domain configured

## Toolchain (Rust / Docker)

- 仓库 **[workspace.package] `rust-version`** 与 **`Dockerfile` 内 Rust builder 镜像**（如 `rust:1.86-slim`）必须对齐；依赖升级拉高 MSRV 时同步 bump，不要等到仅 Docker CI 报错再修 — 参见根 `MEMORY.md`「Rust toolchain / MSRV alignment (2026-05-14)」。

## Pre-launch (go-live gate)

- 上线前加固与验收见任务索引中的 **EOS-P0-001**（`tasks/EOS-P0-001-prelaunch-hardening.yaml`），与 **EOS-P1-001** 功能开发并列跟踪。
