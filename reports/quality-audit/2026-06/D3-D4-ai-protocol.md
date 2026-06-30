# 质量审查报告 — ai-protocol（Dim 3-4）

<!-- AUDIT_META: dimension=D3-D4 repo=ai-protocol auditor=cursor date=2026-06-30 task=PT-073g status=final -->

> **任务**: [PT-073g](../../active/projects/ai-protocol/tasks/PT-073g-cross-repo-quality-audit.yaml)
> **维度**: Dim 3（脚本/工具质量）+ Dim 4（合规真实性 — 本仓最关键）
> **仓库/范围**: `ailib-official/ai-protocol`
> **审查人**: cursor · **日期**: 2026-06-30 · **基线**: `65857ef`

---

## 1. 执行摘要

| 指标 | 值 |
|------|-----|
| P0 | 0（QA-protocol-005/006 为 P0 候选，建议 maintainer 评审定级） |
| P1 | 5（QA-protocol-001/002/003/005/006） |
| P2 | 2（QA-protocol-010/QA-protocol-008 见 D5-D6） |
| 总体结论 | PASS_WITH_FIXES（合规真实性须收口） |

**一段话结论**：作为"跨运行时合规真源"，本仓的最大风险恰在合规执行链：① 跨运行时合规门 `gate-compliance-matrix.js` 指向 CI 中不存在的 `../rustapp/ai-lib-*`，PR 为 report-only、required 必失败/非阻塞 → **ai-protocol 自身 CI 从不执行这些用例**；② 至少一个 mock fixture 与依赖它的用例矛盾（`mock-openai.yaml` 缺 reasoning/structured_output 却被 gen-001/003/007 断言存在）；③ 合规用例 `schema.json` 陈旧且从不强制；④ `e_only` 子集遗漏 10/11 两个用例目录；⑤ P0 用例 gen-005 描述与断言自相矛盾，且能力守卫错用 `E1005`。

---

## 2. 范围与方法

- 包含：`tests/compliance/`（25 文件 ~110 例）、`scripts/{validate,gate-compliance-matrix,gate-manifest-authority}.js`、`.github/workflows/{validate,governance-report}.yml`
- 方法：用例↔schema↔mock 三方一致性核对 + CI 门控可执行性审查

---

## 3. 发现项登记表

| ID | 严重度 | 状态 | 位置 | 问题 | 建议修复 |
|----|--------|------|------|------|----------|
| QA-protocol-006 | P1（P0 候选） | open | `scripts/gate-compliance-matrix.js:17-19,35-46`；`governance-report.yml:47-51,80-81` | 跨运行时合规门指向 CI 中不存在的兄弟仓 → PR report-only（从不阻塞），required-on-main 恒 exit 127；**ai-protocol CI 从不执行合规用例**（假绿/死门） | required 模式在缺失运行时目录时硬失败并给清晰信息，或文档化"强制在运行时仓"并增本仓用例 linter |
| QA-protocol-005 | P1（P0 候选） | open | `tests/compliance/fixtures/providers/mock-openai.yaml:25` vs `generative-capabilities.yaml:14-28` | mock 缺 `reasoning/structured_output/feature_flags`、用 `chat` 而非 `text`，却被 gen-001/003/007 断言存在 → 用例空洞或失败（mock 漂移） | 对齐 mock 至 v2 能力词表+feature_flags，或用例加载真实 `v2/providers/openai.yaml` |
| QA-protocol-003 | P1 | open | `tests/compliance/schema.json:12-22,69-83` | 用例 schema 陈旧（缺 capability_check/request_building/capability_guard/advanced_endpoint_mapping/fallback_decision 等 suite/type）且**从不被任何脚本/CI 强制** | 扩 enum 至实际用法；加 `validate:compliance` 逐文件校验并接入 `validate.yml` |
| QA-protocol-001 | P1 | open | `cases/08-generative-capabilities/generative-capabilities.yaml:130 vs 148-149` | P0 用例 gen-005 描述称分类为 "E1003"，断言却 `error_code:E1005/request_too_large` — 自相矛盾 | 改描述为 E1005/request_too_large（断言正确，匹配 err-010） |
| QA-protocol-002 | P1 | open | `cases/07-advanced-capabilities/capability-and-endpoint.yaml:16,33,50,67`；`generative-capabilities.yaml:188` | 能力守卫拒绝映射到 `E1005`(request_too_large) 语义错误；无 `unsupported_capability` 码 | 增专用码（如 `E1006 capability_not_declared`）或显式文档化复用 |
| QA-protocol-004 | P1 | open | `tests/compliance/ep-boundary/E_ONLY_CASES.md:10-23` | 目录 `10-text-tool-call`、`11-content-block-encoding` 既未纳入也未排除 → `COMPLIANCE_SUBSET=e_only` 下未定义、可能被运行时静默跳过 | 在 included/excluded 表分类目录 10/11（均属 E 层） |
| QA-protocol-010 | P2 | open | `http-status-mapping.yaml:23`(`error_name`) vs `generative-capabilities.yaml:149`(`error_type`) | 跨用例断言键名不一致；schema 未强制 → 笔误静默通过 | 统一键名并经 schema 校验 |

---

## 4. 维度专项检查

### Dim 3 — 脚本/工具质量

| 检查项 | 结果 | 备注 |
|--------|------|------|
| validate.js 覆盖 examples | ⚠️ | 仅 `--examples` 时校验，CI 裸 `npm run validate` 不校验 examples（详见 D5-D6 QA-protocol-008） |
| 门控脚本可执行性 | ❌ | QA-protocol-006（合规门指向缺失仓） |

### Dim 4 — 合规真实性

| 检查项 | 结果 | 备注 |
|--------|------|------|
| 用例数/分组 | ✅ | 25 文件，suite 01-11，~110 例 |
| e_only vs full 定义完整 | ❌ | QA-protocol-004（10/11 未分类）；`COMPLIANCE_SUBSET` 仅运行时侧 env，本仓未实现 |
| 用例被本仓 CI 执行 | ❌ | QA-protocol-006（死门） |
| mock 与用例/manifest 一致 | ❌ | QA-protocol-005 |
| 用例 schema 强制 | ❌ | QA-protocol-003 |
| 错误码映射 E1001-E9999 / 400/401/429/500 | ✅（有保留） | `error-codes.yaml` + `02-error-classification`；保留 QA-protocol-001/002 |

---

## 5. 证据附录

```bash
sed -n '17,46p' scripts/gate-compliance-matrix.js   # 指向 ../rustapp/ai-lib-* （CI 不存在）
sed -n '14,28p' tests/compliance/cases/08-generative-capabilities/generative-capabilities.yaml
sed -n '10,23p' tests/compliance/ep-boundary/E_ONLY_CASES.md   # 缺 10/11
```

## 6. 签核

| 角色 | 姓名 | 日期 | 结论 |
|------|------|------|------|
| 审查人 | cursor | 2026-06-30 | PASS_WITH_FIXES（QA-protocol-005/006 建议升 P0 评审） |
| Maintainer | | | 待评审 |

## 变更记录
| 日期 | 变更 |
|------|------|
| 2026-06-30 | 初稿 |
