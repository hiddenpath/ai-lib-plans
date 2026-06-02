# Prism — AI Protocol Gateway (P-layer)

> **Type**: Commercial product (C-band core)
> **Status**: Phase 1 planning
> **Repo**: `hiddenpath/gateway` (private); ⚠️ NOT `ailib-official` public org
> **Architecture**: P-layer in S=(A,P,E), closed-source commercial gateway
> **Access**: maintainer-only, C-band proprietary code
> **Plan Source**: PRODUCT_PLAN_v2.md + ai_lib_gateway_phase1_plan.md v2.0

## Product Matrix Position

| | To B | To C |
|---|---|---|
| **Prism** | ① Prism Enterprise | ② Prism |
| **Eos**  | — | **⑤ Eos（逸思）** — 详见 `projects/eos/brand-rationale.md` |

## Key Decisions (Confirmed 2026-04-25)

- **D2**: Enterprise + Prism share codebase, `--features enterprise` (Rust feature flag)
- **D3**: Phase 2 billing = pay-per-use + margin; Phase 3 = free-tier + overage
- **D5**: Phase 2 Enterprise + Vela Pro bundled; Phase 3 split

## Architecture

```
User → Prism (P-layer) → ai-lib-core (E-layer) → Provider APIs
         ↓
    Router / KeyPool / Pricer / Logger
    (closed-source C-band)
```

## 远期架构预留（2026-06-02）

### 智能路由策略：多语言插件能力

智能路由是 Phase 2 核心功能。为未来外部化路由策略预留架构地基，避免远期反复：

**总原则：Plugin-first, WASM-first。**

| 层 | 方案 | 何时落地 |
|----|------|---------|
| 1 | 内置 DSL（YAML 规则模板：成本/延迟/区域优先） | Phase 2 内置路由策略时一起做，覆盖 80% 场景 |
| 2 | **WASM 插件接口**（wasmtime 加载用户编写的策略 .wasm） | Phase 2+，覆盖 20% 需要自定义策略的用户 |
| 3 | gRPC sidecar（用户自建策略服务） | 企业版高阶选项（如果有客户坚持其他语言） |

**Phase 1 约束**：不做插件化，不引入 WASM 运行时依赖。内置硬编码路由策略（fallback、轮询）足够。
但路由模块（`Router` trait / `RouteStrategy` trait）的设计应为将来插件化留好 trait 边界：

```rust
trait RouteStrategy: Send + Sync {
    fn select(
        &self,
        request: &ChatRequest,
        pool: &KeyPoolSnapshot,
    ) -> Result<ProviderTarget, RouteError>;
}
```

WASM 插件仅需实现此 trait → 编译为 wasm → Prism 加载。trait 签名保持稳定即可。

**不做的决策**：gRPC sidecar 不在 Phase 1-3 roadmaps 内，仅当有企业客户明确需求时再议。

### Capability-indexed 智能路由（理论框架：Paper 4 — Capability Economy）

Phase 2 智能路由的底层理论基础来自 Paper 4（Capability Economy），核心思路自顶向下：

**Agent 不需要指名道姓选 Provider，而是表达结构化能力需求，由路由层做匹配。**

```
Agent: "I need a capability to [task]"
  → Discovery: Query registry for matching capabilities
  → Selection: Choose based on quality, cost, latency
  → Invocation: Execute capability
```

#### 多维能力索引

不可将所有能力参数塞入一个 WHERE 子句，需要按维度建立多个独立索引：

| 索引维度 | 示例值 | 来源 | 路由角色 |
|---------|--------|------|---------|
| 能力类别 (capability) | text_generation / code / image / audio | manifest `capabilities` | 第一层 filter |
| 上下文窗口 | 128K / 200K / 1M | manifest `context_window` | 范围约束 |
| 最大输出 | 8K / 32K / 128K | manifest `max_output` | 范围约束 |
| 成本等级 | 0.15/1M input | manifest + Pricer | 排序/成本优先 |
| 延迟特征 | 低/中/高 | 运行时统计 | 约束 + 排序 |
| 区域合规 | cn / global | manifest `availability.regions` | 硬约束 |
| 质量分数 | 0.0–1.0 | 基准测试 + 运行时评分 | 排序 |

**理论出处**：Paper 4 §3.2 Demand Side — "Agents express capability requirements without specifying providers"；§4.1 Capability Registry — Federated capability index 三层结构（Capability Index / Discovery API / Validation Engine）；§3.5 Quality Signals — 质量分数与声誉系统

#### 路由工作流

```
请求进入 Prism
  ↓
[1] 请求中是否
    ├── 指定了具体 provider/model?   →  直连（bypass 索引）
    └── 未指定，走智能路由？
        ↓
[2] 解析请求能力需求（context_window, output, capability type, region）
    ↓
[3] 查询多维索引
    ├── capability_index[code]              → 候选集 A
    ├── context_window_index[>=128K]        → 候选集 B
    ├── region_filter[cn]                   → 候选集 C
    └── 求交 → 符合所有硬约束的候选集 D
    ↓
[4] 按策略排序（成本优先 / 质量优先 / 延迟优先 / 自定义插件）
    ↓
[5] 选定 → 发请求 → 记录运行时统计
```

