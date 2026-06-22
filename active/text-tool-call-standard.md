# ai-lib 需求：标准化文本工具调用协议 (Text Tool Call Protocol)

**日期**: 2026-06-23  
**提出者**: velaclaw (Sisyphus)  
**优先级**: P1 — 阻塞 velaclaw 完整可用性  
**关联**: ai-lib-rust, ai-lib-core, ai-protocol

## 问题

ai-lib-core 已定义标准化的 `ToolCall` 结构体（`name`, `arguments`, `id`），但仅适用于支持 native function calling 的 provider（OpenAI 兼容格式）。

对于不支持 native function calling 的 provider（如 DeepSeek），各下游项目被迫自建文本解析层来从 LLM 的文本输出中提取工具调用。这导致：

1. **格式碎片化**：每个项目发明自己的 XML/JSON 格式
2. **Prompt 不可靠**：强 prompt 指令也无法约束 LLM 输出（DeepSeek 持续输出 `<shell>` 而非 `<tool_call>`）
3. **解析器不断修补**：需针对每个 LLM 的格式偏差（属性 vs JSON、`parameters` vs `arguments`、`<tool_calls>` 包装等）

### 实际案例 (velaclaw)

velaclaw 的 `XmlToolDispatcher` 期望格式：
```xml
<tool_call>
{"name": "shell", "arguments": {"command": "ls"}}
</tool_call>
```

DeepSeek 实际输出（5 轮迭代仍无法纠正）：
```xml
<shell>
  <command>ls -la</command>
  <approved>true</approved>
</shell>
```

```xml
<tool_call name="shell">
{"command": "ls -la", "approved": true}
</tool_call>
```

```xml
<tool_calls>
<tool_call id="1">
{"name": "shell", "parameters": {"command": "ls"}}
</tool_call>
</tool_calls>
```

**结果**：工具从不执行，Agent 是空壳。

## 需求

ai-lib-core 或 ai-lib-rust 应提供一个 **`TextToolParser`** 抽象层：

```rust
/// ai-lib-core 新增模块: src/types/text_tool.rs

pub trait TextToolParser: Send + Sync {
    /// 从 LLM 文本响应中提取工具调用
    fn parse(&self, response_text: &str) -> (String, Vec<ToolCall>);

    /// 生成强约束的 prompt 指令，确保 LLM 遵循格式
    fn prompt_instructions(&self, tools: &[ToolDefinition]) -> String;

    /// 将工具结果格式化为文本，供 LLM 继续对话
    fn format_results(&self, results: &[ToolResult]) -> String;
}
```

### 标准实现需求

1. **强 prompt 模板**：经过多个 LLM 测试验证的格式指令，能切实约束 LLM 行为
2. **容错解析器**：处理常见格式偏差（属性位置、字段名变体、嵌套包装）
3. **合规测试**：对 DeepSeek、Claude、Gemini 等主要非 OpenAI LLM 的格式输出验证
4. **默认实现**：`StandardTextToolParser` 使用单一标准化格式

### 下游影响

- velaclaw 可移除自建的 `XmlToolDispatcher`，改用 ai-lib 标准实现
- 所有基于 ai-lib 的 agent 项目共享同一套工具调用格式
- 新 provider 接入时无需适配格式

## 非目标

- 不替代 native function calling（OpenAI 兼容 provider 继续使用 native 路径）
- 不处理流式工具调用（Phase 2）
- 不定义 provider 级别的 tool spec schema（已有 `ToolDefinition`）

## 临时规避方案 (velaclaw)

在 ai-lib 提供标准实现前，velaclaw 已将 `XmlToolDispatcher` 的容错能力扩展到：
- 支持 `<tool_call name="...">` 属性提取
- 接受 `"parameters"` 作为 `"arguments"` 别名
- 自动剥离非标准字段 (`"approved"`)
- 无 `"arguments"`/`"parameters"` 包装时，将根对象视为 arguments

但仍无法处理 `<shell>` 格式——这需要 prompt 级别的约束，而非解析器修补。
