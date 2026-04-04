# Wave-5：执行层/策略层分离与 v1.0 发布计划

> 状态：进行中（2026-04-04：PT-067/068/070/071/072 在工程上已闭合主线；Go 已合入 main；Python client 静态 E/P 门禁收紧；**PT-073 四语言 core-only 全量合规 + 发布列车**仍为 Wave-5 收口项）  
> 创建日期：2026-04-01  
> 更新：2026-04-01 — 实施前提见 **§1.4**（允许破坏性变更；对外兼容非本波硬目标）。  
> 前置依赖：Wave-4B（PT-063~PT-066 四运行时质量门禁）  
> 目标版本：v1.0.0

---

## 1. 背景与动机

### 1.1 论文约束

Paper1《The AI Execution Layer》定义了最小性约束（§3）：

> **Minimality Constraint:** The execution layer MUST implement deterministic
> capability invocation only, and MUST NOT perform policy-driven decisions such
> as provider selection, strategic retry, or workflow-level fallback.

当前四运行时已具备完整的生成式大模型支持，但**执行层（E）与策略层（P）的边界在代码结构上未分离**——routing、cache、batch、complex resilience、plugins 等策略模块与核心调用模块混在同一个包中。

### 1.2 WASM 驱动

PT-061 已完成 WASM 分阶段演进规划。WASM 场景（浏览器、边缘、嵌入式）对二进制大小和无状态性有硬约束——**若不先把 E 拆干净，WASM 构建将被迫拖入策略层依赖**。

### 1.3 v1.0 标志

完成 E/P 分离 + WASM core 构建通过合规矩阵 = **论文所述最小执行层的工程证明** = v1.0 发布条件达成。

### 1.4 实施前提（论文未发表 / 仓库未公开 / 1.0 前）

在首次对外发布与 v1.0.0 定稿之前，**不将「保持旧 import 路径与旧 API 不变」作为 Wave 5 的硬约束**。允许为清晰边界进行**破坏性**的包名、模块路径与公开 API 调整。

- **优先**：`ai-lib-core` 与 `ai-lib-contact`（及各语言对等物）边界清晰、依赖方向可机验、合规矩阵与 **Paper1 §3** 一致。
- **非目标（本波）**：长期双轨 API、仅为兼容而存在的厚 facade；若保留极薄聚合入口，**可选**且不得掩盖 E/P 依赖方向。
- **仍必须**：`ai-protocol` 与各运行时对齐；CHANGELOG / 迁移说明；基线 tag 便于团队回滚与 bisect。

---

## 2. 架构目标

```
┌─────────────────────────────────────────────┐
│           ai-lib-contact (策略层)            │
│  routing · cache · batch · plugins          │
│  interceptors · tokens · telemetry          │
│  guardrails(策略) · negotiation · feedback   │
├─────────────────────────────────────────────┤
│     ↕ ExecutionResult 合同接口 ↕             │
├─────────────────────────────────────────────┤
│           ai-lib-core (最小执行层)           │
│  types · error · protocol · drivers         │
│  transport · pipeline · structured          │
│  client · mcp · registry · utils            │
│  embeddings · stt · tts · rerank (opt)      │
│  multimodal · computer_use (opt)            │
├─────────────────────────────────────────────┤
│            ai-protocol (协议)               │
│  manifests · schemas · compliance fixtures  │
└─────────────────────────────────────────────┘
```

### 2.1 E 留下什么（ai-lib-core）

**判定标准**：§3.1 六项核心职责 + §3.4–3.5 允许的附属功能。

| 模块 | 理由 |
|------|------|
| `types` | 消息、事件、工具——合同类型 |
| `error` / `error_code` | 错误上报与分类（§3.1.5）|
| `protocol` | manifest 加载/校验——翻译前提（§3.1.2）|
| `drivers` | OpenAI/Anthropic/Gemini HTTP 适配（§3.1.2 + §3.1.1）|
| `transport` | 连接池、超时、TLS——纯传输（§3.1.4）|
| `pipeline` | SSE 解码 + 事件映射——流式归一化（§3.4 + §3.1.3）|
| `structured` | JSON schema 输入/输出校验（§3.5）|
| `client` | 单次 chat/stream 调用面（§3.1.1）|
| `mcp` | MCP ↔ AI-Protocol 翻译（§4.1）|
| `registry` | 能力声明查询——manifest 读取的延伸 |
| `utils` | 工具函数，零策略 |
| `embeddings` | 能力调用（可选 feature）|
| `stt` / `tts` | 能力调用（可选 feature）|
| `rerank` | 能力调用（可选 feature）|
| `multimodal` | 模态格式化/校验（§3.5）|
| `computer_use` | 归一化（单次调用翻译层）|
| `resilience`（极小子集）| 有界 micro-retry 1-2 次（§3.1.5.1）|

