# EOS-P2-006-R4 — 非 WASM Fallback 复评

**日期**：2026-06-27  
**状态**：已采纳 — **defer**（Phase 2 不实现）  
**任务**：`tasks/EOS-P2-006-feature-enhancements.yaml` R4  
**前置**：EOS-P0-001 R7 豁免（README 声明浏览器需 WASM）

---

## 1. 背景

Phase 1 明确：**无非 WASM 聊天降级**；WASM 负责 `build_chat_request`、错误分类、上下文 token 估算与 SessionMirror 组装。EOS-P0 将完整 JS 降级标为 Phase 2 复评项。

---

## 2. 候选方案

| 方案 | 描述 | 成本 | 收益 |
|------|------|------|------|
| **A — 纯 JS 客户端** | 在 `index.html` 复刻 WASM 请求构建 + 简易 token 估算 | 高（双实现、漂移风险） | 极老旧浏览器可用 |
| **B — 服务端 build_request** | `POST /api/chat/prepare` 由 eos-server 组装 OpenAI body | 中 | 去 WASM 依赖，违背「浏览器 上下文工程」边界 |
| **C — 维持 WASM 必需** | 加载失败显示明确错误 + 文档链接 | 低 | 与 EOS-P2-001 架构一致 |

---

## 3. 决策：**方案 C — defer 非 WASM fallback**

**理由：**

1. **架构边界**（`CONTEXT_STRATEGY_BOUNDARY.md`）：上下文组装在浏览器 A 层（WASM + SessionMirror）；服务端 fallback 会把 P2-001 能力迁回 C-band，与分层设计冲突。
2. **受众**：2026 年目标浏览器均支持 WASM；EOS-P0 README 已声明要求。
3. **维护**：双路径使 vitest/e2e 矩阵翻倍，收益低于 EOS-P2-006 R1/R2（PDF/多图）产品价值。
4. **可逆**：若 telemetry 显示 WASM 加载失败率 >1%，Phase 3 再开方案 B 的**最小**服务端 prepare 端点（仅 body 构建，不含 SessionMirror）。

---

## 4. 用户可见行为（维持现状）

- WASM 加载失败 → 系统消息提示刷新/换浏览器；**不**静默降级。
- `wasmError` UI 状态已存在（`index.html`）。

---

## 5. 验收

- [x] 决策记录本文档
- [x] EOS-P2-006-R4 标 `completed`
- [ ] 无需代码 PR（除非补充 README 一句指向本文档）

---

## 6. 相关

- `PHASE1_PLAN.md` § WASM vs 非 WASM
- `tasks/EOS-P0-001-prelaunch-hardening.yaml` R7
