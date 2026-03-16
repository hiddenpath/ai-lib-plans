# AI-Protocol 报告治理任务引导基线（2026-03-16）

## 目的

为 PT-040~PT-043 提供统一的任务引导入口，确保执行者在每个任务开始前加载一致上下文，避免 F/D 混写和证据标准漂移。

## 默认任务引导输入（Mandatory）

每个任务启动前，必须填写并确认：

- `d:/ai-protocol/work/report-governance-template-pack/templates/task-context-brief.template.md`

并在引导中明确：

1. 任务属于 F 层还是 D 层（或需拆分双交付）
2. 对应证据矩阵条目是否已创建
3. 本次范围是否触及 runtime/schema（默认不触及）

## 必读上下文（Ordered）

1. `d:/ai-protocol/work/report-governance-template-pack/INDEX.md`
2. `active/projects/ai-protocol/REPORT_GOVERNANCE_UNIFIED_EXECUTION_PLAN_2026-03-15.md`
3. `d:/ai-protocol/work/report-governance-template-pack/TASK-PLAYBOOK.md`
4. `d:/ai-protocol/work/report-governance-template-pack/checklists/report-evidence-gate.checklist.md`

## 范围边界（PT-040 阶段）

- 允许：
  - 文档分层治理（F/D）
  - 证据分级与 claim 编码
  - report-only gate 基线建立
- 禁止：
  - runtime 行为变更
  - schema required 化强推
  - 发布阻塞策略升级

## 交付检查（启动时）

- [ ] 任务上下文 brief 已填写
- [ ] 任务类型（F/D）已标注
- [ ] 输入文档路径已确认
- [ ] 风险边界已确认
