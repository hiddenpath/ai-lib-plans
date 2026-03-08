# PT-025 Manifest Consumption Gate Runbook（2026-03-07）

## 1. 目的

将“最新 V2 manifest 消费验证”从一次性发布前检查，提升为可重复、可审计、可监督的默认质量门禁。

## 2. 适用范围

- `ai-protocol`
- `ai-lib-rust`
- `ai-lib-python`
- `ai-lib-ts`

## 3. 标准执行命令（统一入口）

在 `ai-protocol` 仓运行：

```bash
npm run gate:manifest-consumption
```

脚本会依次执行：

1. `npm run validate`（protocol）
2. `cargo test --test generative_manifest_consumption --features multimodal`（rust）
3. `python -m pytest tests/integration/test_generative_manifest_consumption.py`（python）
4. `npm run test -- tests/protocol-v2.test.ts`（ts）

## 4. 输出与归档

- 默认报告目录：`ai-protocol/reports/manifest-gates/`
- 报告字段包括：
  - `summary`（total/passed/failed/status）
  - `checks`（每个子检查命令、耗时、exit code）
  - `failure_annotations`（owner/eta/rollback）

## 5. 判定策略

### required 模式（默认）

- 任一检查失败即 `blocked`，脚本退出非 0。

### report-only 模式

- 命令：`npm run gate:manifest-consumption -- --report-only`
- 用于治理过渡阶段，失败保留报告但不阻断流水线。

## 6. 失败注释模板（强制）

发生失败时，必须补齐以下字段并写入周监督记录：

- `id`: 失败检查项 ID（如 `python-manifest-consumption`）
- `owner`: 责任人（如 `@hiddenpath`）
- `eta`: 预计修复完成时间（ISO 日期）
- `rollback`: 临时回退策略（如降级 report-only / 回退到前一稳定版本）
- `detail`: 失败摘要（exit code + 关键信息）

## 7. 与监督节奏集成

沿用监督看板（Mon/Wed/Fri）：

- 周一：基线命令与环境路径核对
- 周三：失败注释闭环进度检查
- 周五：证据归档与风险升级（黄/红）

## 8. 环境路径约定

默认使用 sibling 路径；可通过环境变量覆盖：

- `AI_LIB_RUST_DIR`
- `AI_LIB_PYTHON_DIR`
- `AI_LIB_TS_DIR`

## 9. 升级策略

- 当前阶段：report-first + required（本地执行）
- CI 阶段：先 report-only，稳定两个周期后评估升级为 required