#### 用户指定模型的情况

路由引擎必须同时支持两种模式：
1. **显式指定**（用户明确要求 "gpt-4" / "deepseek-chat"）→ 直通，不经能力索引
2. **能力推断**（用户仅表达需求，未指定模型）→ 走多维索引匹配

显式指定是必要条件——即使智能路由成熟后，部分用户仍然（也应当被允许）点名要特定模型。

#### 数据结构原型

```rust
// Prism Phase 2 智能路由核心结构（论文 Capability Economy §4.1 对应实现）
struct CapabilityRouter {
    /// 能力类别 → 候选 Provider 列表
    capability_index: HashMap<CapabilityName, Vec<ProviderEntry>>,
    /// 上下文窗口索引（BTreeMap 按窗口大小自动排序）
    context_window_index: BTreeMap<TokenCapacity, HashSet<ProviderId>>,
    /// 成本索引（排序用）
    cost_index: BTreeMap<MicroCents, ProviderId>,
    /// 运行态质量统计
    quality_tracker: HashMap<ProviderId, QualityMetrics>,
    /// 区域合规过滤
    region_filter: HashMap<RegionCode, HashSet<ProviderId>>,
}
```

#### RouteStrategy trait 演进

Phase 1 的 `RouteStrategy` trait 需要预留 `model_registry` 参数：

```rust
trait RouteStrategy: Send + Sync {
    fn select(
        &self,
        request: &ChatRequest,
        pool: &KeyPoolSnapshot,
        model_registry: &ModelRegistry,  // ← Phase 2 接入 capability index
    ) -> Result<ProviderTarget, RouteError>;
}
```

`ModelRegistry` 是 `CapabilityRouter` 的轻量封装——Phase 1 可以返回空实现（仅返回 key pool 中可用 model），Phase 2 填充真正的多维索引逻辑。

**理论到实践的迭代流程**（先生 2026-06-02）：Capability Economy 的抽象框架 → Prism 路由的具体索引结构 → 上线后根据实际用量数据修正索引权重 → 再反哺理论模型——多回合互相验证。

## Three-Zone Alignment

| Component | Band | License |
|-----------|------|---------|
| Prism routing engine | C | Proprietary |
| Key pool + scheduling | C | Proprietary |
| Pricer + billing | C | Proprietary |
| Admin API | C | Proprietary |
| Prism SDK (client) | A | Apache-2.0 |
| ai-lib-core dependency | A | Apache-2.0 |

## Phase Roadmap

- **Phase 1** (3 weeks): Core API + Key pool + Basic routing + 5 P0 Providers
- **Phase 2** (6-8 weeks): Smart routing + BYOK + Billing + Enterprise MVP
- **Phase 3** (3-6 months): Multi-modal + Local payments + SLA + Compliance templates

## Hot Products (Marketing Focus)

- Phase 1: "5-Provider free gateway" + WASM protocol demo
- Phase 2: BYOK mode + Smart routing "auto" mode
- Phase 3: Multi-modal aggregation API + Compliance template packs

## Phase 1 Tasks

| ID | Title | Priority | Depends On |
|----|-------|----------|------------|
| PR-P1-001 | Project skeleton (Axum + config + health) | P0 | — |
| PR-P1-002 | Core proxy (/v1/chat/completions sync + stream) | P0 | PR-P1-001 |
| PR-P1-003 | Key pool scheduling (rotate + cooldown + circuit-break) | P0 | PR-P1-002 |
| PR-P1-004 | Usage tracking (SQLite + Pricer) | P0 | PR-P1-002 |
| PR-P1-005 | Fallback routing (primary → secondary) | P0 | PR-P1-002, PR-P1-003 |
| PR-P1-006 | Docker deployment + Caddy TLS + api.prism.ailib.info | P0 | PR-P1-005 |
| PR-P1-007 | Admin API (keys/users/usage CRUD) | P1 | PR-P1-003, PR-P1-004 |
| PR-P1-008 | 5 P0 Providers integration verification | P0 | PR-P1-006 |

## Wave 2 Tasks (Productization Prelude)

| ID | Title | Priority | Depends On |
|----|-------|----------|------------|
| PR-PP-001 | Pack contract draft (JSON Schema + example) | P2 | PR-P1-008 |
| PR-PP-002 | Minimal cost routing example (not production SLA) | P2 | PR-P1-005, PR-P1-008 |
| PR-PP-003 | Constitution rules extraction (BIZ-001~005) | P1 | — |

## Gates

- Phase 1 does NOT block on PT-073 (uses published ai-lib-core v0.9.4)
- Phase 2 smart routing depends on Contact API stability (= PT-073 gate)
