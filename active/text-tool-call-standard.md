# Text Tool Call Protocol — 标准化文本工具调用

**状态**: 需求分析 / 待排期  
**提出**: 2026-06-23, velaclaw (Sisyphus)  
**优先级**: P1 — 阻塞 velaclaw 工具执行  
**关联**: `ARCH-001` (一切逻辑皆算子), `ai-lib-core`, `ai-protocol`

---

## 1. 问题空间

### 1.1 现状

ai-lib-core 已定义标准化的 `ToolCall` / `ToolDefinition` / `ToolResult`（`src/types/tool.rs`），但仅覆盖 **native function calling** 路径（OpenAI-compatible JSON schema → API → structured response）。

对于 **不支持 native function calling** 的 provider（或 provider 支持不稳定），LLM 只能通过 **文本输出** 表达工具调用意图。ai-lib 在此路径上没有任何抽象，各下游项目被迫自建解析器。

### 1.2 实际症状 (velaclaw)

| 尝试 | Prompt 指令 | LLM 实际输出 | 解析结果 |
|------|------------|-------------|---------|
| 1 | 无特殊指令 | `<shell><command>ls</command></shell>` | ❌ 不识别的格式 |
| 2 | "Use `<tool_call>` JSON format" | `<tool_call name="shell">{"command":"ls"}</tool_call>` | ❌ name 在属性，JSON 无 `name` 字段 |
| 3 | "JSON must have `name` field" | `<tool_calls><tool_call id="1">{"name":"shell","parameters":{"command":"ls"}}</tool_call></tool_calls>` | ❌ `parameters` vs `arguments`, 嵌套包装 |
| 4 | "MUST use exact format, NEVER use `<shell>`" | `<tool_call>{"name":"shell","arguments":{"command":"ls"}}</tool_call>` | ⚠️ 偶尔正确，不稳定 |
| 5 | 同上 | `<shell><command>ls</command></shell>` | ❌ 回退到自有格式 |

**核心矛盾**：DeepSeek 模型的训练数据中 `<shell>` XML 是其首选工具调用格式。文本 prompt 指令无法可靠覆盖训练 bias。

### 1.3 受影响的 Provider

| Provider | Native Function Calling | 需文本方案 |
|----------|------------------------|-----------|
| OpenAI / Azure | ✅ 完整 | 否 |
| Anthropic Claude | ✅ (tool_use block) | 否（但格式非标准） |
| DeepSeek | ⚠️ 不稳定 / 部分模型不支持 | **是** |
| Google Gemini | ✅ | 否 |
| Groq / Together | ⚠️ 取决于后端模型 | 部分 |
| Ollama (本地) | ❌ 多数模型不支持 | **是** |
| 自部署 vLLM | ⚠️ 取决于模型 | 部分 |

**估算**：30-40% 的实际部署场景需要文本工具调用方案。

### 1.4 格式偏差分类 (已观察)

```
类别 1: 自有 XML 方言
  <shell><command>...</command></shell>
  <bash>...</bash>
  <function>...</function>

类别 2: 属性 vs JSON 字段
  <tool_call name="shell">{"command":"ls"}</tool_call>
  vs
  <tool_call>{"name":"shell","arguments":{"command":"ls"}}</tool_call>

类别 3: 嵌套包装
  <tool_calls><tool_call>...</tool_call><tool_call>...</tool_call></tool_calls>

类别 4: 字段名变体
  "parameters" / "params" / "args" 替代 "arguments"

类别 5: 非标准字段
  "approved": true, "thinking": "...", "confidence": 0.9
```

---

## 2. 架构设计

### 2.1 在 ai-lib 中的位置

```
ai-lib-core/src/types/
├── tool.rs           ← 已有: ToolCall, ToolDefinition, ToolResult
└── text_tool.rs      ← 新增: TextToolParser trait + StandardTextToolParser

ai-protocol/spec/
└── text-tool-call/   ← 新增: 协议规范 (YAML)
    ├── format.yaml       格式定义
    └── prompt.yaml       Prompt 模板

ai-protocol/tests/compliance/cases/
└── 10-text-tool-call/ ← 新增: 合规测试
    ├── basic-parse.yaml
    ├── attribute-variant.yaml
    ├── nested-wrapper.yaml
    ├── field-alias.yaml
    └── prompt-compliance.yaml
```

### 2.2 Trait 设计

