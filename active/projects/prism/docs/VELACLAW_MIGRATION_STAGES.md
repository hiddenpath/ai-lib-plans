# VelaClaw × Prism 集成阶段（PR-P1-016 修订）

> **2026-06-09 修订（VL-ARCH-001）**：VelaClaw **内嵌 prism-core**，**不**默认 HTTP 调 `ai-lib-gateway`。  
> **真源**：`active/projects/velaclaw/VL-ARCH-001-execution-strategy-boundary.md`  
> **不变**：不改 Eos `/api/proxy`；香港 Eos 机 ≠ Prism 生产。

---

## 两种消费方式（勿混淆）

| 消费者 | 集成方式 | 用途 |
|--------|----------|------|
| **VelaClaw** | `prism-core` **Cargo 依赖**（进程内） | 桌面 agent；BYOK 直连 + 陌生 provider 路由 |
| **外部客户端 / ToB** | `ai-lib-gateway` **HTTP** OpenAI `/v1/*` | Prism 产品 API；与 VelaClaw 并行，非 Vela 主路径 |

---

## VelaClaw 演进阶段（EVO）

与 `VELACLAW_PHASE_EVO_PLAN_2026-06.md` 对齐：

| 阶段 | 能力 | prism-core feature | VelaClaw 任务 | 验收 |
|------|------|-------------------|---------------|------|
| **EVO-0** | BYOK 直连 ai-lib-rust | — | VL-TRIAL-001 ✅ | `velaclaw agent` + curl |
| **EVO-1** | ExecutionHandle 统一执行入口 | — | VL-EVO-001 | BYOK 无 adapter 重复逻辑 |
| **EVO-2** | 陌生 provider 内嵌路由 | `router` (+ `key-pool`) | VL-EVO-002 | prism 分流 smoke |
| **EVO-3** | BYOK 调用记录遥测 | `usage-tracking` | VL-EVO-003 | mock endpoint 收到 record |
| **EVO-4** | Adapter 退役 | — | VL-EVO-004 | 无 execution 逻辑在 adapter |

---

## provider 分流（VL-ARCH-001 §4）

| 场景 | 执行 | 密钥 |
|------|------|------|
| 已知 provider + BYOK key | `AiClient` 直连 | 本机 |
| 陌生 / `routing=prism` | 内嵌 `prism-core` router | Prism 路由面（C-band） |
| BYOK 成功调用 | 可选 usage 遥测 | **不上传 key** |

---

## ~~废止~~ 旧 Stage 1–4（HTTP Gateway 作为 Vela 主路径）

以下表述 **仅适用于 Prism Gateway HTTP 产品**，**不再**作为 VelaClaw 迁移目标：

| 旧阶段 | 原意 | VelaClaw 状态 |
|--------|------|---------------|
| Stage 1 Proxy | HTTP → `ai-lib-gateway` | **废止**（Vela 主路径） |
| Stage 2 Key pool | Gateway admin keys | Gateway 产品任务；Vela BYOK 用本机多 key（可选 EVO+） |
| Stage 3 Router | Gateway `/admin/health` | 内嵌 router（EVO-2） |
| Stage 4 Full | Gateway quota/auth | 遥测 + Prism 服务端（EVO-3 + Prism P1） |

Gateway HTTP 验收仍由 **PR-P1-002 / PR-P1-008** 等产品任务跟踪。

---

## 阻塞与依赖

| 项 | 状态 |
|----|------|
| VL-TRIAL-001 BYOK 直连 | ✅ 代码合入；Linux smoke 见 `TRIAL_READINESS_SMOKE.md` |
| prism-core router/usage API 稳定 | eos workspace / PR-P1-012 crates.io |
| VL-EVO-001 ExecutionHandle | ⏳ draft |
| ai-lib-gateway HTTP（外部 API） | ✅ P1-B merged（与 Vela 内嵌无关） |

---

## PR-P1-016 Owner sign-off（修订）

- [x] 迁移阶段文档按 VL-ARCH-001 修订
- [ ] VL-EVO-001 ExecutionHandle 合入 velaclaw main
- [ ] VL-EVO-002 内嵌 router smoke
- [ ] 公开仓无内网/plans 引用（DOC-002）；PR #51 合并
