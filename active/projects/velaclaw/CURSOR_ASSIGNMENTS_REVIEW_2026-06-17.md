# Cursor 指派任务合理性审查（2026-06-17）

## PR #55 / VL-UI-002 回填

| 项 | 状态 |
|----|------|
| `origin/main` | `7cb2528` — VL-UI-002 已合入 |
| `VL-UI-002` task YAML | `completed`，`merge_commit: 7cb2528`，CI 证据齐全 |
| `TASKS_INDEX.md` | 已更新 |

## 指派总表审查结论：**可执行，无硬冲突**

### 轨道 B（UI）— 推荐 Cursor 优先

| 任务 | 判定 | 说明 |
|------|------|------|
| **VL-UI-005** | ✅ Ready | VL-UI-002 已合入；与 VL-ARCH-001 / UI Plan 一致 |
| VL-UI-003 | ✅ 依赖正确 | 阻塞于 B-1，合理 |
| VL-UI-004 | ✅ 依赖正确 | 阻塞于 B-2，合理 |

### 轨道 A（EVO）

| 任务 | 判定 | 说明 |
|------|------|------|
| **VL-EVO-001** | ✅ 可并行 | 高优先级；与 UI 无路由冲突；合入后 chat handler 可迁 ExecutionHandle |
| VL-EVO-002 | ⏸ 正确阻塞 | 依赖 prism-core crates.io，不宜提前 |
| VL-EVO-003/004 | ✅ 顺序正确 | 依赖 A-1/A-2 |

## 小幅修正（已采纳）

1. **VL-EVO-001** `status: running` 但无 `executor_name` / PR — 保留 running，Cursor 在 UI-005 PR 开出后接 A-1。
2. **VL-UI-005** 指派表写 `draft → ready` — 实施时改为 `in_progress`。
3. **并行策略**：先 **B-1（VL-UI-005）** 再 **A-1（VL-EVO-001）**，因 UI 链路用户可立即验收；EVO 为执行层重构，独立 PR 更易审查。

## 无需修改项

- 分支命名 `feat/vl-ui-NNN-*` / `feat/vl-evo-NNN-*` 符合 GOV-001
- WebSocket 合同与已合入 VL-UI-002 一致
- DOC-002：指派文档仅 plans 内网，公开 README 仅用户向说明
