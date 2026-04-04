# md2latex — 后续迭代任务列表（2026-03-26）

> 状态：**可执行**；与合同 `MD2L_APP_PROTOCOL_MIN_CONTRACT_2026-03-25.md`（含 0.3）一致。  
> 已完成并已关闭主线：**MD2L-004**（planner / trace / step gate / policy / 可选 ai-lib）。

| ID | 标题 | 优先级 | 状态 | 说明 |
|----|------|--------|------|------|
| **MD2L-005** | 最终 vars 可选落盘（脱敏 JSON） | 高 | **completed** | `FinalVarsDumpV0_1`；`run --dump-final-vars` / `--dump-final-vars-plain` |
| **MD2L-006** | StepGate 支持合并/补丁 `vars`（HITL 可编辑） | 高 | **completed** | `StepDecision::ApplyPatch` + CLI `--gate-patch-file` |
| **MD2L-007** | 一键 `run-intent`（plan + run 单次会话） | 中 | **completed** | 支持 `--save-planned-app` 与既有 run 选项 |
| **MD2L-008** | 可视化只读导出（graph + 节点状态 JSON） | 中 | **completed** | `--export-view`（run / run-intent）+ view builder |
| **MD2L-009** | per-node 可选 vars 快照（调试） | 低 | **completed** | `RunAppConfig.per_node_vars_dump` + CLI `--dump-vars-after-node` |
| **MD2L-010** | `pandoc` / `latexmk` 等 tool op（v0.3） | 低 | **completed** | 新增 `tool.pandoc_run_v0_3` / `tool.latexmk_run_v0_3`（显式授权） |

**当前执行顺序**：MD2L-009 → MD2L-010 已完成；后续任务按需求增补。
