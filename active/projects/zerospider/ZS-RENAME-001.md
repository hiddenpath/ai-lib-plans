---
title: ZeroSpider → VelaClaw 更名计划
status: pending
created: 2026-04-28
updated: 2026-04-28
prerequisites: ZS-ML-001~006 全部完成（已完成）
target_merge_moment: ZS-ML 系列全量合入 main 后，作为一次集中 rename PR
repo_target: https://github.com/ailib-official/zerospider
---

# ZeroSpider → VelaClaw 更名计划

## 决策依据

- ZeroSpider fork from ZeroClaw，改名 VelaClaw 可蹭上 Claw 生态热度
- Vela 是 ai-lib 品牌体系中已定名的用户端（To C）侧产品名
- VelaClaw 品牌信号明确：Claw 生态 × 用户端产品 × 独立开源项目
- 时机：ZS-ML 全量合入 main 后一次性改名，测试方便

## 改名受影响范围

### 一、仓库级变更（GitHub + Git）

- [ ] 仓库改名：`ailib-official/zerospider` → `ailib-official/velaclaw`
- [ ] 所有本地 clone 更新 remote URL
- [ ] GitHub 自动 301 重定向旧链接，但文档中所有硬编码 URL 仍需更新

### 二、代码内引用（按搜索范围排序）

- [ ] Cargo.toml `[package] name = "zerospider"` → `"velaclaw"`
- [ ] 模块/二进制目标名 `[[bin]] name = "zerospider"` → `"velaclaw"`
- [ ] `src/lib.rs` / `src/main.rs` 内 crate name 引用（如 `extern crate zerospider` 或 `use zerospider::...`）
- [ ] 所有 doc comment 中的 `zerospider` 引用
- [ ] README.md / README.zh-CN.md — 标题、描述、链接
- [ ] CONTRIBUTING.md
- [ ] 迁移指南 `docs/ai-lib-migration.md`
- [ ] 其他 docs/ 下的文档
- [ ] Cargo.lock（`cargo update` 后自动更新包名）

### 三、CI / 基础设施

- [ ] GitHub Actions：`.github/workflows/*.yml` 中仓库名引用、包名
- [ ] 如果已发 crate：crates.io 上标记 `zerospider` 废弃，发布 `velaclaw`
- [ ] 如果存在 GitHub Pages / 文档自动部署：更新源路径

### 四、外部引用

- [ ] 搜索 `ailib-official/zerospider` 在 ailib-official 其他仓库中的引用
- [ ] ai-lib-plans 内所有 `zerospider` 引用 → 更新

### 五、项目目录

- [ ] 可选：`ai-lib-plans/active/projects/zerospider/` → `ai-lib-plans/active/projects/velaclaw/`

## 执行顺序

```
1. 代码内改名（本地分支）
2. 验证：cargo build / cargo test 通过
3. 验证：grep -r "zerospider" src/ 无残留
4. 更新文档
5. 提交 PR 到 ailib-official/main 合并
6. GitHub 手动变更仓库名
7. 更新 CI / 基础设施
8. 更新 ai-lib-plans 引用
9. crates.io 发布（如适用）
```

## 备注

- GitHub 仓库改名后，旧 URL 自动 301 重定向，issues / PR / wiki 都不丢
- 改名当天可能短暂影响 CI hook，建议在低流量时段操作
- 所有本地 collaborator 需要 `git remote set-url origin ...`

---

参考：PR #14 (aa3214a) 改名经验 + OpenClaw ZeroSpider fork from ZeroClaw 原始上下文
