# EOS-P2-005-R3 — Eos `/v1` 生产灰度 Runbook

**状态**：草案（**门控** — 须 owner 审批 + eos #19 合并后执行）  
**前置**：R2 POC ✅（eos `/v1` 壳）、ADR 方案 B  
**范围**：`https://eos.ailib.info`（香港 VPS）— **非** Prism 生产验收环境

---

## 0. 边界

| 项 | 说明 |
|----|------|
| Eos VPS | 香港 `eos.ailib.info`，消费者产品壳 |
| Prism VPS | `api.prism.ailib.info`，独立网关；Eos **不**托管 Prism |
| 灰度对象 | 前端是否走 `/v1/chat/completions` 替代 `/api/proxy` |
| 合规 | `EOS_DEPLOYMENT_REGION` + 备案 registry 不变 |

---

## 1. 发布前检查

- [ ] eos #19 已合并至 `main`，镜像已构建
- [ ] `cargo test -p eos-server` + CI（rust / docker-build / e2e）绿
- [ ] 生产 env：`EOS_*_API_KEY` 已配置且轮换记录在案
- [ ] `EOS_DEPLOYMENT_REGION` 与入口一致（global / cn）
- [ ] cn 入口：`EOS_COMPLIANCE_REGISTRY` 指向最新 `registered_models.yaml`
- [ ] Owner 书面确认灰度窗口与回滚负责人

---

## 2. 部署步骤

```bash
# 1. 拉取 main（含 /v1 路由）
git checkout main && git pull origin main

# 2. 构建并部署（现有脚本）
bash ai-lib-plans/tools/deploy_eos.sh   # 或项目内等效流程

# 3. 健康检查
curl -sS https://eos.ailib.info/health | jq .
curl -sS https://eos.ailib.info/v1/models | jq '.object, (.data | length)'
```

---

## 3. 灰度策略

| 阶段 | 流量 | 验收 |
|------|------|------|
| **G0** | 0% — 仅运维 curl | `/v1/models` 200；合规模型可见 |
| **G1** | 内部账号 / `?v1=1` localStorage 开关 | 单用户非流式 + 流式各 1 次 |
| **G2** | 10% 新会话（前端 `useOpenAiV1`） | 错误率、延迟与 `/api/proxy` 对比 |
| **G3** | 50% → 100% | 24h 无 P0 后全量 |

**回滚**：访问 `?v1=0` 或清除 `localStorage.eos_use_openai_v1`（仍走 `/api/proxy`）；无需回滚数据库（无 schema 变更）。

---

## 4. 回滚

1. 前端静态资源回滚至上一版（或关闭 `useOpenAiV1`）
2. 若必须回滚二进制：`deploy_eos.sh` 指向上一个已知好 commit
3. 验证：`/api/proxy` 聊天 E2E 恢复
4. 事件记录：时间、commit、影响面、根因

---

## 5. 密钥轮换

| 密钥 | 变量 | 轮换步骤 |
|------|------|----------|
| Provider | `EOS_OPENAI_API_KEY` 等 | 厂商控制台换新 → 更新 VPS env → 滚动重启 eos-server |
| Session | `EOS_AUTH_SECRET` | 低峰期更换 → 全用户重新登录 |
| Tavily | `EOS_TAVILY_API_KEY` | 独立轮换，不影响 `/v1` |

轮换后执行 Smoke 2（见 [EOS-P2-005-POC-RUNBOOK.md](./EOS-P2-005-POC-RUNBOOK.md) 路径 B）。

---

## 6. 监控与告警（建议）

- `/health` 5xx 率
- `/v1/chat/completions` 4xx/5xx 按 `compliance_model_blocked` 分类
- Provider 上游 502 尖峰
- 限流 `429` 计数（现有 `rate_limit_rejected_total`）

---

## 7. 完成标准

- [ ] G3 全量 24h 稳定
- [ ] Runbook 执行记录归档（plans 或内部 ops 日志）
- [ ] `EOS-P2-005-R3` 标 `completed`