### 2.2 P 拿走什么（ai-lib-contact）

**判定标准**：§3.2 明确排除的六类 + 引入状态/策略的模块。

| 模块 | 理由 |
|------|------|
| `routing` | 厂商选择 + 负载均衡 + 成本/延迟路由（§3.2）|
| `cache` | 响应缓存——有状态 + TTL 策略（§3.2 + §3.3）|
| `batch` | 批量编排——多次调用组合（§3.2 workflow）|
| `resilience`（大部分）| 熔断器状态机 + 复杂限流 + 跨厂商 fallback（§3.2）|
| `plugins` / `interceptors` | Hook 链 / Middleware 注册——编排扩展机制 |
| `tokens` | 计费 / token 估算——成本优化输入（§3.2 routing）|
| `telemetry` | 指标采集管线 + 导出器——平台层（§3.5 E 只发出指标）|
| `guardrails`（策略引擎）| 完整规则引擎——E 仅保留 schema 校验 |
| `negotiation`（TS）| FallbackChain / parallelAll——多目标编排 |
| `feedback`（采集器）| E 只发出事件类型；采集/消费属于 P |

### 2.3 E ↔ P 合同接口

```rust
/// E 返回给 P 的执行结果
pub struct ExecutionResult<T> {
    pub data: T,
    pub metadata: ExecutionMetadata,
}

pub struct ExecutionMetadata {
    pub provider_id: String,
    pub model_id: String,
    pub execution_latency_ms: u64,
    pub translation_latency_ms: u64,
    pub micro_retry_count: u8,
    pub error_code: Option<StandardErrorCode>,
    pub usage: Option<UsageInfo>,
}
```

P 据 `ExecutionMetadata` 做路由/重试/降级决策；E 不关心 P 的决策结果。

---

## 3. 任务分解（PT-067 ~ PT-073）

### PT-067：E/P 边界合同定义与跨运行时对齐

- 产出：`ExecutionResult` / `ExecutionMetadata` 类型定义（四语言）
- 产出：E-only 模块清单 + P-only 模块清单（本文档 §2 的代码化）
- 产出：E ↔ P 接口 compliance fixture（验证 E 不引入 P 依赖）
- 预估：8h

### PT-068：ai-lib-rust core/contact crate 拆分

- 将 `ai-lib-rust` 拆为 `ai-lib-core`（workspace member）+ `ai-lib-contact`
- `ai-lib-core`：零依赖 routing/cache/batch/plugins/tokens/telemetry/interceptors
- `ai-lib-contact`：依赖 `ai-lib-core`；对外以清晰 crate 边界为准（**允许破坏性**变更旧路径）
- 原 `ai-lib-rust`：**可选用**极薄 workspace 根 crate 或 metapackage 聚合 re-export；**非必须**；若省略，则在 CHANGELOG 写明新入口 crate
- 验证：`ai-lib-core` 单独 `cargo test` 通过全部合规矩阵
- 验证：`cargo build --target wasm32-wasip1 -p ai-lib-core` 编译成功
- 预估：24h

### PT-069：ai-lib-python core/contact 包拆分

- `ai-lib-python[core]` 与 `ai-lib-python[contact]` extras 或独立包
- Core 不引入 routing/cache/batch/plugins/tokens/telemetry 模块
- 验证：`pip install ai-lib-python[core]` + pytest 合规通过
- 预估：16h

### PT-070：ai-lib-ts core/contact 包拆分

- `@ailib/core` + `@ailib/contact` 为主交付面；旧包名上的「全量重导出」**可选**（见 §1.4）
- Core 不含 routing/cache/batch/plugins/tokens/telemetry/interceptors/negotiation
- 验证：`npm test` on core-only 合规通过
- 预估：16h

### PT-071：ai-lib-go core 验证（已近最小）

- Go 当前已接近 core-only（无 routing/cache/batch/plugins/telemetry）
- 任务：审计确认无策略模块泄漏；补齐 `ExecutionMetadata` 合同
- 验证：`go test ./...` + 合规通过
- 预估：4h

### PT-072：WASM 从 core-only 构建（衔接 PT-061 Phase 1 执行）

- 基于 PT-068 的 `ai-lib-core` crate
- 目标 1：`wasm32-wasip1` 编译通过，binary < 2MB
- 目标 2：导出 6 个 WASM 函数（PT-061 定义）
- 目标 3：wasmtime 测试线束跑通 protocol_loading + message_building 合规子集
- 目标 4：浏览器 PoC（wasm-bindgen，加载 manifest + 构建请求）
- 预估：20h

### PT-073：core-only 合规证明 + v1.0 RC 门禁

