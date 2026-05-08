# ZeroSpider — Phase 7： semver 底座收口 + Legacy 彻底退役

**Status:** draft (execution queue for next session)  
**Created:** 2026-05-08  
**Canonical repo:** `https://github.com/ailib-official/zerospider`  
**Depends on:** ZS-ML-001～010 已完成（默认 `ai-protocol`、适配层、CI 整改、文档）

## 背景与目标

ZS-ML-001～010 把 **协议路径** 变成默认，并把 **legacy HTTP 工厂** 限缩在 `legacy-providers` feature 之后，**并未**从代码库中物理删除旧连接方式。若目标是：

1. **ZeroSpider 在 ai-lib（manifest + `AiClient`）支持下可流畅运行**（默认路径、错误信息、文档一致）；且  
2. **旧 string-key / 内置 vendor HTTP 连接方式被彻底弃用**（不可再作为支持矩阵内的官方路径）；

则需要本 Phase 的若干 **顺序化任务**（每条独立 PR + 可重复验证）。

与 **ai-lib v1.0** 的关系：**只做消费者成熟度**；v1.0 semver / 兼容承诺仍服从 `ai-lib-plans/MEMORY.md` 中 maintainer 批准的版本策略。

---

## 仓库对齐核实（2026-05-08）

| 检查项 | 结果 |
|--------|------|
| 本地 `main` = `ailib-official/main` | **是**（示例：`d04b009`） |
| `git remote` 仍以 `hiddenpath/zerospider` 为 `origin` | **常见遗留**；建议按 **ZS-ML-011** 收口，避免 `git pull` 拉到错误默认远端 |
| `Cargo.toml` 中 `ai-lib-rust` | 仍为 **git `rev` 钉死**（非 crates.io）；与 PT-074 后已发布的 `0.9.6+` 不一致 → **ZS-ML-012** |

---

## 任务总览（新 YAML）

| ID | 主题 | 阻塞关系 |
|----|------|----------|
| **ZS-ML-011** | Git 远端与 `main` 上游：以 ailib-official 为默认 | 建议最先做（减少后续 PR 基线混乱） |
| **ZS-ML-012** | `ai-lib-rust` → crates.io semver + `Cargo.lock` + `--locked` | 依赖 011 推荐完成 |
| **ZS-ML-013** | CI：**必选** job 不依赖 `legacy-providers`；legacy 降级为单独 job | 可与 012 并行，但与 014/015 顺序相关 |
| **ZS-ML-014** | Legacy `match` 臂 → ai-protocol manifest **覆盖表**；缺 manifest 的在 **ai-protocol** 开补 | 阻塞 015 |
| **ZS-ML-015** | **删除或迁出** `legacy-providers` 实现（大删或使用独立 `*-legacy` crate） | 依赖 014 闭环 |
| **ZS-ML-016** | 文档/向导/CHANGELOG：官宣废弃区间、迁移 deadline、错误词条 | 可与 015 同 PR 或紧跟 |

---

## 可靠验证原则（全局）

每条任务 **完成定义** 必须同时满足：

1. **自动化：** 列出的 `cargo` / workflow 命令在 **Linux CI**（及文档注明时 **Windows**）可复现。  
2. **可审计：** PR 描述写清 **行为变更**、**风险**、**回滚**（revert commit）。  
3. **负面检查：** 对“legacy 已不存在”类任务，必须在 PR 中包含 `rg`/`grep` 约束或 `compile_error!` 门，避免死代码回流。  
4. **executor 字段：** 任务 YAML 在 `in_progress` / `completed` 时填写 `executor_name`、`executor_terminal`（`ai-lib-plans` 规则）。

---

## ZS-ML-011 — 远端与跟踪分支

### 目的

消除 `main` 跟踪 `hiddenpath`、或 `pull` 默认拉错库导致的 **基线漂移**。

### 实施要点（择一，推荐 A）

- **A.** `git remote rename origin hiddenpath-archive`（或删除），`git remote rename ailib-official origin`，`git fetch origin`，`git branch --set-upstream-to=origin/main main`。  
- **B.** 保留双远端，但 **强制** `main` 只跟踪 `ailib-official/main`：`git branch --set-upstream-to=ailib-official/main main`。

