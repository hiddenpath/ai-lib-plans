---
title: ZeroSpider ai-lib Migration — Executable Step Plan
status: in_progress
created: 2026-04-22
updated: 2026-04-22
completion_notes: >
  Single integration branch feat/zerospider-ai-lib-migration: Phase 0–2 implemented in-repo
  (docs, CI, ai-lib-rust 0.9.4, protocol_adapter, protocol_registry + CLI, legacy-providers gate,
  Cargo.toml fix for ai-lib-rust on Windows). Phases 4–7 partially covered via docs/CHANGELOG;
  full legacy removal and wizard hardening remain for follow-up PRs per original one-PR-per-phase ideal.
repo_target: https://github.com/ailib-official/zerospider
related:
  - ai-protocol
  - ai-lib-rust
execution_model: one GitHub PR per phase (sequential merge recommended)
---

# ZeroSpider → ai-lib：可执行分步计划

本文档定义 **zerospider** 从「自研 provider 工厂 + 多 vendor adapter」迁移到 **ai-protocol manifest + ai-lib-rust 唯一连接底座** 的分步执行方案。  
**约定：每个 Phase 对应独立 PR，按顺序合并**，降低审查风险与回滚成本。

## 目标与验收口径（终态）

- 大模型调用：**逻辑 model id** → **`AiClient`（ai-lib-rust）** → manifest 驱动；不再维护与 manifest 重复的第二套 HTTP 适配层。
- Provider 范围：以 **ai-protocol 仓库中已包含的 manifest** 为准；无聚合平台阶段，**本地 API key 环境变量**（及 manifest 声明的鉴权占位符）决定某 provider/model 是否可用。
- 终态删除：`providers/` 下按 vendor 分文件的大工厂与 adapter（通过 `legacy-providers` 等 feature 可选保留直至完全退役）。

## 仓库与分支约定

| 项 | 约定 |
|----|------|
| 主仓库 | `ailib-official/zerospider` |
| 分支 | `feat/zerospider-ai-lib-phase-N`（N 与下表 Phase 号一致） |
| 依赖 | `ai-lib-rust` **0.9.x**；`ai-protocol` 与 ai-lib-rust **兼容的 tag/commit**（在 Phase 0 锁版本矩阵） |
| 本地开发 | 可选 `[patch.crates-io]` 指向本地 `ai-lib-rust` workspace |

## PR 映射总览

| PR | Phase | 标题（建议） | 合并前提 |
|----|-------|----------------|----------|
| 1 | 0 | chore(ai-lib): baseline, version matrix, patch docs | — |
| 2 | 1 | feat(ai-lib): bump ai-lib-rust 0.9 + thin adapter alignment | PR1 |
| 3 | 2 | feat(ai-lib): manifest registry + env-based availability | PR2 |
| 4 | 3 | feat(ai-lib): runtime entry — AiClient as primary path | PR3 |
| 5 | 4 | feat(ai-lib): fallback, routing/metrics, resilience boundaries | PR4 |
| 6 | 5 | refactor(ai-lib): remove legacy providers / factory (feature-gated deletion) | PR5 |
| 7 | 6 | docs+ux: migration guide, wizard hooks, security hardening | PR6 |

---

## PR1 — Phase 0：基线与文档

**目的**：固定协作方式，避免迁移中与 0.8 API 或错误 protocol 提交纠缠。

### 执行清单（zerospider）

- [ ] 在 `docs/` 新增或更新 **`ai-lib-migration.md`**（或等价单页）：`AI_PROTOCOL_DIR`、推荐 `ai-protocol` **tag/commit**、对应 `ai-lib-rust` **crate 版本**、本地 `[patch.crates-io]` 示例。
- [ ] `Cargo.toml`：明确 `ai-lib-rust` 目标版本线（**0.9**），与当前 `Cargo.lock` 策略一致；若仍为 0.8，仅在本 PR **写明**「下一 PR 将升级」，不强制在本 PR 完成升级（避免与 PR2 职责混淆时可把版本 bump 全部放 PR2）。
- [ ] CI：确保存在 **`--features ai-protocol`**（或后续重命名后的 feature）的 `cargo check` 任务。
- [ ] （可选）`CONTRIBUTING` 片段：如何 submodule / 克隆 `ai-protocol` 到本地。

