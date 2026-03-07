# 实施监督看板（P1/P2）— 2026-03-07

## 目的

将已规划任务转为“可监督的实施推进机制”，确保任务不止于文档，而进入执行并闭环。

## 监督对象

- PT-012 / PT-013（多模态门禁与发布回滚治理）
- PT-019 ~ PT-024（P1/P2 扩展包）

## 周次节奏

- 周一：计划校准（依赖与风险更新）
- 周三：中期检查（阻塞项与偏差修正）
- 周五：闭环检查（验收与证据归档）

## 监督指标

1. 进度指标
- `task_completion_rate`
- `blocked_task_count`

2. 质量指标
- `gate_pass_rate`
- `semantic_drift_critical_count`

3. 发布安全指标
- `rollback_readiness_score`
- `drill_coverage_rate`

## 责任矩阵

- 协议负责人：矩阵/契约/映射一致性
- 运行时负责人：跨运行时语义与性能稳定
- 发布负责人：门禁裁决与回滚执行
- 计划负责人：周节奏推进与风险升级

## 升级规则

- 任一关键任务延迟 > 1 周：升级为黄色风险
- 关键语义漂移 > 0 且未在 48h 收敛：升级为红色风险
- rollback drill 连续 2 次失败：冻结新能力发布

## 执行记录模板

- week
- task_id
- status
- blockers
- decisions
- evidence_links
- next_actions

## 当前执行状态（初始化）

- PT-012：已形成执行闭环包，进入周监督
- PT-013：已形成执行闭环包，进入周监督
- PT-019~PT-024：已完成规划产物，进入实施监督队列
