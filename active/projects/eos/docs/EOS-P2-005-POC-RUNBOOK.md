# EOS-P2-005-R2 — Prism 集成 POC Runbook

**范围**：local/CI only（同 PR-P1-008 惯例）  
**前置**：ADR [EOS-P2-005-PRISM_INTEGRATION_ADR.md](./EOS-P2-005-PRISM_INTEGRATION_ADR.md)  
**目标**：验证 OpenAI 兼容 `/v1/chat/completions`（含 stream）经 Prism 路径可达

---

## 路径 A — 对照 ai-lib-gateway（推荐先做）

验证 Prism 生产或本地 gateway 行为，作为 eos-server `/v1` 壳的实现参照。

### 环境

```bash
# 生产（需 PRISM_GATEWAY_API_KEY 或平台 key）
export PRISM_BASE="https://api.prism.ailib.info"
export PRISM_KEY="<gateway-bearer-key>"

# 或本地 gateway（ai-lib-gateway 仓库）
# cargo run --manifest-path d:/rustapp/ai-lib-gateway/Cargo.toml
# export PRISM_BASE="http://127.0.0.1:8080"
```

### Smoke 1 — `GET /v1/models`

```bash
curl -sS -H "Authorization: Bearer $PRISM_KEY" \
  "$PRISM_BASE/v1/models" | jq '.data | length'
```

期望：返回 ≥1 个 model 对象。

### Smoke 2 — `POST /v1/chat/completions`（非流式）

```bash
curl -sS -H "Authorization: Bearer $PRISM_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"<model-id>","messages":[{"role":"user","content":"ping"}],"max_tokens":16}' \
  "$PRISM_BASE/v1/chat/completions" | jq '.choices[0].message.content'
```

期望：HTTP 200，含 assistant 文本。

### Smoke 3 — 流式

```bash
curl -sS -N -H "Authorization: Bearer $PRISM_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"<model-id>","messages":[{"role":"user","content":"ping"}],"stream":true,"max_tokens":16}' \
  "$PRISM_BASE/v1/chat/completions" | head -5
```

期望：SSE `data:` 行，末行 `data: [DONE]`。

### Smoke 4 — `POST /v1/route/decide`（可选，智能路由）

```bash
curl -sS -H "Authorization: Bearer $PRISM_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"<model-id>","preferences":{"optimize":"balanced"}}' \
  "$PRISM_BASE/v1/route/decide" | jq '{model, provider_id, reason}'
```

---

## 路径 B — eos-server `/v1` 壳（R2 完整验收）

**状态**：✅ 已合并 — #19 `703a942` + #20 `3b1fd1c`（`?v1=1` 灰度）

实现要点（见 ADR §3）：

1. 新增 `GET /v1/models`、`POST /v1/chat/completions`（+ SSE）
2. 复用 `compliance_check` 逻辑（model id 自 body，非 URL）
3. 内部 `prism_core::proxy` + `EnvConfig`（与 `/api/proxy` 同源 key pool）
4. **不**删除 `/api/proxy`

验收：将上文 curl 的 `PRISM_BASE` 换为 `http://127.0.0.1:$EOS_PORT`，Bearer 可省略或复用 session（实现时定）。

### CI 建议

- 单元测试：model 解析、compliance 403、空 model 400（无需 live key）
- 集成测试：`#[ignore]` + `EOS_LIVE_SMOKE=1` 时跑路径 A 同等断言

---

## 证据回填

完成后更新 `tasks/EOS-P2-005-prism-integration.yaml`：

- `EOS-P2-005-R2.status` → `completed`
- `evidence`：PR 链接 + 「local/CI only」注明
- `EOS-P2-005-R4`：引用 gateway `COST_ROUTING.md` + Vela PR-V2-006 模式

---

## 相关

- `ai-lib-gateway/docs/COST_ROUTING.md`
- `../prism/tasks/PR-P1-008-provider-verification.yaml`
