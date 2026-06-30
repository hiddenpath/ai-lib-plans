# 质量审查报告 — ai-lib-ts

<!-- AUDIT_META: dimension=D1-D2 repo=ai-lib-ts auditor=cursor date=2026-06-30 task=PT-073g status=final -->

> **任务**: [PT-073g](../../active/projects/ai-protocol/tasks/PT-073g-cross-repo-quality-audit.yaml)
> **维度**: Dim 1（公共 API 面）+ Dim 2（E/P 深度边界）
> **仓库/范围**: `ailib-official/ai-lib-ts`（npm `@ailib-official/ai-lib-ts@0.5.3`）
> **审查人**: cursor（cloud agent）
> **日期**: 2026-06-30
> **基线 commit**: `aa3f5fa`（`main` @ 2026-06-30，PT-073f #7）

---

## 1. 执行摘要

| 指标 | 值 |
|------|-----|
| 抽样路径数 | `package.json` exports + `src/index.ts` / `src/core.ts` + `tsup.config.ts` |
| **P0 发现** | **3（QA-ts-001/002/003）** |
| P1 发现 | 1（QA-ts-004 CHANGELOG 虚假声明） |
| P2 发现 | 0（D1/D2 范围内） |
| 总体结论 | **BLOCKED** |

**一段话结论**：**本仓库是当前唯一携带 D1/D2 级 P0 的运行时**。`package.json` 对外宣告 `./core` 与 `./contact` 两个 E/P 子路径导出，但 ① `tsup` 仅构建 `src/index.ts`，`dist/core.*`/`dist/contact.*` 从不产出；② **`src/contact.ts` 源文件根本不存在**（P 层公共面未定义）；③ E-only 的 `core.ts` 经 `transport` 传递性 import 了 P 层 `resilience`，与其自身注释"Excludes: …resilience"矛盾。即"已发布的 E/P 子路径不可用"，构成发布阻断。

---

## 2. 审查范围与方法

- **包含**: `package.json`（exports/main/types）、`src/index.ts`、`src/core.ts`、`src/transport/index.ts`、`tsup.config.ts`
- **排除**: `tests/`（归 Dim 4）、`benchmarks/`
- **对照文档**: `README.md`、`CHANGELOG.md`
- **方法**: exports map ↔ 构建产物 ↔ 源文件三方核对 + import 追踪

---

## 3. 发现项登记表（D1-D2）

| ID | 严重度 | 状态 | 位置 | 问题 | 建议修复 |
|----|--------|------|------|------|----------|
| QA-ts-001 | **P0** | open | `tsup.config.ts:4` vs `package.json:20-39` | `./core`→`dist/core.*`、`./contact`→`dist/contact.*`，但构建只产 `dist/index.*`；子路径 import 运行时 `ERR_MODULE_NOT_FOUND` | tsup 多入口 `entry:['src/index.ts','src/core.ts','src/contact.ts']`；publish 前验证 dist 产物 |
| QA-ts-002 | **P0** | open | `src/`（无 `src/contact.ts`） vs `package.json:30` | 宣告的 `./contact` 策略入口**无源文件**，P 层公共面未定义 | 新增 `src/contact.ts` 聚合 P 模块（routing/cache/batch/guardrails/negotiation/resilience/plugins/telemetry/interceptors/tokens）并纳入构建 |
| QA-ts-003 | **P0** | open | `src/transport/index.ts:15-27` + `src/core.ts:13` | E-only `core` 经 `export * from './transport'` 传递性 import P 层 `resilience`，违反 `core.ts:6` 自述边界；HttpTransport 构造即实例化 RetryPolicy/CircuitBreaker/RateLimiter | 将 transport 拆为纯 E 的 HTTP/SSE + 位于 P 层的 resilience 装饰器；`core.ts` 仅 import 纯 transport |
| QA-ts-004 | P1 | open | `CHANGELOG.md:24` | 声称子路径 "built via tsup multi-entry"——不实，掩盖 QA-ts-001 | 构建修复后更正 CHANGELOG，并加 known-issue 说明 |

---

## 4. 维度专项检查

### Dim 1 — 公共 API

| 检查项 | 结果 | 备注 |
|--------|------|------|
| exports map 与构建产物一致 | 🔴 | QA-ts-001（`./core`/`./contact` 无产物） |
| `src` 源覆盖所声明入口 | 🔴 | QA-ts-002（无 `src/contact.ts`） |
| 内部路径泄漏 | ✅ | 经 barrel 再导出，无 `src/...` 内部路径泄漏到 d.ts |
| README 与 exports 一致 | ❌ | README 停留 V0.4.0、未述 `/core` `/contact`（详见 D6 QA-ts-007） |

### Dim 2 — E/P 深度边界

| 检查项 | 结果 | 备注 |
|--------|------|------|
| core 入口无 P 模块 | 🔴 | QA-ts-003（transport→resilience 泄漏） |
| transport 纯 E | 🔴 | transport 实为 mixed（import resilience） |
| contact 仅聚合 E | ➖ | 无 contact 源可审（QA-ts-002） |

---

## 5. 证据附录

```bash
# 子路径无源、无产物
ls src/contact.ts            # No such file or directory
grep -n "entry" tsup.config.ts   # entry: ['src/index.ts']  （仅单入口）
sed -n '20,39p' package.json     # ./core→dist/core.js, ./contact→dist/contact.js

# core 传递性引入 resilience
grep -n "transport" src/core.ts                 # 13: export * from './transport/index.js'
sed -n '15,27p' src/transport/index.ts          # import { RetryPolicy, CircuitBreaker, ... } from '../resilience'
```

抽样路径：`package.json`（exports 真源）、`tsup.config.ts`（构建入口）、`src/core.ts` + `src/transport/index.ts`（E/P 边界泄漏证据链）。

---

## 6. 签核

| 角色 | 姓名 | 日期 | 结论 |
|------|------|------|------|
| 审查人 | cursor | 2026-06-30 | **BLOCKED** — QA-ts-001/002/003 为 1.0 发布阻断 P0 |
| Maintainer | | | 待评审（需修复后复审） |

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-06-30 | 初稿 |
