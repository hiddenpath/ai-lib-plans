# Eos Phase 2 近期执行排期 — 2026-06

> **版本**: 2026-06-04  
> **阶段标志**: **Eos P2**（用户 + 同步 + 免费 tier）  
> **Prism 协调**: 必读 [../prism/NEAR_TERM_EXECUTION_2026-06-P1.md](../prism/NEAR_TERM_EXECUTION_2026-06-P1.md)

---

## 边界（与 Prism P1 对齐）

| 规则 | 说明 |
|------|------|
| **不改 Prism P1 范围** | Eos Phase 2 任务不得要求 Prism 团队修改 Eos `/api/proxy` 或把香港机作为 Prism 生产验收 |
| **库层复用** | 配额、usage、router 优先用 `hiddenpath/eos/crates/prism-core`（A-band） |
| **产品层在 eos-server** | 用户 DB、同步 blob 存储、登录 UI 均在 `hiddenpath/eos`（C-band） |
| **集成门控** | EOS-P2-005 生产联调 **blocked on** Prism P1-C（`PR-P1-006`/`013`/`008` 外网） |

---

## 现状（2026-06-04）

| 里程碑 | 状态 |
|--------|------|
| M1–M4 Phase 1 + 上下文工程 + 合规 | ✅ |
| EOS-CI-001 | ⏳ open |
| M6–M10 Phase 2 产品化 | 📋 任务已建档，未启动 |

---

## 排期总览

```text
P2-0  CI 债务           EOS-CI-001              与 Prism P1-A 并行
P2-1  用户身份           EOS-P2-002              无 Prism 硬依赖
P2-2  云同步 + 免费 tier  EOS-P2-003/004        004 依赖 002；004 库层依赖 PR-P1-011 ✅
P2-3  Prism 集成         EOS-P2-005              门控：Prism P1-B 设计 / P1-C 生产
P2-4  功能增强           EOS-P2-006              可与 P2-1/2 并行（R1 权宜技术债）
P2-5  文档能力路由       EOS-P2-007              门控：ALR-DOC-001
P2-6  上下文 2.5         EOS-CX-001/002          Phase 2 末或 2.5
```

---

## P2-1 — 用户身份（第 1–2 周）

| 序 | 任务 ID | 工作项 | 仓库 | Prism 依赖 |
|----|---------|--------|------|------------|
| 1 | **EOS-CI-001** | CI 绿 | `hiddenpath/eos` | 无（建议先做） |
| 2 | **EOS-P2-002** | 注册/登录/会话 | `eos-server` + static | 无 |

**出口**: Playwright 注册→登录→发消息 E2E。

---

## P2-2 — 同步与配额（第 3–6 周）

| 序 | 任务 ID | 工作项 | 仓库 | Prism 依赖 |
|----|---------|--------|------|------------|
| 1 | **EOS-P2-003** | E2E 云同步（密文） | `eos-server` + frontend | 协议可与 Vela 对齐；无 Prism 硬依赖 |
| 2 | **EOS-P2-004** | 免费 tier + 配额 | `eos-server` + `prism-core` | **PR-P1-011** ✅；admin 可选 **PR-P1-014** |

**出口**: 两设备恢复对话；免费用户触达日限额有明确 UX。

---

## P2-3 — Prism 集成（Prism P1-B 后可开设计，P1-C 后生产）

| 序 | 任务 ID | 工作项 | 阻塞 |
|----|---------|--------|------|
| 1 | **EOS-P2-005-R1** | 集成 ADR | Prism **PR-P1-002** 本地 `/v1` 可演示 |
| 2 | **EOS-P2-005-R2** | 本地 POC | **PR-P1-008** 本地 smoke |
| 3 | **EOS-P2-005-R3** | 生产切换 | **PR-P1-006/013** + 生产 VPS 决策 |

**不在此阶段做**: 要求 Prism 团队改 Eos 现网 proxy；不把 `deploy_eos.sh` 当作 Prism 交付。

---

## P2-4 — 功能增强（并行）

| 任务 ID | 说明 |
|---------|------|
| **EOS-P2-006** | PDF/多图/Anthropic/WASM fallback；R1 为权宜 `pdf_extract`，出路 **EOS-P2-007** |

---

## P2-5 — 文档能力路由（ALR-DOC-001 后）

| 任务 ID | 说明 |
|---------|------|
| **EOS-P2-007** | Document block + 能力路由；退役 pdf_extract 主路径 |
| **ALR-DOC-001** | ai-lib-rust Core 基建（上游） |

协调真源：`active/document-capability-routing.md`

---

## P2-6 — 上下文 2.5（延后）

| 任务 ID | 说明 |
|---------|------|
| **EOS-CX-001** | 消息 Priority 分层 |
| **EOS-CX-002** | 外部文档化与召回 |

---

## Prism ↔ Eos 需求槽位（仅记录，不耦合开发）

| 需求 ID | 描述 | 状态 | 触发条件 |
|---------|------|------|----------|
| EOS-REQ-P2-001 | Eos 前端可选指向 `api.prism.ailib.info` | `deferred` | EOS-P2-005 + Prism P1-C |
| EOS-REQ-P2-002 | 共享 E2E sync crypto 协议（Vela/Eos） | `deferred` | EOS-P2-003 R1 + Vela Phase 2 |
| EOS-REQ-P2-003 | 智能路由 auto 模式 | `completed` | eos #26+#27；document decide uplift |
| EOS-REQ-P2-004 | 文档能力路由（Document block + provider-native） | `completed` | EOS-P2-007 + PT-079 轨道 |

---

## 本周建议（若启动 Phase 2）

1. **EOS-CI-001** —  unblock 后续 PR  
2. **EOS-P2-002-R1/R2** — 用户模型 + 注册 API 设计评审  
3. 与 Prism 负责人确认：**EOS-P2-004** 是否等 **PR-P1-014** 还是 eos-server 内嵌 quota 管理  

---

## 文档索引

- 任务真源：`TASKS_INDEX.md`  
- 详细计划：`PHASE2_PLAN.md`  
- 文档能力路由：`../../document-capability-routing.md`  
- Prism 真源：`../prism/TASKS_INDEX.md`  
