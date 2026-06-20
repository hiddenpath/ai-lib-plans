# Cursor 任务指派总表

> 生成：2026-06-17 | 仓库：`ailib-official/velaclaw` | Plans 真源：本目录（DOC-002 内网 only）
>
> 请 Cursor 按依赖顺序从 Head 开始执行，完成一个 PR 合并后再启动下一个。

---

## 两个独立轨道（可并行）

### 轨道 A：EVO — 执行层演进（依赖 prism-core 上线 → 部分需等待）

| 序号 | ID | 任务 | 优先级 | 前置依赖 | 状态 |
|:----:|----|------|:------:|----------|:----:|
| A-1 | **VL-EVO-001** | ExecutionHandle 抽象（策略/执行边界） | **高** | VL-TRIAL-001 ✅ | ✅ completed ([PR #58](https://github.com/ailib-official/velaclaw/pull/58) `e4ddf2a`) |
| A-2 | VL-EVO-002 | 内嵌 prism-core router | 中 | A-1 + prism-core-routing ✅ | ✅ completed ([PR #66](https://github.com/ailib-official/velaclaw/pull/66) `a521ed2`) |
| A-3 | VL-EVO-003 | BYOK 调用记录遥测 | 中 | A-1 ✅ | ✅ completed ([PR #65](https://github.com/ailib-official/velaclaw/pull/65) `d5edb5d`) |
| A-4 | VL-EVO-004 | ProtocolBackedProvider 执行逻辑退役 | 中 | A-1, A-2 | ✅ completed ([PR #67](https://github.com/ailib-official/velaclaw/pull/67) `02ce38c`) |

**A-1 详细brief 见**：`tasks/VL-EVO-001-execution-handle.yaml`  
**架构 ADR**：`VL-ARCH-001-execution-strategy-boundary.md`  
**EVO 全景**：`VELACLAW_PHASE_EVO_PLAN_2026-06.md`

### 轨道 B：UI — Web Chat 本地控制面

| 序号 | ID | 任务 | 优先级 | 前置依赖 | 状态 |
|:----:|----|------|:------:|----------|:----:|
| B-1 | **VL-UI-005** | Phase 1b: Svelte SPA @ `/chat` + rust-embed | 中 | VL-UI-002 ✅ | **✅ completed** |
| B-2 | VL-UI-003 | Phase 2: 会话持久化 / Memory / Config 面板 | 中 | B-1 | ✅ completed ([PR #57](https://github.com/ailib-official/velaclaw/pull/57) `bc09cb8`) |
| B-3 | VL-UI-004 | Phase 3: Cron / Tools / Tool Approval 运维面板 | 低 | B-2 | ✅ completed ([PR #63](https://github.com/ailib-official/velaclaw/pull/63) `e5b61d9`) |

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
  A-2 (VL-EVO-002)  →  ✅ [PR #66](https://github.com/ailib-official/velaclaw/pull/66) `a521ed2`
  A-3 (VL-EVO-003)  →  ✅ [PR #65](https://github.com/ailib-official/velaclaw/pull/65) `d5edb5d`
  A-4 (VL-EVO-004)  →  ✅ [PR #67](https://github.com/ailib-official/velaclaw/pull/67) `02ce38c`

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
| VL-EVO-001 | `tasks/VL-EVO-001-execution-handle.yaml` | [PR #58](https://github.com/ailib-official/velaclaw/pull/58) `e4ddf2a` |
| VL-EVO-002 | `tasks/VL-EVO-002-embed-prism-router.yaml` | [PR #66](https://github.com/ailib-official/velaclaw/pull/66) `a521ed2` |
| VL-EVO-003 | `tasks/VL-EVO-003-byok-telemetry.yaml` | [PR #65](https://github.com/ailib-official/velaclaw/pull/65) `d5edb5d` |
| VL-EVO-004 | `tasks/VL-EVO-004-adapter-retirement.yaml` | [PR #67](https://github.com/ailib-official/velaclaw/pull/67) `02ce38c` |
| VL-UI-005 | `tasks/VL-UI-005-web-chat-phase1-frontend.yaml` | VL-UI-002: PR #55 `7cb2528` |
| VL-UI-003 | `tasks/VL-UI-003-web-chat-phase2.yaml` | [PR #57](https://github.com/ailib-official/velaclaw/pull/57) `bc09cb8` |
| VL-UI-003 | `tasks/VL-UI-003-web-chat-phase2.yaml` | — |
| VL-UI-004 | `tasks/VL-UI-004-web-chat-phase3.yaml` | — |

---

## 分支命名规范

- EVO 轨道：`feat/vl-evo-NNN-<short-slug>`
- UI 轨道：`feat/vl-ui-NNN-<short-slug>`

## PR 审查

Cursor 开 PR 后，Spider 在 GitHub 上做 review。Prism 侧任务（PR-P1-012 等）由另一个轨道跟踪。

## Spider ↔ Cursor 职责边界（2026-06-18 确立）

| 职责 | 负责人 | 工具 | 说明 |
|------|:------:|------|------|
| **编码实现** | Cursor | IDE / CLI | AGENTS.md 铁律：Spider 不改代码 |
| **开 PR** | Cursor | `gh pr create` | 按分支命名规范 |
| **PR 审查** | Spider | `gh pr review` + `gh pr checks` | GOV-003 四阶段；review comments 直接写在 GitHub PR 上 |
| **合并** | Spider | `git merge --no-ff` + `git push` | 审查通过 + CI 绿 → 立即合并 |
| **Plans 回填** | **Spider** | 直接更新 task YAML + TASKS_INDEX.md | 合并后 30s 内完成；更新 status 为 `completed` + 填入 merge_commit |
| **LAN mirror 同步** | **Spider** | `git push lan main` | 回填完成后顺手推送 velaclaw + ai-lib-plans 到 git-server.local |
| **验证** | Cursor | `git pull lan && git log` | Cursor 拉取 LAN 确认 Spider 的合并/回填已就位，不再重复操作 |

### Cursor 不需要做的事
- ❌ 合并后手动回填 plans YAML → Spider 会做
- ❌ 合并后手动 push LAN → Spider 会做
- ❌ 在聊天里通知 Spider「可以合并了」→ CI 绿 = 自动信号，Spider 定时扫描

### Spider 不需要做的事
- ❌ 修改源代码 → Cursor 的领域
- ❌ 创建新分支 / 开新 PR → Cursor 的领域
- ❌ 本地 `cargo build` 验证编译 → 信任 CI

### 冲突处理
如果 Cursor 和 Spider **同时**修改了 plans（比如双方都在回填）：
1. Spider 检测到 push 冲突时，执行 `git pull lan --no-rebase` → 合并
2. 冲突内容以 **Spider 的 status/merge_commit 为准**（因为 Spider 是合并执行者）
3. Cursor 的 assignee/terminal 字段保留
4. 合并后 Spider 推送到 LAN + GitHub

### 通信渠道
- **PR review comments**：Spider → GitHub PR 页面（Cursor 在 GitHub 上查看）
- **紧急问题**：可通过飞书 / Discord 联系
- **定时扫描**：Spider 每天 10:00 + 22:00 扫描所有 ai-lib 仓库 open PR
