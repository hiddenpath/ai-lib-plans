# AI-Protocol 报告治理统一落地计划（2026-03-15）

## 背景

基于两份内部报告：

- `d:/ai-protocol/work/AI-Protocol 供应商 API 事实核查报告 (2025-2026).pdf`
- `d:/ai-protocol/work/AI-Protocol 协议规范与能力结构化演变深度报告.pdf`

团队决定采用 **方案 A（先修文档，再推 schema）**，优先提升证据可复核性，控制对 runtime 的影响。

## 目标

1. 将“事实层（F）”与“设计层（D）”彻底分离治理。
2. 统一 Claim-Evidence 证据矩阵，形成审计底账。
3. 在不阻塞发布的前提下，建立 `report-evidence-gate` 的 report-only 质量门禁。
4. 为后续流程化（周度复核、双周演进）提供标准模板与任务引入机制。

## 范围

- 包含：
  - 报告模板包治理落地
  - 两份报告重构与证据对齐
  - report-only gate 基线执行
- 不包含：
  - runtime 功能改动
  - v2 schema 字段强制升级
  - required gate 阻塞策略变更

## 任务分解（纳入 ai-lib-plans）

- PT-040：模板包采用与治理基线固化
- PT-041：F 层事实报告重构与补证
- PT-042：D 层演进报告重构与可验证化
- PT-043：report-evidence-gate（report-only）试运行与归档

依赖关系：

`PT-040 -> PT-041 -> PT-042 -> PT-043`

## 交付产物

- 事实层报告（F）
- 设计层报告（D）
- 证据矩阵（Claim-Evidence Matrix）
- gate 检查记录（report-only）
- 下一周期补证清单

## 验收门槛

1. F/D 分层清晰，无混写。
2. 关键结论有 Claim ID + E1~E4 证据等级。
3. 所有“推断项”已显式标记，且不写成事实。
4. 完成一次 report-only gate 并留档。

## 风险与缓解

- 风险：引用来源质量不稳定（第三方/聚合站）
  - 缓解：E1/E2 作为关键结论主证据，E3/E4 仅作补充
- 风险：结论与当前仓库状态漂移
  - 缓解：交付前与 `reports/compliance-gates` / `reports/release-gates` 对账
- 风险：流程成本上升
  - 缓解：先 report-only，稳定后再评估 required

## 建议节奏

- W1：PT-040 + PT-041
- W2：PT-042 + PT-043
- W3+：周度轻量复核与双周演进评审常态化
