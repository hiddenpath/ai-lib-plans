# Eos（逸思）Phase 2 — 产品化开发计划

> **版本**: v1.0  
> **日期**: 2026-06-04  
> **前置**: Phase 1 ✅、EOS-P2-001（上下文工程）✅、EOS-ARCH-001（区域合规）✅  
> **协调文档**: [NEAR_TERM_EXECUTION_2026-06-P2.md](./NEAR_TERM_EXECUTION_2026-06-P2.md)（与 Prism P1 边界）  
> **真源索引**: [TASKS_INDEX.md](./TASKS_INDEX.md)

---

## 1. Phase 2 范围定义

Phase 2 在 `project-overview.md` 中的产品目标：

| 能力域 | 说明 | 任务 ID |
|--------|------|---------|
| **用户身份** | 注册、登录、会话、账号安全 | EOS-P2-002 |
| **云历史同步** | 多设备对话恢复；服务端仅存密文（BIZ-004） | EOS-P2-003 |
| **免费 tier** | 注册用户配额、用量可见、超限 UX | EOS-P2-004 |
| **Prism 协调** | 可选迁网关/智能路由；**不**阻塞 Prism P1 | EOS-P2-005 |
| **功能增强** | PDF/多图上传、Anthropic、WASM fallback 复评 | EOS-P2-006 |
| **文档能力路由** | 退役 `pdf_extract` 权宜路径；Document block + 能力路由 | EOS-P2-007（依赖 ALR-DOC-001） |
| **上下文进阶** | 消息分层、外部文档化（Phase 2.5） | EOS-CX-001/002 |

**已完成、不计入本计划交付：**

- EOS-P2-001 — SessionMirror + ALR 组装管线（milestone `eos-phase2-context`）
- EOS-ARCH-001 — 区域合规双入口

**前置债务（Phase 2 启动前建议关闭）：**

- EOS-CI-001 — compliance CI 路径修复

---

## 2. 与 Prism 启动阶段的协调矩阵

> 遵守 `prism/NEAR_TERM_EXECUTION_2026-06-P1.md`：**Prism P1 不改 Eos `/api/proxy`**；香港 `eos.ailib.info` ≠ Prism 生产。

| Eos Phase 2 任务 | 依赖的 Prism 任务 | 门控 | 协调原则 |
|------------------|-------------------|------|----------|
| **EOS-P2-004** 免费 tier / 配额 | PR-P1-011 ✅（库层 quota） | **PR-P1-014** admin HTTP 或 eos-server 内嵌同等逻辑 | 复用 `prism-core` A-band；不等待 `ai-lib-gateway` 生产上线即可在 eos-server 试点 |
| **EOS-P2-005** Prism 集成 | PR-P1-002 `/v1/*`、PR-P1-008 5-provider E2E | **P1-B 本地/CI 通过** 后再开集成设计；生产联调需 **P1-C**（006/013） | 集成形态二选一：前端指 `api.prism.ailib.info`，或 eos-server 新增并行 `/v1` 壳；**禁止**把 Prism P1 验收绑在香港 Eos 机 |
| **EOS-P2-005** 智能路由 | PT-073、PR-PP-002、Prism Phase 2 billing | Prism Phase 2 门 | 仅设计占位，不进入 Phase 2 必交付 |
| **EOS-P2-003** 云同步 | Vela E2E sync B-band 客户端（远期） | 可与 Vela Phase 2 共享 crypto 协议 | 服务端零知识：仅存 ciphertext；密钥不出浏览器（BIZ-004） |
| **EOS-CI-001** | 无 | 与 Prism P1 并行 | 独立负责人，不进 Prism 关键路径 |

**Prism P1 进行中时 Eos 可并行：**

- EOS-P2-002（用户系统）— 纯 Eos 产品层，无 Prism 硬依赖  
- EOS-P2-003 设计阶段 — crypto 协议文档可与 Vela 对齐  
- EOS-P2-006（文件增强）— 独立功能块  

**Prism P1 完成前不建议启动：**

- EOS-P2-005 生产联调、EOS-P2-004 与 Prism 托管计费的商业闭环  

---

## 3. 任务包与建议排期

```text
Wave 0  债务          EOS-CI-001                    (~2–3d)
Wave 1  身份          EOS-P2-002                    (~2w)
Wave 2  同步+配额     EOS-P2-003 + EOS-P2-004       (~3–4w，003 可与 002 部分重叠)
Wave 3  集成          EOS-P2-005                    (门控：Prism P1-B/C)
Wave 4  增强          EOS-P2-006                    (与 Wave 2–3 并行；R1 为权宜技术债)
Wave 5  文档路由      EOS-P2-007 ✅                 (#24 ea62ebb；见 document-capability-routing.md)
Wave 6  上下文 2.5    EOS-CX-001 → EOS-CX-002       (Phase 2 末 / Phase 2.5)
```

### Wave 1 — 用户身份（EOS-P2-002）

