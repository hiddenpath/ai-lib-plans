# Cursor 任务指派总表

> 生成：2026-06-17 | 仓库：`ailib-official/velaclaw` | Plans 真源：本目录（DOC-002 内网 only）
>
> 请 Cursor 按依赖顺序从 Head 开始执行，完成一个 PR 合并后再启动下一个。

---

## 两个独立轨道（可并行）

### 轨道 A：EVO — 执行层演进（依赖 prism-core 上线 → 部分需等待）

| 序号 | ID | 任务 | 优先级 | 前置依赖 | 状态 |
|:----:|----|------|:------:|----------|:----:|
| A-1 | **VL-EVO-001** | ExecutionHandle 抽象（策略/执行边界） | **高** | VL-TRIAL-001 ✅ | **running** |
| A-2 | VL-EVO-002 | 内嵌 prism-core router | 中 | A-1 + prism-core crates.io | draft |
| A-3 | VL-EVO-003 | BYOK 调用记录遥测 | 中 | A-2 | draft |
| A-4 | VL-EVO-004 | ProtocolBackedProvider 执行逻辑退役 | 中 | A-1, A-2 | draft |

**A-1 详细brief 见**：`tasks/VL-EVO-001-execution-handle.yaml`  
**架构 ADR**：`VL-ARCH-001-execution-strategy-boundary.md`  
**EVO 全景**：`VELACLAW_PHASE_EVO_PLAN_2026-06.md`

### 轨道 B：UI — Web Chat 本地控制面

| 序号 | ID | 任务 | 优先级 | 前置依赖 | 状态 |
|:----:|----|------|:------:|----------|:----:|
| B-1 | **VL-UI-005** | Phase 1b: Svelte SPA @ `/chat` + rust-embed | 中 | VL-UI-002 ✅ | **in_progress** |
| B-2 | VL-UI-003 | Phase 2: 会话持久化 / Memory / Config 面板 | 中 | B-1 | draft |
| B-3 | VL-UI-004 | Phase 3: Cron / Tools / Tool Approval 运维面板 | 低 | B-2 | draft |

**B-1 详细brief 见**：`tasks/VL-UI-005-web-chat-phase1-frontend.yaml`  
**UI 全景**：`VELACLAW_PHASE_UI_PLAN_2026-06.md`  
**WebSocket 协议**：参见 VELACLAW_PHASE_UI_PLAN_2026-06.md §4

---

## 执行顺序（推荐）

```
启动 A 和 B 并行：

A 轨道：
  A-1 (VL-EVO-001)  →  编译通过 + clippy clean  →  PR 到 ailib-official/velaclaw main
  ↓
  [等待: prism-core crates.io 发布]
  ↓
  A-2 (VL-EVO-002)  →  编译通过  →  PR
  A-3 (VL-EVO-003)  →  合并后 PR
  A-4 (VL-EVO-004)  →  合并后 PR

B 轨道：
  B-1 (VL-UI-005)  →  Svelte SPA 完成 + rust-embed 集成  →  PR
  ↓
  B-2 (VL-UI-003)  →  PR
  ↓
  B-3 (VL-UI-004)  →  PR
```

---

## 任务文件索引

| ID | 文件路径 | 合并参照 |
|----|----------|----------|
| VL-EVO-001 | `tasks/VL-EVO-001-execution-handle.yaml` | — |
| VL-EVO-002 | `tasks/VL-EVO-002-embed-prism-router.yaml` | — |
| VL-EVO-003 | `tasks/VL-EVO-003-byok-telemetry.yaml` | — |
| VL-EVO-004 | `tasks/VL-EVO-004-adapter-retirement.yaml` | — |
| VL-UI-005 | `tasks/VL-UI-005-web-chat-phase1-frontend.yaml` | VL-UI-002: PR #55 `7cb2528` |
| VL-UI-003 | `tasks/VL-UI-003-web-chat-phase2.yaml` | — |
| VL-UI-004 | `tasks/VL-UI-004-web-chat-phase3.yaml` | — |

---

## 分支命名规范

- EVO 轨道：`feat/vl-evo-NNN-<short-slug>`
- UI 轨道：`feat/vl-ui-NNN-<short-slug>`

## PR 审查

Cursor 开 PR 后，Spider 在 GitHub 上做 review。Prism 侧任务（PR-P1-012 等）由另一个轨道跟踪。