```rust
/// ai-lib-core/src/types/text_tool.rs

/// 跨 LLM 的文本工具调用解析器。
/// 适用于不支持 native function calling 的 provider。
pub trait TextToolParser: Send + Sync {
    /// 从 LLM 文本响应中分离纯文本和工具调用。
    /// 返回 (纯文本部分, 工具调用列表)。
    fn parse(&self, response_text: &str) -> (String, Vec<ToolCall>);

    /// 生成强约束的 system prompt 指令。
    /// 注入到 System Prompt 中，指导 LLM 输出正确的工具调用格式。
    fn prompt_instructions(&self, tools: &[ToolDefinition]) -> String;

    /// 将工具执行结果格式化为 LLM 可理解的文本。
    /// 插入到对话历史中作为下一轮 LLM 输入。
    fn format_results(&self, results: &[ToolResult]) -> String;
}

/// 默认实现：单一标准化 XML/JSON 混合格式
pub struct StandardTextToolParser {
    /// 自定义配置
    config: TextToolConfig,
}

pub struct TextToolConfig {
    /// 是否启用容错解析（处理常见格式偏差）
    pub lenient_parsing: bool,
    /// 最大工具调用深度（嵌套 tool_call 内不再递归解析）
    pub max_call_depth: u8,
    /// 是否在 prompt 中包含反例（what NOT to do）
    pub include_counterexamples: bool,
}
```

### 2.3 标准化格式

```xml
<tool_call>
{"name": "shell", "arguments": {"command": "ls -la"}}
</tool_call>
```

**设计理由**：
- `<tool_call>` 作为 XML 边界，方便 LLM 理解和正则匹配
- JSON body 利用 LLM 的 JSON 生成能力，减少格式错误
- 不支持多行参数时，单行 JSON 也可工作
- 与 OpenAI function calling 的 `name` + `arguments` 结构一致，降低概念切换成本

### 2.4 Prompt 模板策略

问题：纯文本 prompt 指令无法可靠覆盖 LLM 的训练 bias。

策略（三级递进）：

| 级别 | 方法 | 适用场景 |
|------|------|---------|
| **L1: 标准指令** | 描述格式 + 示例 | 服从指令的模型 (Claude, GPT-4) |
| **L2: 反例警告** | 明确列出禁止格式 + 后果 | DeepSeek 等有格式偏见的模型 |
| **L3: Few-shot** | 注入 2-3 轮正确格式的对话示例 | 顽固模型 |

```markdown
## Tool Use Protocol

You have access to tools. To invoke a tool, output EXACTLY:

<tool_call>
{"name": "tool_name", "arguments": {"param": "value"}}
</tool_call>

CRITICAL RULES:
- Use <tool_call> ONLY. <shell>, <bash>, <function> WILL BE IGNORED.
- JSON must contain "name" (string) and "arguments" (object).
- Do NOT wrap in <tool_calls> or any other tag.
- If you output any other format, the tool WILL NOT execute.
```

### 2.5 容错解析器层级

```
输入文本
  │
  ├─ L1: 严格解析 ─── 仅接受标准格式 ──→ 成功 → 返回
  │                                          │
  ├─ L2: 属性补偿 ─── 从 <tool_call name="x"> 提取 name
  │                   "parameters" → "arguments"
  │                                          │
  ├─ L3: 嵌套解包 ─── 剥离 <tool_calls> 包装
  │                   id 属性忽略
  │                                          │
  └─ L4: 方言适配 ─── <shell> → shell tool
                      <bash> → shell tool
                      <function name="x"> → tool x
```

---

## 3. 任务拆分

### Phase 1: 协议规范 + Provider 调查 (ai-protocol) — 2-3天

**T1.1 格式规范编写**  
- 文件：`ai-protocol/spec/text-tool-call/format.yaml`
- 内容：标准格式定义、字段说明、错误处理约定
- 产出的 JSON Schema 可被各语言 SDK 引用

**T1.2 Prompt 模板规范**  
- 文件：`ai-protocol/spec/text-tool-call/prompt.yaml`
- 内容：L1/L2/L3 三级 prompt 模板，含变量占位符
- 多语言：EN / ZH 双语版本

**T1.3 合规测试用例**  
- 目录：`ai-protocol/tests/compliance/cases/10-text-tool-call/`
- basic-parse.yaml — 标准格式解析
- attribute-variant.yaml — 属性提取
- nested-wrapper.yaml — 嵌套解包
- field-alias.yaml — 字段别名
- prompt-compliance.yaml — prompt 模板注入验证

**T1.4 Provider 工具调用能力调查**  
- 目录：`ai-protocol/research/tool-calling/`
- 对主要 provider 逐一调查 native function calling 的实际可靠性
- 记录各 provider 的文本格式偏差（known_dialects）
- 调查清单：DeepSeek, Anthropic, Google, Groq, Together, Ollama, 自部署 vLLM

**T1.5 Manifest schema 扩展**  
- 在 `ai-protocol/schemas/v2/provider.json` 中新增 `tool_calling` 块（见第 6 节）
- 向后兼容：`tool_calling` 为 optional，缺失时默认 native full support
- 更新现有 provider manifest 填充 `tool_calling` 字段

