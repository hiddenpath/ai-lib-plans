# 工程规则：仓库内嵌构建工具二进制（Vendored build tool binaries）

> **适用范围**：任何在 Git 中提交 **预编译可执行文件**（含 `wasm-pack`、`wasm-bindgen`、单次下载的 CLI 等），用于规避 CI / Docker 内网络受限或 TLS 问题时。
>
> **不替代**：正常情况仍应 **`cargo install` / 发行版 tarball + checksum** / 镜像内官方渠道安装；内嵌二进制是 **例外路径**。

## PL-ENGINE-019 — 必须具备的元数据

1. **声明用途**：文档或 Dockerfile 注释中说明 **为何不能**仅用官方下载（典型：GitHub 访问失败、企业代理）。
2. **平台与架构**：明确目标 **OS / CPU**（示例：Linux glibc x86_64）；禁止把未标注平台的二进制说成「通用」。
3. **可追溯版本**：至少在文档中记载 **上游版本号或 Release tag**，以及替换日期。
4. **完整性校验**：在仓库旁的 `docs/`（或等价位置）给出 **SHA-256**（或 SHA-512）；替换二进制后必须 **更新哈希**。
5. **更新流程**：写明「如何升级到下一版」（下载源、校验、谁更新 PR）。
6. **Prism / 网关类 crate**：若以同样方式 vendoring 工具链，沿用本条；运行时库本身仍须遵守 **unsafe / panic** 等与产品相关的 RUST-* 规则。

## 参考落地

- Eos：`hiddenpath/eos` 根目录 `wasm-pack-bin`、`wasm-bindgen-bin`（`main@299575a`）；SHA-256 / 版本记录应在本文件或 Dockerfile 注释中维护（eos 仓暂无独立 `docs/` 说明文件）。

## 与其它治理关系

- 若仓库 **对外公开**，需注意二进制体积与许可证（上游通常为 Apache-2.0 / MIT，以各 release 为准）；内部私有仓亦建议保留校验与版本记录。
