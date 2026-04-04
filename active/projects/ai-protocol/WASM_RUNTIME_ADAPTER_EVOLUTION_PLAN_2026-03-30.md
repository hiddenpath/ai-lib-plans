# WASM Runtime Adapter 分阶段演进规划

> 状态：Phase 1 契约已定义（PT-061）
> 日期：2026-03-30
> 前置：PT-022 (Go/WASM 可行性报告) 结论继承

## 1. 总体愿景

将 ai-protocol 的协议解析、manifest 加载、消息构建、错误分类等核心逻辑编译为
WASM 模块，使其可在浏览器、Edge 运行时、嵌入式环境中运行，作为第五种运行时形态。

## 2. Phase 1：契约定义与可行性验证（本阶段）

### 2.1 WASM 能力范围定义

| 能力 | Phase 1 | Phase 2 | Phase 3 |
|------|---------|---------|---------|
| Protocol loading (manifest parse) | **In scope** | Stable | Stable |
| Capability gating (fail-fast) | **In scope** | Stable | Stable |
| Message building (request construction) | **In scope** | Stable | Stable |
| Response parsing (sync) | **In scope** | Stable | Stable |
| Error classification | **In scope** | Stable | Stable |
| Streaming decode | Out of scope | **In scope** | Stable |
| HTTP transport | Out of scope | **Host-provided** | Production |
| Filesystem access | Out of scope | Out of scope | Optional |
| Native TLS | Out of scope | Out of scope | Host-provided |

### 2.2 构建目标矩阵

| Target | 适用场景 | Phase |
|--------|---------|-------|
| `wasm32-unknown-unknown` | 浏览器、嵌入式（无 WASI） | Phase 2 |
| `wasm32-wasip1` | 服务端 WASM (Wasmtime, WasmEdge) | **Phase 1** |
| `wasm32-wasip2` (Component Model) | 可组合 AI 管道（未来） | Phase 3 |

Phase 1 主目标为 `wasm32-wasip1`，因为：
- Wasmtime 测试框架成熟，可直接运行 compliance 测试
- 不依赖浏览器环境，CI 可集成
- 后续向 `wasm32-unknown-unknown` 降级相对容易

### 2.3 源运行时选择评估

| 候选 | 优势 | 劣势 | 评估结论 |
|------|------|------|---------|
| **ai-lib-rust** (主选) | Rust→WASM 生态最成熟；`wasm-pack` 工具链完善；`no_std` 可选 | HTTP client 需 shim；部分 crate 不兼容 wasm | **主选** |
| ai-lib-go (TinyGo) | TinyGo 支持 `wasm32-wasip1` | 标准库支持不完整；JSON parse 性能差 | **备选/评估** |
| ai-lib-ts (原生) | 天然 JS/WASM 互操作 | 不需要编译到 WASM（本身就是 JS） | N/A |
| ai-lib-python (Pyodide) | 浏览器 Python | 包体积过大（>10MB），启动慢 | 不推荐 |

**决策：以 ai-lib-rust 为 WASM 编译源。**

### 2.4 需要 Shim 的模块

| 依赖 | 原始 crate | WASM Shim 策略 |
|------|-----------|---------------|
| HTTP client | `reqwest` | Phase 1 不需要（仅解析/构建）; Phase 2 host-provided fetch |
| Filesystem | `std::fs` | 不需要（manifest 作为 bytes 传入） |
| Random | `rand` | `getrandom` with `js` feature（Phase 2）; Phase 1 不需要 |
| Time | `std::time` | `wasi-clocks`（Phase 1）; `js_sys::Date`（Phase 2） |
| Async runtime | `tokio` | Phase 1 不需要（同步接口）; Phase 2 可用 `wasm-bindgen-futures` |

### 2.5 WASM Compliance 子集

Phase 1 从现有 compliance 矩阵中提取可在 wasm 目标运行的子集：

| Compliance Category | 包含 | 排除原因 |
|--------------------|------|---------|
| `01-protocol-loading` | **全部** | - |
| `02-error-classification` | **全部** | - |
| `03-message-building` | **全部** | - |
| `05-request-building` | **全部** | - |
| `08-generative-capabilities` | gen-001, gen-002, gen-003, gen-005, gen-007 | gen-004/006 需要 streaming |
| `04-streaming` | 排除 | 依赖网络 I/O |
| `06-resilience` | 排除 | 依赖 HTTP 请求 |
| `07-advanced-capabilities` | 部分 | 需逐 case 评估 |

### 2.6 PoC 规格

**目标产物**: 一个 `.wasm` 模块，导出以下函数：

```
// Manifest loading
fn load_manifest(yaml_bytes: &[u8]) -> Result<ManifestHandle, ErrorCode>

// Capability check
fn check_capability(handle: ManifestHandle, cap: &str) -> bool

// Message building
fn build_chat_request(handle: ManifestHandle, messages_json: &[u8]) -> Result<Vec<u8>, ErrorCode>

// Response parsing
fn parse_chat_response(handle: ManifestHandle, response_json: &[u8]) -> Result<Vec<u8>, ErrorCode>

// Error classification
fn classify_error(handle: ManifestHandle, status: u16, body: &[u8]) -> ErrorCode

// Token usage extraction
fn extract_usage(handle: ManifestHandle, response_json: &[u8]) -> Result<Vec<u8>, ErrorCode>
```

**验证标准**:
- PoC 通过 protocol_loading compliance 子集（wasmtime 测试 harness）
- Binary size < 2MB (release + wasm-opt)
- Manifest parse time < 10ms for standard provider YAML

### 2.7 TinyGo 辅助评估

在 Phase 1 结束前，对 ai-lib-go 的 loader 模块尝试 TinyGo 编译：
- 目标：`tinygo build -target=wasip1 ./loader/`
- 评估：是否通过 `load-001` ~ `load-007` compliance cases
- 结论写入 Phase 1 closure report

## 3. Phase 2：MVP 与集成（后续任务）

- 浏览器 SDK wrapper（`wasm-bindgen` + JS/TS interop）
- Edge 运行时集成（Cloudflare Workers, Vercel Edge Functions）
- Streaming decode via host-provided fetch + ReadableStream
- Spiderswitch WASM runtime adapter 注册
- `wasm32-unknown-unknown` target 支持

## 4. Phase 3：产品化（远期）

- 完整 compliance 矩阵通过（含 streaming / resilience）
- 性能基准对标原生运行时
- 安全审计（WASM 沙箱边界）
- Component Model 探索（可组合 AI 管道）

## 5. 回滚与边界

- WASM 始终作为**可选 / 默认禁用**的运行时，直到 Phase 2 证明稳定
- 不影响现有四运行时的任何行为
- Phase 1 仅产出设计文档 + PoC spec；不要求修改任何现有 runtime crate
- 如 PoC 不可行，记录结论后暂停，不阻塞 v1.0.x RC
