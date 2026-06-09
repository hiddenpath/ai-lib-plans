# VelaClaw Phase EVO — 执行层演进计划（2026-06）

> **前置**：ZS-ML-001~016 ✅、ZS-RN-001~003 ✅、VL-TRIAL-001 ✅（代码合入；Linux smoke 见 `docs/TRIAL_READINESS_SMOKE.md`）  
> **架构真源**：`VL-ARCH-001-execution-strategy-boundary.md`  
> **公开仓**：`ailib-official/velaclaw` — 仅用户向 BYOK/迁移文档；本计划 **DOC-002 内网 only**

---

## 目标

1. 策略层（VelaClaw agent loop）与执行层（AiClient / 内嵌 prism-core）边界清晰  
2. BYOK 永远直连；陌生 provider 走内嵌 Prism 路由  
3. 消除 `ProtocolBackedProvider` 中的执行重复逻辑  
4. 为 prism-core 特性（router、usage）按 feature 增量接入做准备  

---

## 阶段

| 阶段 | 名称 | 能力 | 依赖 crate/feature | 任务 |
|------|------|------|-------------------|------|
| **EVO-0** | Trial 基线 | BYOK 直连 + protocol adapter model 修复 | `ai-lib-rust` default | VL-TRIAL-001 ✅ |
| **EVO-1** | ExecutionHandle | 统一执行入口；adapter 仅 trait 桥接 | `ai-lib-rust` | VL-EVO-001 |
| **EVO-2** | 陌生 provider | 内嵌 `prism-core` router；allowlist 分流 | `prism-core/router` | VL-EVO-002 |
| **EVO-3** | BYOK 遥测 | 调用记录上报 Prism（无 key 上传） | `prism-core/usage-tracking` | VL-EVO-003 |
| **EVO-4** | Adapter 退役 | 删除 `effective_model` 等死代码；评估移除 `Provider` protocol 分支 | — | VL-EVO-004 |

**不在 VelaClaw EVO 范围**：`ai-lib-gateway` HTTP 部署验收（Prism P1 产品任务）；Eos `/api/proxy`；Py/TS SDK。

---

## EVO-1 要点（ExecutionHandle）

```rust
// 目标形态（示意，非最终实现）
enum ExecutionBackend {
    Byok(Arc<AiClient>),           // 直连
    PrismRouter(PrismRouterHandle), // 内嵌 prism-core
}

trait ExecutionHandle {
    async fn chat(&self, req: AgentChatRequest) -> Result<AgentChatResponse>;
    async fn stream(&self, req: AgentChatRequest) -> impl Stream<...>;
}
```

- 策略层只构造 `AgentChatRequest`（messages、tools、temperature、logical_model）  
- **禁止** 在执行层之外调用 `.model(provider/model)`  
- 分流逻辑读取 config + credential 可用性（VL-ARCH-001 §4）

---

## EVO-2 要点（内嵌 prism-core）

- `velaclaw/Cargo.toml` 可选 dependency：`prism-core` with `features = ["router"]`（路径或 crates.io，与 eos workspace 对齐策略另文）  
- 与 `ai-lib-gateway` **无运行时 HTTP 依赖**  
- 验收：配置 `routing=prism` 或 unknown provider id 时，请求不经 AiClient 直连而经 router

---

## EVO-3 要点（遥测）

- BYOK 成功调用后异步写入 `UsageRecord`（provider、model、token 估算、latency）  
- 上报目标：Prism 配置的 endpoint（可关）  
- **不上传** API key、prompt 正文（除非用户显式 opt-in 且 C-band 合规）

---

## 与 Prism / Gateway 任务关系

| Prism 任务 | VelaClaw 关系 |
|------------|---------------|
| PR-P1-016 | 修订为 **内嵌 prism-core 集成** 跟踪（非 HTTP 迁移） |
| PR-P1-002 等 Gateway HTTP | 外部 API 产品；VelaClaw 不依赖 |
| PR-P1-012 crates.io prism-core | EVO-2 前置（或 git path 过渡） |

---

## 近期排期建议

1. **本周**：Linux 完成 VL-TRIAL-001 G/H/I smoke；合并 velaclaw PR #51（DOC-002）  
2. **EVO-1 启动**：VL-EVO-001 分支 + 分流 config schema 草案  
3. **EVO-2**：待 prism-core 依赖路径稳定（eos workspace / crates.io）  

---

## 文档索引

| 文档 | 用途 |
|------|------|
| `VL-ARCH-001-execution-strategy-boundary.md` | 架构决策 ADR |
| `docs/TRIAL_READINESS_SMOKE.md` | 维护者冒烟 |
| `tasks/VL-EVO-*.yaml` | 可执行任务 |
| `ailib-official/velaclaw` `docs/migration-legacy-to-protocol.md` | 公开 BYOK 用户文档 |