### Phase 2: Rust 参考实现 (ai-lib-rust/ai-lib-core) — 3-5天

作为性能基准和 trait 定义的 reference implementation。

**T2.1 TextToolParser trait + StandardTextToolParser**  
- 文件：`ai-lib-core/src/types/text_tool.rs`
- `TextToolParser` trait 定义（所有运行时共享同一 trait 语义）
- 严格解析器（L1）
- 单元测试覆盖所有合规用例

**T2.2 容错解析器（L2-L4）**  
- `lenient_parsing = true` 时启用
- 属性提取、字段别名、嵌套解包、方言适配
- 每个容错层级独立测试

**T2.3 Prompt 模板引擎**  
- `prompt_instructions()` 实现
- 支持 L1/L2/L3 级别切换
- `include_counterexamples` 控制是否注入反例
- 测试：对已知顽固模型验证 prompt 有效性

**T2.4 与现有 Provider trait 集成**  
- `Provider::supports_native_tools()` → false 时自动切换
- 或提供 `Provider::text_tool_parser()` 方法
- 不破坏现有 NativeToolDispatcher 路径

### Phase 3: 多语言运行时对齐 — 2-3天

`ARCH-003`：所有运行时（Rust/Python/TS）通过同一套 ai-protocol 合规测试。

**T3.1 合规测试框架适配**  
- 将 Phase 1 的合规用例（basic-parse, attribute-variant, nested-wrapper, field-alias, prompt-compliance）注册到各运行时合规 runner
- 确保 YAML 测试用例跨语言共享，不做复制

**T3.2 Python 实现 (ai-lib-python)**  
- `TextToolParser` 等价 abstract class / protocol
- `StandardTextToolParser` 实现，行为与 Rust 参考实现一致
- 合规测试通过（与 Rust 共享同一套 YAML 用例）

**T3.3 TypeScript 实现 (ai-lib-ts)**  
- `TextToolParser` interface
- `StandardTextToolParser` 实现
- 合规测试通过

**T3.4 确定性验证**  
- 同一输入文本 → 三个运行时输出相同的 `(text, Vec<ToolCall>)`
- 同一 tool list → 三个运行时生成等价的 prompt 指令
- 交叉测试：Rust 解析器处理 Python SDK 的输出，反之亦然

**T3.5 Prompt 模板多语言对齐**  
- EN / ZH prompt 模板在各运行时中行为一致
- 变量替换规则统一（`{tool_name}`, `{tool_desc}`, `{param_schema}` 等）

### Phase 4: 模型验证 — 2-3天

**T4.1 DeepSeek 验证**  
- deepseek-chat, deepseek-reasoner 两个模型
- 测试 prompt 指令的有效性（5 轮重复）
- 记录格式偏差残留情况

**T4.2 Claude 验证**  
- Claude 3.5 Sonnet, Claude 3 Opus
- 验证 text 路径 vs native tool_use 路径的一致性

**T4.3 Ollama 本地模型验证**  
- Llama 3, Qwen 2.5, Mistral
- 覆盖不同参数规模的模型

**T4.4 回归测试**  
- 确保 native function calling provider（OpenAI）不受影响
- 确保 ai-lib-rust 现有测试全部通过

### Phase 5: 下游迁移 — 1-2天

**T5.1 velaclaw 迁移**  
- 移除 `XmlToolDispatcher`
- 改用 `StandardTextToolParser`
- 验证 E2E 工具执行（ls, file_read, shell）

**T5.2 迁移指南**
- 文档：`ai-lib-rust/docs/text-tool-migration.md`
- 覆盖：API 变更、配置迁移、测试策略

---

## 4. 验收标准

| 标准 | 度量 |
|------|------|
| DeepSeek 5 轮对话中 ≥4 轮输出标准格式 | Pass/Fail |
| 容错解析器能处理全部 5 类格式偏差 | 5/5 |
| 合规测试 100% 通过 (Rust + Python + TS) | `cargo test` / `pytest` / `jest` |
| 同一输入在三运行时输出一致的 `(text, Vec<ToolCall>)` | 确定性测试通过 |
| velaclaw 工具执行 E2E 通过 | ls + file_read + shell |
| 不破坏现有 native function calling 路径 | 现有测试不退化 |

---

## 5. 风险 & 缓解

| 风险 | 概率 | 缓解 |
|------|------|------|
| 部分 LLM 无论 prompt 如何都无法遵循格式 | 中 | L3 few-shot + 最终降级为原生格式适配（方言解析器） |
| 文本路径延迟明显高于 native 路径 | 低 | 文本解析本身 <1ms；额外 LLM 轮次由调用方控制 |
| Provider trait 改动影响面过大 | 低 | 新增可选方法，默认实现返回 None，不影响现有代码 |
| 三语言解析行为不一致 | 中 | T3.4 确定性交叉验证；合规测试共享 YAML 用例，不做复制 |

