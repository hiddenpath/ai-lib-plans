# EOS-P2-005 — Eos × Prism 集成方案 ADR

**日期**：2026-06-25  
**状态**：已采纳（R1）  
**任务**：`tasks/EOS-P2-005-prism-integration.yaml`  
**关联**：`COMPLIANCE_REGIONAL_ROUTING.md`、`brand-rationale.md`、`../prism/docs/PHASE2_CLOSEOUT_2026-06.md`

---

## 1. 背景

Prism Phase 1（`/v1/*` 代理）与 Phase 2（µUSD、BYOK、智能路由 `/v1/route/decide`）已在 `api.prism.ailib.info` 交付。Vela 作为 A 层客户端已完成 `POST /v1/route/decide` 接线（vela #11）。

Eos 是 To C 消费者网站（`eos.ailib.info`），当前聊天走 **eos-server `/api/proxy`**，网关逻辑复用 workspace 内 `prism-core`。Phase 2 需决定：是否、以及如何与 Prism 生产网关对齐，同时遵守：

- **不改** 现网 `/api/proxy` 契约作为 Prism 团队交付物（Prism P1 边界）
- **EOS-ARCH-001**：zh-cn / global 双入口区域滤镜仍在 P 层执行
- **BIZ-004**：eos-server 不存明文对话；云同步仅密文 blob

---

## 2. 候选方案

| 方案 | 描述 | 适用产品 |
|------|------|----------|
| **A — 前端直调 Prism** | 浏览器持 Bearer 调 `api.prism.ailib.info/v1/*` | Vela（用户自带 gateway key） |
| **B — eos-server `/v1` 壳** | 前端仍调同源 eos-server；新增 OpenAI 兼容 `/v1/chat/completions` 等，内部 `prism-core` 或转发 Prism | **Eos（平台代管密钥）** |
| **C — 双路径并行** | `/api/proxy` 保留；新会话可选 `/v1`；灰度切换 | 迁移过渡期 |

---

## 3. 决策

### 3.1 主路径：**方案 B**（eos-server 并行 `/v1` 壳）

**理由：**

1. **密钥与计费**：Eos 免费 tier / 平台 key pool 必须在服务端；不能把 gateway key 暴露给浏览器（与 Vela BYOK 模型不同）。
2. **合规落点**：`route_with_region`、模型 allowlist、Contact 元数据注入已在 `eos-server` P 层；直调 Prism 会绕过区域滤镜 unless 额外网关策略 — 风险高、责任边界模糊。
3. **代码复用**：`eos-server` 已声明由 `prism-core` 驱动；与 `ai-lib-gateway` 同模式，POC 可对照 gateway 行为。
4. **Prism P1 边界**：保留 `/api/proxy` 不动；`/v1` 为**新增**端点，不修改 Prism 验收范围。

**方案 A** 仅作为 **EOS-REQ-P2-001** 远期选项（高级用户 BYOK 插件场景），**不**作为 Eos 主站默认路径。

### 3.2 迁移策略：**方案 C 的子集**

| 阶段 | 行为 |
|------|------|
| **现网** | `/api/proxy` + `/api/proxy/stream` 不变 |
| **R2 POC** | 本地/CI：`eos-server` 挂载 `/v1/chat/completions`（+ stream），对 `ai-lib-gateway` 或内嵌 `prism-core` smoke |
| **R3 生产** | 灰度：新前端 flag `useOpenAiV1=true` 指向 `/v1/*`；回滚切回 proxy；需 owner 确认香港 VPS 与 Prism 生产拓扑 |

---

## 4. 认证模型

| 层级 | Eos 现网 | Prism 集成后 |
|------|----------|--------------|
| **用户 → eos-server** | Session / cookie（EOS-P2-002） | 不变 |
| **eos-server → Provider** | 平台 key pool（`prism-core`） | 同左；可选 BYOK 模块（Prism P2 ✅）按用户绑定 |
| **用户 → Prism 直连** | 不适用 | 仅 EOS-REQ-P2-001 远期 BYOK 场景 |

配额与 usage：`prism-core` A-band 计数 + eos-server C-band 产品策略（日限额 UX）。

---

## 5. 区域合规继承（EOS-ARCH）

集成 `/v1` 时 **必须** 在 eos-server 请求进入 `prism-core` 转发前：

1. 解析入口 region（`zh-cn` | `global`）— 与现网一致  
2. 应用 `compliance` 模块模型 allowlist（已备案 vs 全球）  
3. 拒绝或降级未授权模型（HTTP 403 + 明确错误码）  
4. 同步数据 residency：对话内容不落库明文（BIZ-004）；仅 sync blob 存储策略见 `COMPLIANCE_REGIONAL_ROUTING.md` §5  

Prism 网关层的 pack/compliance 模板（Phase 3）可作为**补充**，不替代 Eos P 层滤镜。

---

## 6. 智能路由（R4 占位，非必交付）

| 项 | 说明 |
|----|------|
| **依赖** | PT-073（Contact 富化）、Prism P2 `/v1/route/decide` ✅ |
| **Eos 形态** | eos-server 可选代理 `POST /v1/route/decide`；前端 **不**直调 Prism（同 §3） |
| **参考实现** | Vela `decideRoute.ts` + debounced hook；Eos 可在服务端 decide 后注入 `model` 字段 |
| **SLA** | 与 gateway 一致：**非生产 SLA**，cost/latency/balanced 为 best-effort |

R4 在 R2 POC 通过后文档化接口即可；不阻塞 M9（ADR + POC）。

---

## 7. 依赖与门控（2026-06-25 更新）

| 依赖 | 状态 | 对 Eos 的影响 |
|------|------|---------------|
| PR-P1-002 `/v1` core | ✅ | R2 可开 |
| PR-P1-008 provider smoke | ✅ | R2 证据模板 |
| PR-P1-006 / PR-P1-013 生产 | ✅ `api.prism.ailib.info` | R3 **技术** unblock；仍须 owner 灰度审批 |
| Prism Phase 2 smart routing | ✅ | R4 占位可写 |
| PT-073 | 并行 | 软依赖，不阻塞 R2 |

**香港 `eos.ailib.info` ≠ Prism 生产验收环境** — R3 runbook 须写明 Eos VPS 与 Prism VPS 独立，仅 API 级联调。

---

## 8. 验收与后续任务

| Block | 交付物 | 状态 |
|-------|--------|------|
| **R1** | 本文 ADR | ✅ |
| **R2** | 本地/CI curl：`/v1/chat/completions` 经 eos 或 gateway | open |
| **R3** | 生产灰度 runbook（回滚、密钥轮换） | open，门控 owner |
| **R4** | 智能路由接口预期（§6） | open（文档） |

---

## 9. 相关文档

- `../prism/docs/COST_ROUTING.md`（gateway）
- `crates/prism-core/DESIGN.md`（eos 仓库）
- Vela `SMART_ROUTING.md` + PR-V2-006
