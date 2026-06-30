# 质量审查报告 — ai-lib-python

<!-- AUDIT_META: dimension=D1-D2 repo=ai-lib-python auditor=cursor date=2026-06-30 task=PT-073g status=final -->

> **任务**: [PT-073g](../../active/projects/ai-protocol/tasks/PT-073g-cross-repo-quality-audit.yaml)
> **维度**: Dim 1（公共 API 面）+ Dim 2（E/P 深度边界）
> **仓库/范围**: `ailib-official/ai-lib-python`（package root `src/ai_lib_python/`，逻辑 E/P 单包布局）
> **审查人**: cursor（cloud agent）
> **日期**: 2026-06-30
> **基线 commit**: `c3f4d53`（`main` @ 2026-06-30，PT-073f #6）

---

## 1. 执行摘要

| 指标 | 值 |
|------|-----|
| 抽样路径数 | `__init__.py` 导出 + E/P 子包 import 图 + `client/core.py` |
| P0 发现 | 0 |
| P1 发现 | 2（QA-python-001 版本漂移、QA-python-003 README 不存在的方法） |
| P2 发现 | 0（D1/D2 范围内） |
| 总体结论 | PASS_WITH_FIXES |

**一段话结论**：E→P import 边界**真正干净**——所有执行层包零静态 import 策略层；唯一 E→P 耦合（resilience）经 `importlib` 动态 opt-in 加载，符合 Paper1 §3.2 与 CHANGELOG 声明。D1 缺口：`__version__`(0.7.5) 与 dist(0.8.5) 漂移，且 README 调用了不存在的 `client.report_feedback(...)`（实际为模块级函数）。

---

## 2. 审查范围与方法

- **包含**: `src/ai_lib_python/__init__.py`、E 包（client/protocol/pipeline/transport/types…）、P 包（routing/cache/batch/guardrails/telemetry…）
- **排除**: `tests/`（归 Dim 4）、`benchmarks/`、`examples/`
- **对照文档**: `README.md`、`pyproject.toml`、`CHANGELOG.md`
- **方法**: `__all__` vs README 核对 + E→P import grep + 动态加载点确认

---

## 3. 发现项登记表（D1-D2）

| ID | 严重度 | 状态 | 位置 | 问题 | 建议修复 |
|----|--------|------|------|------|----------|
| QA-python-001 | P1 | open | `src/ai_lib_python/__init__.py:31` vs `pyproject.toml:7` | `__version__="0.7.5"` ≠ dist `0.8.5`；UA/telemetry 上报错误版本 | 单一真源（`importlib.metadata`）或同步 `__version__`；CI 加版本一致性断言 |
| QA-python-003 | P1 | open | `README.md:300-309` vs `client/core.py` | README 调用 `client.report_feedback(...)`，但其为 `telemetry.feedback` 模块级函数，`AiClient` 无此方法 → `AttributeError` | 修正示例为 `from ai_lib_python.telemetry import report_feedback`，或为 `AiClient` 增方法 |

---

## 4. 维度专项检查

### Dim 1 — 公共 API

| 检查项 | 结果 | 备注 |
|--------|------|------|
| `__all__` 无内部模块泄漏 | ✅ | `__init__.py:33-63` 全为公共类型 |
| `py.typed` 存在 | ✅ | `src/ai_lib_python/py.typed` + `Typing :: Typed` 分类 |
| core/contact 可独立 import | ⚠️ | 仅逻辑分层（单 wheel），README 已明示，"E-only 安装" 物理不可强制 |
| 版本一致 | ❌ | QA-python-001 |
| README API 与实际一致 | ❌ | QA-python-003（其余示例 `AiClient.create`/`.builder().production_ready()`/`Message` 等核对通过） |

### Dim 2 — E/P 深度边界

| 检查项 | 结果 | 备注 |
|--------|------|------|
| 执行层无静态 import 策略层 | ✅ | grep `from/import ai_lib_python.{routing,cache,batch,plugins,resilience,telemetry,guardrails,tokens,registry}` 于 E 包 → 0 命中 |
| 唯一 E→P 耦合为动态 opt-in | ✅ | `client/core.py:23-30` 经 `importlib.import_module("ai_lib_python.resilience")` |
| 本地边界守卫 | ⚠️ | `check_ep_boundary.py` 在 ai-protocol；本地 `tests/architecture/test_*_import_boundary.py` 有路径 bug 在 CI 跳过（详见 D3-D4 QA-python-006） |
| P→E 无业务逻辑反渗 | ✅ | `_parse_response` 为 path/shape 驱动，非 provider-slug 驱动 |

---

## 5. 证据附录

```bash
# E→P 静态 import（应为 0）
rg -n "ai_lib_python\.(routing|cache|batch|plugins|resilience|telemetry|guardrails|tokens|registry)" \
   src/ai_lib_python/{client,protocol,pipeline,transport,types,drivers}   # 0

# 动态 opt-in 加载点
sed -n '23,30p' src/ai_lib_python/client/core.py
```

抽样路径：`src/ai_lib_python/__init__.py`（公共面真源）、`src/ai_lib_python/client/core.py:23-30`（唯一 E→P 动态耦合）。

---

## 6. 签核

| 角色 | 姓名 | 日期 | 结论 |
|------|------|------|------|
| 审查人 | cursor | 2026-06-30 | PASS_WITH_FIXES（边界优秀；版本/文档须修） |
| Maintainer | | | 待评审 |

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-06-30 | 初稿 |