---

## 6. Provider Manifest 增强：工具调用能力声明

### 6.1 现状

当前 manifest（以 `deepseek.json` 为例）：

```json
"capabilities": {
    "required": ["tools"],
    "feature_flags": {
        "parallel_tool_calls": true
    }
}
```

`"tools"` 是一个**二进制标记**：有或无。不区分：
- 是 native function calling（OpenAI 格式）还是 API 仅透传
- 实际可靠性如何（DeepSeek 声明支持但部分模型不稳定）
- 不支持 native 时的 fallback 文本格式是什么

### 6.2 提案：`tool_calling` 块

在 provider manifest 中新增 `tool_calling` 块，描述该 provider 的工具调用实际能力：

```yaml
# 示例：OpenAI（native 完整支持）
tool_calling:
  native:
    supported: true
    reliability: full          # full | partial | unreliable
    parallel: true
    streaming: true
  text_fallback: null          # 不需要 text fallback

# 示例：DeepSeek（部分支持，需 text fallback）
tool_calling:
  native:
    supported: true
    reliability: partial       # deepseek-chat 支持，reasoner 不稳定
    parallel: true
    streaming: true
    notes: "deepseek-reasoner 模型 function calling 不稳定，建议 text fallback"
  text_fallback:
    format: xml_json           # xml_json | markdown_fence | custom
    wrapper: "tool_call"       # 外层标签
    body: json                 # 内容格式
    name_location: attribute   # attribute | json_field
    args_key: "parameters"     # arguments | parameters | params
    known_dialects:            # 该 provider 常见但非标的输出格式
      - tag: "shell"
        map_to: "shell"
      - tag: "bash"  
        map_to: "shell"
    prompt_level: L2           # 推荐的 prompt 策略级别

# 示例：Ollama / 本地模型（无 native 支持）
tool_calling:
  native:
    supported: false
  text_fallback:
    format: xml_json
    wrapper: "tool_call"
    body: json
    name_location: json_field
    args_key: "arguments"
    prompt_level: L2
```

### 6.3 Manifest 字段语义

| 字段 | 类型 | 说明 |
|------|------|------|
| `native.supported` | bool | 是否支持 OpenAI-compatible function calling |
| `native.reliability` | enum | `full` / `partial` / `unreliable` — 决定是否启用 text fallback |
| `text_fallback.format` | enum | 推荐文本格式：`xml_json`, `markdown_fence`, `custom` |
| `text_fallback.wrapper` | string | 工具调用的 XML 包装标签 |
| `text_fallback.body` | enum | 内容格式：`json` / `yaml` / `plain` |
| `text_fallback.name_location` | enum | tool name 位置：`attribute`（标签属性）或 `json_field`（JSON 字段） |
| `text_fallback.args_key` | string | arguments 的 JSON 键名（处理 `parameters` vs `arguments`） |
| `text_fallback.known_dialects` | array | 该 provider 特有的非标格式 → 标准 tool 映射 |
| `text_fallback.prompt_level` | enum | 建议的 prompt 策略：L1（标准）/ L2（反例）/ L3（few-shot） |

### 6.4 对运行时的收益

```
运行时启动
  │
  ├─ 加载 provider manifest
  │     │
  │     ├─ native.reliability = full  → 使用 NativeToolDispatcher
  │     │
  │     └─ native.reliability ≠ full  → 读取 text_fallback 配置
  │           │
  │           ├─ 自动选择 prompt_level
  │           ├─ 预配置 known_dialects 映射
  │           └─ 设置 args_key / name_location 容错参数
  │
  └─ StandardTextToolParser::from_manifest(manifest)
       → 零代码适配新 provider
```

### 6.5 任务补充

在 Phase 1 中新增：

**T1.4 Provider 工具调用能力调查**  
- 对主要 provider 逐一调查 native function calling 的实际可靠性
- 记录各 provider 的文本格式偏差（known_dialects）
- 产出：`ai-protocol/research/tool-calling/` 下的调研报告

**T1.5 Manifest schema 扩展**  
- 在 `ai-protocol/schemas/v2/provider.json` 中新增 `tool_calling` 块
- 向后兼容（`tool_calling` 为 optional，缺失时默认 `native: {supported: true, reliability: full}`）

---

## 7. 参考资料

- `ai-lib-core/src/types/tool.rs` — 现有 ToolCall 定义
- `ai-protocol/tests/compliance/cases/04-streaming/tool-accumulation.yaml` — 现有 native tool call 测试
- `ai-lib-constitution/rules/ARCH-003.md` — 跨运行时一致性要求
- `velaclaw/src/agent/dispatcher.rs` — 当前 text tool 解析实现（迁移前参考）
- `velaclaw/src/agent/agent.rs:342-347` — dispatcher 选择逻辑
