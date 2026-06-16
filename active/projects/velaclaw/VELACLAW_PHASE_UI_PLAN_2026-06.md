# VelaClaw Phase UI — Web Chat 与本地控制面（2026-06）

> **前置**：VL-TRIAL-001 ✅、VL-ARCH-001（执行边界）、VL-UI-001（Path 2 决策 ✅）  
> **真源**：本文件 + `tasks/VL-UI-*.yaml`  
> **DOC-002**：内网 plans only；公开仓仅用户向 setup 文档

---

## 1. 定位（与 Vela / Prism 分工）

| SKU | UI | 执行 |
|-----|-----|------|
| **VelaClaw** | 本地 Web SPA（`velaclaw daemon` loopback） | 进程内 agent loop + BYOK 直连 |
| **Vela**（`PR-V1-*`） | 浏览器 → Prism SDK | HTTP → Prism Gateway |
| **Prism Gateway** | 外部 ToB `/v1` 客户端 | 独立产品 |

**关键**：VelaClaw Web Chat 的 `/api/chat`、`/ws` 是 **本地控制面（Local Control Plane）**，调用 **与 CLI 相同的 agent 策略层**，**不是**把 chat 转发到 `ai-lib-gateway` 或 Prism HTTP（VL-ARCH-001 D6）。

「与 Prism 兼容」仅指 **可选的 API 形状/前端组件复用**（未来 Vela 可共享 chat 组件样式），**不**指执行路径复用。

---

## 2. 已决事项（VL-UI-001，owner 2026-06-10）

| 项 | 决策 |
|----|------|
| 路径 | **Path 2** — 自建前端 + 扩展现有 gateway，**不同步** zeroclaw-gateway crate |
| 框架 | **Svelte 5 + Vite**（轻量、bundle 小、易 rust-embed） |
| 嵌入 | **rust-embed**（release 编译进二进制）；dev 用 Vite proxy → gateway |
| 鉴权 | 复用现有 **PairingGuard** bearer；`/api/chat`、`/ws` 与 `/webhook` 同级保护 |
| 绑定 | 默认 **127.0.0.1**；公网 bind 须 pairing + 文档警告 |
| 路由 | **`/chat`** 服务 SPA；**保留 `/dashboard`** 运维只读面板 |
| 多 crate | Phase 1 **留在单 crate**；handler 放 `src/gateway/chat_api.rs` 等模块，便于日后 `crates/velaclaw-gateway` 抽出 |
| Agent 集成 | Chat handler **必须**走 `Agent::turn` / tool loop，**禁止** gateway 内重复调 Provider |

---

## 3. 阶段与任务映射

```
VL-UI-001 ✅ 规划与 Path 2 决策
    │
    ├─► VL-UI-002  Phase 1a — Local Control API（REST + WS + 鉴权）
    │       └─► VL-UI-005  Phase 1b — Chat SPA（Svelte + embed）
    │
    ├─► VL-UI-003  Phase 2 — 会话持久化 + Memory + Config + Provider 列表
    │
    └─► VL-UI-004  Phase 3 — Cron + Tools + Tool Approval 运维面板
```

### 与 Phase EVO 关系

| 轨道 | 关系 |
|------|------|
| **VL-EVO-001** | 可与 UI-002 **并行**；UI chat 先绑 agent loop，EVO-001 合入后迁到 ExecutionHandle |
| **VL-EVO-003** | Phase 2+ 可在 dashboard 展示 BYOK usage 遥测 |
| **VL-EVO-002** | 不阻塞 UI；陌生 provider 在 UI 的 provider 列表由 protocol_registry + 未来 router 反映 |

---

## 4. WebSocket 协议（Phase 1 合同）

Client → Server:
```json
{"type":"chat","session_id":"optional","messages":[...],"model_id":"deepseek/deepseek-v4-pro","temperature":0.7}
```

Server → Client:
```json
{"type":"delta","content":"..."}
{"type":"tool_start","tool":"shell","call_id":"..."}
{"type":"tool_end","tool":"shell","success":true}
{"type":"approval_required","request_id":"...","summary":"..."}
{"type":"done","usage":{...},"cost":0.0}
{"type":"error","message":"..."}
```

Phase 1 至少支持：`delta`、`done`、`error`；`tool_*` / `approval_required` 在 Phase 1b 或 Phase 3 完整化。

---

## 5. 入口命令

| 命令 | 行为 |
|------|------|
| `velaclaw daemon` | 启动 gateway（含 chat API + 可选 SPA） |
| `velaclaw agent` | **保留** headless CLI，不废弃 |
| 浏览器 `http://127.0.0.1:<port>/chat` | Web Chat UI |

---

## 6. 不在范围

- Tauri/Electron 原生壳（Phase 4 候选，单独立项）
- 把 VelaClaw UI 合并进 `ailib-official/vela` 仓库
- Chat 默认走 Prism Gateway HTTP
- 从 ZeroClaw 整体 merge gateway crate

---

## 7. 文档索引

| 文档 | 用途 |
|------|------|
| `tasks/VL-UI-001-web-chat-ui-planning.yaml` | 原始路径分析 |
| `VL-ARCH-001-execution-strategy-boundary.md` | 执行层 ADR |
| `VELACLAW_PRODUCT_ALIGNMENT_2026-06.md` | 三品牌对照 |
