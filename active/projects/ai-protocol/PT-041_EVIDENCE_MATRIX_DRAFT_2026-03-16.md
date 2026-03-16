# PT-041 证据矩阵草稿（2026-03-16）

| Claim ID | 文档层级 | Claim 内容 | 证据等级 | 证据类型 | 证据链接 | 快照日期 | 可复核步骤 | 状态 |
|---|---|---|---|---|---|---|---|---|
| F-001 | F | 算子流水线在项目文档中为显式结构（Decoder/Selector/Accumulator/FanOut/Event Mapper） | E3 | 项目实现文档 | `docs/RUNTIME_INTEGRATION.md` | 2026-03-16 | 读取 pipeline layer 段落 | verified |
| F-002 | F | v2 schema 包含 MCP 与 Computer Use 相关 schema 文件 | E3 | 项目结构文档 | `README.md` | 2026-03-16 | 检查 schemas/v2 目录说明 | verified |
| F-003 | F | OpenAI v1 provider 当前映射为 `max_tokens: "max_tokens"` | E3 | provider 清单 | `v1/providers/openai.yaml` | 2026-03-16 | 检查 `parameter_mappings` 段落 | verified |
| F-004 | F | 合规 gate 样本为 report-only 且 summary pass（4/4） | E3 | gate 报告 | `reports/compliance-gates/compliance-gate-2026-03-08T06-55-46-209Z.json` | 2026-03-16 | 检查 `mode` 与 `summary` 字段 | verified |
| F-005 | F | 发布 gate 样本为 required 且状态 pass | E3 | gate 报告 | `reports/release-gates/release-gate-2026-03-10T16-49-52-304Z.json` | 2026-03-16 | 检查 `mode` 与 `status` 字段 | verified |
| F-006 | F | OpenAI Responses 全面迁移结论证据链需补强 | E1+E3 | 官方文档 + 报告引用 | `platform.openai.com` / `developers.openai.com` / 报告引用 4/5/6 | 2026-03-16 | 做 claim 级引用摘录对账 | partial |
| F-007 | F | Anthropic/Gemini/DeepSeek 关键字段结论需逐条补齐 claim 级摘录 | E1+E3 | 官方文档 + 报告引用 | 报告引用 7~16 与项目清单 | 2026-03-16 | 按字段生成“结论-摘录-状态”表 | partial |
| F-008 | F | “建议迁移 V2”属于策略，不属于事实结论 | E4 | 文本分类判断 | 报告结论段 | 2026-03-16 | 标注至 D 层并从 F 层剥离 | verified |

## 证据等级标准（本次执行）

- `E1`：官方一手文档/API reference/官方公告
- `E2`：官方 SDK、官方 changelog、官方示例
- `E3`：项目实现证据（manifest、测试、gate 报告）
- `E4`：推断、经验结论、未验证假设
