# Prism — Phase 2 产品化开发计划

> **版本**: v1.0  
> **日期**: 2026-06-22  
> **前置**: Phase 1 ✅（见 [TASKS_INDEX.md](./TASKS_INDEX.md) M1–M3）  
> **门控分析**: [PRISM_P2_PT073_GATE_ANALYSIS_2026-06.md](./PRISM_P2_PT073_GATE_ANALYSIS_2026-06.md)  
> **协调**: Vela PR-V2-004、Eos EOS-P2-005（智能路由占位）

---

## 1. 版本与里程碑原则

1. **1.0 之前**：允许多个持续优化的可用版本（0.x patch 列车）；功能可按 Wave 逐步上线。
2. **PT-073**：协议 v1.0 **就绪里程碑**，与 Prism P2 **并行**，**不是** P2 开工前提。
3. **Phase 1 路径延续**：P2 首波仍用 **prism-core libcurl + Pricer**（D6）；ai-lib-core / Contact 集成为 **P2 末波增强**，软依赖 PT-073。

---

## 2. Phase 2 范围（来自 project-overview.md + PRODUCT_PLAN_v2）

| 能力域 | 说明 | 任务 ID | PT-073 |
|--------|------|---------|--------|
| **成本路由示例** | 最低价 provider 选择；NOT PRODUCTION SLA | PR-PP-002, PR-P2-003 | 不阻塞 |
| **定价精度** | `cost_usd` → µUSD，为 billing 奠基 | PR-P2-001 | 不阻塞 |
| **按量计费** | pay-per-use + margin（D3） | PR-P2-004 | 不阻塞 |
| **BYOK** | 用户自带 Key；平台路由 | PR-P2-002 | 不阻塞 |
| **Pack 合同** | manifest 扩展草案 | PR-PP-001 | 不阻塞 |
| **智能路由 GA** | 成本 + 延迟 + 健康；可选 Contact 元数据 | PR-P2-005 | **软依赖** PT-073 |
| **Enterprise MVP** | SSO/审计占位（与 PT-073 松耦合） | PR-P2-006 | 松耦合 |

**营销热点（Phase 2）**：BYOK + Smart routing「auto」模式（PRODUCT_PLAN §5.2）。

---

## 3. 与 Vela / Eos 协调

| 消费方 | 依赖 Prism P2 | 原则 |
|--------|---------------|------|
| **Vela** PR-V2-004 | PR-P2-003 `/v1/route/decide`、PR-P2-004 billing | 门控 flip 按实际交付；Interim WASM 可保留 |
| **Eos** EOS-P2-005 | 同上 + 可选前端指 `api.prism.ailib.info` | 智能路由仍为 P2 非必交付 |
| **VelaClaw** | PR-P2-005 后可选 HTTP decide | EVO-2 内嵌 router 不变 |

**不变**：不改 Eos `/api/proxy`；香港 `eos.ailib.info` ≠ Prism 生产验收环境。

---

## 4. Wave 排期（建议 6–8 周）

```text
Wave 0  对照 + 规划     本文档 + PR-PP-002 方案 + PT-073 审计     (已完成建档)
Wave 1  成本路由        PR-PP-002 + PR-P2-003                    (~1–2w) ← 可立即开工
Wave 2  定价基础        PR-P2-001 µUSD                           (~1w)
Wave 3  计费闭环        PR-P2-004                                  (~2w)
Wave 4  BYOK            PR-P2-002                                  (~2w，可与 Wave 3 部分重叠)
Wave 5  合同 / Pack     PR-PP-001                                  (并行，低优先级)
Wave 6  智能路由 GA     PR-P2-005                                  (软门控 PT-073)
Wave 7  Enterprise 占位 PR-P2-006                                  (Phase 2 末)
```

**后台并行**：PT-073 差距收口（见 `ai-protocol/PT-073-GAP-AUDIT_2026-06.md`），不阻塞 Wave 1–4。

---

## 5. 任务包摘要

### Wave 1 — 成本路由（PR-PP-002 + PR-P2-003）

| Block | 内容 |
|-------|------|
| R1 | `CostRoutingStrategy` in prism-core：读外部 pricing YAML，健康过滤 + 最低价 |
| R2 | 集成测试：mock health → 断言 provider 选择 |
| R3 | `POST /v1/route/decide` in ai-lib-gateway（对齐 Vela `SMART_ROUTING.md`） |
| R4 | 文档：**NOT PRODUCTION SLA** 警告 |

实现细节：[docs/PR-PP-002-IMPLEMENTATION.md](./docs/PR-PP-002-IMPLEMENTATION.md)

### Wave 2 — µUSD（PR-P2-001）

| Block | 内容 |
|-------|------|
| R1 | `UsageRecord` / API 边界迁 `cost_micro_usd: i64` |
| R2 | Pricer 内部整数运算；对外可选保留 `cost_usd` 只读换算 |
| R3 | 迁移测试 + admin usage JSON 兼容说明 |

### Wave 3 — 按量计费（PR-P2-004）

| Block | 内容 |
|-------|------|
| R1 | margin 配置（YAML/TOML）：provider 成本 + 平台费 |
| R2 | 用户维度用量累计（复用 PR-P1-011 quota 基础设施） |
| R3 | Admin 查询 + 超限 UX 钩子（Eos EOS-P2-004 可复用） |

### Wave 4 — BYOK（PR-P2-002）

| Block | 内容 |
|-------|------|
| R1 | 用户级 Key 存储（加密 at rest 设计占位） |
| R2 | 路由时优先 BYOK pool，fallback 托管 Key |
| R3 | Admin / 自助注册 API 草案 |

### Wave 6 — 智能路由 GA（PR-P2-005）

| Block | 内容 |
|-------|------|
| R1 | `optimize`: cost \| latency \| balanced 策略 |
| R2 | 接入 `/admin/health` 延迟信号 |
| R3 | （可选，PT-073 后）ExecutionMetadata / Contact 路由提示 |
| R4 | Vela `isSmartRoutingLive()` 门控 flip 条件文档化 |

---

## 6. 验收原则

- 每任务独立 PR → **Spider 审查后合并**（Cursor 不自 merge）
- 关闭前：`executor_name` + `executor_terminal` + `merge_commit` 回填 `lan`
- PR-PP-002 / 路由示例：代码与文档必须含 **NOT PRODUCTION SLA**
- 不将 PT-073 未完成作为 Wave 1–4 的阻塞理由

---

## 7. 仓库落点

| 组件 | 仓库 | Band |
|------|------|------|
| prism-core 路由/计费库 | `hiddenpath/eos/crates/prism-core` → `ailib-official/prism-core` | A |
| Gateway HTTP 壳 | `ailib-official/ai-lib-gateway` | C（产品壳） |
| Pack schema 草案 | `ai-protocol` 或 prism docs | A |

---

## 8. 文档索引

| 文档 | 说明 |
|------|------|
| [PRISM_P2_PT073_GATE_ANALYSIS_2026-06.md](./PRISM_P2_PT073_GATE_ANALYSIS_2026-06.md) | 门控对照分析 |
| [docs/PR-PP-002-IMPLEMENTATION.md](./docs/PR-PP-002-IMPLEMENTATION.md) | 成本路由 + decide API |
| [../ai-protocol/PT-073-GAP-AUDIT_2026-06.md](../ai-protocol/PT-073-GAP-AUDIT_2026-06.md) | PT-073 差距 |
| [NEAR_TERM_EXECUTION_2026-06-P1.md](./NEAR_TERM_EXECUTION_2026-06-P1.md) | P1 排期（已完成） |
