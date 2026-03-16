# AGENT-002 恢复演练证据

日期：2026-03-13  
任务：AGENT-002

## 演练目标

- 验证 sqlite 状态存储可跨实例恢复
- 验证 recover_pending 流程可回放未完成任务
- 验证重试/回退事件可导出为 evidence JSON

## 演练方式

通过测试用例驱动演练（本地执行）：

- `tests/test_state_machine.py::test_sqlite_store_recoverable_inputs`
- `tests/test_recovery_and_evidence.py::test_recover_pending_tasks_replays_unfinished`
- `tests/test_recovery_and_evidence.py::test_export_evidence_file_contains_retry_and_events`

## 执行命令

```bash
cd /home/alex/ai-agent-core
.venv/bin/pytest -q
```

## 结果

- 测试结果：`8 passed`
- 关键结论：
  1. sqlite 状态快照可正确持久化并重载
  2. 非终态任务可被 recover_pending 检出并重放成功
  3. evidence 导出包含 retrying 等关键状态事件

## 关联代码

- `/home/alex/ai-agent-core/src/ai_agent_core/state.py`
- `/home/alex/ai-agent-core/src/ai_agent_core/orchestrator.py`
- `/home/alex/ai-agent-core/src/ai_agent_core/cli.py`
- `/home/alex/ai-agent-core/src/ai_agent_core/executor/spiderswitch_mcp.py`
- `/home/alex/ai-agent-core/tests/test_recovery_and_evidence.py`
