# ai-protocol-mock 生成式模型场景扩展规范

> 状态：Wave-4 执行产出（PT-059）
> 日期：2026-03-30
> 目标仓库：`ai-protocol-mock`（Python/FastAPI）

## 1. 目标

扩展 `ai-protocol-mock` 的 `http_provider.py`，使其支持生成式 LLM 特有的行为模拟，
供四运行时的 `08-generative-capabilities` compliance 测试消费。

## 2. 新增场景清单

### 2.1 Token Usage 报告

- **控制方式**: 请求头 `X-Mock-Usage-Format: openai|anthropic|gemini`
- **行为**:
  - `openai`: `usage.prompt_tokens`, `completion_tokens`, `total_tokens`, `completion_tokens_details.reasoning_tokens`
  - `anthropic`: `usage.input_tokens`, `output_tokens`（外加 `cache_creation_input_tokens`, `cache_read_input_tokens`）
  - `gemini`: `usageMetadata.promptTokenCount`, `candidatesTokenCount`, `totalTokenCount`
- **默认**: 跟随请求路径自动选择格式（`/v1/chat/completions` → openai, `/v1/messages` → anthropic）

### 2.2 Reasoning Mode 模拟

- **控制方式**: 请求头 `X-Mock-Reasoning: true`
- **行为（Anthropic 风格 /v1/messages）**:
  - 流式响应先发 `content_block_start` (type=thinking)，再发 thinking delta，再发 text content block
  - `usage` 含 reasoning tokens（在 `output_tokens` 之外额外报告）
- **行为（OpenAI 风格 /v1/chat/completions）**:
  - 在 `choices[0].message` 中增加 `reasoning_content` 字段
  - `usage.completion_tokens_details.reasoning_tokens` 填充
- **流式**: thinking chunks 先于 answer chunks 发出

### 2.3 结构化输出（JSON Mode）

- **控制方式**: 请求 body 中 `response_format.type = "json_object"` 或 `"json_schema"`
- **行为**:
  - `json_object`: 返回 `{"result": "mock_structured_output", "items": ["a","b","c"]}`
  - `json_schema`: 校验请求中的 schema 是否存在（不校验内容），返回符合格式的 mock JSON
- **流式**: JSON 分 chunk 返回，最终拼接为完整 JSON

### 2.4 工具调用场景

- **单工具调用**: 已有基础，保持现状
- **并行工具调用**: `X-Mock-Tool-Calls: parallel`
  - 返回 `choices[0].message.tool_calls` 含 2 个并行工具调用
- **递归工具调用**: `X-Mock-Tool-Calls: recursive`
  - 第一轮返回工具调用；客户端提交工具结果后，第二轮再返回一个工具调用
  - 控制深度：`X-Mock-Tool-Depth: 2`（默认 2）
- **MCP 工具桥接**: `X-Mock-Tool-Calls: mcp`
  - 工具定义和调用使用 MCP 格式（`tool_use` content block）

### 2.5 错误注入（生成式特有）

- **上下文溢出**: `X-Mock-Error: context_overflow`
  - 返回 400, `error.code: "context_length_exceeded"`
- **内容过滤**: `X-Mock-Error: content_filter`
  - 返回 400, `error.code: "content_filter"`, `finish_reason: "content_filter"`
- **速率限制（含 Retry-After）**: `X-Mock-Error: rate_limit`
  - 返回 429, `Retry-After: 5` header
- **流式中断**: `X-Mock-Error: stream_interrupt`
  - 发送 3 个正常 chunk 后中断连接

### 2.6 多模型 metadata 模拟

- **控制方式**: 请求 body `model` 字段
- **行为**: 根据模型名返回不同的 `context_window` 等 metadata
  - `gpt-4o` → context_window: 128000
  - `claude-3.5-sonnet` → context_window: 200000
  - `gemini-2.0-flash` → context_window: 1000000
  - 未知模型 → context_window: 4096（安全默认）

## 3. 实现约定

- 所有新场景遵循现有 `_apply_test_controls` → error/delay → 核心逻辑 模式
- Header 控制优先于 body 控制
- 所有行为确定性（无随机性），便于 compliance 复现
- 未知 header 值回退到安全默认
- 不新增 endpoint path；复用 `/v1/chat/completions`, `/v1/messages`, Gemini 路径

## 4. 测试覆盖

新增 `tests/test_generative.py` 覆盖：
- token usage 三种格式提取
- reasoning mode 流式输出
- structured output json_object/json_schema
- parallel/recursive tool calls
- context_overflow / content_filter / rate_limit 错误注入
- stream_interrupt 行为

## 5. 回滚策略

- 新增行为仅在 `X-Mock-*` header 触发时激活，不影响现有默认行为
- 如需回滚：移除新增 handler 分支即可，现有测试不受影响
