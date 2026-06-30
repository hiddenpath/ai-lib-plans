# PT-073g — 跨仓库质量审查计划

> **日期**: 2026-06-29  
> **状态**: 执行中（R2）  
> **决策**: Maintainer 同意 **暂缓 v1.0.0**，待本审查关闭 P0 后再走 PT-073 §6 release train  
> **任务 YAML**: [tasks/PT-073g-cross-repo-quality-audit.yaml](./tasks/PT-073g-cross-repo-quality-audit.yaml)

---

## 1. 背景

PT-073 §1–§5 已证明 **core-only 合规矩阵、WASM、E/P 脚本、CHANGELOG、治理门控** 在工程上可重复验证。  
合规通过 ≠ 产品结构/质量达到 **1.0 语义**（对外稳定、可维护、可安全部署）。

本审查在合规基线之上，对 **四运行时 + protocol + 代表性 P 层消费者** 做结构化质量抽样。

## 2. 范围

| 仓库 | 角色 | 审查深度 |
|------|------|----------|
| ai-protocol | 规范真源 | 全量 schema/manifest + 合规用例覆盖缺口 |
| ai-lib-rust | E 层参考实现 | core + contact + wasm 导出面 |
| ai-lib-python | E 层 | core/contact 包边界 + pt073 CI |
| ai-lib-ts | E 层 | @ailib/core + contact + facade |
| ai-lib-go | E 层 | module 边界 + pt073 |
| eos | P 层代表（浏览器 SKU） | context、密钥、部署 |
| velaclaw | text-tool 下游 | dispatcher 迁移后回归 |
| ailib.info | 对外文档 | 包结构 vs 实际发布 |

**显式排除**（非 1.0 门控）：spiderswitch MCP showcase、未纳入 release train 的实验分支。

## 3. 六维审查框架

### Dim 1 — 公共 API 面一致性

- 各运行时 **导出符号** 与 README「公开 API」是否一致
- 跨运行时 **同名概念**（ToolCall、ExecutionMetadata、Provider 配置）字段语义对齐
- **SemVer 意图**：0.x 下已暴露的 breaking 面是否已在 CHANGELOG 标注
- **抽样方法**：每运行时 2 个入口文件 + 1 个「用户最常 import」路径

### Dim 2 — E/P 深度边界

- 超越 `check_ep_boundary.py`：动态 import、feature flag、WASM 打包是否引入 P 模块
- contact 层是否仅 re-export / 薄包装，无业务逻辑渗入 core
- 下游（eos/velaclaw）是否误将 core 类型与 P 层类型混用

### Dim 3 — 代码质量

- Rust: `#![deny(...)]` 范围、unwrap/expect/panic、unsafe 块
- Python/TS/Go: 异常吞没、any 滥用、硬编码 provider 逻辑（ARCH-001）
- 死代码、TODO/FIXME 密度、重复实现

### Dim 4 — 测试真实性

- pt073 **subset** vs **full** matrix 差异是否文档化
- compliance mock 与真实 provider 响应漂移
- 被 `#[ignore]` / `skip` / `COMPLIANCE_SUBSET` 跳过的用例清单
- flaky 测试与仅 CI 绿、本地红的已知项

### Dim 5 — 安全边界

- 密钥：`.env`、workflow、日志中无 PAT/API key 泄漏
- HTTP：proxy、`trust_env`、TLS 校验默认
- 多租户/区域：eos EOS-ARCH 路由是否仍满足 BIZ-004
- 依赖：已知 CVE 与 pin 策略

### Dim 6 — 文档与迁移对齐

- CHANGELOG（四运行时 + protocol）与 **实际 merge** 一致
- README 安装/特性矩阵 vs Cargo.toml/pyproject/package.json
- `ailib.info`、MEMORY.md v1.0 决策记录
- text-tool-call、document-capability-routing 等跨项目 ADR 状态

## 4. 执行阶段（3–4 周）

| 周 | 任务块 | 产出 |
|----|--------|------|
| W1 | PT-073g-R2 Dim 1–2 | 每仓库 D1/D2 报告草稿 |
| W2 | PT-073g-R3 Dim 3–4 | 静态扫描 + 测试矩阵对照表 |
| W3 | PT-073g-R4 Dim 5–6 | 安全抽样 + 文档 diff |
| W4 | PT-073g-R5/R6 | SUMMARY.md、P0 修复 PR、sign-off |

## 5. 分级与准入

- **P0**：必须在 v1.0.0 tag 前关闭（或回滚暴露面）
- **P1**：修复或 maintainer 书面 defer（含截止日期）
- **P2**：记入 backlog，不阻塞 1.0

**v1.0.0 admission** = P0=0 + SUMMARY 已评审 + MEMORY 决策记录 + PT-073 §6 可执行。

## 6. 报告归档路径

```
ai-lib-plans/reports/quality-audit/2026-06/
  D1-D2-{repo}.md
  D3-D4-{repo}.md
  D5-D6-{scope}.md
  SUMMARY.md
```

模板：[templates/QUALITY_AUDIT_REPORT_TEMPLATE.md](./templates/QUALITY_AUDIT_REPORT_TEMPLATE.md)

## 7. 与 PT-073 父任务关系

| PT-073 节 | 状态 | PT-073g 关系 |
|-----------|------|----------------|
| §1–§5 | ✅ | 基线证据，审查不重复跑 full matrix |
| §6 release train | ⏳ | **阻塞于 PT-073g-R6** sign-off |

## 8. 多端同步（非本机执行必读）

审查可在 LAN 内其他机器、WSL 或代理会话执行。**开工前**：

1. 拉取 `ai-lib-plans` `main`（`lan` 与 `origin` 应对齐）
2. 运行同步脚本（见 [PT-073g-SYNC_BASELINE.md](./PT-073g-SYNC_BASELINE.md) §3）
3. 确认 §2 基线表 SHA 与本地 `HEAD` 一致
4. 报告写入 `reports/quality-audit/2026-06/` 后 **双推** `lan` + `origin`

私有仓（plans / constitution / eos）须保持 `lan/main` ≡ `origin/main`；公开仓以 `ailib-official` `main` 为准。

## 9. 冲突处理（GOV-002）

真分歧时 **禁止** 盲 `reset` 或整文件 `--ours`/`--theirs`。按 [PT-073g-CONFLICT-RUNBOOK.md](./PT-073g-CONFLICT-RUNBOOK.md) 手工合并后双推 `lan` + `origin`。
