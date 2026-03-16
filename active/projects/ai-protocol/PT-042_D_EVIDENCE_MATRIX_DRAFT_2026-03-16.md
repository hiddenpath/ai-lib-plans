# PT-042 D 层证据矩阵草稿（2026-03-16）

| Claim ID | 文档层级 | Claim 内容 | 证据等级 | 证据类型 | 证据链接 | 快照日期 | 可复核步骤 | 状态 |
|---|---|---|---|---|---|---|---|---|
| D-H01 | D | 可选 I/O/P/S/C 元数据可在不破坏现有 provider schema 的前提下引入 | E3 | 代码实现 | `schemas/v2/capability-profile.json` + `schemas/v2/provider.json` | 2026-03-16 | 运行 `npm run validate` | verified |
| D-H02 | D | 在不修改 runtime 逻辑的情况下，可通过 schema 扩展承载能力契约元数据 | E3 | 代码实现 + 边界约束 | `schemas/v2/capability-profile.json`（metadata-only 描述） | 2026-03-16 | 检查 schema description 与字段约束 | verified |
| D-H03 | D | 边界条件可通过独立校验脚本进行事实化验证并归档为 report-only 证据 | E3 | 校验脚本 + 报告 | `scripts/validate-capability-profile-boundary.js` + `reports/report-evidence-gates/*` | 2026-03-16 | 运行 `npm run validate:capability-profile` | verified |
| D-H04 | D | 关键边界（上限越界、未知字段、未知模态）可稳定拦截 | E3 | 边界用例结果 | `reports/report-evidence-gates/capability-profile-boundary-2026-03-16T15-35-35-560Z.json` | 2026-03-16 | 查看 checks 中 cp-003/004/005/006 | verified |
| D-H05 | D | 该迭代可作为后续 report-evidence-gate 的流程化输入依据 | E3 | 过程产物 | `active/projects/ai-protocol/PT-042_BOUNDARY_EVIDENCE_AND_CODE_ITERATION_2026-03-16.md` | 2026-03-16 | 读取“流程化建议”章节 | verified |
