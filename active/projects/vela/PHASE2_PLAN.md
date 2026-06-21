# Vela — Phase 2 产品化开发计划

> **版本**: v1.0  
> **日期**: 2026-06-21  
> **前置**: Phase 1 ✅（PR-V1-001/002/003）  
> **真源索引**: [TASKS_INDEX.md](./TASKS_INDEX.md)

---

## 1. Phase 2 范围（来自 project-overview.md）

| 能力域 | 说明 | 任务 ID | 门控 |
|--------|------|---------|------|
| **模型对比** | 同一 prompt 并行多模型，流式并排展示 | PR-V2-001 | 无 — Prism `/v1/*` 已 live |
| **E2E 云同步** | B-band 客户端；与 Eos 共享 crypto 协议（BIZ-004） | PR-V2-002 | 需 sync 后端（可先用 Eos `/api/sync` 或 Vela 自建） |
| **WASM 路由** | A-band 基础路由决策（客户端侧） | PR-V2-003 | `ailib-wasm-test` WASM 产物可嵌入 |
| **智能推荐** | 基于延迟/成本/历史的模型建议 | PR-V2-004 | Prism Phase 2 + PT-073（占位，Phase 2 末） |

**营销热点（Phase 2）**: 并排模型对比 + WASM routing demo。

---

## 2. 与 Prism / Eos 协调

| Vela 任务 | 依赖 | 原则 |
|-----------|------|------|
| PR-V2-001 | PR-V1-003 ✅ | 纯客户端；并行 `chat.completions` |
| PR-V2-002 | EOS-P2-003 ADR ✅ | 复用 AES-GCM + PBKDF2 信封；Vela IndexedDB export 为 payload |
| PR-V2-003 | ailib-wasm-test | 嵌入 `wasm-browser`；不依赖 ai-lib-gateway 变更 |
| PR-V2-004 | PT-073, PR-PP-002 | 设计占位；不阻塞 Wave 1–2 |

**Vela ≠ Eos**：Vela 走 `api.prism.ailib.info`；Eos 走 `eos.ailib.info`。E2E sync 协议共享，后端可分离。

---

## 3. 建议排期（Wave）

```text
Wave 1  对比 UI       PR-V2-001                     (~1–2w)
Wave 2  云同步客户端   PR-V2-002                     (~2–3w)
Wave 3  WASM 路由      PR-V2-003                     (~2w)
Wave 4  智能推荐       PR-V2-004                     (门控：Prism P2)
```

---

## 4. 验收原则

- 每个任务独立 PR → **Spider 审查后合并**（Cursor 不自 merge）
- 任务关闭前：`executor_name` + `executor_terminal` + `merge_commit` 回填 `lan`
