# AGENT-003 执行证据（策略插件 / A-B / 回滚 / 仪表盘）

日期：2026-03-13  
任务：AGENT-003

## 实施范围

1. 冻结策略插件契约（`v1`）
2. 上线 A/B 策略路由与失败率自动回滚
3. 增加治理审计日志（policy_audit）
4. 提供 SLO/成本/失败仪表盘导出（JSON/Markdown）

## 核心代码

- `/home/alex/ai-agent-core/src/ai_agent_core/router/policy.py`
- `/home/alex/ai-agent-core/src/ai_agent_core/state.py`
- `/home/alex/ai-agent-core/src/ai_agent_core/orchestrator.py`
- `/home/alex/ai-agent-core/src/ai_agent_core/observe/dashboard.py`
- `/home/alex/ai-agent-core/src/ai_agent_core/observe/metrics.py`
- `/home/alex/ai-agent-core/src/ai_agent_core/cli.py`

## 测试证据

执行命令：

```bash
cd /home/alex/ai-agent-core
.venv/bin/pytest -q
```

结果：`11 passed`

新增覆盖：
- `tests/test_policy_and_dashboard.py`
  - 插件契约版本冻结验证
  - A/B 策略切换与回滚触发验证
  - 仪表盘渲染与治理审计日志验证

## 验收映射

- Policy plugin contract frozen：完成（`POLICY_PLUGIN_API_VERSION = "v1"`）
- A/B routing with rollback：完成（router experiment + failure-rate rollback）
- SLO/cost/failure dashboards：完成（`build_dashboard` + markdown report）
- Governance audit log：完成（sqlite `policy_audit` + `log_policy_event`）
