# [F] 供应商 API 事实核查报告（PT-041 草稿）

> 文档类型：Fact Layer (F)  
> 目标：仅输出已验证事实，不包含演进方案与策略建议。

## 0. 文档元信息

- 报告标题：`AI-Protocol 供应商 API 事实核查（F层重构版）`
- 范围（Provider/Schema/Runtime）：`ai-protocol 文档与清单（OpenAI/Anthropic/Gemini/DeepSeek 样本）`
- 核查时间窗口：`2025-2026（以报告引用与仓库快照为准）`
- 核查日期：`2026-03-16`
- 核查人：`codex`
- 版本：`draft-v0.1`

## 1. 核查方法

- 核查对象：
  - `work/AI-Protocol 供应商 API 事实核查报告 (2025-2026).pdf`
  - `v1/providers/openai.yaml`
  - `README.md`、`docs/RUNTIME_INTEGRATION.md`
  - `reports/compliance-gates/*`、`reports/release-gates/*`
- 采样策略（全量/抽样）：`分层抽样（关键结论全检，字段明细抽检）`
- 数据来源类型：`E1/E2/E3/E4`
- 排除项：
  - 未在当前仓库中可直接复核的外部推断
  - 演进路线与治理策略性判断

## 2. 关键结论（仅事实）

| 结论ID | 结论描述 | 状态 | 证据等级 | 是否可复核 |
|---|---|---|---|---|
| F-001 | ai-protocol 文档明确采用算子流水线（Decoder/Selector/Accumulator/FanOut/Event Mapper） | Implemented | E3 | Yes |
| F-002 | v2 schema 目录已包含 `mcp.json` 与 `computer-use.json`，MCP/Computer Use 作为显式 schema 资产存在 | Implemented | E3 | Yes |
| F-003 | OpenAI v1 provider 当前参数映射仍为 `max_tokens -> max_tokens`（并非统一改写为 `max_completion_tokens`） | Implemented | E3 | Yes |
| F-004 | 合规 gate（样本）在 report-only 模式下通过（4/4） | Implemented | E3 | Yes |
| F-005 | 发布 gate（样本）处于 required 模式且状态为 pass | Implemented | E3 | Yes |
| F-006 | “OpenAI 已全面迁移 Responses API”属于高强度结论，当前报告中的主证据链不足以单独闭环 | Partially Implemented | E1+E3 | Yes |
| F-007 | Anthropic/Gemini/DeepSeek 的多项细节结论可被官方文档链接支持，但仍需逐条做 claim 级摘录对账 | Partially Implemented | E1+E3 | Yes |
| F-008 | “建议 2026 年底迁移 V2”属于策略建议，不应作为 F 层事实结论 | Proposed | E4 | Yes |

## 3. 逐项核查明细

| 项目 | 预期规范 | 实际行为 | 差异 | 结论 | 证据链接 |
|---|---|---|---|---|---|
| 算子流水线存在性 | 报告声称使用算子流水线统一多供应商行为 | 运行时集成文档明确列出五类 Pipeline Operators | 无 | Implemented | `docs/RUNTIME_INTEGRATION.md` |
| v2 能力 schema 资产 | 报告声称 V2 引入 MCP/Computer Use 抽象 | README 结构列出 `schemas/v2/mcp.json` 与 `schemas/v2/computer-use.json` | 无 | Implemented | `README.md` |
| OpenAI `max_tokens` 映射 | 报告称需重命名兼容 | provider 实际映射为 `max_tokens: "max_tokens"` | 与“已完成重命名”叙述不一致 | Implemented（现状） | `v1/providers/openai.yaml` |
| 合规门禁状态 | 报告暗含治理能力可执行 | 选取样本 gate：4/4 pass（report-only） | 无 | Implemented | `reports/compliance-gates/compliance-gate-2026-03-08T06-55-46-209Z.json` |
| 发布门禁状态 | 报告强调治理与发布衔接 | 选取样本 release gate 为 pass（required） | 无 | Implemented | `reports/release-gates/release-gate-2026-03-10T16-49-52-304Z.json` |
| Responses 迁移强结论 | 报告以高确定性描述迁移状态 | 当前引用以 Chat/Deprecations 为主，缺少 claim 级逐条摘录 | 证据链强度不足 | Partially Implemented | 原报告引用 4/5/6 |

## 4. 风险与限制

- 当前证据盲区：
  - 多数外部官方文档尚未形成“结论-段落摘录-快照”的 claim 级底账。
- 时间有效性风险：
  - 供应商 API 变化快，单次引用快照可能在短周期内过时。
- 已知争议点：
  - 事实结论与策略建议混写会降低报告的可审计性。

## 5. 可审计附件

- 证据矩阵文件：
  - `active/projects/ai-protocol/PT-041_EVIDENCE_MATRIX_DRAFT_2026-03-16.md`
- 原始引用列表：
  - `work/AI-Protocol 供应商 API 事实核查报告 (2025-2026).extracted.txt`
- 相关 gate 结果：
  - `reports/compliance-gates/compliance-gate-2026-03-08T06-55-46-209Z.json`
  - `reports/release-gates/release-gate-2026-03-10T16-49-52-304Z.json`

## 6. 非目标（必须写）

- 本文不包含演进方案。
- 本文不包含策略建议。
