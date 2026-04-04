# md2latex App Protocol - Minimal Contract (v0.1)

> 目标：让 `md2latex` 这类 AI 原生应用可以用 YAML graph 声明流程，再由 App Runtime interpreter 执行。
> 约束：本文件只冻结最小字段集合；后续迭代通过增加字段或版本号完成。

## 0. 约定

1. 本合同中的“应用运行时（App Runtime）”是 graph interpreter；不等同于 `ai-protocol` 的执行 runtime。
2. 本合同中的“执行运行时（Execution runtime）”仅负责 LLM 调用与 streaming 事件归一；由实现方对接 `ai-lib-rust`。
3. 本合同中的“错误日志（error_log）”是可读摘要，不包含敏感信息；用于驱动 LLM 节点重提示重试。

## 0.1 AI 原生应用：意图、schema 与 LLM 闭包

以下原则用于约束 **AI 原生应用** 的产品形态与实现分工；与本合同中的 YAML graph、最小运行时（graph interpreter）对齐，但不替代下文各节的**最小字段**定义。

### 0.1.1 输入与声明

- **唯一外部输入**：用户意图（自然语言或其它交互形态均可，经宿主归一为意图描述即可）。
- **程序功能与输出形态**：由 **schema**（本合同的 app schema、FigureSpecV1、以及上层与 `ai-protocol` 对齐的能力/工具声明）统一声明；schema 是 **对 LLM 可生成内容与运行时行为的共同契约**，而不是与模型脱节的第二套“手写业务脚本”。

### 0.1.2 Graph 的来源与第一步

- **Graph（或可执行计划）** 通常不是产品作者逐行维护的主路径，而是由 **planner** 经 **orchestrator** 调用 **最小运行时**，向 **LLM** 请求得到的、**符合 schema** 的结构化产物；这往往是应用功能流程的 **第一步**。
- 仓库中 **手写 YAML graph** 在完整叙事下应视为：**测试夹具、默认配方、seed** 或与 LLM 生成物 **同构** 的可消费对象；运行时对二者走 **同一套** 解析、校验与执行路径。

### 0.1.3 “所有结果来自 LLM”的精确含义

- **语义与计划层面**：执行图、节点绑定、工具/op 调用列表、面向用户的中间说明等，均应能 **追溯到** LLM 在 schema 约束下的生成。
- **工程层面**：宿主侧的解析、校验、调度、以及对已生成内容的 **确定性物化**（例如 JSON 解析、字符串替换、局部纯计算）属于 **执行层**；产品逻辑上不把“人另写的隐藏业务线”夹在中间——**可观测的中间态**仍视为该次运行中 **LLM 驱动流水线** 的一部分，便于审计与纠偏（与 0.2 节一致）。

## 0.2 Human-in-the-loop 与流程可治理性（实现侧必选）

为保证 **用户意图可被落实、可被纠偏**，AI 原生应用的端到端流程在实现上必须满足下列能力；本合同要求 **产品/宿主** 在架构上预留挂钩，不要求 v0.1 一次性做满 UI，但 **不得** 设计成无法补齐的形态。

| 能力 | 含义 | 目的 |
|------|------|------|
| **可视化** | 用户可看到当前/历史 **计划（含 graph）**、节点状态、关键中间产物（经脱敏与隐私策略过滤后的摘要或结构化视图） | 理解“系统在做什么”，降低黑箱感 |
| **可编辑** | 在用户授权前提下，可对 **计划、提示、绑定、待执行调用** 等进行人工修改后再提交执行 | 意图纠偏、应急改道、专家介入 |
| **可回溯** | 每次运行具备 **可追溯记录**（时间、输入意图版本、schema 版本、LLM 请求/响应摘要或引用、图版本、错误与重试链路） | 复盘、排错、合规与复现 |
| **可授权** | 对外部 API、敏感数据、高影响 op（写文件、网络、多步提交等）实行 **显式同意与策略**（谁、何时、何种范围） | 安全与信任，与最小权限一致 |

**Human-in-the-loop** 指：上述能力共同支撑 **人在回路**——用户或受信任操作者能在关键节点 **审阅、批准、修改或中止** 自动化流程，使 **用户意图的实现与纠偏** 成为一等需求，而非事后补救。

> 说明：`error_log` 驱动的 LLM 重试（见第 4 节）属于 **自动纠偏**；0.2 节要求的是 **人机协同纠偏** 的基础设施，两者互补。

## 0.3 实现侧非功能约束（薄层、中间态、HITL）

以下三条为 **编码与演进守则**，与 0.1 / 0.2 一致，用于避免 interpreter / graph 引擎再次膨胀为“万能胶”；不新增合同字段，但 **实现应遵守**。

