# VL-RUST-001 — VelaClaw Rust Crate 布局：Thin Binary（禁止双模块树）

> **状态**：已采纳（2026-06-11）  
> **动因**：PR #58 CI 排障时发现 `main.rs` 与 `lib.rs` 各维护一套 `mod` 树，导致 `execution` 等 lib 新模块在 binary 侧 `E0433`。  
> **适用范围**：`ailib-official/velaclaw` 及所有同时定义 `[lib]` + `[[bin]]` 的 Rust 仓。

---

## 问题：什么是「双模块树」

`Cargo.toml` 同时存在：

- `src/lib.rs` → **library crate**（crate 名 `velaclaw`）
- `src/main.rs` → **binary crate**（可执行文件 `velaclaw`）

在 Rust 中，这是 **两个独立的 crate root**，各自拥有自己的模块树。

**错误模式（历史债务）**：在 `main.rs` 里重复声明 `mod agent;`、`mod gateway;` …（与 `lib.rs` 镜像），导致：

1. **同一批 `.rs` 文件被编译两次**（lib 一份、bin 一份）——编译慢、符号重复。
2. **模块树必须人工同步**：在 `lib.rs` 新增 `mod execution;` 后，若 `main.rs` 未同步，**仅 binary 编译失败**（典型：`E0433: failed to resolve: use of unresolved module`），而 lib 测试可能仍通过。
3. **类型不互通**：bin 内 `crate::agent::Foo` 与 lib 内 `velaclaw::agent::Foo` 在类型系统上是不同 crate 的类型（即使源文件相同）。
4. **CLI 枚举重复**：`ServiceCommands` 等在 main 与 lib 各定义一份，改一处漏一处。

PR #58 的临时创可贴是在 `main.rs` 补 `mod execution;`——**禁止**再采用此模式。

---

## 决策：Thin Binary

| 层级 | 职责 |
|------|------|
| **`src/lib.rs`** | **唯一**共享模块树；业务逻辑、gateway、agent、tests 的 `velaclaw` 依赖均在此。 |
| **`src/main.rs`** | 仅 CLI：`clap` 解析、`main()`、子命令分发；通过 `use velaclaw::{ ... }` 调用库。 |
| **Binary-only 模块** | 仅保留确实不应进 lib 的模块，例如 `deploy`、`skillforge`（`mod deploy;` / `mod skillforge;` 只在 `main.rs`）。 |
| **Binary-only 子模块引用 lib** | 如 `deploy/cli.rs` 使用 `velaclaw::config::`，**不得** `crate::config::`（bin 侧无此模块）。 |

`main.rs` 头部应保留说明注释，防止后人恢复双树：

```rust
// Binary-only modules (not part of the `velaclaw` library crate).
mod deploy;
mod skillforge;

// Thin binary: shared implementation lives in the library crate (`src/lib.rs`).
// Do not re-declare `mod agent;` etc. here.
use velaclaw::{ agent, gateway, config, ... };
```

---

## CLI 与子命令枚举

- 在 **`lib.rs`** 定义并 **`pub`** 导出 CLI 需要的子命令枚举（如 `ServiceCommands`、`CronCommands`、`HardwareCommands` 等）。
- **`main.rs`** 只保留 **纯 binary 专用** 的顶层 `Commands` / `Cli` 及与 clap 绑定的 wrapper。
- **禁止**在 main 与 lib 各复制一份相同 enum。

---

## 新增模块检查清单（每次改 `lib.rs`）

- [ ] 只在 `lib.rs` 增加 `pub mod new_thing;`（或 `mod` + `pub use`）
- [ ] **不要**在 `main.rs` 增加 `mod new_thing;`
- [ ] 若 binary 需要调用，在 `main.rs` 的 `use velaclaw::{ ..., new_thing }` 中导入
- [ ] 若新代码在 `deploy/` / `skillforge/` 下，通过 `velaclaw::` 访问共享类型
- [ ] CI：`cargo build` + `cargo test` 覆盖 **lib + bin**（默认即两者）

---

## 未来可选演进（非阻塞）

- 将 `deploy` / `skillforge` 移入 lib，用 **Cargo feature**（如 `deploy-cli`）控制是否链接，进一步统一测试面。
- 提取 `crates/velaclaw-gateway` 时，gateway 仍从 lib 导出或独立 crate，**bin 仍保持 thin**。

---

## 关联

- **修复 PR 上下文**：VL-UI-004 分支含 thin-binary 重构 + Web Chat Phase 3 ops API。
- **架构边界**：VL-ARCH-001（执行模型）— 本决策仅涉及 **crate 布局**，不改变 BYOK / prism 内嵌等产品边界。

---

## 参考真源（代码）

- `velaclaw/src/main.rs` — thin binary 入口
- `velaclaw/src/lib.rs` — 模块树与 `pub` CLI 枚举
- `velaclaw/src/deploy/cli.rs` — `velaclaw::config::` 用法示例
