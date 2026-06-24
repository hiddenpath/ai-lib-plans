# PR-PP-002 — 成本路由示例 + `/v1/route/decide` 实现方案

> **版本**: v1.0  
> **日期**: 2026-06-22  
> **任务**: [PR-PP-002-cost-routing-example.yaml](../tasks/PR-PP-002-cost-routing-example.yaml)、[PR-P2-003-route-decide-http.yaml](../tasks/PR-P2-003-route-decide-http.yaml)  
> **状态**: 设计稿 — **NOT PRODUCTION SLA**  
> **消费者**: Vela `SMART_ROUTING.md`、Eos EOS-REQ-P2-003

---

## 1. 目标与非目标

### 目标

1. 在 **prism-core** 实现可测试的 **成本优先路由策略**（给定 model class / model id，在健康 provider 中选 per-token 成本最低者）。
2. 在 **ai-lib-gateway** 暴露 `POST /v1/route/decide`，供 Vela 等客户端在发送前获取推荐 `model` + `provider_id`。
3. 定价来自 **外部配置文件**（YAML/JSON），与 `Pricer` 表可共享或引用同一文件。
4. 全链路标注 **示例 / 非生产 SLA**。

### 非目标（本 PR 不做）

- 生产级 SLA、多租户计费扣款（→ PR-P2-004）
- ai-lib-core ExecutionPipeline 替换 libcurl（→ PR-P2-005 可选，PT-073 后）
- Pack 签名与市场（→ PR-PP-001）
- 用户历史 / 个性化推荐

---

## 2. 架构

```text
Client (Vela)
    │ POST /v1/route/decide  (Bearer: PRISM_GATEWAY_API_KEY)
    ▼
ai-lib-gateway  src/v1/route_decide.rs
    │ AppState.config + AdminService.health
    ▼
prism-core      cost_router.rs  (new)
    ├─ PricingTable   ← pricing.yaml (file or TOML embed)
    ├─ FallbackRouter.health()  (reuse ProviderHealth)
    └─ CostRoutingStrategy::decide()
```

与现有 `FallbackRouter` 关系：**组合**而非替换 — `CostRouter` 持有 `&FallbackRouter`（或共享 health `HashMap`），在 fallback chain 上按成本排序后选第一个有 Key 的 provider。

---

## 3. prism-core 设计

### 3.1 新模块 `cost_router.rs`

```rust
// 概念 API（实现时放 prism-core/src/cost_router.rs）

pub struct PricingTable {
    /// model_id → ModelPricing（复用 usage::ModelPricing）
    models: HashMap<String, ModelPricing>,
    /// provider_id → 默认定价回退（可选）
    provider_defaults: HashMap<String, ModelPricing>,
}

pub enum OptimizeGoal {
    Cost,      // Wave 1 仅实现此项
    Latency,   // PR-P2-005
    Balanced,  // PR-P2-005
}

pub struct DecideInput<'a> {
    pub model_id: Option<&'a str>,
    pub model_class: Option<&'a str>,  // 如 "chat-economy" — 可后续扩展
    pub messages_preview_len: usize,    // 用于粗估 token（可选）
    pub optimize: OptimizeGoal,
    pub region: Option<&'a str>,
}

pub struct DecideOutput {
    pub model: String,
    pub provider_id: String,
    pub reason: String,           // e.g. "lowest_cost"
    pub estimated_cost_per_1k: f64,
    pub fallback_chain: Vec<String>,
}

pub struct CostRouter<'a> {
    pricing: &'a PricingTable,
    router: &'a FallbackRouter,
    min_success_rate: f64,        // 默认 0.5，过滤不健康 provider
}

impl CostRouter<'_> {
    pub fn decide(&self, input: DecideInput) -> Option<DecideOutput> { /* ... */ }
}
```

### 3.2 决策算法（Wave 1 — cost only）

1. 解析目标 model：优先 `input.model_id`；若空则从 `model_class` 查 pricing 表（首版可要求必传 `model_id`）。
2. 从 `FallbackRouter` 获取该 model 的 provider chain（`route(model_id)` 的 chain 逻辑复用）。
3. 过滤：`health.success_rate() >= min_success_rate`。
4. 对每个候选 provider，用 `PricingTable` 计算 **估算每 1K prompt token 成本**（`prompt_per_1m / 1000`）。
5. 选最低成本且有可用 Key 的 provider（与 `FallbackRouter` 的 key_pool 一致）。
6. `fallback_chain` = 其余候选按成本升序。

### 3.3 定价配置 `pricing.yaml`（示例）

```yaml
# NOT PRODUCTION SLA — example public pricing snapshots
# Refresh manually from provider pricing pages; no warranty.
version: 1
models:
  deepseek-chat:
    provider_id: deepseek
    prompt_per_1m: 0.14
    completion_per_1m: 0.28
  gpt-4o-mini:
    provider_id: openai
    prompt_per_1m: 0.15
    completion_per_1m: 0.60
  # ... 5 P0 providers
```