### 0.3.1 薄层守则（编排 vs 业务）

- **Graph / App Runtime（如 `GraphRuntimeV0_1`）** 只负责：解析 schema、DAG 调度、变量与 prompt 解析、op 派发、策略类扩展点（trace、step gate、policy）。
- **禁止**在 graph 引擎核心路径内编写 Markdown / LaTeX / 具体厂商 API 等 **领域专有逻辑**；此类逻辑必须落在 **独立 op handler、tool 适配层或可替换模块** 中。
- 新能力优先通过 **注册新 `op` / 新 handler** 扩展，而非在调度层加分支或特例。

### 0.3.2 中间态守则（可观测、可追溯、可选落盘）

- 业务中间结果应优先以 **结构化数据**（如运行时变量表中的 JSON 值）在流水线内传递，避免不可追溯的临时字符串拼接成为隐式协议。
- **可回溯** 须能通过运行记录体现（例如 trace 事件、节点级成功/失败摘要）；**不得**依赖仅存在于日志 printf 且无法与某次 `run_id` 关联的状态。
- **可选落盘**（如将选定变量导出为 `.json`）可作为 HITL / 调试增强；默认可关闭，避免强制写盘带来的隐私、体积与路径管理负担（与 0.2「可编辑」演进一致）。

### 0.3.3 HITL 与授权守则（高影响动作）

- 对 **网络出站**（如 LLM HTTP）、**写文件**、以及未来 **子进程 / 编译器 / 包管理** 等高影响能力，须有 **显式策略与同意机制**（环境变量、CLI flag、宿主策略等均可，但必须可审计、可默认收紧）。
- 上述动作应能被 **trace / 运行记录** 关联到具体节点或阶段，便于纠偏与复盘（与 0.2「可授权」「可回溯」一致）。

**参考实现入口（Rust，`md2latex` 仓库）**：`GraphRunObserverV0_1`、`GraphTraceEventV0_1`、`StepGateV0_1`、`RunAppConfig`（graph 运行时）；`FinalVarsDumpV0_1`（可选最终变量表 JSON 导出）；策略见 `policy` 模块；CLI 子命令 `plan` / `run`。

## 1. 顶层 App Schema（最小字段）

```yaml
app_schema:
  schema_version: "0.1"
  name: "md2latex_app"
  output: "final_markdown"   # variable name
  graph:
    start: "node_id"          # 可选；默认按 nodes 列表第一个节点执行
    nodes:
      - id: "node_1"
        op: "op_type"
        inputs:                         # 显式输入映射（允许 $ref 引用或字面量）
          var_name: "$ref"            # 引用前置节点 outputs / app inputs
          system_prompt: "$prompt.llm_ascii_to_figure_v1.system"
          user_prompt: "{{block_text}}"
        outputs: { var_name: "$ref_or_local" } # 输出变量名
        fanout:                        # 可选
          over: "$ref"                # 对哪个输入集合做并行/迭代
          limit: 10                   # MVP 默认上限；超过需失败返回下一版扩容
          concurrency: 4             # 并发上限（可空，runtime 用默认）
        retry:                          # 可选
          max_attempts: 3
          feedback_to: "error_log"     # runtime 负责把 error_log 回填到某个输入
          on: ["json_parse_error","output_validation_error","latex_validation_error"]
```

说明：
- `inputs`/`outputs`：只使用变量名与引用（`$ref` 指向前置节点 outputs 或 app inputs）。
- `inputs.<field>` 的值也可为字面量字符串，用于在 app schema 内直接携带开发者意图（prompt 模板）。
- 引用约定：
  - `$ref`：引用前置节点 outputs 或 app inputs
  - `$prompt.<prompt_id>.<field>`：引用 schema 顶层 `prompts` 下的提示模板
- 模板渲染（最小约束）：使用 `{{var_name}}` 占位符替换为运行时上下文变量（例如 `block_text`）。
- `retry.on`：最小约束集合；runtime 可映射到实际错误类型并产出 `error_log`。

## 1.1 Prompts（开发者意图携带，最小字段）

为保证“runtime 无状态且只做事”，本 contract 允许在 app schema 顶层携带必要 prompts：

```yaml
app_schema:
  prompts:
    llm_ascii_to_figure_v1:
      system: "..."
      user: "..."
```

其中 `system/user` 都可包含模板占位符 `{{...}}`，由 runtime 在执行该节点时渲染后发给 LLM。

## 1.2 Prompts 结构化组织与索引（约定）

