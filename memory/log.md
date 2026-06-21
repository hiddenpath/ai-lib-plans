# Decision Log — Complete Dated History

> Chronological record of all durable decisions. Extracted principles live in:
> [`architecture.md`](./architecture.md) · [`infrastructure.md`](./infrastructure.md) · [`conventions.md`](./conventions.md)
> See [`INDEX.md`](./INDEX.md) for per-task loading strategy.

**Last sync from MEMORY.md**: 2026-06-21

---

<!-- Content preserved from ai-lib-plans/MEMORY.md (commit 816b04e).
     Dated entries restructured chronologically — oldest first, newest last.
     Extractions into memory/*.md noted inline. -->

## Rust toolchain / MSRV alignment (2026-05-14)

- **Eos（`hiddenpath/eos`）**：`Cargo.toml` 中 `[workspace.package] rust-version` 必须与 `Dockerfile` 的 `ARG RUST_IMAGE`（例如 `rust:1.86-slim`）所隐含的 **rustc 最低要求**一致；每次 `cargo update` 或引入会使依赖链 MSRV 上移的 crate 后，应 **本地**用与 CI 同大版本的 Rust 跑一次 `cargo build` / `cargo test`，并 **同步**更新 `rust-version` 与 Docker builder 镜像，避免"本地/PR 用 stable 过、Docker CI 才暴露要 bump"的反模式。
- **其他 Rust 仓库**（如 `ai-lib-rust`、`ai-protocol`）：**不要求**与 Eos 同号 MSRV，但开发习惯上应在 **依赖升级后**核对关键传递依赖的 `rustc` 版本要求（crates.io `rust-version` / 构建报错提示 / 可选 `cargo-msrv`）；若工作流含 **Docker 多阶段 Rust 镜像**，应保持镜像中的 rustc **不低于** crate 标注的 MSRV。
- **检查点**：合并前对比三处——根 `Cargo.toml` 的 `rust-version`、`Dockerfile`/CI 选用的 Rust 版本、以及最近一次 `cargo build --locked`（或等价 CI）是否在 **三者较低者**之上仍能编过。
- **内嵌构建工具二进制**：任何将 `wasm-pack`、`wasm-bindgen` 等预编译二进制纳入 Git 的路径，必须符合 `docs/engineering/VENDORED_BUILD_TOOL_BINARIES.md`。

→ **Extracted to**: [`conventions.md#rust-toolchain`](./conventions.md#rust-toolchain)

## Product cadence — matrix vs validation vs tooling (2026-05-07)

- **VelaClaw 迁移**（原 ZeroSpider）：ai-lib 消费者集成成熟度验证已完成；产品定位为 Claw 生态 Rust-only 桌面/CLI agent SKU。
- **VelaClaw 执行模型（VL-ARCH-001，2026-06-09）**：Rust-only；BYOK 直连；prism-core 内嵌；非默认 HTTP Gateway 客户端。
- **PR / CI / release 自动化**：工作中理顺协作与发版方法，不等同于"产品已 ready"。

→ **Extracted to**: [`architecture.md#velaclaw`](./architecture.md#velaclaw)

## Pre-v1.0 versioning and PT-073 scope (2026-05-07)

- PT-073 的目标是 v1.0 的充分准备，不是自动判定"可以升级到 v1.0"的开关。
- 将版本提升至 v1.0.0 必须由 maintainer 明确批准；在此之前对外版本号仅按 0.x 系列 patch 递增。
- v1.0 之后 SemVer 下 1.x 默认承担向后兼容义务。

→ **Extracted to**: [`conventions.md#versioning`](./conventions.md#versioning)

## Planning truth source — task status

- Canonical per-task records: `active/projects/<project>/tasks/*.yaml`
- Do not treat narrative reports as authoritative if they disagree with task YAML.
- Known drift cleaned (2026-04-21): PT-054~062 synced.

## crates.io 发布记录 (2026-04-13)

### ai-lib-rust v0.9.4

- 发布：ai-lib-core v0.9.4, ai-lib-contact v0.9.4, ai-lib-rust v0.9.4
- 关键修复：transport mapping hardening, ExecutionUsage partial JSON, v2 provider loading
- Protocol v1→v2 一致性修复

## Governance — internal repositories (2026-04-06)

- ai-lib-constitution, ai-lib-plans, papers 是内部仓，不可推送到 ailib-official。
- GOV-001 v2: 所有公开代码仓在 ailib-official；hiddenpath 公开仓已归档。
- npm: `@ailib-official/ai-lib-ts` (v0.6.0+)。

→ **Extracted to**: [`conventions.md#governance`](./conventions.md#governance)

## Architecture Decisions

### Protocol-Driven Design (ARCH-001)
- 一切逻辑皆算子，一切配置皆协议
- Adding a new provider = add manifest only, no runtime code changes.

### Operator Pipeline (ARCH-002)
- Chat flow: decode → select → accumulate → fanout → map

### Cross-Runtime Consistency (ARCH-003)
- All runtimes must pass ai-protocol compliance tests.
- Unified request/response format across Rust, Python, TypeScript, Go.

### E/P Separation Architecture (2026-04-01)
- Split each runtime into ai-lib-core (minimal execution) + ai-lib-contact (strategy/policy).
- Core retains: types, error, protocol, drivers, transport, pipeline, client, mcp, registry.
- Contact extracts: routing, cache, batch, plugins, interceptors, telemetry, guardrails.
- E↔P contract: `ExecutionResult<T>` with `ExecutionMetadata`.
- WASM enabler: core-only compiles to wasm32-wasip1.

### Four-Runtime Quality Gates (2026-03-31)
- Rust/Python/TS/Go each have CI gates for format, lint, typecheck, tests.

### Benchmarks, Multimodal, Generative Coverage, Spiderswitch, Release Trains
- See full log for Wave-1 through Wave-4 decisions (2026-03-07 to 2026-03-30).

→ **Extracted to**: [`architecture.md#principles`](./architecture.md#principles)

## Cross-Project Conventions

### Documentation Language (DOC-001)
- Code docs: English; Chinese summary line at each module header.
- Internal docs: Chinese by default.

### Message Roles (AI-Protocol v2)
- system, user, assistant, tool.

### Default Branch Naming (ARCH-004)
- Canonical default branch: `main`.

### Internal Work Doc Privacy (DOC-002)
- Internal work documents must remain private.

→ **Extracted to**: [`conventions.md`](./conventions.md)

## Workspace Requirement
- ai-lib-constitution and ai-lib-plans must be workspace roots.

## Repository Layout (Updated 2026-04-20)

| Repo | Purpose | Latest Version |
|------|---------|---------------|
| ai-protocol | Spec, schemas, provider manifests | v0.8.4 |
| ai-lib-rust | Rust runtime | v0.9.6 |
| ai-lib-python | Python runtime | v0.8.3 |
| ai-lib-ts | TypeScript runtime | v0.5.3 |
| ai-lib-go | Go runtime | v0.6.0 |
| ai-protocol-mock | Mock server | v0.1.11 |

→ **Extracted to**: [`conventions.md#repo-layout`](./conventions.md#repo-layout)

## CI Release Automation Status (2026-05-08)

| Runtime | Registry | Status |
|---------|----------|--------|
| ai-lib-go | GitHub Release | ✅ v0.6.0 |
| ai-lib-rust | crates.io + GitHub | ✅ v0.9.6 |
| ai-lib-ts | npmjs + GitHub | ✅ |
| ai-protocol | npmjs + GitHub | ✅ |
| ai-lib-python | PyPI + GitHub | ⏳ OIDC pending |

npm token: automation token (bypass_2fa=true, @ailib-official scope), stored as NPM_TOKEN.

→ **Extracted to**: [`infrastructure.md#ci-release`](./infrastructure.md#ci-release)

## WASM Hardening Tasks (2026-04-20)

- ailib-wasm-test: Browser WASM chat demo + Axum server proxy
- 两种 WASM 架构：wasm-browser (wasm-bindgen) + ai-lib-wasm (C ABI / wasi)
- 三项加固任务：WASM-001 (ABI), WASM-002 (Memory), WASM-003 (State Migration) — pending

## AI 聚合平台架构决策 (2026-04-19)

- ailib.info 留 Vercel (静态站); api.ailib.info 指向 VPS (跑 ai-lib-gateway)
- P 层闭源，E 层开源
- 3 个 Driver 覆盖几乎所有 provider: OpenAiDriver, AnthropicDriver, GeminiDriver

## 2026-04-30 — Eos 品牌决策

**三品牌体系**：Prism（棱镜）→ Eos（逸思）→ Vela（船帆）
**决策文件**：`active/projects/eos/brand-rationale.md`
- 放弃 AnyAI；Eos = 希腊黎明女神；中文「逸思」

→ **Extracted to**: [`architecture.md#eos`](./architecture.md#eos)

## 2026-05-09 — Eos 仓库归属决策

- Eos 作为商业产品，不公开源代码（hiddenpath/eos 私有）。
- ailib-wasm-test 承担开源验证+展示角色。
- 仓库归属：GitHub 私有 hiddenpath/eos + 内网 Git git-server.local。

## 2026-05-10 — prism-core 架构决策（从 eos-server 拆出）

- 拆分 eos-server → prism-core (A-band 开源) + eos-server (C-band 闭源)。
- prism-core 开源 (Apache-2.0)，含 proxy, key-pool, router, usage, admin logic, Anthropic adapter。
- crates.io 发布为 prism-core-routing v0.1.0。

→ **Extracted to**: [`architecture.md#prism-core`](./architecture.md#prism-core)

## 2026-05-15 — Eos 部署自动化

- 部署脚本：`tools/deploy_eos.sh`
- 目标：43.159.226.236，Caddy 反代

→ **Extracted to**: [`infrastructure.md#eos-deploy`](./infrastructure.md#eos-deploy)

## 2026-05-22 — 上下文容量与策略层运行时边界

- context_window + max_output 进协议；压缩策略不进协议。
- SKU 分界：Velaclaw 可用磁盘做 session 镜像；Eos WASM 经 IndexedDB/OPFS。

## 2026-05-24 — Eos 区域合规路由

- 方案 B：zh-cn 入口仅路由已备案模型，global 入口路由全球模型。
- 决策文件：`COMPLIANCE_REGIONAL_ROUTING.md`
- 配套任务：EOS-ARCH-R2~R5

## Eos 腾讯云香港服务器 — SSH 访问 (2026-05-27)

| 项目 | 值 |
|------|-----|
| IP | 43.159.226.236 |
| 域名 | eos.ailib.info |
| OS | Ubuntu 24.04.4 LTS |
| 用户名 | ubuntu |
| 密码 | eUMxUa-8.9wa3x2 |
| SSH | `ssh eos-hk`（key `~/.ssh/id_ed25519_eos_hk`） |
| 配置 | 2C / 3.6GB / 50GB |

部署架构：Caddy (:443/:80) → Eos (:3000) → xray (:10808 SOCKS) → AI API。
xray：63 节点（57 SS + 2 VLESS + 4 VMess），logrotate daily 7d。

→ **Extracted to**: [`infrastructure.md#eos-vps`](./infrastructure.md#eos-vps)

## 2026-05-27 — Eos 生产 go-live

- `https://eos.ailib.info` 已公网可访问
- hiddenpath/eos PR #2 merge `bbd4231`
- EOS-P0-001 完成，R7 关闭于 PR #3

## 2026-05-28 — Eos NVIDIA 默认模型策略

- HK VPS 上 GLM-5.1 stall；默认模型改为 llama-3.3-nemotron + llama-3.1-8b
- 公共 manifest 不得再有 `source: eos` 等 hiddenpath 引用

## 2026-06-04 — Prism Phase 1 计划对齐

- 任务增加 scope: library | product
- 调用链：gateway shell (Axum) → prism-core (libcurl) → Provider；不依赖 ai-lib-core
- prism-core = A-band；C-band = product shell + commercial policy
- 依赖链修正 + 新增 009~017
- Eos proxy 路径始终在 ai-lib 产品规划外

→ **Extracted to**: [`architecture.md#prism-phase1`](./architecture.md#prism-phase1)

## 2026-06-05 — 内网 Git 服务器 GOV-004 试运行

- 日常以 lan (git-server.local) 为主 remote
- eos 保留 origin 跑 GitHub Actions；合并后必须 git push lan main
- 仓库矩阵见 GOV-004

→ **Extracted to**: [`infrastructure.md#lan-git`](./infrastructure.md#lan-git)

## 2026-06-05 — GOV-005 LAN 基础设施规则

- git-server 为私有仓唯一真相源
- 轻量 CI → LAN；重型 (release/WASM/e2e) → GitHub Actions
- 设备：alex-S8, piubt (192.168.2.13), git-server (192.168.2.22)

→ **Extracted to**: [`infrastructure.md#lan-infra`](./infrastructure.md#lan-infra)

## 2026-06-09 — VelaClaw 策略层 / 执行层边界 (VL-ARCH-001)

- D1–D2：Rust-only；BYOK 直连 provider API
- D3–D4：prism-core 内嵌
- D6：ai-lib-gateway HTTP 服务外部 ToB 客户端
- D7：Python/TS 不在 VelaClaw 范围
- 废止 PR-P1-016 原 HTTP Gateway 主路径
- 任务链：VL-EVO-001→002→003→004 全部完成

→ **Extracted to**: [`architecture.md#velaclaw`](./architecture.md#velaclaw)

## 2026-06-11 — VelaClaw Rust crate 布局 (VL-RUST-001)

- lib.rs 维护模块树；main.rs 为 thin binary
- Binary-only：deploy, skillforge 在 main.rs
- 禁止 main.rs 与 lib.rs 重复声明模块

## 2026-06-15 — ai-protocol Manifest 权威性治理

- PR #8：清除 manifest 中 hiddenpath 引用
- ARCH-005 规则生效
- 合规测试：load-023 + MANIFEST_AUTHORITY.md

## 2026-06-17 — Manifest 分发韧性 (PT-077)

- 未知字段容忍 → Phase 1 立即做
- 四运行时 forward-compat 用例通过

## 2026-06-21 — Vela 长期架构愿景（意图声明）

- Phase 1: VelaClaw 产品 / Vela 积木 — 不动 task YAML
- Phase 2: VelaClaw → 参考实现 / Vela → 平台 — 等 Vela 有代码
- Phase 3: 正式平台化 — 等第三方采用
- Prism 是统一 API 后端 — Eos, Vela, VelaClaw, 第三方 agent 最终都走它

→ **Extracted to**: [`architecture.md#vela-vision`](./architecture.md#vela-vision)

## 2026-06-21 — `@ailib-official/prism-sdk` npm 首发

- 包：`@ailib-official/prism-sdk@0.1.0`（vela monorepo `packages/prism-sdk`）
- CI：`ailib-official/vela` workflow `publish-prism-sdk.yml`（tag `prism-sdk-v*` 或 workflow_dispatch）
- Secret：`NPM_TOKEN` 存于 GitHub `ailib-official/vela`（Automation、bypass 2FA、`@ailib-official` publish scope）；**不得**写入 plans/仓库
- 验收：`npm view @ailib-official/prism-sdk version` → `0.1.0`；CI run `27911434037` success
- 关联任务：PR-V1-001（npm 验收项完成；Web 手动 smoke 仍 pending）

→ **Extracted to**: [`conventions.md#npm-scope`](./conventions.md), [`infrastructure.md#npm-publish-prism-sdk`](./infrastructure.md)

## Infrastructure — LAN Git Server 运维记忆 (2026-06-08)

- 角色：私有仓库唯一真相源
- 一级备份：USB 硬盘 → /mnt/backup/gitmirror01
- 二级备份：piubt (192.168.2.13) → /gitmirror02
- 关键配置：/etc/fstab 持久化挂载 + /etc/hosts 解析
- 故障模式：每日 07:03 定时重启导致 fstab 缺失
- 免密配置：Ed25519 密钥对，lan-git/piubt 别名

→ **Extracted to**: [`infrastructure.md#lan-git-ops`](./infrastructure.md#lan-git-ops)
