# VL-ARCH-001 — VelaClaw 策略层 / 执行层边界（2026-06-09）

> **状态**：已采纳（产品决策）  
> **取代**：PR-P1-016 / `VELACLAW_MIGRATION_STAGES.md` 中「VelaClaw 默认 HTTP 调 Gateway」的表述  
> **关联**：MEMORY.md §2026-06-09；`VELACLAW_PHASE_EVO_PLAN_2026-06.md`；BIZ-002 A/C-band

---

## 1. 决策摘要

| # | 决策 | 说明 |
|---|------|------|
| D1 | **Rust-only 产品** | VelaClaw 永远是 Rust 桌面/CLI agent 产品，不是跨语言 agent SDK |
| D2 | **BYOK 永远直连 provider** | 已知 provider + 用户自有 key → `ai-lib-rust` `AiClient` 直连 API；密钥不出本机 |
| D3 | **prism-core 进程内嵌** | Gateway **核心库**（prism-core A-band）以 **Cargo 依赖** 形式复用到 VelaClaw；**不是**默认 HTTP 客户端调 `ai-lib-gateway` |
| D4 | **陌生 provider 走 Prism 路由** | 未配置 / 未 allowlist / manifest 不可用的 provider → 嵌入式 `prism-core` router（Prism 托管路由面） |
| D5 | **BYOK 只上报调用记录** | BYOK 路径下 Prism 仅收 **usage/audit 遥测**，不托管用户 provider secret |
| D6 | **ai-lib-gateway 独立产品** | Axum HTTP 壳面向 ToB / **Vela Web** 等外部 OpenAI-compatible 客户端；与 VelaClaw 内嵌执行 **并行存在**，非 VelaClaw 主路径 |
| D7 | **Python/TS 不在 VelaClaw 范围** | Py/TS 消费者各自用 `ai-lib-python` / `ai-lib-ts` 构建 agent；**不会**复用 VelaClaw Rust agent，VelaClaw 也不为 Py/TS 暴露 ABI |
| D8 | **adapter 是技术债** | `ProtocolBackedProvider` 仅保留 trait 桥接职责，执行语义归 `AiClient` / 内嵌 prism-core；最终收敛为 `ExecutionHandle` 后删除重复层 |

---

## 2. 分层模型

```
┌─────────────────────────────────────────────────────────┐
│ 策略层 Strategy — VelaClaw                             │
│  session / tools / context shaping / 模型与 fallback 选择 │
└───────────────────────────┬─────────────────────────────┘
                            │ 意图：logical model, messages, tools
                            ▼
┌─────────────────────────────────────────────────────────┐
│ 执行层 Execution — 进程内（无默认 HTTP 跳）              │
│  ┌─────────────────────┐  ┌──────────────────────────┐ │
│  │ AiClient (BYOK 直连) │  │ prism-core 内嵌 (陌生路由) │ │
│  │ ai-lib-rust         │  │ router / key-pool / usage  │ │
│  └──────────┬──────────┘  └────────────┬─────────────┘ │
└─────────────┼──────────────────────────┼───────────────┘
              │                          │
              ▼                          ▼
        Provider API              Prism 路由面 / 托管能力
              │                          │
              └──────────┬───────────────┘
                         ▼
              遥测：UsageRecord → Prism（BYOK 仅计量，无 key）
```

**协议层**（ai-protocol）：manifest、`context_window`、streaming decoder —— 由 ai-lib-rust / prism-core 消费，VelaClaw 策略层不重复解析 wire format。

---

## 3. 与旧规划的差异

| 旧表述（2026-06-04 前） | VL-ARCH-001 后 |
|-------------------------|----------------|
| VelaClaw Stage 1 = HTTP → `ai-lib-gateway` | **废止** 作为 VelaClaw 主路径；Gateway HTTP 仅服务外部客户端 |
| BYOK key 在 Gateway env/TOML | BYOK key **仅在 VelaClaw 本机**；Gateway 不持有 |
| `ProtocolBackedProvider` 长期存在 | 逐步 **瘦身 → ExecutionHandle → 删除** |
| 考虑 Py/TS 复用 Provider trait | **明确不在范围** |

`ai-lib-gateway` 与 `prism-core` 的关系不变：**gateway = HTTP 壳，prism-core = 可嵌入库**。变化的是 VelaClaw 消费方式：嵌入库，非调 HTTP。

---

## 4. provider 分流规则（配置真源）

| 条件 | 执行路径 | 密钥 | 遥测 |
|------|----------|------|------|
| manifest 可用 + 用户已配置 `*_API_KEY` | `AiClient` 直连 | 本机 env / keyring | 可选上报 usage |
| provider 在 allowlist 但无 key | 引导 BYOK 或走 Prism 托管（若用户启用） | — | — |
| 未 allowlist / manifest 缺失 / 显式 `routing=prism` | 内嵌 `prism-core` router | Prism 侧（C-band 策略） | 全量 usage |
| 开发/CI mock | `MOCK_HTTP_URL` / ai-protocol-mock | 测试 | 无 |

具体 config schema 在 `VL-EVO-001` 任务中落地。

---

## 5. 非目标（Non-goals）

- VelaClaw 不做 Python/TS binding 或 FFI agent SDK
- VelaClaw 默认不依赖独立 `ai-lib-gateway` 进程
- 不在公开仓写 maintainer 冒烟清单（DOC-002 → `docs/TRIAL_READINESS_SMOKE.md`）
- 不把 context 压缩算法写入 ai-protocol（见 MEMORY 2026-05-22）

---

## 6. 验收锚点

- **VL-TRIAL-001** ✅：BYOK 直连 smoke（Linux `velaclaw agent`）
- **VL-EVO-001**：`ExecutionHandle` + provider 分流
- **VL-EVO-002**：内嵌 prism-core 陌生 provider 路径
- **VL-EVO-003**：BYOK usage 遥测
- **VL-EVO-004**：adapter 瘦身与删除计划

---

## 8. 产品矩阵与双 BYOK（对照总体规划）

**矩阵位置**：VelaClaw = **Claw 生态 A 层 agent SKU**（`ailib-official/velaclaw`），**不是** Vela 品牌 Web 客户端（`PR-V1-*` → Prism HTTP）。Eos = 浏览器 To C。详见 `VELACLAW_PRODUCT_ALIGNMENT_2026-06.md`。

**两种 BYOK（并存、不混称）**：

| 模式 | 产品 | 密钥 | 执行 |
|------|------|------|------|
| Client-local BYOK | **VelaClaw** | 本机 | AiClient 直连 |
| Gateway-hosted BYOK | **Vela** / HTTP 客户端 | Gateway 配置（Prism Phase 2） | HTTP → Gateway |

**HTTP 例外**：chat 不经 Gateway；**usage 遥测**（EVO-3）可 HTTP 至 Prism endpoint。

**凭证**：BYOK 须走 PT-074 CredentialResolver 链，禁止 VelaClaw 平行 credential 表。

---

## 9. 引用

- `active/projects/velaclaw/VELACLAW_PRODUCT_ALIGNMENT_2026-06.md`
- `active/projects/velaclaw/VELACLAW_PHASE_EVO_PLAN_2026-06.md`
- `active/projects/prism/docs/VELACLAW_MIGRATION_STAGES.md`（已按本 ADR 修订）
- `active/projects/eos/CONTEXT_STRATEGY_BOUNDARY.md`（上下文策略层，与执行层正交）