> v0.1 里 runtime 通过 `app_schema.prompts` 的 key 进行解析；为了可维护性，建议额外约定索引与组织规则（可选字段，不改变最小合同）。

- `prompts` 下的每个 key 是一个唯一的 `prompt_id`（例如 `llm_ascii_to_figure_v1`）
- 同一类能力（例如 “LLM 生成 figure”）尽量使用同一命名前缀（例如 `llm_...`），并用 `_vN` 表示版本
- 建议在文档侧维护一个“人类可读索引”，列出所有已实现的 `prompt_id` 及其用途
- 可选：在 schema 里新增 `app_schema.prompt_index: [prompt_id...]` 用于人类快速检索；runtime 如果不实现该字段也必须不报错

## 2. 最小 GraphNode op_type 列表（v0.1）

本 MVP 固定需要的 op_type：

1. `markdown.extract_fenced_blocks_v1`
   - 输入：`markdown_text: string`
   - 输出：`ascii_blocks: [ { block_id, block_text, fence_lang } ]`
   - fence 识别规则：以 fenced code block 为单位；是否“ascii 与表/图分类”由后续 LLM 负责

2. `llm.generate_json_v1`
   - 通用 LLM JSON 生成 op
   - 输入：
     - `system_prompt: string`（来自 schema 的 prompts 或节点 inputs）
     - `user_prompt: string`（可含占位符，如 `{{block_text}}`）
     - `error_log?: string`（由 runtime 在重试时注入）
     - `model_pool?: [ { model_id, api_key_env } ]`（可选；MVP 可由 runtime 默认 env 探测）
   - 输出：`json_result: object`（由 runtime 做 JSON 解析）

3. `figure.spec_validate_v1`
   - 输入：`figure_spec: object`
   - 输出：`figure_spec_validated: object`（通过校验则原样返回）

4. `md.replace_blocks_with_latex_v1`
   - 输入：
     - `markdown_text: string`
     - `figures: [ { block_id, figure_latex } ]`
   - 输出：`final_markdown: string`

> 说明：`ascii 图/表识别 + 输出 figure/table LaTeX` 由 `llm.generate_json_v1` 的提示词与输出合同完成，不单独抽成一个 op_type，保持最小 contract。

## 3. FigureSpecV1 输出合同（结构化 JSON，v0.1）

LLM 节点必须只输出一个 JSON object（不允许自然语言解释）：

```json
{
  "content_type": "figure" | "table",
  "block_id": "string",
  "figure_latex": "string"
}
```

约束：
- `content_type`：
  - `figure`：用于图（TikZ/流程图/架构图等），通常封装在 `\\begin{figure}...\\end{figure}` 或你约定的图环境
  - `table`：用于表（最终可在 LaTeX 里映射到 `\\begin{table}...\\end{table}` 或等价结构）
- `block_id`：必须与输入集合里的 `block_id` 完全一致
- `figure_latex`：
  - 必须是“完整 figure/table 结构”（按你的要求），可直接插入回 Markdown 或进一步交给 pandoc
  - 必须包含必要环境起止（例如 `\\begin{figure}` 或 `\\begin{table}`），否则视为 `latex_validation_error`

## 4. 错误反馈（error_log）最小策略

runtime 在以下错误类型发生时触发重试，并把 `error_log` 注入到 LLM 节点输入（对应 `llm.generate_json_v1` 的 `error_log`）：
- `json_parse_error`：LLM 输出不是合法 JSON
- `output_validation_error`：JSON 可解析但不满足 FigureSpecV1
- `latex_validation_error`：`figure_latex` 不满足最小 LaTeX 环境/关键字约束

> MVP 不要求编译 LaTeX；只要求基于规则的结构校验即可。后续迭代可加入编译日志驱动。

## 5. 并发与上限

- 默认 `ascii_blocks` 上限为 `10`（你规定的 MVP）；超过返回错误提示“需升级到下一版扩容”。
- `fanout.limit` 与 `fanout.concurrency` 由 graph schema 声明；runtime 负责执行背压（最小实现：超并发直接排队或拒绝）。

## 6. 版本演进建议

- v0.1：只冻结本文字段与 FigureSpecV1
- v0.2：可加入
  - `latex_validation` 更细粒度或编译日志回填
  - 更丰富的 figure/table meta 字段（caption/label）
  - 更多 op_type（例如 ASCII 表的确定性转换器等）
  - prompt distillation（精炼但充分的提示词生成）：
    - 新增 op_type：`llm.prompt_distill_v1`
    - 输入：`developer_intent` + `block_text` + （可选）`error_log`
    - 输出：`system_prompt/user_prompt`（替换给后续 `llm.generate_json_v1` 节点使用）