### 交付物

- 文档 + CI 任务可指向的链接/命令。

### PR1 合并条件

- CI 绿色；文档中 **版本矩阵** 与 `ai-lib-rust` / `ai-protocol` 实际兼容关系一致（人工审查）。

---

## PR2 — Phase 1：依赖与薄适配层对齐

**目的**：把可选旁路升级为 **正式、API 对齐** 的 ai-lib 调用面。

### 执行清单（zerospider）

- [ ] `Cargo.toml`：`ai-lib-rust` → **0.9.x**；核对 feature：`embeddings` / `batch` / `telemetry` 等；按需打开后续 Phase 用的 feature 占位（如 `routing_mvp`）但默认可先关闭。
- [ ] `src/providers/protocol_adapter.rs`（或重命名为 `ai_lib_provider.rs`）：
  - [ ] 所有 chat/stream 路径在需要时使用 **`ChatRequestBuilder::model(...)`**（与上层传入 model 一致）。
  - [ ] `convert_messages`：支持 **tool** 角色及与 `Message` 对齐的字段（多轮工具调用）。
  - [ ] 流式：记录对 `PartialToolCall` / `Metadata` 的 **策略**（实现或显式 TODO + 不崩溃）。
- [ ] 明确 **重试分层**：仅 `Error::is_retryable` / `retry_after` + 本层有限重试；与将来 `resilience` 的边界写在注释中。
- [ ] 单元测试：消息转换、model 覆盖逻辑。
- [ ] `CHANGELOG.md`：Breaking / 依赖升级说明。

### 交付物

- 可编译、可测的适配层；CHANGELOG 条目。

### PR2 合并条件

- `cargo test` 相关模块通过；至少一条集成路径（可 mock）验证非流式 + 流式。

---

## PR3 — Phase 2：逻辑 Model 注册表与本地 Key 可用性

**目的**：无聚合平台时，用 **manifest + env** 表达「哪些模型可用」。

### 执行清单（zerospider）

- [ ] 扫描 `AI_PROTOCOL_DIR`：枚举 **provider id** 与 **逻辑 model id**（与 ai-lib / manifest 结构一致，可封装为独立模块 `registry`）。
- [ ] 解析鉴权占位符 → **required env**；规则：**全部满足非空** → provider **可用**。
- [ ] 对外输出：CLI 子命令或 JSON 导出（`list-providers` / `list-models` 二选一或都要）。
- [ ] 配置模型：用户配置以 **逻辑 model id** 为主；可选 fallback 列表结构预留。

### 交付物

- 注册表模块 + 文档中的「env ↔ provider」说明。

### PR3 合并条件

- 无 key 时列表为空或标记不可用；设置 env 后出现对应项；更换 `ai-protocol` 提交后列表变化可感知（手动或轻量测试）。

---

## PR4 — Phase 3：运行时入口切换 — AiClient 为主路径

**目的**：业务默认走 **manifest + AiClient**，旧工厂退居 feature gate。

### 执行清单（zerospider）

- [ ] 引入统一入口（示例名）：`resolve_ai_client(model_id) -> ...`，封装 `AiClient`/`AiClientBuilder` 构造方式（与 ai-lib 当前推荐一致）。
- [ ] Agent 会话层：**主路径** 调用薄适配层；**单一** `Provider` 实现覆盖 ai-lib（若暂时保留 trait）。
- [ ] Feature 策略：新增 **`legacy-providers`**（默认 **off**），旧 `create_provider*` 仅在该 feature 下编译。
- [ ] 默认 feature 集验证：二进制体积或依赖树对比（可选记录在 PR 描述）。

