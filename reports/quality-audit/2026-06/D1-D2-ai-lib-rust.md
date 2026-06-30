# 质量审查报告 — ai-lib-rust

<!-- AUDIT_META: dimension=D1-D2 repo=ai-lib-rust auditor=cursor date=2026-06-30 task=PT-073g status=final -->

> **任务**: [PT-073g](../../active/projects/ai-protocol/tasks/PT-073g-cross-repo-quality-audit.yaml)
> **维度**: Dim 1（公共 API 面）+ Dim 2（E/P 深度边界）
> **仓库/范围**: `ailib-official/ai-lib-rust`（workspace @ 0.9.6；crates: ai-lib-core / ai-lib-contact / ai-lib-rust / ai-lib-wasm / ai-lib-wasmtime-harness）
> **审查人**: cursor（cloud agent）
> **日期**: 2026-06-30
> **基线 commit**: `2f331b4`（`main` @ 2026-06-29）

---

## 1. 执行摘要

| 指标 | 值 |
|------|-----|
| 抽样路径数 | core/contact `lib.rs` 导出 + 5 个 `Cargo.toml` + wasm 导出面 |
| P0 发现 | 0 |
| P1 发现 | 1（QA-rust-002 README 文档不存在的 API） |
| P2 发现 | 1（QA-rust-008 feature 矩阵不全） |
| 总体结论 | PASS_WITH_FIXES |

**一段话结论**：E/P 边界为整套生态最干净的参考实现——`ai-lib-core` 零依赖 `ai-lib-contact`，`ai-lib-wasm` 仅依赖 core，contact 无任何 driver/transport 业务逻辑；6 个 WASM 导出函数齐备。D1 主要问题是 README 宣传了已被移除的 `AiClientBuilder::circuit_breaker_default()` 等 API（编译不通过），以及 feature 矩阵漏列 `stt/tts/reranking`。

---

## 2. 审查范围与方法

- **包含**: `crates/ai-lib-core/src/lib.rs`、`crates/ai-lib-contact/src/lib.rs`、各 `Cargo.toml`、`crates/ai-lib-wasm/src/lib.rs`
- **排除**: `benchmarks/`、`#[cfg(test)]`（归 Dim 3/4）
- **对照文档**: `README.md`、`CHANGELOG.md`、`docs/ARCHITECTURE.md`
- **方法**: 依赖图静态分析 + 导出符号 vs README diff + WASM 导出清点

---

## 3. 发现项登记表（D1-D2）

| ID | 严重度 | 状态 | 位置 | 问题 | 建议修复 |
|----|--------|------|------|------|----------|
| QA-rust-002 | P1 | open | `README.md:188-198,398-400` | README 文档化 `AiClientBuilder::circuit_breaker_default()` 与 `AI_LIB_BREAKER_*`/`AI_LIB_RPS/RPM` 环境变量，但 `CHANGELOG.md:63` 已移除（grep 无该方法/env 读取者）→ 示例无法编译，宣传不存在的公共 API | 改指向 `ai_lib_contact::resilience`（facade `ai_lib_rust::resilience`）；删除失效 builder 方法与 env |
| QA-rust-012 | P2 | open | `crates/ai-lib-rust/src/lib.rs:7` | facade 用 `pub use ai_lib_core::*;` glob 全量再导出，README 仅文档化子集 | 评估是否收敛为显式 re-export，控制公共面 |
| QA-rust-008 | P2 | open | `README.md:132-146` vs `crates/ai-lib-rust/Cargo.toml:93-95` | feature 矩阵漏列 `stt/tts/reranking`，`keyring` 仅在散文 | 补全 feature 矩阵并与 `[features]` 同步 |

---

## 4. 维度专项检查

### Dim 1 — 公共 API

| 检查项 | 结果 | 备注 |
|--------|------|------|
| workspace 各 crate 版本一致 | ✅ | 全部 `0.9.6`，内部 path dep pin `0.9.6` |
| 内部模块路径经 `pub use` 泄漏 | ⚠️ | facade glob 再导出（QA-rust-012，非阻塞） |
| README 公共 API 与导出一致 | ❌ | 宣传不存在的 builder API（QA-rust-002）+ 版本号 `0.8.0` 陈旧（详见 D6 QA-rust-007） |
| 废弃 API 有 `#[deprecated]`/CHANGELOG | ⚠️ | 全仓零 `#[deprecated]`；breaker/rate-limiter 从 `AiClient` 移除无弃用周期，仅 CHANGELOG 记录 |
| WASM 导出函数与 PT-061 一致 | ✅ | 6 个：`ailib_load_manifest/check_capability/build_chat_request/parse_chat_response/classify_error/extract_usage`（`wasm/src/lib.rs`） |

### Dim 2 — E/P 深度边界

| 检查项 | 结果 | 备注 |
|--------|------|------|
| core 不依赖 contact | ✅ | `ai-lib-core/Cargo.toml` 无 contact 依赖；仅 doc-comment 提及，无 `use ai_lib_contact` |
| 默认 feature 不拉 P 依赖 | ✅ | core `default=["keyring"]`，无 contact 依赖可拉 |
| wasm 仅依赖 core | ✅ | `ai-lib-wasm/Cargo.toml` 仅 core+serde；`keyring` 被 `cfg(not(wasm32))` gate，wasm 构建不含 |
| contact 仅策略层 | ✅ | grep `reqwest/ProviderDriver/create_driver/HttpTransport/build_request/parse_response` 于 contact/src → 0 命中；模块为 cache/routing/resilience/guardrails 等 |

---

## 5. 证据附录

```bash
# core 不依赖 contact
rg -n "ai-lib-contact|ai_lib_contact" crates/ai-lib-core/src crates/ai-lib-core/Cargo.toml
#   仅 lib.rs:3 / preflight.rs:3 的 doc 注释命中，无 use

# contact 无 driver/transport
rg -n "reqwest|ProviderDriver|HttpTransport|build_request" crates/ai-lib-contact/src   # 无命中

# WASM 导出
rg -n "pub fn ailib_" crates/ai-lib-wasm/src/lib.rs   # 6 个
```

抽样路径：`crates/ai-lib-core/Cargo.toml`（依赖方向真源）、`crates/ai-lib-contact/src/lib.rs`（策略层边界）、`crates/ai-lib-wasm/src/lib.rs`（WASM 导出面）。

---

## 6. 签核

| 角色 | 姓名 | 日期 | 结论 |
|------|------|------|------|
| 审查人 | cursor | 2026-06-30 | PASS_WITH_FIXES（E/P 干净；QA-rust-002 须在 1.0 README 前修） |
| Maintainer | | | 待评审 |

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-06-30 | 初稿 |
