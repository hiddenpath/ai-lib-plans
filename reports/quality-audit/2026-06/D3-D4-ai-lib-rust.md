# 质量审查报告 — ai-lib-rust（Dim 3-4）

<!-- AUDIT_META: dimension=D3-D4 repo=ai-lib-rust auditor=cursor date=2026-06-30 task=PT-073g status=final -->

> **任务**: [PT-073g](../../active/projects/ai-protocol/tasks/PT-073g-cross-repo-quality-audit.yaml)
> **维度**: Dim 3（代码质量）+ Dim 4（测试真实性）
> **仓库/范围**: `ailib-official/ai-lib-rust`（crates: core/contact/rust/wasm）
> **审查人**: cursor · **日期**: 2026-06-30 · **基线**: `2f331b4`

---

## 1. 执行摘要

| 指标 | 值 |
|------|-----|
| P0 | 0 |
| P1 | 3（QA-rust-001 传输 panic、QA-rust-003 合规自证、QA-rust-004/005 假绿） |
| P2 | 3（QA-rust-009/010/011） |
| 总体结论 | PASS_WITH_FIXES |

**一段话结论**：代码卫生优秀（core/contact 无 `unsafe`、TODO/FIXME ≈ 0、driver 按 `ApiStyle` 而非 slug 分派，ARCH-001 达标）。但有一条远端可触发的传输层 panic，以及合规套件的"自我验证"问题——多数 `run_*` 在测试内**重新实现**逻辑而非调用生产代码，且 fixture 缺失时静默 `return` 通过（断言仅 `failed==0`，0 例也算过）。

---

## 2. 范围与方法

- 包含：`crates/ai-lib-core/src`、`crates/ai-lib-contact/src`、`tests/compliance_runner/`、`.github/workflows/{ci,pt073-rust-core-wasm}.yml`
- 排除：`benchmarks/`
- 方法：`rg` 扫 unwrap/expect/panic/unsafe（排除 `#[cfg(test)]`）+ 合规 runner 逐项核对调用链 + CI 配置审查

---

## 3. 发现项登记表

| ID | 严重度 | 状态 | 位置 | 问题 | 建议修复 |
|----|--------|------|------|------|----------|
| QA-rust-001 | P1 | open | `crates/ai-lib-core/src/transport/http.rs:316,399` | `last_err.expect("at least one route exists")`：当配置多路由（proxy+direct）且**最后**一条路由返回可重试状态（403/407/451/502/503/504）时，循环越过末位退出，`last_err==None` → HTTP 热路径 panic | 循环后返回合成错误而非 `expect`；或仅在非末位 `continue` |
| QA-rust-003 | P1 | open | `tests/compliance_runner/mod.rs:381-980`（message_building/retry/stream/event/tool/param/capability/endpoint/fallback） | 多数合规行为在 harness 内重新实现而非调用 core；`run_message_building` 实为 input==expected 的近乎恒真断言 → 绿 ≠ 生产行为被验证 | 每个 `run_*` 走真实 core API（driver `build_request`/`parse_stream_event`、真实 retry 引擎），用 YAML 断言运行时输出 |
| QA-rust-004 | P1 | open | `tests/compliance_runner/mod.rs:1215-1221,1272-1276`（6 个合规测试同模式） | fixture 缺失即早退（通过），仅断言 `failed==0`，`passed==0` 也算过 → CI 假绿 | 断言 `passed >= 最小期望数`；CI 显式设 `COMPLIANCE_DIR` 时目录缺失硬失败 |
| QA-rust-005 | P1 | open | `.github/workflows/ci.yml:16-20,54-58,74-78`；`pt073-rust-core-wasm.yml:24-28` | `actions/checkout` of `ailib-official/ai-protocol` **无 `ref:`** → 浮动默认分支；叠加 QA-rust-004 静默跳过 → 上游改名可静默关停合规而 CI 仍绿 | 将 protocol checkout 的 `ref:` pin 到 tag/SHA，刻意升级 |
| QA-rust-009 | P2 | open | `crates/ai-lib-core/src/pipeline/select.rs:17-21` | `Selector::new` 中 `JsonPathEvaluator::new(...).unwrap()`：manifest 病态 JSONPath 可在流水线构造时 panic | `Selector::new` 改为 fallible，或退化为恒假/恒真 evaluator |
| QA-rust-010 | P2 | open | `crates/ai-lib-wasm/src/lib.rs:98,102` | `set_out/set_err` 用 `.expect("out lock")`：mutex 中毒跨 FFI 硬 panic | `lock().unwrap_or_else(|e| e.into_inner())` 毒锁恢复 |
| QA-rust-011 | P2 | open | `tests/compliance_runner/mod.rs:137-141` | `parse_test_cases` 反序列化失败仅 `[WARN]` 后继续 → 改名/坏例静默丢弃 | 区分非测试文档与坏例，后者失败 |

---

## 4. 维度专项检查

### Dim 3 — 代码质量

| 检查项 | 结果 | 备注 |
|--------|------|------|
| 热路径 unwrap/expect/panic | ❌ | QA-rust-001（传输）+ QA-rust-009（pipeline 构造） |
| core/contact `unsafe` | ✅ | 0；`unsafe` 仅限 wasm FFI（预期） |
| 硬编码 provider-slug 分支 | ✅ | `create_driver` 按 `ApiStyle` 枚举分派；slug 字面量仅在 `#[cfg(test)]` |
| TODO/FIXME/HACK 密度 | ✅ | `crates/` 内 0（唯一 `XXX` 为 SSN 占位串） |

### Dim 4 — 测试真实性

| 检查项 | 结果 | 备注 |
|--------|------|------|
| 合规 runner 调用生产代码 | ❌ | QA-rust-003（多数 `run_*` 自实现）；真实调用仅 error_classification/text_tool/content_block_encode |
| fixture 缺失 fail-closed | ❌ | QA-rust-004（静默 return 通过） |
| `#[ignore]` 有理由 | ✅ | mock/keyring 相关均带理由 |
| full matrix 在 main 运行 | ✅（有保留） | `ci.yml` 跑 `--workspace --tests` + `--all-features`，但受 skip-on-missing 影响 |
| CI checkout 正确 protocol ref | ⚠️ | QA-rust-005（无 ref pin） |

---

## 5. 证据附录

```bash
sed -n '314,317p' crates/ai-lib-core/src/transport/http.rs   # last_err.expect("at least one route exists")
rg -n "if !compliance_dir.exists" tests/compliance_runner/mod.rs   # 1215,1397... -> return; 通过
rg -n "ref:" .github/workflows/ci.yml   # 无（protocol checkout 未 pin）
```

## 6. 签核

| 角色 | 姓名 | 日期 | 结论 |
|------|------|------|------|
| 审查人 | cursor | 2026-06-30 | PASS_WITH_FIXES |
| Maintainer | | | 待评审 |

## 变更记录
| 日期 | 变更 |
|------|------|
| 2026-06-30 | 初稿 |
