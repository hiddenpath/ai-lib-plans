# AGENT 后续建议完成回执

日期：2026-03-13

## 完成项

### 建议1：策略热更新（无重启）
- 已完成：`RuleBasedRouter` 支持文件配置与自动重载。
- 关键参数：
  - `--policy-config-file`
  - `--policy-config-auto-reload`
- 代码：
  - `/home/alex/ai-agent-core/src/ai_agent_core/router/policy.py`

### 建议2：A/B 压测与成本校准
- 已完成：
  - CLI 压测模式：`--run-ab-stress`
  - 压测输出：`--stress-output`
  - 成本校准建议：`--actual-costs-file` + calibrated suggestion
- 代码：
  - `/home/alex/ai-agent-core/src/ai_agent_core/cli.py`
  - `/home/alex/ai-agent-core/src/ai_agent_core/observe/cost.py`
  - `/home/alex/ai-agent-core/src/ai_agent_core/observe/metrics.py`

### 建议3：多租户治理与配额
- 已完成：
  - 每租户日限额 + 并发限额
  - 配额检查审计事件写入 `policy_audit`
  - CLI 配置化配额：
    - `--tenant-id`
    - `--tenant-quota-file`
- 代码：
  - `/home/alex/ai-agent-core/src/ai_agent_core/tenant/quota.py`
  - `/home/alex/ai-agent-core/src/ai_agent_core/orchestrator.py`
  - `/home/alex/ai-agent-core/src/ai_agent_core/intake/queue.py`

## 验证结果

执行：

```bash
cd /home/alex/ai-agent-core
.venv/bin/pytest -q
```

结果：`14 passed`

## UI与整体组装方案

- 文档：`/home/alex/ai-agent-core/docs/UI_ASSEMBLY_PLAN.md`
- 覆盖：
  - UI面板划分
  - API组装契约
  - 单机/扩展部署拓扑
  - 里程碑落地路径

## 追加落地（AGENT-004）

- 已实现 UI-facing `agent-api`（FastAPI）：
  - `POST /api/tasks`
  - `POST /api/tasks/batch`
  - `POST /api/tasks/recover`
  - `GET /api/tasks/{task_id}`
  - `GET /api/dashboard`
  - `GET /api/audit/policy`
  - `PUT /api/policy/config`
  - `PUT /api/tenant/quotas`
- API 测试覆盖已纳入并通过。

## 继续推进（AGENT-005）

- 前端 UI 骨架已落地：`/home/alex/ai-agent-core/ui-console/`
- 页面完成：
  - `/tasks`
  - `/dashboard`
  - `/policy`
  - `/tenants`
- 已完成与 `agent-api` 接口联调代码（API client 层）。
- 构建验证：
  - `npm run build` 通过
