# Prism 近期执行排期 — 2026-06 / Phase P1

> **版本**: 2026-06-04  
> **阶段标志**: **P1**（Prism 产品 API + 库补齐；**不含** Eos 基础设施与 proxy 路径改造）  
> **前置邮件**: 需你线下完成的事项见 `tools/outbox/EMAIL_manual-prerequisites_2026-06-04_prism-p1.txt`（已尝试通过 `email_skill` 发送）

---

## 边界（必须遵守）

### 1. Eos 与 ai-lib 产品解耦

| 范围 | 说明 |
|------|------|
| **Eos `eos-server` proxy 路径**（`/api/proxy` 等） | **始终在 ai-lib 产品规划之外**。不在本排期中改路由、不绑 Prism 验收、不把腾讯香港现网当作 Prism 生产目标。 |
| **有需求时** | 仅在本仓或 `ai-lib-plans` 记录 **需求清单**（接口/行为/环境），由你 **另行安排** 执行，研发任务 YAML **不** 写「改 Eos proxy」。 |
| **腾讯香港 `eos.ailib.info`** | **临时/开发部署**，≠ Prism 未来生产环境。Docker/Caddy/DNS/密钥轮换等 **基础设施** 不写入 Prism 产品任务验收。 |

### 2. Prism Phase P1 代码落点

| 组件 | 仓库 | 说明 |
|------|------|------|
| **prism-core**（库） | `hiddenpath/eos/crates/prism-core`（当前）；发布后 `ailib-official/prism-core` | 009/010/011 等库任务 |
| **Prism 产品 HTTP 壳** | **`ailib-official/ai-lib-gateway`**（主）；与 Eos 无 proxy 路径耦合 | 001/002/014；新建 Axum，OpenAI `/v1/*` |
| **生产部署** | **未来生产主机**（待你确认，见邮件） | 006/013 仅在对生产环境决策后执行 |

### 3. 与 Eos 产品线的关系

- **Eos Phase 1/2** 在 plans 中已 **completed**；维护项 **EOS-CI-001** 独立排期，**不** 进入 Prism P1 关键路径。  
- **Eos 迁 Prism API**（若将来需要）单独立项，**不** 在本 P1 排期内。

---

## 现状（2026-06-04）

| 里程碑 | 状态 |
|--------|------|
| M1 库层 | ✅ prism-core `cargo test --features full` 45 passed |
| M2 产品 API | ⏳ `ai-lib-gateway` 仍为占位 |
| M3 生产 | ⏳ 阻塞于生产环境与 DNS（线下） |

---

## 排期总览

```text
P1-A  治理 + 库补齐     (~1–2 周)   不依赖生产 VPS
P1-B  Gateway 产品壳    (~2 周)     ai-lib-gateway，本地/CI 验收
P1-C  生产与外网 E2E    (T+0 起)    仅在你完成邮件中的前置项之后启动
P1-D  加固与生态        (并行/延后) quota、crates.io、Vela、PT-073
```

---

## P1-A — 治理与库层（第 1–2 周）

| 序 | 任务 ID | 工作项 | 仓库 | 依赖 |
|----|---------|--------|------|------|
| A1 | **PR-PP-003** | 修订 BIZ-002：prism-core = A-band | `ai-lib-constitution` | — |
| A2 | **PR-P1-009** | TOML `config.toml` + `ConfigProvider` | `prism-core` | — |
| A3 | **PR-P1-010** | Anthropic Messages 适配 | `prism-core` | A2 可并行 |
| A4 | **PR-P1-011** | Quota 日/月限额 enforce | `prism-core` | 库 004 已完成 |

**出口**: 库测试保持全绿；010 有单测或集成脚本 evidence。

---

## P1-B — Gateway 产品壳（第 2–4 周）

> **禁止**: 修改 Eos `/api/proxy` 或复用香港 Eos 部署作为 Prism 验收环境。

