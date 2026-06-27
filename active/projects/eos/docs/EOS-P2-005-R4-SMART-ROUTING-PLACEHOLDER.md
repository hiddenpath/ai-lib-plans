# EOS-P2-005-R4 — Eos 智能路由接口占位

**状态**：文档占位（非必交付，不阻塞 M9）  
**依赖**：Prism P2 `/v1/route/decide` ✅、Vela PR-V2-006 参考实现  
**软依赖**：PT-073（Contact / ExecutionMetadata 富化）

---

## 1. 原则（ADR §6）

- Eos **前端不直调** `api.prism.ailib.info`（平台 key 在服务端）
- 智能路由在 **eos-server P 层** 代理或内嵌 `prism-core` 路由
- SLA：**非生产 SLA**，与 gateway 一致

---

## 2. 目标接口

### 2.1 服务端代理（推荐 Phase 2.5）

```
POST /v1/route/decide
Authorization: <session cookie>  # 或内部 service token
Content-Type: application/json

{
  "model": "deepseek-chat",
  "messages": [ ... ],           // 可选，供上下文感知路由
  "preferences": {
    "optimize": "cost" | "latency" | "balanced"
  }
}
```

**响应**（与 gateway 同形）：

```json
{
  "model": "deepseek-chat",
  "provider_id": "deepseek",
  "reason": "lowest_cost",
  "fallback_chain": ["deepseek-chat", "gpt-4o-mini"],
  "disclaimer": "NOT PRODUCTION SLA"
}
```

实现选项：

| 选项 | 描述 | 复杂度 |
|------|------|--------|
| **A** | eos-server 转发至 `api.prism.ailib.info/v1/route/decide`（服务端 Bearer） | 低 |
| **B** | eos-server 内嵌 `prism_core::CostRouter` + health | 中（与 gateway 对齐） |

### 2.2 聊天发送时应用

1. 用户选模型或默认模型
2. （可选）debounce 400ms 调 `/v1/route/decide`
3. 用响应 `model` 覆盖请求体后 `POST /v1/chat/completions`
4. 失败时回退用户原选模型（同 Vela WASM/heuristic 模式）

---

## 3. 与 Vela 差异

| 项 | Vela | Eos |
|----|------|-----|
| decide 调用方 | 浏览器 → Prism | 浏览器 → eos-server → Prism/core |
| Auth | User gateway key | Session + 平台 key pool |
| UI | RoutingHintBar | 待产品定义（可复用提示条模式） |

参考：`ailib-official/vela` — `decideRoute.ts`、`usePrismRouteDecide.ts`、`RoutingHintBar.tsx`

---

## 4. 合规

- decide 结果仍须过 `ComplianceFilter::is_model_allowed`
- cn 入口不得因路由推荐未备案模型

---

## 5. 验收（未来实现时）

- [ ] `POST /v1/route/decide` 200 + 合法 model
- [ ] 推荐模型被合规拒绝时 403 或降级到 allowlist 内备选
- [ ] PT-073 完成后可注入 Contact 元数据增强 reason 字段

---

## 6. 相关

- `ai-lib-gateway/docs/COST_ROUTING.md`
- `../prism/docs/PHASE2_CLOSEOUT_2026-06.md`
- [EOS-P2-005-PRISM_INTEGRATION_ADR.md](./EOS-P2-005-PRISM_INTEGRATION_ADR.md) §6
