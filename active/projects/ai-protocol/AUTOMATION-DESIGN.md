# Spider ↔ Cursor 自动化协作设计

## 概述

本文档描述 Spider（OpenClaw）与 Cursor（云端 Sandbox Agent）之间的自动化协作流程，实现从 PR 创建到合并的端到端自动化。

## 架构

```
PR 创建/同步 → GH Actions fire-cursor
  → Cursor Cloud Sandbox 修复代码
  → push 修复
  → GH Actions verify-and-merge
  → Spider 最终验证 + 合并 + 回填 plans
```

## 新增分支 Workflow 同步协议

新分支创建时 **必须确保 workflow 文件存在**，否则 CI 可能从 `main` 读取不匹配的版本（或其他分支上没有 workflow 文件时 Actions 无法执行）。

### 原则

- CI 触发时使用 **分支 HEAD 上的 workflow 文件**（而非默认分支）。
- 如果分支没有 workflow 文件，GitHub Actions 会回退到默认分支（`main`）的文件。这种回退不安全，因为：
  - 默认分支的 workflow 可能与分支代码不兼容（如参数变更、新增步骤）
  - 分支覆盖可能因缺失 workflow 文件导致空洞
- **设计约束**：分支创建后，Spider 自动检查 `/.github/workflows/` 下是否有必要 workflow，若缺失则 **从 main 同步**。

### 流程

1. Cursor push 新分支 → GH Actions 触发（若分支有 workflow 文件）。
2. Spider 检测分支状态：
   - 若分支缺少 `.github/workflows/verify-and-merge-*.yml`
   - Spider 从 main 同步完整 workflow，push 到该分支
3. workflow 同步后重新触发 CI。

## 组件清单

### 1. 审查报告模板

**文件路径:** `templates/REVIEW_TEMPLATE.md`
**格式:** Markdown 表格 + HTML meta 注释
**关键约定:**
- `⏳` = pending fix（cursor 处理）
- `✅` = 已解决或无需修复
- `🔄` = 正在修复中
- `<!-- REVIEW_META: {...} -->` = 机器可读元数据

### 2. GH Actions: trigger-cursor-fix

**文件路径:** `templates/GH_TRIGGER_CURSOR.yml`
**放置位置:** `.github/workflows/trigger-cursor-fix.yml`（目标 repo）
**触发条件:** `issue_comment` where body contains `## Review Report` and `⏳`
**动作:** POST 到 Cursor Automations API

### 3. GH Actions: verify-and-merge

**文件路径:** `templates/GH_VERIFY_AND_MERGE.yml`
**放置位置:** `.github/workflows/verify-and-merge.yml`（目标 repo）
**触发条件:** push 到 `feat/**` / `fix/**` / `pt-*/**` 分支
**动作:** 跑 CI 矩阵 → 打 `ready-for-spider` label → 通知 Spider

**试点 repo（ai-lib-rust）说明（AUTO-5）：** 模板未检出 `ai-protocol`，在 `ai-lib-rust` 中会直接导致 compliance 测试失败。试点采用 **单独工作流** `.github/workflows/verify-and-merge-gate.yml`（与模板等价语义 + `ailib-official/ai-protocol` checkout + `COMPLIANCE_DIR`）。合并到 `main` 后，feature 分支 push 即可走「验证 → PR 留言 → `ready-for-spider`」路径。PR：`ailib-official/ai-lib-rust` 分支 `feat/pt-074-auto5-verify-merge-gate`。

### 4. Spider Review Module

**文件路径:** `templates/SPIDER_REVIEW_MODULE.sh`
**使用方式:** `source` 后调用 `spider_review <repo> <branch>`
**功能:**
- 拉分支
- 自动检测审查深度（deep/medium/shallow）
- 基于 diff 自动检测部分常见问题
- 运行验证套件（fmt/clippy/test/no-default-features）
- 输出结构化审查报告

## 部署步骤

### 阶段一（当前 · 手工辅助）

1. 先生 @spider "审查 PT-XXX"
2. 执行 `spider_review ai-lib-rust feat/pt-xxx`
3. Spider 输出报告，先生复制给 Cursor
4. Cursor 修复 + push
5. 先生 @spider "验证合并 PT-XXX"
6. Spider 拉最新、验证、合并、回填 plans

### 阶段二（先生配置 Cursor Automation 后）

1. 先生 @spider "审查 PT-XXX"
2. Spider 自动审查、自动发表 PR comment
3. Cursor Automation 监听到此 comment → 自动拉取、修复、push
4. GH Actions verify-and-merge 跑 CI → 打 ready-for-spider label
5. Spider 检测到 label → 验证 → 合并 → 回填 plans → 通知先生

### 阶段三（全自动）

1. Cursor push 到 `feat/*` → GH Actions fire-cursor → Spider 审查
2. Spider 自动发表审查报告
3. Cursor Automation 自动修复
4. CI → Spider 验证 → 合并 → 回填
5. 先生只需要在出现 `🔴 blocking` 问题时介入

## 防循环设计

- `ready-for-spider` label 防止反复触发
- Spider 合并时不触发 verify-and-merge（通过 `if: github.actor != 'spider-bot'`）
- 最大 3 轮迭代，超时标记 blocked
- Cursor 只修 `⏳`，不修 `✅`

## 安全边界

- GH Token 用 GitHub App 或 fine-grained PAT，权限最小化
- Cursor 云端沙箱不能访问先生的内网资产
- 合并决策最终保留在 Spider（先生控制）
- 关键 PR（突破性变更）必须经过人工 approve
