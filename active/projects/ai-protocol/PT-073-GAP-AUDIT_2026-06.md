# PT-073 剩余 Checklist 差距审计

> **版本**: v1.0  
> **日期**: 2026-06-22  
> **任务真源**: [tasks/PT-073-core-compliance-proof-v1-rc.yaml](./tasks/PT-073-core-compliance-proof-v1-rc.yaml)  
> **检查清单镜像**: `ai-protocol/docs/WAVE5_V1_GATE_CHECKLIST.md`  
> **定位**: PT-073 = **v1.0 就绪里程碑目标**（非 Prism P2 / 智能路由的阶段起点）

---

## 1. 审计方法

| 来源 | 说明 |
|------|------|
| WAVE5_V1_GATE_CHECKLIST.md | 逐项对照 |
| PT-073 YAML `completion_notes` | 2026-04-15 基线 |
| 各仓库 `.github/workflows/pt073-*.yml` | CI 实际覆盖范围 |
| [PRISM_P2_PT073_GATE_ANALYSIS_2026-06.md](../prism/PRISM_P2_PT073_GATE_ANALYSIS_2026-06.md) | 与产品门控关系 |

**图例**：✅ 有证据 | 🟡 部分 / subset | ❌ 未满足 | ⏳ 需 maintainer 决策

---

## 2. 分项差距

### §1 Core-only compliance（blocking）

| 项 | 状态 | 证据 / 差距 |
|----|------|-------------|
| Rust full compliance matrix | ✅ | `pt073-rust-core-wasm.yml` on main — `cargo test -p ai-lib-core` (incl. compliance_from_core); green run 2026-06-29 (`28364691515`) |
| Python **full** `pytest tests/compliance/` | ✅ | PR #4 merged `b30b831` — `pt073-python-full.yml` + `COMPLIANCE_SUBSET`；e_only 保留 `pt073-python-e-only.yml` |
| TypeScript **full** compliance | ✅ | PR #4 merged `324e67a` — `pt073-ts-full.yml` + `test:compliance:full`；E-only 保留 `pt073-ts-core.yml` |
| Go compliance PASS | ✅ | PR #2 merged `334ac74` — `pt073-go.yml`; green run 2026-06-29 (`28380766175`) |

**§1 状态（2026-06-29）：四运行时 full/subset CI 均已绿 — P0 收口完成。**

**收口动作（建议 PT-073a / PT-073 子项）**：

1. 新增或扩展 workflow：`pt073-python-full.yml` — `COMPLIANCE_SUBSET` 未设置或 `full`
2. 新增 `pt073-ts-full.yml` — 完整 vitest compliance matrix
3. Rust：将 `compliance_from_core` 纳入默认 `ci.yml` required check 或 pt073 workflow required
4. Go：在 checklist 附最近一次 green run URL

---

### §2 WASM compliance（blocking）

| 项 | 状态 | 证据 / 差距 |
|----|------|-------------|
| wasm32-wasip1 on CI runners | ✅ | `pt073-rust-core-wasm.yml` green 2026-06-29 (`28364691515`) |
| release build PASS | ✅ | 2026-04-03 证据 |
| Binary < 2 MB | ✅ | ~1.24 MB |
| Six exported functions | ✅ | PT-061 spec |
| wasmtime harness | ✅ | `ai-lib-wasmtime-harness` |

**收口动作**：将 §2 在 checklist 中勾选；确保 pt073 rust workflow 为 **required** status check。

---

### §3 E/P separation integrity（blocking）

| 项 | 状态 | 证据 / 差距 |
|----|------|-------------|
| No P-imports in core | 🟡 | Rust：`check_ep_boundary.py` 在 Python pt073 workflow；**TS/Python 扩展静态检查**未在 checklist 勾选 |
| ExecutionMetadata 四运行时 | 🟡 | 2026-04-05 审计修 3 项缺陷；需 **schema 对齐复验** `execution-metadata.json` |
| ai-lib-contact builds | 🟡 | Rust pt073 workflow 含 compile smoke；Python/TS contact 子包 **独立 evidence** 待补 |

**收口动作**：

1. 四仓库各附 EP boundary CI 日志链接
2. 跨运行时 ExecutionMetadata 快照测试（JSON golden）
3. contact 包 publish dry-run

---

### §4 Migration documentation（blocking）

