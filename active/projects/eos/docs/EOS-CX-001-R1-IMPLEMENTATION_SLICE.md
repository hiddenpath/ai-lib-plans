# EOS-CX-001 — R1 实现切片（Priority 元数据）

> **任务**: [EOS-CX-001-message-priority-layering.yaml](./tasks/EOS-CX-001-message-priority-layering.yaml)  
> **状态**: R1 `in_progress`（2026-06-29）  
> **设计真源**: [CONTEXT_ARCHITECTURE_V2.md](./CONTEXT_ARCHITECTURE_V2.md) §3

---

## 1. 目标（R1）

在 **不改变默认 flat 行为** 的前提下，为 SessionMirror 消息引入 `priority`（Layer 0–5），并提供默认推断规则。

## 2. 代码落点

| 层 | 路径 | 变更 |
|----|------|------|
| 浏览器 SessionMirror | `eos/static/js/session_mirror.js` | entry 增加 `priority?`；`inferPriority(entry, index)` |
| 单元测试 | `eos/static/js/session_mirror.test.mjs` | 默认推断 + 显式 override |
| WASM 组装（R2） | `eos/crates/eos-wasm-browser/src/core_logic.rs` | `AssembleOptions.strategy = Layered`（依赖 ai-lib-contact 扩展） |
| Contact 策略（R2 上游） | `ai-lib-rust/crates/ai-lib-contact/src/context/` | `MessageAssembler` priority-aware fill |

**现有钩子**：`assembleMessages(maxTokens, strategy)` 已对 `layered` 打 warn 并回退 flat — R2 实现后移除 warn。

## 3. Priority 枚举（JS + 后续 Rust 对齐）

```javascript
/** @typedef {0|1|2|3|4|5} MessagePriority */
// 0 System — 不可裁
// 1 Active — 当前 round
// 2 Relevant — 显式标记/引用命中
// 3 Summary — 外部摘要注入
// 4 Background — 普通历史
// 5 Archive — 仅索引，不展开
```

### 默认推断规则（v1）

| 条件 | Layer |
|------|-------|
| `role === 'system'` | 0 |
| 最后一条 user 消息 | 1 |
| 最后一条 assistant 消息（紧接 user 之后） | 1 |
| `entry.priority` 显式设置 | 使用显式值 |
| 其他 | 4 |

Layer 2/3/5 在 R1 仅预留字段；EOS-CX-002 负责 Summary/Archive 填充。

## 4. R1 验收

- [ ] `append()` 接受可选 `priority`；序列化 export 含字段
- [ ] `inferPriority` 单测覆盖 system / current round / explicit
- [ ] 默认 `assembleMessages(..., 'flat')` 行为 **字节级不变**（回归现有 test）
- [ ] `CONTEXT_ARCHITECTURE_V2.md` §6 勾选 R1

## 5. PR 切片建议

1. **eos PR-A**: `session_mirror.js` + tests（仅 metadata，strategy 仍 flat）
2. **ai-lib-rust PR-B**（R2）: `MessagePriority` + layered assembler + compliance 单测
3. **eos PR-C**（R2）: WASM `layered` strategy 接线 + Playwright 长对话

## 6. 非目标（R1）

- UI「标记重要」→ R3
- 外部文档归档 → EOS-CX-002
- LLM 检索向导 → 远期
