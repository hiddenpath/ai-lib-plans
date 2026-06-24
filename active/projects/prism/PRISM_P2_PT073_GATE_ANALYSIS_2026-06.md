# Prism Phase 2 × PT-073 门控分析（对照文档）

> **版本**: v1.0  
> **日期**: 2026-06-22  
> **用途**: 回头对照 — Vela PR-V2-004、Eos EOS-P2-005、Prism P2 启动决策  
> **真源**: 本分析不替代任务 YAML；以 [TASKS_INDEX.md](./TASKS_INDEX.md) 与各 `tasks/*.yaml` 为准

---

## 1. 版本哲学（2026-06-22 确认）

| 原则 | 说明 |
|------|------|
| **1.0 之前允许多个可用版本** | 0.x 可持续 patch 发布；功能可在未达 v1.0 时逐步上线、迭代优化 |
| **PT-073 是里程碑目标，不是阶段起点** | Prism P2、Vela 智能路由、成本示例等 **不必等 PT-073 开工**；PT-073 完成 = 协议层「v1.0 就绪」证据齐备 + maintainer 可决策发版 |
| **门控是产品保守策略，不是工程硬阻塞** | `smartRouting.ts` 三门控可同时 false，但 PR-PP-002、billing 草案可并行推进 |

来源：`memory/conventions.md`（pre-v1.0 patch-only）、`PT-073` YAML §description（readiness ≠ auto-bump）、用户 2026-06-22 指令。

---

## 2. 三门控映射

Vela `apps/web/src/lib/smartRouting.ts` 与下游消费方（Eos EOS-REQ-P2-003）共用下列门控语义：

| 门控字段 | 任务 / 决策 | 仓库 | 当前状态 |
|----------|-------------|------|----------|
| `pt073ProtocolRc` | **PT-073** | ai-protocol + 四运行时 | `in_progress` — subset CI 绿，full-matrix / 治理项未闭 |
| `prPp002CostRouting` | **PR-PP-002** | prism-core + ai-lib-gateway | `open` — **P1 前置已满足**，可立即实施 |
| `prismPhase2Billing` | **PR-P2-004**（草案）等 | prism-core + gateway | 无任务 YAML → 见 [PHASE2_PLAN.md](./PHASE2_PLAN.md) |

**关键结论**：只有「依赖 Contact API / ExecutionMetadata 的策略路由增强」才 **强依赖** PT-073；**成本比较 + `/v1/route/decide` 示例**可走现有 prism-core libcurl + Pricer 路径，与 P1 架构一致（D6）。

---

## 3. 现状快照（2026-06-22）

### Prism Phase 1 — 已完成

- M1 库层、M2 产品 API、M3 生产（`api.prism.ailib.info`）均在 [TASKS_INDEX.md](./TASKS_INDEX.md) 标 ✅
- 已有能力：`FallbackRouter`（健康 + fallback）、`Pricer`（静态定价）、`/v1/chat/completions`、`/admin/health`

### Prism Phase 2 — 规划前空白

- `project-overview.md` 定义范围：Smart routing + BYOK + Billing + Enterprise MVP（6–8 周）
- **此前无** `PHASE2_PLAN.md`、无 `PR-P2-*` 任务 → 本次补齐

### PT-073 — 后台里程碑轨道

- PT-068–072（E/P 拆分）已闭
- WASM 合规有证据（~1.24MB、wasmtime harness）
- Python/TS 为 **E-only subset** CI，非 full `tests/compliance/`
- v1.0.0 tag 需 maintainer 显式批准

---

## 4. 依赖关系图

```text
                    ┌─────────────────────────────────────┐
                    │  PT-073（里程碑，并行后台）          │
                    │  full-matrix CI / 迁移文档 / 治理    │
                    └──────────────┬──────────────────────┘
                                   │ 增强（非阻塞起步）
                                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────────┐
│ PR-PP-002    │───▶│ PR-P2-003    │───▶│ Vela decide 接线  │
│ 成本路由库    │    │ /v1/route/   │    │ smartRouting 门控 │
│ prism-core   │    │ decide HTTP  │    └──────────────────┘
└──────────────┘    └──────────────┘
        │                    │
        ▼                    ▼
┌──────────────┐    ┌──────────────┐
│ PR-P2-001    │    │ PR-P2-004    │
│ µUSD 迁移    │───▶│ 按量 billing │
└──────────────┘    └──────────────┘
                           │
┌──────────────┐           ▼
│ PR-P2-002    │    ┌──────────────┐
│ BYOK         │    │ PR-P2-005    │◀── PT-073 后可选 ai-lib-core 集成
└──────────────┘    │ 智能路由 GA   │
                    └──────────────┘
```

---

## 5. 建议执行顺序（与 PHASE2_PLAN 对齐）

| 序 | 轨道 | 可开始 | 说明 |
|----|------|--------|------|
| 1 | PR-PP-002 + PR-P2-003 | **立即** | 库 + HTTP；不依赖 PT-073 |
| 2 | PR-P2-001 → PR-P2-004 | P2 第 2–3 周 | billing 门控；µUSD 为先决 |
| 3 | PR-P2-002 BYOK | 与 billing 部分重叠 | 商业 Phase 2 热点之一 |
| 4 | PT-073 差距收口 | 并行后台 | 见 `ai-protocol/PT-073-GAP-AUDIT_2026-06.md` |
| 5 | PR-P2-005 + Vela 门控 flip | PP-002 + billing 后 | PT-073 增强项可后续迭代 |

---

## 6. 相关文档索引

| 文档 | 路径 |
|------|------|
| Phase 2 计划 | [PHASE2_PLAN.md](./PHASE2_PLAN.md) |
| PR-PP-002 实现方案 | [docs/PR-PP-002-IMPLEMENTATION.md](./docs/PR-PP-002-IMPLEMENTATION.md) |
| PT-073 差距审计 | [../ai-protocol/PT-073-GAP-AUDIT_2026-06.md](../ai-protocol/PT-073-GAP-AUDIT_2026-06.md) |
| Vela 智能路由占位 | vela `apps/web/docs/SMART_ROUTING.md` |
| Wave-5 检查清单 | ai-protocol `docs/WAVE5_V1_GATE_CHECKLIST.md` |

---

## 7. 决策记录（待 maintainer 确认）

- [ ] Prism P2 Wave 1 是否以 PR-PP-002 为首个研发 PR（建议：是）
- [ ] `/v1/route/decide` 是否纳入 gateway Bearer 与 `/v1/*` 同鉴权（建议：是）
- [ ] billing 首版是否仅 admin 可见用量 + 静态 margin（建议：是，对齐 D3）
- [ ] PT-073 达标后是否立即打 v1.0.0，或继续 0.x 功能迭代（maintainer 决策）
