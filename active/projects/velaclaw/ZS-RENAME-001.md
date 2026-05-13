---
title: ZeroSpider → VelaClaw 更名计划
status: completed
created: 2026-04-28
updated: 2026-05-13
prerequisites: ZS-ML-001~016 全部完成（已完成）
target_merge_moment: ZS-ML 系列全量合入 main 后，分 PR 集中 rename
repo_target: https://github.com/ailib-official/velaclaw
execution_model: 分 3 个 PR + 1 个 infra 任务，串行执行
task_ids:
  - ZS-RN-001
  - ZS-RN-002
  - ZS-RN-003
---

# ZeroSpider → VelaClaw 更名计划

## 决策依据

- ZeroSpider fork from ZeroClaw，改名 VelaClaw 可蹭上 Claw 生态热度
- Vela 是 ai-lib 品牌体系中已定名的用户端（To C）侧产品名
- VelaClaw 品牌信号明确：Claw 生态 × 用户端产品 × 独立开源项目
- 时机：ZS-ML 全量合入 main 后一次性改名，测试方便

## 改名受影响范围

### 一、仓库级变更（GitHub + Git）

- [x] 仓库改名：`ailib-official/zerospider` → `ailib-official/velaclaw`
- [x] 所有本地 clone 更新 remote URL
- [x] GitHub 自动 301 重定向旧链接，但文档中所有硬编码 URL 仍需更新

### 二、代码内引用（按搜索范围排序）

- [x] Cargo.toml `[package] name = "zerospider"` → `"velaclaw"`
- [x] 模块/二进制目标名 `[[bin]] name = "zerospider"` → `"velaclaw"`
- [x] `src/lib.rs` / `src/main.rs` 内 crate name 引用（如 `use zerospider::...`）
- [x] 所有 doc comment 中的 `zerospider` 引用
- [x] README.md / README.zh-CN.md — 标题、描述、链接
- [x] CONTRIBUTING.md
- [x] 迁移指南 `docs/ai-lib-migration.md`
- [x] 其他 docs/ 下的文档
- [x] Cargo.lock（`cargo update` 后自动更新包名）

### 三、CI / 基础设施

- [x] GitHub Actions：`.github/workflows/*.yml` 中仓库名引用、包名
- [ ] 如果已发 crate：crates.io 上标记 `zerospider` 废弃，发布 `velaclaw`（N/A — 未发布 crates.io）
- [ ] 如果存在 GitHub Pages / 文档自动部署：更新源路径

### 四、外部引用

- [x] 搜索 `ailib-official/zerospider` 在 ailib-official 其他仓库中的引用
- [x] ai-lib-plans 内所有 `zerospider` 引用 → 更新

### 五、项目目录

- [x] 可选：`ai-lib-plans/active/projects/zerospider/` → `ai-lib-plans/active/projects/velaclaw/`

## 执行顺序

```
1. ✅ 代码内改名（本地分支 rename/zs-rn-001-crate-name-rename）
2. ✅ 验证：cargo check / clippy / fmt 通过
3. ✅ 验证：grep -r "zerospider|zeroclaw|ZeroClaw|ZeroSpider" 无残留
4. ✅ 更新文档 + 固件 + 脚本（ZS-RN-001 + ZS-RN-002 合并为单 PR）
5. ✅ 提交 PR 到 ailib-official/main — PR #38 (squash-merged as 36b9a5c)
6. ✅ GitHub 仓库名变更 → ailib-official/velaclaw（ZS-RN-003）
7. ✅ 更新 CI / 基础设施（N/A — CI 在 PR #38 中已更新）
8. ✅ 更新 ai-lib-plans 引用
9. N/A crates.io 发布（未发布 crates.io）
```

## 备注

- GitHub 仓库改名后，旧 URL 自动 301 重定向，issues / PR / wiki 都不丢
- 改名当天可能短暂影响 CI hook，建议在低流量时段操作
- 所有本地 collaborator 需要 `git remote set-url origin ...`

---

参考：PR #14 (aa3214a) 改名经验 + OpenClaw ZeroSpider fork from ZeroClaw 原始上下文
