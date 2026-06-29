# TTC Phase 4 — Live 验证 Harness 规范

> **任务**: ALR-TTC-003-R1  
> **实现位置（计划）**: `ai-lib-rust/crates/ai-lib-core/tests/text_tool_live/` 或 `ai-lib-benchmark` 可选集成  
> **本文件**: plans 侧合同，指导 harness 实现与报告归档

---

## 1. 目标

对 **非 native** 或 **text 回退** 路径，用真实 LLM 输出验证：

1. `StandardTextToolParser` 容错层级（L1–L4）在实战中的分布
2. EN/ZH prompt 模板对训练 bias（如 DeepSeek `<shell>`）的抑制效果
3. 与 native `tool_use` 路径的行为差异（Claude）

## 2. 用例集 `TTC-P4-CASES-v1`

| ID | 消息 | 注册工具 | 通过标准 |
|----|------|----------|----------|
| P4-01 | "List files in current directory" | shell | name=shell, args 含 command |
| P4-02 | "Read README.md" | file_read | path 合理 |
| P4-03 | "Run uname -a" | shell | |
| P4-04 | 中文："列出当前目录文件" | shell | 同 P4-01 |
| P4-05 | 多工具歧义："read package.json and list dir" | shell, file_read | ≥1 正确 tool |

每用例 **5 轮**（固定 seed 不可行时用轮次序号）；温度建议 `0` 或 provider 默认。

## 3. 运行方式（草案）

```bash
# 需环境变量，名称随 provider manifest
export DEEPSEEK_API_KEY=...
export ANTHROPIC_API_KEY=...

cd ai-lib-rust
cargo test -p ai-lib-core text_tool_live -- --ignored --nocapture
# 或专用 binary:
# cargo run -p ai-lib-benchmark -- ttc-phase4 --model deepseek-chat --rounds 5
```

- 测试标记 `#[ignore]` 默认跳过 CI；仅 maintainer 本地/夜间 job 执行
- 输出 JSONL → `ai-lib-plans/reports/text-tool-call/2026-06/raw/`（gitignore 大文件可选）

## 4. 结果 JSONL schema

```json
{
  "schema_version": 1,
  "task": "ALR-TTC-003",
  "provider": "deepseek",
  "model": "deepseek-chat",
  "round": 1,
  "case_id": "P4-01",
  "prompt_lang": "en",
  "raw_output": "...",
  "parsed": { "tools": [], "remainder_text": "..." },
  "parse_level": "L2",
  "success": true,
  "deviation": null,
  "timestamp": "2026-06-29T12:00:00Z"
}
```

## 5. 报告

每模型一份：[TTC_MODEL_VALIDATION_REPORT_TEMPLATE.md](../templates/TTC_MODEL_VALIDATION_REPORT_TEMPLATE.md)  
总览：`reports/text-tool-call/2026-06/PHASE4_SUMMARY.md`

## 6. 与 PT-073g 关系

- Phase 4 为 **text-tool 产品轨道**，不阻塞 PT-073 §1–§5
- live 结果可作为 PT-073g Dim 4（测试真实性）的 **补充证据**