| Block | 内容 |
|-------|------|
| R1 | 用户模型 + 持久化（SQLite/Postgres 选型） |
| R2 | 注册 API（邮箱 + 密码，强度校验） |
| R3 | 登录 / JWT 或 session cookie + 刷新 |
| R4 | 前端登录/注册 UI + 登出 |
| R5 | 匿名会话可选迁移至登录账号 |

### Wave 2a — 云历史同步（EOS-P2-003）

| Block | 内容 |
|-------|------|
| R1 | E2E 同步协议设计（与 Vela B-band 对齐） |
| R2 | 密文 blob 存储 API（`POST/GET /api/sync/*`） |
| R3 | SessionMirror → 加密导出 / 导入 |
| R4 | 冲突策略（LWW 或版本向量，文档化） |
| R5 | 对话列表 UI + 跨设备恢复 |

### Wave 2b — 免费 tier（EOS-P2-004）

| Block | 内容 |
|-------|------|
| R1 | 产品 tier 定义（日/月 token 或请求数上限） |
| R2 | 接入 `prism-core` `authorize_with_quota`（按 user_id） |
| R3 | 认证用户配额 vs 匿名 IP 限流分层 |
| R4 | 用量展示 + 超限友好提示 |

### Wave 3 — Prism 集成（EOS-P2-005，可选/门控）

| Block | 内容 |
|-------|------|
| R1 | 集成方案 ADR（直连 Provider vs Prism `/v1`） |
| R2 | 最小 POC：本地 gateway 或 mock |
| R3 | 生产切换 runbook（**不在 Prism P1 排期内**） |
| R4 | 智能路由占位（依赖 PT-073，Phase 2 非必交付） |

### Wave 4 — 功能增强（EOS-P2-006）

| Block | 内容 |
|-------|------|
| R1 | PDF/纯文本文件上传（**权宜**：`pdf_extract` + 文本注入；出路见 EOS-P2-007） |
| R2 | 多图拖拽上传 |
| R3 | Anthropic Messages 路径启用 |
| R4 | 非 WASM fallback 复评（EOS-P0 豁免项） |

### Wave 5 — 文档能力路由（EOS-P2-007）

| Block | 内容 |
|-------|------|
| R1 | upload 返回 `document_ref`（PDF 不再默认 extract） |
| R2 | Document block + 模型 `document_understanding` 校验与显式降级 UX |
| R3 | 经 `/v1`/proxy 发送厂商原生 document 载荷 |
| R4 | 退役 `pdf_extract` 主路径 + E2E |

**上游**: `ALR-DOC-001`（ai-lib-rust）。**协调真源**: [`../../document-capability-routing.md`](../../document-capability-routing.md)。

### Wave 6 — 上下文 2.5（EOS-CX-001/002）

见 `CONTEXT_ARCHITECTURE_V2.md`；依赖 EOS-P2-001 与 OPFS 持久化（EOS-P2-003 R3 可复用存储层）。

---

## 4. 里程碑

| 里程碑 | 验收标准 | 目标 |
|--------|----------|------|
| **M6: Accounts** | 注册/登录/登出 E2E | Wave 1 末 |
| **M7: Sync** | 两浏览器同账号恢复同一对话 | Wave 2a 末 |
| **M8: Free tier** | 配额耗尽返回明确错误 + UI 提示 | Wave 2b 末 |
| **M9: Prism-ready** | ADR + 本地 POC（若开 Wave 3） | Prism P1-B 后 |
| **M10: Feature+** | PDF 上传 + 多图（权宜路径） | Wave 4 |
| **M11: Doc-route** | Document block + 能力路由；无静默 extract | ✅ #24 `ea62ebb` (2026-06-29) |
| **M5**（延续） | CX-001/002 | Phase 2.5 |

---

## 5. 架构约束（必须遵守）

1. **BIZ-004**：P 层 / eos-server **不存明文对话**；云同步仅 ciphertext blob。  
2. **BIZ-002**：`prism-core` 配额逻辑 A-band 复用；Eos 产品策略 C-band。  
3. **NEAR_TERM Prism P1**：不改现有 `/api/proxy` 契约作为 Prism 交付物；集成走独立路径或新端点。  
4. **EOS-ARCH-001**：登录用户仍按入口 region 过滤模型；同步数据 residency 在 ADR 中声明。  

---

## 6. 相关文档

- `project-overview.md` — Phase 2 产品一句话目标  
- `CONTEXT_STRATEGY_BOUNDARY.md` — 上下文分层边界  
- `CONTEXT_ARCHITECTURE_V2.md` — CX-001/002 设计  
- `COMPLIANCE_REGIONAL_ROUTING.md` — 区域合规  
- `../prism/NEAR_TERM_EXECUTION_2026-06-P1.md` — Prism P1 边界  
- `../prism/TASKS_INDEX.md` — Prism 任务真源
- `../../document-capability-routing.md` — 文档能力路由跨项目演进
- `docs/EOS-DOC-001-document-capability-routing.md` — Eos ADR  