| 序 | 任务 ID | 工作项 | 仓库 | 依赖 |
|----|---------|--------|------|------|
| B1 | **PR-P1-001** | Workspace：`prism-core` 依赖 + `/health` + 加载 TOML | `ai-lib-gateway` | A2 |
| B2 | **PR-P1-002** | `POST /v1/chat/completions`、`GET /v1/models`、SSE、Bearer | `ai-lib-gateway` | B1, A3 |
| B3 | **PR-P1-014** | `/admin/*` 绑定 AdminService | `ai-lib-gateway` | B1 |
| B4 | **PR-P1-008**（**本地/CI**） | 5 P0 smoke（对 **gateway 进程**，非 eos.ailib.info） | `ai-lib-gateway` + scripts | B2 |

**出口**: 本地 `curl` 通过 `/v1/*`；008 的 `testing.evidence` 注明 **local/CI only**。

---

## P1-C — 生产与外网（邮件前置完成后）

| 序 | 任务 ID | 工作项 | 阻塞 |
|----|---------|--------|------|
| C1 | **（线下）** | 生产 VPS、域名、密钥、TLS 策略 | 见邮件 checklist |
| C2 | **PR-P1-006** | Dockerfile + compose + Caddy（**生产主机**） | C1 |
| C3 | **PR-P1-013** | `api.prism.ailib.info` DNS | C1 |
| C4 | **PR-P1-008**（**外网**） | 5 provider 外网 E2E | C2, C3 |

**不在此阶段做**: 把香港 Eos 机当作 Prism 生产；不跑 `deploy_eos.sh` 作为 Prism 交付物。

---

## P1-D — 并行/延后

| 任务 ID | 说明 | 建议时间 |
|---------|------|----------|
| **EOS-CI-001** | Eos CI 债务 | 与 Prism 并行，独立负责人 |
| **PR-P1-012** | prism-core crates.io | P1-B 稳定 + P1-C 可选后 |
| **PR-P1-016** | VelaClaw 内嵌 prism-core（VL-EVO-*；非 HTTP Gateway 客户端） | P1-B 后 / 与 VL-EVO-001 并行 |
| **PR-V1-001~003** | Vela demo | 依赖 **P1-B** 的 `/v1` API，非 006 |
| **PT-073** | 协议 RC | 后台；Gate Phase 2 智能路由 |
| **PR-PP-001/002** | Pack / 成本示例 | P1-C 之后 |

---

## Eos Phase 2 协调（2026-06-04 建档）

Eos 产品 Phase 2 任务已补齐，见 `active/projects/eos/PHASE2_PLAN.md` 与 `NEAR_TERM_EXECUTION_2026-06-P2.md`。

| Eos 任务 | 与 Prism P1 关系 |
|----------|------------------|
| EOS-P2-002/003/006 | 无硬依赖，可与 P1-A/B 并行 |
| EOS-P2-004 免费 tier | 复用 **PR-P1-011** ✅；admin 可选 **PR-P1-014** |
| EOS-P2-005 集成 | 本地 POC 需 **PR-P1-002/008**；生产门控 **P1-C** |
| EOS-CI-001 | 与 P1 并行，不进 Prism 关键路径 |

**不变**：Prism P1 仍不改 Eos `/api/proxy`；香港机 ≠ Prism 生产。

## Eos 相关「仅需求清单」槽位（不排开发）

若你后续需要 Eos 侧配合，在此 **只记需求**，不生成耦合任务：

| 需求 ID | 描述 | 状态 |
|---------|------|------|
| EOS-REQ-P2-001 | Eos 前端改指向 `api.prism.ailib.info` | `deferred` — 见 EOS-P2-005 |
| EOS-REQ-P2-002 | E2E sync crypto 协议与 Vela 共享 | `deferred` — 见 EOS-P2-003 |
| EOS-REQ-P2-003 | 智能路由 auto 模式 | `deferred` — PT-073 + Prism Phase 2 |

---

## 本周 Top 5（研发）

1. PR-P1-009（TOML）  
2. PR-P1-001 + PR-P1-002（**ai-lib-gateway**）  
3. PR-P1-010（Anthropic）  
4. PR-PP-003（BIZ-002）  
5. PR-P1-008 本地 smoke 脚本骨架  

---

## 文档索引

- 任务真源：`TASKS_INDEX.md`  
- 审计报告：`ailib.info` 侧 `ai-lib-gateway/.doc/prism-plan-review-2026-06-04.md`（参考，非 plans 真源）  
- MEMORY.md § 2026-06-04 Prism 计划对齐  