加载路径：
- **库测试**：`tests/fixtures/pricing_example.yaml`
- **gateway**：`PRISM_PRICING_YAML` 环境变量或 `config.toml` 新段 `[pricing] path = "..."`

### 3.4 测试

| 测试 | 断言 |
|------|------|
| `cost_router_picks_cheapest` | 两 provider 同 model class，选低价 |
| `cost_router_skips_unhealthy` | success_rate 低于阈值时跳过 |
| `cost_router_fallback_chain_order` | 次选为第二低价 |
| `pricing_table_loads_yaml` | 解析 fixture |

运行：`cargo test -p prism-core --features full cost_router`

---

## 4. ai-lib-gateway HTTP 设计

### 4.1 路由注册

在 `src/app.rs` 的 `v1_routes` 增加：

```rust
.route("/v1/route/decide", post(v1::route_decide))
```

与 `/v1/models`、`/v1/chat/completions` 相同：**`require_gateway_bearer`** 中间件。

### 4.2 请求 / 响应（与 Vela SMART_ROUTING.md 对齐）

**Request**

```http
POST /v1/route/decide
Authorization: Bearer <PRISM_GATEWAY_API_KEY>
Content-Type: application/json
```

```json
{
  "model": "deepseek-chat",
  "messages": [{ "role": "user", "content": "..." }],
  "preferences": { "optimize": "cost" }
}
```

| 字段 | 必填 | 说明 |
|------|------|------|
| `model` | 是* | 首版必填；未来可仅传 `model_class` |
| `messages` | 否 | 用于日志/未来 token 估算；首版可忽略内容 |
| `preferences.optimize` | 否 | 默认 `cost`；`latency`/`balanced` 返回 501 直至 PR-P2-005 |

**Response 200**

```json
{
  "model": "deepseek-chat",
  "provider_id": "deepseek",
  "reason": "lowest_cost",
  "estimated_cost_per_1k_prompt_usd": 0.00014,
  "fallback_chain": ["openai", "anthropic"],
  "disclaimer": "NOT_PRODUCTION_SLA"
}
```

**Errors**

| 状态 | 条件 |
|------|------|
| 400 | 缺少 model / 非法 optimize |
| 404 | 无可用 provider / 定价未配置 |
| 501 | optimize 非 cost（首版） |
| 503 | 全部 provider 不健康 |

### 4.3 实现文件

| 文件 | 职责 |
|------|------|
| `src/v1/route_decide.rs` | handler、JSON 类型、调用 CostRouter |
| `src/v1/mod.rs` | `pub mod route_decide;` |
| `tests/route_decide.rs` | axum 集成测试（test_app + fixture pricing） |

### 4.4 AppState 扩展

首版可在 handler 内 **按需构建** `CostRouter`（读 `LoadedConfig` + `state.admin` health），避免大改 `AppState`。后续 PR-P2-005 可提升为启动时单例。

---

## 5. 与 Vela 接线（PR-V2-004 后续 PR，非本任务）

1. `smartRouting.ts`：`prPp002CostRouting` 在 gateway decide 端点 live 后置 `true`（仍可能因 billing / PT-073 保持 aggregate false）。
2. 新增 `decideRoute.ts`：`fetch(apiBase + '/v1/route/decide', ...)`。
3. `RoutingHintBar`：decide 成功时展示 server 推荐，替换纯客户端启发式。
4. 错误时 fallback 到 PR-V2-003 WASM + TS heuristics。

---

## 6. 安全与合规

- 与 chat 相同 Gateway Bearer；**不**暴露 provider API Key 给客户端。
- Response 仅含 `provider_id` 与成本估算，无 admin 令牌。
- 日志不记录 `messages` 全文（BIZ-004 精神）。
- 文档与 OpenAPI 注释含 **NOT PRODUCTION SLA**。

---

## 7. 交付清单（PR 验收）

- [ ] `prism-core/src/cost_router.rs` + tests
- [ ] `pricing.yaml` fixture + loader
- [ ] `ai-lib-gateway` `POST /v1/route/decide` + integration tests
- [ ] `docs/COST_ROUTING.md`（运维：如何更新定价文件）
- [ ] 更新 PR-PP-002 YAML `repo` 字段为 `prism-core` + `ai-lib-gateway`
- [ ] CI：`cargo test --features full` + gateway `cargo test`

---

## 8. 演进路线

| 阶段 | 能力 |
|------|------|
| **Wave 1（本方案）** | cost-only decide |
| PR-P2-005 | latency / balanced；admin health 权重 |
| PT-073 后 | ExecutionMetadata 注入 route reason |
| PR-P2-004 | decide 结果写入 usage 预估 |
