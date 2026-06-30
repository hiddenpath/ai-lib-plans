# 质量审查报告 — ai-protocol

<!-- AUDIT_META: dimension=D1-D2 repo=ai-protocol auditor=cursor date=2026-06-30 task=PT-073g status=final -->

> **任务**: [PT-073g](../../active/projects/ai-protocol/tasks/PT-073g-cross-repo-quality-audit.yaml)
> **维度**: Dim 1（规范/API 一致性）+ Dim 2（E/P 契约）
> **仓库/范围**: `ailib-official/ai-protocol`（package `@ailib-official/ai-protocol@0.8.4`）
> **审查人**: cursor（cloud agent）
> **日期**: 2026-06-30
> **基线 commit**: `65857ef`（`main` @ 2026-06-30，PT-073f #17）

---

## 1. 执行摘要

| 指标 | 值 |
|------|-----|
| 抽样路径数 | schemas/v2（20）+ v1/v2/v2-alpha manifests + tests/compliance（25 文件 ~110 例） |
| P0 发现 | 0 |
| P1 发现 | 2（QA-protocol-001/002，详见 D3-D4） |
| P2 发现 | 2（QA-protocol-009/014） |
| 总体结论 | PASS_WITH_FIXES |

**一段话结论**：协议真源在 D1/D2 维度健康——`execution-metadata.json` schema 规范且四运行时样本均符合；E/P 契约（`ExecutionResult`/`ExecutionMetadata` + `module-matrix.yaml` + `check_ep_boundary.py`）定义清晰。主要风险集中在 D4（合规执行），D1/D2 仅有错误码分类语义与 v2-alpha schema 复用两处非阻塞项。

---

## 2. 审查范围与方法

- **包含**: `schemas/`、`v1/`、`v2/`、`v2-alpha/`、`dist/`、`tests/compliance/ep-boundary/`
- **排除**: 历史 `reports/`、`research/`
- **对照文档**: README、CHANGELOG、`docs/spec/text-tool-call/*`、`docs/spec/content-block-encoding/*`
- **方法**: 静态阅读 + schema/样本一致性核对 + manifest 清点

---

## 3. 发现项登记表（D1-D2）

| ID | 严重度 | 状态 | 位置 | 问题 | 建议修复 |
|----|--------|------|------|------|----------|
| QA-protocol-009 | P2 | open | `schemas/v2/errors.json:18,23,…` | 非标准 `const_name` 关键字被 JSON Schema 忽略；`http_status/retryable` 仅存在于 `error-codes.yaml`，两份真源无交叉校验 | 增加 yaml↔schema 一致性测试，或合并为单一真源 |
| QA-protocol-014 | P2 | open | `scripts/validate.js:459-475` | `v2-alpha` provider 用 stable `schemas/v2/provider.json` 校验，无 `schemas/v2-alpha/` | 增补 v2-alpha schema 或文档化故意复用 |

> 注：错误码语义/合规 schema 失配等 P1 项（QA-protocol-001/002/003/005）属 Dim 4，登记于 `D3-D4-ai-protocol.md`。

---

## 4. 维度专项检查

### Dim 1 — 规范/API 一致性

| 检查项 | 结果 | 备注 |
|--------|------|------|
| execution-metadata schema 存在且规范 | ✅ | `schemas/v2/execution-metadata.json:1-59` valid 2020-12，`error_code` 模式 `^E[0-9]{4}$`，`additionalProperties:false` |
| tool-call / content-block schema | ✅/⚠️ | tool-calling.json 独立；content-block 仅以 `content_block_mapping.document` 内嵌 `provider-contract.json:136-139`（PT-079 ADR 决策） |
| error-code schema | ✅ | `schemas/v2/errors.json`（13 码）+ 数据 `error-codes.yaml` |
| schema 版本化 v1/v2/v2-alpha | ⚠️ | v2-alpha 无独立 schema（QA-protocol-014） |
| dist 与源 v2 一致 | ⚠️ | 抽样 `dist/v2/providers/openai.json` 与源一致；但**无 CI 校验 committed dist == 重新构建**（详见 D6） |
| README provider/schema 计数 | ⚠️ | README 称 "6 V2 provider"（实际 12）；schema 清单遗漏 6 个（详见 D6 QA-protocol-011） |

### Dim 2 — E/P 契约

| 检查项 | 结果 | 备注 |
|--------|------|------|
| E/P 契约已定义 | ✅ | `execution-metadata.json` + `ep-boundary/module-matrix.yaml`（逐运行时 E/P 分层）+ `check_ep_boundary.py` |
| 四运行时样本符合 schema | ✅ | `fixtures/execution-metadata/{ts,go,rust,python}-sample.json` 均满足必填；`rust-sample.json:7` `error_code:"E1003"` 合模式 |
| 样本校验器接入 CI | ❌ | `validate_execution_metadata_samples.py:24` 依赖 `fastjsonschema`（未列入 deps）且无 workflow 调用 → 详见 D3-D4 QA-protocol-006 |
| micro-retry / E-only 语义文档化 | ✅ | `execution-metadata.json:33-38`；`ep-boundary/E_ONLY_CASES.md:25-26` |

---

## 5. 证据附录

```bash
# execution-metadata schema 与样本
sed -n '1,59p' schemas/v2/execution-metadata.json
ls tests/compliance/fixtures/execution-metadata/   # ts/go/rust/python-sample.json
# manifest 清点
ls v2/providers/ | wc -l   # 12（README 称 6）
```

抽样路径：`schemas/v2/execution-metadata.json`（E/P 核心契约）、`tests/compliance/ep-boundary/module-matrix.yaml`（边界定义真源）、`v2/providers/openai.yaml` vs `dist/v2/providers/openai.json`（源↔发布一致性）。

---

## 6. 签核

| 角色 | 姓名 | 日期 | 结论 |
|------|------|------|------|
| 审查人 | cursor | 2026-06-30 | PASS_WITH_FIXES（D1/D2 无 P0；P2 记 backlog） |
| Maintainer | | | 待评审（SUMMARY 汇总） |

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-06-30 | 初稿（cloud agent 跨仓库审查） |