- 四语言 core-only（不含任何 P 模块）通过完整合规矩阵
- WASM core 通过合规子集
- 门禁清单（在 PT-062 基础上升级）：
  - schema readiness: v1.0.0 final
  - four-runtime core-only compliance: PASS
  - WASM compliance subset: PASS
  - drift:check: no critical
  - release notes: cover E/P separation + WASM
- 若通过：触发 v1.0.0 发布列车
- 预估：12h

---

## 4. 执行顺序与依赖

```
PT-067 (合同定义)
   ├──→ PT-068 (Rust 拆分) ──→ PT-072 (WASM)
   ├──→ PT-069 (Python 拆分)
   ├──→ PT-070 (TS 拆分)
   └──→ PT-071 (Go 验证)
                    全部 ──→ PT-073 (v1.0 RC 门禁)
```

### 4.1 里程碑时间线（建议）

| 阶段 | 任务 | 预估周期 |
|------|------|----------|
| **M1：合同** | PT-067 | 1 周 |
| **M2：拆分** | PT-068 + PT-069 + PT-070 + PT-071（可并行）| 2-3 周 |
| **M3：WASM** | PT-072 | 1-2 周 |
| **M4：发布** | PT-073 + 发布列车 | 1 周 |
| **总计** | | 5-7 周 |

---

## 5. 风险与缓解

| 风险 | 影响 | 缓解 |
|------|------|------|
| Rust workspace 拆分引发依赖循环 | 阻塞 PT-068 | 先画 crate 依赖图，E 不可依赖 P |
| 破坏性变更导致内部调用方迁移成本 | 拖慢集成 | CHANGELOG + 迁移小节 + 基线 tag；不强制长期 facade |
| WASM binary 超 2MB | 降低可用性 | 逐模块审计依赖大小；serde_json → simd-json 或 miniserde |
| Go 隐含策略模块未发现 | 合规矩阵误判 | PT-071 显式审计 |
| 合规矩阵 fixtures 耦合 P 模块 | 测试无法在 core-only 跑 | PT-067 分离 E-only 合规子集 |

---

## 6. 成功标准

完成以下全部时，视为 Wave-5 闭环 + v1.0.0 发布就绪：

1. **四语言 core-only 包**独立存在，不依赖任何 P 模块，通过完整合规矩阵
2. **WASM core** 编译通过并通过合规子集，binary < 2MB
3. **ai-lib-contact**（及各语言对等物）作为独立面存在，**依赖 core**；破坏性变更已文档化即可（不要求与拆分前 API 逐符号一致）
4. **E ↔ P 合同接口**在四语言实现，P 消费 `ExecutionMetadata` 做决策
5. **论文 §3 可验证**：core-only = 六项核心职责 + 零策略 = 最小执行层

---

## 7. 与现有路线的关系

- **Wave-4B**（PT-063~066 生成式适配 + 质量门禁）→ **前置闭合**
- **PT-061**（WASM 分阶段演进）→ Phase 1 执行落入 **PT-072**
- **PT-062**（v1.0.x RC 门禁）→ 升级为 **PT-073**（含 E/P 证明 + WASM）
- **spiderswitch** → Contact 层的天然消费者，可复用 `ai-lib-contact` 能力

---

## 8. 附录：新 Session 执行 Prompt（可复制）

将以下块粘贴到新会话作为系统/用户上下文；按需收窄范围（例如「本会话仅 PT-067」）。

```text
You are continuing Wave 5 of the ai-lib ecosystem: Execution Layer (E) vs Contact/Policy (P) split, WASM from core-only, then v1.0.0 gate.

Authoritative plan (read first):
- ai-lib-plans: active/projects/ai-protocol/WAVE5_EP_SEPARATION_AND_V1_PLAN_2026-04-01.md (note §1.4 pre-1.0 policy)
- Tasks: PT-067 → PT-068–071 → PT-072 → PT-073
- ROADMAP_MASTER.md (Wave-5), MEMORY.md (E/P decision 2026-04-01)

Policy (until paper is public / repo is public / v1.0.0):
- Backward compatibility is NOT a goal for this wave. Breaking package names, import paths, and public APIs is acceptable when it clarifies E/P boundaries.
- Do NOT invest in long-lived facade crates or dual-track APIs unless trivially small; optional thin re-exports are allowed but not required.
- Hard constraints remain: ai-protocol alignment across four runtimes, compliance tests passing, Paper1 §3 minimality (no provider selection / strategic retry / workflow fallback inside E), machine-verifiable E-does-not-import-P.

Paper: Paper1_AI_Execution_Layer_v1.8.md (§3.1–3.2).

Repos (local): ai-protocol, ai-lib-rust, ai-lib-python, ai-lib-ts, ai-lib-go, ai-lib-plans.

Suggested order: baseline tag on each repo main for bisect → PT-067 (contract + types + E-only compliance subset) → PT-068+ splits.

Deliverable for this session: [state PT-ID and concrete files/PR scope].
```
