# P1/P2 编码执行波次（Wave 1）— 2026-03-07

## 1. 目标

将规划态任务转为可执行代码交付，优先覆盖：

1. `PT-015`：mock 多模态链路的异步轮询与失败注入闭环  
2. `PT-023`：协议侧漂移检测自动化最小可用实现（MVP）  
3. `PT-024`：发布门禁自动化判定脚本（GO / BLOCK）

## 2. 编码实施计划（执行版）

### Batch-A：ai-protocol-mock 行为增强（PT-015）

- 实施项
  - 新增视频生成接口：`POST /v1/video/generations`
  - 新增异步查询接口：`GET /v1/video/generations/{job_id}`
  - 新增统一测试控制头处理器（status/timeout/invalid-content-type）
  - 复用到 chat / stt / tts / rerank / video 端点
- 验收口径
  - 支持 sync + async-polling
  - 支持失败注入：`X-Mock-Status` / `X-Mock-Timeout-Ms` / `X-Mock-Invalid-Content-Type`
  - 新增测试并全量通过

### Batch-B：ai-protocol 漂移检测自动化（PT-023）

- 实施项
  - 新增 `scripts/drift-detect.js`
  - 检查维度：`v2/providers`、compliance fixtures、protocol-loading cases
  - 输出报告到 `reports/drift/`
  - 提供 CI 友好退出码（发现 high/critical 漂移则非 0）
- 验收口径
  - 覆盖 P0 provider：OpenAI/Anthropic/Google/DeepSeek/Qwen/Doubao
  - 支持 legacy fixture 命名兼容（`mock-<id>.yaml`）
  - 生成可归档 JSON 报告

### Batch-C：发布门禁自动化（PT-024）

- 实施项
  - 新增 `scripts/release-gate.js`
  - 新增示例输入 `scripts/release-gate-input.example.json`
  - 新增 npm 命令：`release:gate`
  - 输出报告到 `reports/release-gates/`
- 验收口径
  - 校验 coverage / compliance / stability / rollback / docs 五维门禁
  - 输出 `pass` 或 `blocked`，并给出失败项
  - 支持 `--input=<path>` 覆盖默认输入

## 3. 实际编码结果

### 已交付代码

- `ai-protocol-mock`
  - `src/ai_protocol_mock/mocks/http_provider.py`
  - `tests/test_mock.py`
- `ai-protocol`
  - `scripts/drift-detect.js`
  - `scripts/release-gate.js`
  - `scripts/release-gate-input.example.json`
  - `package.json`
  - `README.md`
  - `tests/compliance/fixtures/providers/mock-google-v2.yaml`
  - `tests/compliance/fixtures/providers/mock-deepseek-v2.yaml`
  - `tests/compliance/cases/01-protocol-loading/load-v2-p0-generative-providers.yaml`

### 验证证据

- `ai-protocol-mock`
  - `python -m pytest tests/test_mock.py` -> `22 passed`
- `ai-protocol`
  - `npm run validate` -> `Failed: 0`
  - `npm run drift:check` -> `Drifts: 0`
  - `npm run release:gate` -> `Status: pass`

## 4. 风险与回滚

- 风险
  - Mock 新增视频异步行为可能影响既有调用方的默认假设（仅同步返回）。
  - 自动化脚本初期规则可能产生误报/漏报。
- 回滚策略
  - Mock：可回退新增视频端点与测试控制头统一入口。
  - 自动化：`drift:check`/`release:gate` 保持可独立禁用，不影响 `validate` 主链路。

## 5. 下一波建议（Wave 2）

- 将 `drift:check` 接入 CI 的 report-only 阶段并沉淀周报。
- 扩展 `release:gate` 输入为真实流水线指标来源（而非示例静态输入）。
- 为三运行时补充同一套视频异步语义对齐用例（request/poll/terminal states）。