### 交付物

- 架构说明（短）：Session → AiLib provider → AiClient。

### PR4 合并条件

- 默认 feature 下核心场景 E2E 通过；`legacy-providers` 关闭时旧路径不可达或明确报错。

---

## PR5 — Phase 4：横切能力 — Fallback、路由、指标、韧性边界

**目的**：删除重复逻辑前，把行为 **对齐 ai-lib 语义**。

### 执行清单（zerospider）

- [ ] **Fallback 链**：配置 `primary_model_id` + `fallbacks: Vec<_>`；实现链式切换；与 `ChatRequestBuilder::model` / 多 client 策略选其一并文档化。
- [ ] 按需启用 **`routing_mvp`** 等 ai-lib feature；对接 **`AiClient::metrics()`**（若适用）。
- [ ] **`ai_lib_rust::resilience`**（可选）：与 Phase 1 应用层重试 **不重复**；开关与行为写清。
- [ ] 遥测：与现有 OpenTelemetry 并存策略（不重复计数同一指标）。

### 交付物

- 配置示例 + 429/5xx 下的行为说明。

### PR5 合并条件

- 模拟失败场景下 fallback / 重试符合设计；指标/日志可观察（若项目已启用）。

---

## PR6 — Phase 5：删除 Legacy Provider 与工厂

**目的**：代码层面 **移除** vendor 模块与大 `match`（或迁至独立 crate）。

### 执行清单（zerospider）

- [ ] 清单化 `providers/*.rs`：确认无不可被 manifest 替代的逻辑。
- [ ] 删除或迁移至 `legacy` crate；默认 feature 不包含。
- [ ] **Breaking**：主版本号与 `CHANGELOG` **醒目标注**。
- [ ] 迁移指南：旧 env / 旧 shorthand → 新逻辑 model id + manifest 要求。

### 交付物

- 大量删除 diff + 迁移文档。

### PR6 合并条件

- 全量测试通过；grep 确认无意外引用旧工厂（除 legacy feature）。

---

## PR7 — Phase 6：产品化与体验

**目的**：「个人通用代理」可长期维护。

### 执行清单（zerospider）

- [ ] 配置向导：检测 `AI_PROTOCOL_DIR`、缺失 env、友好错误信息。
- [ ] 嵌入/批处理（若需要）：与聊天共用 manifest 路径。
- [ ] 日志脱敏；密钥仅 env/keyring。
- [ ] 文档：`ai-protocol` **兼容提交区间** 与发版节奏说明。

### 交付物

- 用户可见文档与可选 CLI 改进。

### PR7 合并条件

- 文档审查通过；冒烟路径手动或通过 E2E 脚本验证。

---

## 跨 PR 测试矩阵（最低要求）

| 层级 | 内容 |
|------|------|
| 单元 | 消息转换、model id 解析、registry 可用性 |
| 集成 | 带真实 env 的 chat（可 nightly / 手动） |
| 回归 | 固定 `ai-protocol` 小版本下的 smoke：列表 + 一次对话 |

## 风险与回滚

| 风险 | 缓解 |
|------|------|
| manifest 与 ai-lib 漂移 | Phase 0 锁矩阵；CI 可选 submodule 固定 commit |
| 双重重试 | Phase 1/4 明确开关与文档 |
| PR 过大 | **严格遵守一 Phase 一 PR**；超大变更拆到子任务但仍在同一 Phase PR 内用 commit 分层 |

## 执行状态回填

本计划执行完成后，请在本文件末尾或关联 task YAML 中更新：`status`、`completion_notes`、各 PR 链接。  
并按 `ai-lib-plans` 仓库规则执行文档变更后的同步脚本（若适用）。

---

**Maintainer**: 由 zerospider / ai-lib 负责人维护  
**格式**: Markdown；与仓库内 YAML task 可交叉引用