### 验证（必须）

```bash
git remote -v
git status -sb   # main 不应再出现对错误 upstream 的 “ahead/behind” 误报
git rev-parse main
git rev-parse ailib-official/main   # 或与 origin/main 在改名后一致
# 期望：main === 官方默认远端 main
```

### 交付

- 若涉及 **贡献文档**：`CONTRIBUTING.md` 或 `docs/ai-lib-migration.md` 顶部 **一行** 写明「clone URL 以 ailib-official 为准」。  
- 本任务 **可单独小 PR**（仅文档 + 无代码）或维护者本地执行后由 PR 更新文档；若仓库政策要求所有变更走 PR，则 **仅文档 PR**。

---

## ZS-ML-012 — `ai-lib-rust` crates.io 与 Lockfile

### 目的

将 `Cargo.toml` 中 `ai-lib-rust` **从 git `rev`** 改为 **crates.io**（如 `0.9.6`，或与 `ai-lib-rust` 当前兼容补丁对齐），与 PT-074 发布节奏及 `MEMORY` 一致。

### 实施要点

1. 选择 **最低兼容版本**（须包含 `ai_lib_rust::credentials` 等当前 call site 所需 API）。  
2. 替换 dependency 表；`cargo update -p ai-lib-rust`；提交 **最小 diff 的 `Cargo.lock`**。  
3. 注释掉旧 git pin 说明，改为 **semver 范围**（例如 `0.9.6` 精确 pin 或 `0.9` patch 允许）。  
4. 若启用 `routing_mvp` 等 features，确认 **crates.io 发布的 feature 名** 与 git 一致。

### 验证（必须）

```bash
cargo fetch --locked
cargo tree -p ai-lib-rust -i  # 或 cargo tree | rg ai-lib-rust — 须显示 registry 来源而非 git
cargo test -p zerospider --features ai-protocol --locked
cargo test -p zerospider --features "ai-protocol legacy-providers" --locked   # 在 015 删除 legacy 前仍须绿
```

CI：现有 **`--locked`** 步骤必须 **绿**（若 CI 未加 `--locked`，本任务 **顺带加上** `cargo fetch --locked` 与测试矩阵中的 `--locked`）。

---

## ZS-ML-013 — CI：`ai-protocol` 为主，`legacy-providers` 为隔离回归

### 目的

**合并门禁** 不以 “带了 legacy 才能全绿” 为隐含前提；legacy 仅 **显式 job**（可选 `continue-on-error: false` 但允许从 `merge-required` 组摘除，由团队选择）。

### 实施要点

1. 拆分 workflow：  
   - **required：** `cargo test` / `cargo check` 使用 **`--features ai-protocol`**（与 `default` 一致）。  
   - **legacy-regression：** `cargo test --features "ai-protocol legacy-providers"`（或命名 `legacy_http_factory`）。  
2. 在 `CONTRIBUTING.md` 说明：改 `providers/mod.rs` legacy 臂时 **必须跑** legacy job 本地等价命令。  
3. （可选）在 `merge_queue` / branch protection 中仅勾选 required jobs。

### 验证（必须）

- PR 中贴 **两份** workflow 运行链接：required 绿；legacy job 绿（在 015 删除前）。  
- **发布后 015**：legacy job **删除或改名** 为不再调度。

---

## ZS-ML-014 — Legacy 覆盖审计（manifest 真源）

### 目的

在删除代码前，对每个 **legacy-only** 解析路径（`openrouter`、`custom:`、`anthropic` shorthand 等）建立 **ai-protocol manifest 等价物** 或在 **ai-protocol** 仓库开 issue/PR **补 manifest**。

### 实施要点

1. 产出表格（可放在 `docs/internal/legacy-manifest-parity.md` 或 plans）：列 = legacy 触发条件 | protocol `provider_id/model_id` | manifest PR | 验证方式。  
2. **ZeroSpider 不写 vendor 特例**；缺口在 **ai-protocol** 修。  
3. 对 **确实无人维护** 的 vendor：在文档标 **unsupported**，并在 `create_provider` 错误信息指向上游 issue。

### 验证（必须）

