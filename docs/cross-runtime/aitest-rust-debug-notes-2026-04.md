# aitest + ai-lib-rust 联调排障纪要（2026-04）

> **用途**：记录在 `aitest`（演示应用）与 `ai-lib-rust` / `ai-protocol` 联调中暴露的问题与根因，供 **Python / TypeScript / Go** 等运行时做 manifest 解析、非流式/流式路径、传输层行为对齐时对照。  
> **范围**：以 DeepSeek 等 OpenAI 兼容厂商为主；结论多具通用性。  
> **关联**：`ai-protocol` v2 manifests、`ai-lib-core` 非流式解析、流式 pipeline、`HttpTransport`。

---

## 1. 现象：非流式 200 OK，但助手正文为空

- **表现**：上游 JSON 里已有 `choices[0].message.content`，本地 `/chat` 返回 `content` 空，usage 可能为估算值；日志或告警提示需检查 key / 代理 / 协议映射。
- **根因**：运行时加载的是 **v2 manifest**（如 `dist/v2/providers/*.json`），其中未提供与 v1 等价的 **`response_paths.content`**（或等价非流式映射）。非流式解析逻辑**仅按 manifest 声明路径**取正文，路径缺失时不会落到常见 OpenAI 形状。
- **对齐要点**：
  - **协议**：v2 OpenAI 兼容厂商应在 manifest 中明确非流式 `response_paths`（或运行时规范约定缺省路径）。
  - **运行时**：在「manifest 未声明」时，应对 **OpenAI Chat Completions** 形状提供 **兜底路径**（例如 `choices[0].message.content`），避免静默空结果。
- **验证**：对同一模型直接 `curl` 上游与 `curl` 本地 `/chat`，对比 JSON 与解析结果。

---

## 2. 现象：流式开启后无 delta，仅有 usage / done（或 completion 恒为 0）

此处曾叠加 **多个** 独立问题，需分层排除。

### 2.1 请求体未带 `stream: true`

- **根因**：v2 manifest 缺少 **`parameter_mappings`** 中对 `stream` 的映射（例如 `stream: "stream"`）。编译请求时未把 SDK 的流式标志写入 HTTP body，上游按**非流式**返回**整段 JSON**。
- **表现**：流式解码器按 SSE/增量语义解析，实际收到的是单次大块 JSON，**无**符合预期的增量 `delta` 事件序列。
- **对齐要点**：凡支持 SSE 的 OpenAI 兼容厂商，manifest 必须显式映射 `stream`（以及常用 `temperature`、`max_tokens`、`tools` 等），与各语言运行时的 `compile_request` 规则一致。

### 2.2 `streaming.event_map` 与 `RuleBasedEventMapper` 契约不一致

- **根因**：部分 v2 YAML 使用了 **`extract:`** 或 **`match:` 为单一路径字符串**；而规则映射器期望 **`fields:`** 以及 **`match` 为布尔表达式**（如 `exists($.choices[*].delta.content)`）。规则不匹配则**不产生** `PartialContentDelta`。
- **对齐要点**：
  - **协议**：统一 v2 `event_map` 的 schema 与示例，并在 `npm run validate:providers` 或 CI 中校验。
  - **运行时**：对 `streaming.decoder.strategy == openai_chat` 可优先走 **路径驱动**的 `PathEventMapper`（`content_path` / `usage_path` 等），降低与规则语法强耦合导致的静默失败。

### 2.3 传输层 `Accept` 与上游期望不一致

- **根因**：流式请求若未使用 **`Accept: text/event-stream`**，部分网关/厂商行为不一致（与非流式 `application/json` 混用风险）。
- **对齐要点**：在通用 HTTP 传输层区分流式与非流式的 **Accept**（及必要的头策略），并在各运行时保持一致。

---

## 3. 为何「同为 OpenAI 兼容」，Groq 与 DeepSeek 的 manifest 差别很大？

- 并**非**协议层否定 OpenAI 兼容，而是 **manifest 完整度**不同：一侧已包含非流式路径、流式字段、`parameter_mappings`、`event_map` 等；另一侧 v2 片段不完整会导致运行时走不同代码路径（含「无映射即空」「未开 stream」）。
- **对齐目标**：同构的 OpenAI Chat 厂商应在 v2 上达到 **同一最小完备集**（非流式路径、流式 paths、`stream` 映射、`event_map` 或明确仅用 Path 策略）。

---

## 4. 网络与代理（跨区域）

- **现象**：直连失败、429、403、502/503 等与区域或代理相关。
- **做法（Rust 侧已加强）**：多路由（直连 / `AI_PROXY_URL` / 系统代理）与 **可配置 `NO_PROXY` / `AI_PROXY_NO_PROXY`**；对部分状态码尝试切换路由。
- **对齐要点**：其他运行时在文档与示例中说明相同环境变量语义，避免「应用走代理而厂商域名应直连」类配置错误。

---

## 5. 推荐调试顺序（给其他运行时抄作业）

1. **非流式**：直连上游一次 `curl`，再请求本地封装层，确认 JSON 路径与解析结果一致。  
2. **流式**：对上游 `stream: true` 抓一段原始 SSE，确认确有 `delta.content`；再抓本地 SSE，确认是否发出 `delta`。若上游非 SSE，先查 body 是否含 `stream: true`。  
3. **Manifest**：核对 `parameter_mappings.stream`、`streaming.content_path` / `usage_path`、`event_map` 与实现契约。  
4. **头与代理**：Accept、代理、NO_PROXY。

---

## 6. 辅助资产

- **`aitest/scripts/provider-smoke.ps1`**：对 `/models` 下列模型依次测非流式 `/chat` 与流式 `/chat/stream`（Windows 下用临时 UTF-8 无 BOM JSON + `curl` 避免引号/编码坑）。

---

## 7. 仓库分支约定（aitest）

- **`aitest` 默认分支已对齐为 `main`**（与 ARCH-004 / 生态约定一致）。若远程仍保留 `master`，需在 GitHub **Settings → Branches** 将 **default branch** 设为 `main` 后，再执行 `git push origin --delete master`。

---

**文档状态**：2026-04-11 写入，基于当次联调与代码审阅；若协议或运行时行为变更，请同步更新本节并改日期。

---

## 8. 运行时对齐执行记录（2026-04-14）

| 运行时 | 动作 |
|--------|------|
| **Python** | `COMPLIANCE_DIR` + `COMPLIANCE_SUBSET=e_only`：`tests/compliance` **72 passed, 4 skipped**；非流式 / 流式行为见 CHANGELOG [Unreleased]。 |
| **TypeScript** | 非流式：`parseNonstreamChatResponse` + `response_paths`；流式：`Pipeline.fromManifest` 按 `decoder.strategy` 选择 Anthropic vs OpenAI路径映射器，OpenAI 使用可配置 `content_path` / `tool_call_path` / `usage_path`。README 补充代理说明。 |
| **Go** | `response_paths` 写入 V1/V2 manifest 模型；`Chat` 读全文 JSON 后 `EnrichNonstreamChatResponse`；`internal/protocol` 提供 JSON path 解析。README 补充代理说明。 |

代理环境变量语义仍以 **ai-lib-rust `HttpTransport`** 为参考实现；各运行时 README 中汇总 `AI_PROXY_URL`、`HTTP(S)_PROXY`、`NO_PROXY`、`AI_HTTP_TRUST_ENV`（Python）等。
