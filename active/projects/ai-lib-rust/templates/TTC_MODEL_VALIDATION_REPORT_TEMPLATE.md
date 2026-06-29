# TTC Phase 4 — Live 模型验证报告 — {MODEL_ID}

<!-- TTC_META: phase=4 task=ALR-TTC-003 model={id} provider={slug} date={YYYY-MM-DD} rounds={n} status={draft|final} -->

> **标准**: [text-tool-call-standard.md](../../../text-tool-call-standard.md) §Phase 4  
> **任务**: [ALR-TTC-003](../tasks/ALR-TTC-003-model-validation.yaml)  
> **Provider / Model**: `{provider}` / `{model_id}`  
> **Parser**: `StandardTextToolParser` @ `{git_sha}`  
> **Prompt 模板**: `{en|zh}` @ `{template_version}`  
> **日期**: {YYYY-MM-DD}

---

## 1. 执行配置

| 项 | 值 |
|----|-----|
| API 端点 | {base_url} |
| tool_calling.native | `{true|false}` |
| tool_calling.text.reliability | `{manifest value}` |
| 温度 / max_tokens | `{t}` / `{n}` |
| 用例集版本 | `TTC-P4-CASES-v{n}` |
| 重复轮次 | 5 |

**环境**（无密钥）: OS={…}, ai-lib-rust={version}, ai-protocol={ref}

---

## 2. 用例清单

| Case ID | 用户提示意图 | 期望工具 | 期望参数要点 |
|---------|--------------|----------|--------------|
| P4-01 | 列出目录 | `shell` | `command=ls` |
| P4-02 | 读文件 | `file_read` | path |
| … | | | |

---

## 3. 轮次结果矩阵

| Round | Case | 原始 LLM 输出摘要 | 解析结果 | L 层级 | 偏差类型 | 备注 |
|-------|------|-------------------|----------|--------|----------|------|
| 1 | P4-01 | `<shell>…` | ✅ 1 tool | L2 | `shell_xml_bias` | |
| 1 | P4-02 | … | ❌ 0 tools | — | `json_shape` | |

**偏差类型枚举**: `shell_xml_bias`, `wrapper_nesting`, `parameters_vs_arguments`, `json_shape`, `hallucinated_tool`, `empty`, `other`

---

## 4. 汇总指标

| 指标 | 值 |
|------|-----|
| 总调用次数 | {cases × rounds} |
| 解析成功（≥1 正确 tool） | {n} ({%}) |
| 完全失败 | {n} ({%}) |
| 平均 L 层级 | {L1–L4} |
| 最常见偏差 | {type} ({%}) |

---

## 5. 结论与建议

- **Prompt 有效性**: {adequate / needs_tuning / insufficient}
- **是否推荐 default text path**: {yes/no/conditional}
- **规范/实现跟进项**: {链接 ALR-TTC-00x 或 PT-078}

---

## 6. 原始日志

> 存于 `reports/text-tool-call/2026-06/raw/{model_id}-round{N}.jsonl`（不入 git 若含 PII）

```json
{"round":1,"case":"P4-01","raw_output":"...","parsed_tools":[...]}
```

---

## 签核

| 审查 | 日期 | 备注 |
|------|------|------|
| | | |