- **协议合规：** `ai-protocol` PR（若有）通过其 **schema / compliance** 校验。  
- **ZeroSpider：** 增加 **最少 1 个** 集成测试：`AI_PROTOCOL_DIR` 指向 **最小 fixture**，`create_provider` / `resolve_ai_client` **仅 protocol** 路径可解析该 provider（不启用 `legacy-providers`）。  
- 维护者 **签字**：表格中 **无** “仍依赖 legacy 臂才能工作” 的行（或已接受 unsupported）。

---

## ZS-ML-015 — 删除 / 迁出 `legacy-providers`

### 目的

**物理移除** `src/providers/mod.rs` 中大段 `#[cfg(feature = "legacy-providers")]` 工厂，或迁至 **独立 crate**（默认不依赖），使 **默认构建树** 不包含旧 HTTP 连接实现。

### 实施要点

1. **策略选择**（PR 中必须二选一写清）：  
   - **硬删：** 删除 feature 与模块；**semver** 按项目当前政策（0.x patch bump 若仅内部、或 minor 若公开 API 表面变化——由 maintainer 定）。  
   - **外置 legacy crate：** `zerospider-legacy-providers` optional path dependency；默认 `zerospider` 不引用。  
2. 删除 `Cargo.toml` 中 `legacy-providers` feature 或标记 `deprecated = ...`（如 Cargo 支持）并最终移除。  
3. 清理 `doctor`、`tests/provider_resolution.rs` 等 **cfg** 分支。  
4. `CHANGELOG.md` **Breaking** 节：列出移除的 string keys。

### 验证（必须）

```bash
rg "legacy-providers" -S .github src Cargo.toml
# 期望：无 或 仅文档 “历史” 节

cargo build -p zerospider --features ai-protocol --locked
cargo test -p zerospider --features ai-protocol --locked
# 全量 workspace 测试按 CI 矩阵

# 负面： intentional 尝试 legacy key 应返回清晰错误（协议迁移文档链接）
```

### 回滚

保留 **revert PR** 或 tag **pre-legacy-removal** 便于应急。

---

## ZS-ML-016 — 文档、向导与用户体验

### 目的

在 legacy 移除前后，用户 **仅** 被引导至 `provider/model` + `AI_PROTOCOL_DIR`。

### 实施要点

1. 更新 `docs/migration-legacy-to-protocol.md`、`docs/ai-lib-migration.md`、`README` 快速开始。  
2. CLI / doctor：当检测到 **旧 config 键** 时，打印 **可操作** 迁移步骤（非泛泛 “see docs”）。  
3. 若适用：在 `CHANGELOG` 标注 **移除版本** 与 **最后仍含 legacy 的版本**。

### 验证（必须）

- **文档契约测试**（若仓库已有 `docs_contract` 测试）：更新 golden / 包含新链接。  
- **手动清单（PR 模板勾选）：**  
  - [ ] 全新 clone + 仅 `AI_PROTOCOL_DIR` 可完成一次 chat smoke（或 mock）。  
  - [ ] 故意使用已废弃 key 时错误信息含迁移关键词与 doc 链接。

---

## 建议执行顺序（下一 session）

1. **ZS-ML-011**（可本地 + 文档 PR）  
2. **ZS-ML-012**（依赖 semver）  
3. **ZS-ML-013**（CI 语义）  
4. **ZS-ML-014**（跨仓：ai-protocol + zerospider 测试）  
5. **ZS-ML-015**（大删，需谨慎 review）  
6. **ZS-ML-016**（可部分提前，终稿在 015 后）

---

## 关联文档

- `ZEROSPIDER_AI_LIB_MIGRATION_PLAN.md` — Phase 0～6 历史；**Phase 7 以本文为准**  
- `TASKS_INDEX.md` — 任务登记与状态  
- `docs/migration-legacy-to-protocol.md`（zerospider 仓库）  
- `ai-lib-plans/MEMORY.md` — pre-v1.0 版本与 PT-073 边界  

---

**Maintainer notes:** 完成每条任务后，更新对应 YAML 的 `status`、`pr`、`testing.evidence_*`，并运行 `ai-lib-plans` 文档同步流程（若机构要求）。