| 项 | 状态 | 证据 / 差距 |
|----|------|-------------|
| CHANGELOG per runtime | ❌ | E/P 拆分后 import 路径变更需 **逐包** CHANGELOG |
| Downstream (spiderswitch) | ❌ | 需 issue 或 PR 跟踪 contact 迁移 |

**收口动作**：按 PT-073 release train 顺序起草 CHANGELOG 草稿（可先 0.x 迁移说明，不必等 tag）。

---

### §5 Governance gates（blocking）

| 项 | 状态 | 证据 / 差距 |
|----|------|-------------|
| drift:check | ❌ | 无近期 evidence |
| gate:fullchain | ❌ | required mode PASS 待跑 |
| Rollback drill | ❌ | evidence 过期或未刷新 |

**收口动作**：在 `ai-lib-constitution` / plans tools 跑一次并归档日志到 task `testing.evidence`。

---

### §6 Release（blocking for v1.0.0 tag only）

| 项 | 状态 | 说明 |
|----|------|------|
| Tag ai-protocol v1.0.0 | ⏳ | **需 maintainer 批准** — PT-073 就绪 ≠ 自动发版 |
| Release notes | ❌ | E/P + WASM + migration |
| ailib.info 更新 | ❌ | 新包结构 |
| MEMORY.md 决策记录 | ❌ | v1.0.0 timing |

**重要**：§1–§5 可在 **0.x 继续交付功能**；§6 仅在决定打 1.0.0 时 blocking。

---

## 3. 已完成基线（无需重复劳动）

| 项 | 状态 |
|----|------|
| PT-068 Rust core/contact split | ✅ |
| PT-069 Python split | ✅ |
| PT-070 TS split | ✅ |
| PT-071 Go verification | ✅ |
| PT-072 WASM build | ✅ |
| PT-074 unified credential chain | ✅（见 YAML） |
| Python/TS subset CI on main | ✅ 2026-04-15 merge |

---

## 4. 优先级排序（建议）

```text
P0  全矩阵 compliance 进 CI（Py/TS full）     → 最大 checklist 缺口
P0  Rust compliance required on main            → 已有 workflow，升格 required
P1  CHANGELOG + migration 草稿                  → 不阻塞 0.x 功能，阻塞 1.0 tag
P1  EP boundary 四语言 evidence 归档
P2  drift:check / fullchain / rollback
P3  Maintainer v1.0.0 决策 + release train      → 里程碑终点，非起点
```

---

## 5. 与 Prism P2 / Vela 的关系（避免误用门控）

| 误解 | 纠正 |
|------|------|
| 「PT-073 完成才能做 Prism P2」 | **错误** — P2 Wave 1（PR-PP-002）可立即开工 |
| 「PT-073 = 智能路由开始」 | **错误** — 智能路由示例不依赖 Contact API |
| 「PT-073 完成 = 自动 v1.0.0」 | **错误** — 仅为就绪证明 + maintainer 决策输入 |
| 「0.x 不能交付路由/decide」 | **错误** — 0.x 可持续优化可用版本 |

**软依赖 PT-073 的项**：PR-P2-005 可选 ai-lib-core 集成、Vela `pt073ProtocolRc` 门控、Contact 稳定度敏感策略。

---

## 6. 建议子任务拆分（可选录入 plans）

| 建议 ID | 标题 | 阻塞 |
|---------|------|------|
| PT-073a | Python full compliance CI | §1 |
| PT-073b | TypeScript full compliance CI | §1 |
| PT-073c | Migration CHANGELOG 四运行时 | §4 |
| PT-073d | Governance gates evidence | §5 |
| PT-073e | Maintainer v1.0.0 决策记录 | §6 |

---

## 7. 下一步

1. 在 `PT-073` YAML `completion_notes` 追加本审计摘要 + 日期（执行人回填时）。
2. 优先开 PR：**Python/TS full compliance workflow**（P0）。
3. Prism P2 Wave 1（PR-PP-002）**并行**，不等待 PT-073 P0 完成。

---

## 8. 参考

- `active/projects/ai-protocol/WAVE5_EP_SEPARATION_AND_V1_PLAN_2026-04-01.md`
- `memory/conventions.md` — pre-v1.0 versioning
- `memory/log.md` § Pre-v1.0 versioning and PT-073 scope
