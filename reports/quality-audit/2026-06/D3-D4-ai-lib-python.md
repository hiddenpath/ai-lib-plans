# 质量审查报告 — ai-lib-python（Dim 3-4）

<!-- AUDIT_META: dimension=D3-D4 repo=ai-lib-python auditor=cursor date=2026-06-30 task=PT-073g status=final -->

> **任务**: [PT-073g](../../active/projects/ai-protocol/tasks/PT-073g-cross-repo-quality-audit.yaml)
> **维度**: Dim 3（代码质量）+ Dim 4（测试真实性）
> **仓库/范围**: `ailib-official/ai-lib-python`
> **审查人**: cursor · **日期**: 2026-06-30 · **基线**: `c3f4d53`

---

## 1. 执行摘要

| 指标 | 值 |
|------|-----|
| P0 | 0 |
| P1 | 4（QA-python-004 合规自证、005 静默 skip、006 边界测试空跑、010 并发态修改） |
| P2 | 3（QA-python-009/011/012） |
| 总体结论 | PASS_WITH_FIXES |

**一段话结论**：代码质量整体良好（无裸 `except:`、`src/` 无 TODO/FIXME），但测试真实性问题与 Rust 同构且更广：合规 runner 大量在测试内重实现运行时逻辑（retry/fallback/message_building/stream/event/tool/protocol_loading），未知用例类型 `pytest.skip` 静默通过，架构边界 pytest 因路径 bug 在 CI **跳过空跑**。另有一处真实并发缺陷：fallback 期间修改共享 `self._model_id/_manifest`。

---

## 2. 范围与方法

- 包含：`src/ai_lib_python/`（client/transport/routing/protocol…）、`tests/compliance/`、`tests/architecture/`、`.github/workflows/{ci,pt073-python-*}.yml`
- 方法：异常处理/类型/并发态阅读 + 合规 runner 调用链核对 + CI 配置审查

---

## 3. 发现项登记表

| ID | 严重度 | 状态 | 位置 | 问题 | 建议修复 |
|----|--------|------|------|------|----------|
| QA-python-004 | P1（近 P0） | open | `tests/compliance/test_compliance.py:579-586,832-834,607-613,646-768,483-546` | 合规 runner 在测试内重实现 retry/fallback/message_building/stream decode/event mapping/tool accum/protocol loading → 绿不能证明运行时合规 | 每个 runner 走真实库（`resilience`/`pipeline`/`protocol`/`types`） |
| QA-python-005 | P1 | open | `tests/compliance/test_compliance.py:138-139` | 未知用例类型静默 `skip` → 上游新增类型时假绿 | 未知类型 `fail`（或带理由 xfail）；断言最小用例数 |
| QA-python-006 | P1 | open | `tests/architecture/test_execution_layer_import_boundary.py:24-37,85-86` | matrix 路径用 `/../../ai-protocol` 且忽略 `COMPLIANCE_DIR`，CI 中两个边界测试均 `skip` 空跑（边界另有 CLI 步骤兜底，但 pytest 门误绿） | 经 `COMPLIANCE_DIR`/`AI_PROTOCOL_DIR` 解析；env 声明存在时缺失则 fail |
| QA-python-010 | P1 | open | `src/ai_lib_python/client/core.py:274-282` | fallback 临时改写共享 `self._model_id/_manifest`（finally 还原），单 `AiClient` 并发 `chat()` 期间可观测/竞争 → 错误 payload | 由局部 manifest/model 参数构造 payload，勿改实例态 |
| QA-python-007 | P1 | open | `ci.yml:29-33,67-77`；`pt073-python-{e-only,full}.yml:28-32` | `ai-protocol` 浮动 `main`（无 `ref:`）→ 不可复现/假绿 | pin `ref:` 到 tag/SHA 或 protocol 版本变量 |
| QA-python-009 | P2 | open | `src/ai_lib_python/routing/manager.py:575-582` | `provider=="openai"/"anthropic"` 硬编码分支（ARCH-001 气味，P 层） | 由 manifest/registry 驱动 preset |
| QA-python-011 | P2 | open | `protocol/loader.py:195-196`（+`cache/backends.py:259,325`） | `async` 路径同步 `read_text`（PY-002） | `asyncio.to_thread`/`anyio`，或文档化为有意同步 |
| QA-python-012 | P2 | open | `transport/http.py:56-58` | UA 版本 fallback 硬编码陈旧 `"0.5.0"` | 修 QA-python-001 后回落 `__version__` |

---

## 4. 维度专项检查

### Dim 3 — 代码质量

| 检查项 | 结果 | 备注 |
|--------|------|------|
| 无裸 `except:` / 吞异常 | ✅ | 热路径 re-raise；`except Exception: pass` 仅遥测/取消清理等非关键且有注释 |
| 硬编码 provider-slug 分支 | ⚠️ | QA-python-009（P 层 routing） |
| 并发安全 | ❌ | QA-python-010（fallback 改共享态） |
| 异步路径阻塞 I/O | ⚠️ | QA-python-011 |
| `src/` TODO/FIXME | ✅ | 0 |

### Dim 4 — 测试真实性

| 检查项 | 结果 | 备注 |
|--------|------|------|
| 合规 runner 调用真实库 | ❌ | QA-python-004（真实调用仅 error_classification/credential/auth/text_tool） |
| 未知类型 fail-closed | ❌ | QA-python-005（静默 skip） |
| 架构边界测试有效 | ❌ | QA-python-006（CI 空跑） |
| full vs subset 文档化 | ✅ | `ci.yml` 跑全量；`pt073-python-full.yml` 全矩阵；`e-only` 排除 `06-resilience`（`conftest.py:13-22`） |
| CI checkout 正确 ref | ⚠️ | QA-python-007（无 ref pin） |

---

## 5. 证据附录

```bash
sed -n '138,139p' tests/compliance/test_compliance.py     # pytest.skip 未知类型
sed -n '274,282p' src/ai_lib_python/client/core.py        # fallback 改写共享 self._model_id
rg -n "ref:" .github/workflows/ci.yml                       # protocol checkout 无 ref
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
