# VelaClaw — 项目概览

> **公开仓**：`ailib-official/velaclaw`（Rust agent 产品）  
> **Plans 真源**：本目录（内网 `lan` only，DOC-002）

## 定位

- **Rust-only** 桌面/CLI agent（Claw 生态）— **SKU 独立于 Vela Web**（见 `VELACLAW_PRODUCT_ALIGNMENT_2026-06.md`）
- **BYOK 永远直连** provider（`ai-lib-rust` + `ai-protocol`）
- **陌生 provider** → 进程内嵌 `prism-core` router（非 HTTP Gateway 客户端）
- **不** 服务 Python/TS agent SDK 需求（各语言用 `ai-lib-*` 自建 agent）

## 文档索引

| 文档 | 用途 |
|------|------|
| [VL-ARCH-001-execution-strategy-boundary.md](./VL-ARCH-001-execution-strategy-boundary.md) | 架构决策 ADR |
| [VELACLAW_PRODUCT_ALIGNMENT_2026-06.md](./VELACLAW_PRODUCT_ALIGNMENT_2026-06.md) | 与三品牌/Prism/Vela 总体规划对照 |
| [VELACLAW_PHASE_EVO_PLAN_2026-06.md](./VELACLAW_PHASE_EVO_PLAN_2026-06.md) | 下一阶段演进计划 |
| [TASKS_INDEX.md](./TASKS_INDEX.md) | 任务队列 |
| [docs/TRIAL_READINESS_SMOKE.md](./docs/TRIAL_READINESS_SMOKE.md) | 维护者冒烟（内网） |
| [ZEROSPIDER_AI_LIB_MIGRATION_PLAN.md](./ZEROSPIDER_AI_LIB_MIGRATION_PLAN.md) | 历史：ZS-ML 迁移（已完成） |

## 当前阶段

| 里程碑 | 状态 |
|--------|------|
| ZS-ML / ZS-RN | ✅ completed |
| VL-TRIAL-001 | ✅ completed（Linux smoke 待执行） |
| VL-EVO-001 ~ 004 | draft — 下一阶段 |

## 跨项目

- **Prism**：PR-P1-016 跟踪 VelaClaw 内嵌 prism-core（`active/projects/prism/docs/VELACLAW_MIGRATION_STAGES.md`）
- **ai-protocol**：provider manifest 消费方
- **ai-lib-gateway**：独立 HTTP 产品；**不是** VelaClaw 默认执行路径
