# PT-042 边界证据与代码迭代记录（2026-03-16）

## 目标

在 A 方案前提下，快速推进到“可验证边界条件”，取得事实级证据，并启动低风险实质性代码迭代。

## 本轮代码迭代（ai-protocol）

### 变更文件

- `schemas/v2/capability-profile.json`（新增）
- `schemas/v2/provider.json`（新增可选字段 `capability_profile` 引用）
- `scripts/validate-capability-profile-boundary.js`（新增边界校验脚本）
- `package.json`（新增脚本 `validate:capability-profile`）
- `README.md`（新增 schema 索引项）

### 设计边界

- 仅引入可选元数据，不改 runtime 执行逻辑。
- 不改变 required gate 策略，不影响现有发布路径。
- 约束未知字段与越界值，保证 schema 稳定性。

## 事实证据

### 全量校验

- 命令：`npm run validate`
- 结果：`Passed 102 / Failed 0`

### 边界校验（report-only）

- 命令：`npm run validate:capability-profile`
- 报告：`reports/report-evidence-gates/capability-profile-boundary-2026-03-16T15-35-35-560Z.json`
- 用例摘要：`total=6, passed=6, failed=0`

覆盖边界：

- 空对象最小输入可通过（可选元数据）
- 合法完整对象可通过
- `max_references` 超上限拦截
- `typical_duration_seconds` 超上限拦截
- 未知顶层字段拦截
- 未知模态值拦截

## 对后续流程化的依据

1. 已具备“report-only 可复核证据”生成路径。
2. 可将 `validate:capability-profile` 作为后续 `report-evidence-gate` 的自动化检查项候选。
3. 可在 PT-043 中把本报告作为“边界事实证据样本”纳入归档。

## 建议下一步

- 在 PT-043 中纳入该脚本结果到 gate 清单，形成固定归档字段。
- 在不改变 runtime 的前提下，扩展更多边界用例（例如 contract 引用字段格式约束）。
