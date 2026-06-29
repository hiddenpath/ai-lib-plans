# 质量审查报告 — {REPO_OR_SCOPE}

<!-- AUDIT_META: dimension={D1|D2|D3|D4|D5|D6|SUMMARY} repo={name} auditor={name} date={YYYY-MM-DD} task=PT-073g status={draft|final} -->

> **任务**: [PT-073g](../tasks/PT-073g-cross-repo-quality-audit.yaml)  
> **维度**: {维度名称 — 见 QUALITY_AUDIT_PLAN §3}  
> **仓库/范围**: `{owner/repo}` 或 `{跨仓库主题}`  
> **审查人**: {name}  
> **日期**: {YYYY-MM-DD}  
> **基线 commit**: `{sha}`（`main` @ {date}）

---

## 1. 执行摘要

| 指标 | 值 |
|------|-----|
| 抽样路径数 | {n} |
| P0 发现 | {n} |
| P1 发现 | {n} |
| P2 发现 | {n} |
| 总体结论 | {PASS_WITH_FIXES / BLOCKED / DEFER} |

**一段话结论**（maintainer 可读）：

> {例如：公共 API 与文档基本一致；发现 1 项 P0 contact 误导出 P 类型，需 PR 修复后方可 1.0。}

---

## 2. 审查范围与方法

### 2.1 范围

- **包含**: {路径、crate、package}
- **排除**: {tests only / generated / vendor}
- **对照文档**: {README, CHANGELOG, WAVE5, MEMORY}

### 2.2 方法

- [ ] 静态阅读（入口 + 热路径）
- [ ] 自动化扫描（{工具名，如 ripgrep、cargo clippy、ruff}）
- [ ] CI 配置对照
- [ ] 合规用例 vs 实现 diff
- [ ] 其他: {…}

---

## 3. 发现项登记表

> 状态: `open` | `fixed` | `deferred` | `wontfix`  
> 严重度: **P0** | P1 | P2

| ID | 严重度 | 状态 | 位置 | 问题 | 建议修复 | 跟踪 |
|----|--------|------|------|------|----------|------|
| QA-{repo}-001 | P0 | open | `{file}:{line}` | {描述} | {具体修复} | PR #{n} / issue |

---

## 4. 维度专项检查

### Dim 1 — 公共 API（若适用）

| 检查项 | 结果 | 备注 |
|--------|------|------|
| 导出符号与 README 一致 | ⏳/✅/❌ | |
| 跨运行时同名字段语义对齐 | | |
| CHANGELOG 覆盖已暴露 breaking | | |

### Dim 2 — E/P 深度（若适用）

| 检查项 | 结果 | 备注 |
|--------|------|------|
| 无 P 模块渗入 core 编译单元 | | |
| WASM 打包无 P 依赖 | | |
| contact 仅为 E 层聚合 | | |

### Dim 3 — 代码质量（若适用）

| 检查项 | 结果 | 备注 |
|--------|------|------|
| unwrap/panic/unsafe 在热路径 | | |
| 无 hardcoded provider 分支 | | |
| 错误传播一致 | | |

### Dim 4 — 测试真实性（若适用）

| 检查项 | 结果 | 备注 |
|--------|------|------|
| full vs subset CI 文档化 | | |
| 跳过/ignore 用例清单 | | |
| mock 与 manifest 同步 | | |

### Dim 5 — 安全（若适用）

| 检查项 | 结果 | 备注 |
|--------|------|------|
| 无密钥入仓/日志 | | |
| proxy / trust_env 默认安全 | | |
| 依赖 CVE 审查 | | |

### Dim 6 — 文档迁移（若适用）

| 检查项 | 结果 | 备注 |
|--------|------|------|
| CHANGELOG 与 merge 一致 | | |
| ailib.info / README 对齐 | | |
| MEMORY 决策待更新项 | | |

---

## 5. 证据附录

### 5.1 命令与输出摘要

```bash
# 示例
cd {repo} && cargo clippy -p ai-lib-core -- -D warnings 2>&1 | tail -20
```

```
{粘贴关键输出或「无 findings」}
```

### 5.2 抽样路径清单

1. `{path}` — {为何选此路径}
2. …

---

## 6. 签核

| 角色 | 姓名 | 日期 | 结论 |
|------|------|------|------|
| 审查人 | | | |
| Maintainer | | | 批准进入 SUMMARY / 要求 P0 修复 |

---

## 变更记录

| 日期 | 变更 |
|------|------|
| {date} | 初稿 |
