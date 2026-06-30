# 质量审查报告 — ai-lib-ts（Dim 3-4）

<!-- AUDIT_META: dimension=D3-D4 repo=ai-lib-ts auditor=cursor date=2026-06-30 task=PT-073g status=final -->

> **任务**: [PT-073g](../../active/projects/ai-protocol/tasks/PT-073g-cross-repo-quality-audit.yaml)
> **维度**: Dim 3（代码质量）+ Dim 4（测试真实性）
> **仓库/范围**: `ailib-official/ai-lib-ts`
> **审查人**: cursor · **日期**: 2026-06-30 · **基线**: `aa3f5fa`

---

## 1. 执行摘要

| 指标 | 值 |
|------|-----|
| P0 | 0（D3/D4 内；P0 集中于 D1/D2） |
| P1 | 1（QA-ts-006 CI 未 pin ref） |
| P2 | 3（QA-ts-010/011/012） |
| 总体结论 | PASS_WITH_FIXES |

**一段话结论**：代码质量是四运行时中最规整的——`tsconfig` strict 全开（TS-001 达标）、零 `@ts-ignore`/`as any`、零 TODO/FIXME、无 provider-slug 分支。测试方面优于其他运行时：full 合规矩阵确实在 main 上跑（两个 pt073 workflow 均 `push:main`）。残余风险：CI 仍以浮动 `main` checkout ai-protocol；"compliance-full" 配置实际遗漏若干真实套件（routing/resilience/batch…），命名易误导。

---

## 2. 范围与方法

- 包含：`src/`、`tsconfig*.json`、`vitest*.config.ts`、`.github/workflows/{ci,pt073-ts-*}.yml`
- 方法：`rg` any/@ts-ignore/catch{} + vitest 配置 include/exclude 对照 + CI 触发与 ref 审查

---

## 3. 发现项登记表

| ID | 严重度 | 状态 | 位置 | 问题 | 建议修复 |
|----|--------|------|------|------|----------|
| QA-ts-006 | P1 | open | `.github/workflows/{pt073-ts-core,pt073-ts-full,ci}.yml`（checkout 块） | `ai-protocol` 无 `ref:`，浮动默认分支；而 peer dep pin `^0.8.4` → 合规可独立于实发版本红/绿，假绿风险 | 全部 checkout `ref:` pin 到匹配 tag |
| QA-ts-012 | P2 | open | `vitest.compliance-full.config.ts:13-20` | "full" 配置遗漏 routing/resilience/batch/negotiation/mcp/plugins 等真实套件（仅默认 `npm test` 跑）→ 绿的 PT-073-full ≠ 绿的全套件 | 重命名为 "compliance-full (protocol matrix)" 或纳入余下套件；确保 `ci.yml` 全量为 required |
| QA-ts-010 | P2 | open | `src/guardrails/guardrails.ts:105` | 安全相关累加器 `const violations: any[]` 丧失类型检查 | 改 `Violation[]` |
| QA-ts-011 | P2 | open | `src/transport/index.ts:354-356,201,297` | SSE JSON 解析与 error-body 读取 `catch {}` 静默吞错，生产难排查 | 接可选 debug logger/计数器，保持不抛 |

---

## 4. 维度专项检查

### Dim 3 — 代码质量

| 检查项 | 结果 | 备注 |
|--------|------|------|
| strict 模式 | ✅ | `tsconfig.json:10-16` strict+strictNullChecks+noUncheckedIndexedAccess |
| `any` 滥用 | ✅ | 仅 1 处内部变量（QA-ts-010） |
| `@ts-ignore`/`as any` | ✅ | 0 |
| 吞错 | ⚠️ | transport 静默 catch（QA-ts-011，有意但应可追踪） |
| provider-slug 分支 | ✅ | 无；解析为 manifest/path 驱动 |
| TODO/FIXME | ✅ | 0 |

### Dim 4 — 测试真实性

| 检查项 | 结果 | 备注 |
|--------|------|------|
| 多 vitest 配置清晰 | ✅ | `config`（全部）/`core`（E-only 4 文件）/`compliance-full`（+credential/text-tool/retry 7 文件） |
| full matrix 在 main 跑 | ✅ | `pt073-ts-full.yml` 在 `push:main` 跑 `test:compliance:full` |
| "full" 名实相符 | ⚠️ | QA-ts-012（遗漏多套件） |
| 跳过测试 | ✅ | 仅 1 处环境门控 `describe.skipIf(!mockAvailable)` |
| CI checkout 正确 ref | ⚠️ | QA-ts-006（无 ref pin，经 `AI_PROTOCOL_DIR` 接线但 ref 浮动） |

---

## 5. 证据附录

```bash
sed -n '10,16p' tsconfig.json                       # strict family on
rg -n "@ts-ignore|as any|TODO|FIXME" src | wc -l    # 0
sed -n '13,20p' vitest.compliance-full.config.ts    # full 仅 7 文件
```

## 6. 签核

| 角色 | 姓名 | 日期 | 结论 |
|------|------|------|------|
| 审查人 | cursor | 2026-06-30 | PASS_WITH_FIXES（代码质量优；CI ref 须 pin） |
| Maintainer | | | 待评审 |

## 变更记录
| 日期 | 变更 |
|------|------|
| 2026-06-30 | 初稿 |
