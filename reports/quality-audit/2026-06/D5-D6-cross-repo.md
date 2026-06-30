# 质量审查报告 — 跨仓库（Dim 5-6）

<!-- AUDIT_META: dimension=D5-D6 repo=cross-repo auditor=cursor date=2026-06-30 task=PT-073g status=final -->

> **任务**: [PT-073g](../../active/projects/ai-protocol/tasks/PT-073g-cross-repo-quality-audit.yaml)
> **维度**: Dim 5（安全边界）+ Dim 6（文档与迁移对齐）
> **范围**: ai-protocol / ai-lib-rust / ai-lib-python / ai-lib-ts / ai-lib-go / velaclaw / ailib.info（**eos 私有仓本端 token 无访问权限，未覆盖**）
> **审查人**: cursor · **日期**: 2026-06-30
> **基线 commit**: 见 [PT-073g-SYNC_BASELINE.md](../../active/projects/ai-protocol/PT-073g-SYNC_BASELINE.md) §2（本端 HEAD 全部对齐）

---

## 1. 执行摘要

| 指标 | 值 |
|------|-----|
| 覆盖仓库 | 7 / 8（eos 无访问权限） |
| P0 发现 | 0 |
| P1 发现 | 2（QA-ts-008 mock 重定向；QA-python-008 内部信息入公共仓） |
| P2 发现 | 多（文档漂移，见下表） |
| 总体结论 | PASS_WITH_FIXES（+ eos 须由有权限节点补审） |

**一段话结论**：Dim 5 整体稳健——四运行时源码均无硬编码密钥、无 `verify=False`/`InsecureSkipVerify`，Python/TS 凭据可脱敏，ai-protocol manifest 全为官方域名（PT-053 hygiene 由 `gate-manifest-authority.js` 守护）。两处需修：TS 的 `MOCK_HTTP_URL` 在**所有环境**优先于 proxy/manifest 重定向全部流量（含 auth 头），可被用作重定向/外泄向量；Python 多份内部 report `.md` 把 `/home/alex/...` 路径与废弃 `hiddenpath` org 带进公共仓（无实活密钥）。Dim 6 普遍存在 CHANGELOG/README/版本漂移，单条非阻塞，但 1.0 发版前应统一收口。

---

## 2. 范围与方法

- **包含**: 各仓 `src/`/`pkg/`/manifests、`.github/workflows/`、README/CHANGELOG/pyproject/package.json/Cargo.toml、ailib.info 文档站
- **排除**: eos（无访问权限——见 §5 覆盖缺口）
- **方法**: 密钥正则扫描（排除 test/mock/示例）+ HTTP 客户端默认审查 + 文档↔实发物 diff

---

## 3. 发现项登记表（Dim 5 安全）

| ID | 严重度 | 状态 | 位置 | 问题 | 建议修复 |
|----|--------|------|------|------|----------|
| QA-ts-008 | P1 | open | `ai-lib-ts/src/transport/index.ts:142-145,135-154` | `MOCK_HTTP_URL` 在所有环境优先于 `proxyUrl`/manifest base_url，重定向全部传输（含 auth 头）；纯测试钩子无 test-mode 守卫 | 仅在显式测试标志（如 `AILIB_ALLOW_MOCK_URL` 或 `NODE_ENV==='test'`）下生效 |
| QA-ts-009 | P2 | open | `ai-lib-ts/src/transport/index.ts:34` | 发布源码内置默认内网 IP `http://192.168.2.13:4010` | 默认 `127.0.0.1:4010` 或要求 env、无内置默认 |
| QA-go-011 | P1 | open | `ai-lib-go/pkg/ailib/builder.go:11-71`；`README.md:62-66` | builder 无 `WithHTTPClient`/transport 选项，但 README 称可传 `http.Client` 配置 proxy/`AI_PROXY_URL` → 出口控制能力缺失 + 文档过度承诺 | 增 `WithHTTPClient`/transport 选项（和/或 `AI_PROXY_URL`），或修正 README |

**Dim 5 通过项（证据）**：

| 仓库 | 结论 | 证据 |
|------|------|------|
| ai-lib-rust | ✅ 无硬编码密钥 | `rg` core/contact 无密钥；无 `unsafe`（wasm FFI 除外） |
| ai-lib-python | ✅ 强 | 无密钥；`trust_env` opt-in（`http.py:43-45`，默认 `AI_HTTP_TRUST_ENV=0`）；`ResolvedCredential.__repr__` 脱敏（`auth.py:52-61`）；无 `verify=False` |
| ai-lib-ts | ✅（除上） | 无硬编码密钥；`LoggingInterceptor` 不记录头；凭据支持 REDACTED |
| ai-lib-go | ✅ | 无密钥；无 `InsecureSkipVerify`；默认 transport 走 `http.ProxyFromEnvironment` |
| ai-protocol | ✅ 强 | 全仓密钥扫描 0 命中；manifest base URL 全官方域；PT-053 公链 hygiene 由 `gate-manifest-authority.js` 强制（`validate.yml:47`）；凭据用例强制脱敏 |
| velaclaw | ✅ | 命中均为文档占位（`discord-bot-token`/`your-verify-token`）；具 `SECURITY.md`/`deny.toml`/`clippy.toml` |

---

## 4. 发现项登记表（Dim 6 文档/迁移）

| ID | 严重度 | 状态 | 位置 | 问题 | 建议修复 |
|----|--------|------|------|------|----------|
| QA-python-008 | P1 | open | `ai-lib-python/`：`PYPI_TOKEN_SEARCH_REPORT.md`、`PYPI_UPLOAD_STATUS.md`、`RELEASE_INSTRUCTIONS_V0.5.0.md`、`RELEASE_COMPLETE_REPORT.md`、`CODE_REVIEW_REPORT_V0.5.0.md`、`RELEASE_NOTES_V0.5.0.md`、`ROUTING_MANAGER_REFACTORING_ASSESSMENT.md` | 公共仓泄漏内部信息：`/home/alex/...` 路径、废弃 `hiddenpath` org、token/上传流程（**无实活密钥**），违反 DOC-002 | 移出公共仓（转私有笔记）；加 `.gitignore`；用户向文档链接改 `ailib-official` |
| QA-rust-006 | P2 | open | `ai-lib-rust/CHANGELOG.md:5,17,19,40` | 乱序+重复版本：顶部 `0.9.4(04-13)`，下方才是最新 `0.9.6`，又一个 `0.9.4(04-11)` | 重排使 0.9.6 居顶；合并/消歧两个 0.9.4 |
| QA-rust-007 | P2 | open | `ai-lib-rust/README.md:153,156,159,343` | 安装片段 pin `0.8.0`，实为 `0.9.6` | 升级 README 版本引用（建议单一真源） |
| QA-python-002 | P1 | open | `ai-lib-python/CHANGELOG.md:13` vs `pyproject.toml:38-64` | 文档化的 `[contact]` extra 未定义 → `pip install ai-lib-python[contact]` 失败 | 定义 `contact=[...]`（或移除引用）；按需纳入 `[full]` |
| QA-python-013 | P2 | open | `ai-lib-python/CHANGELOG.md:648-657` | footer link-ref/对比基止于 0.8.1，0.8.4/0.8.5 有段无链 | 补 `[0.8.5]/[0.8.4]` link-ref 并更新 Unreleased 比较基 |
| QA-ts-005 | P1 | open | `ai-lib-ts/package.json:3` vs `CHANGELOG.md:8,36` | `0.5.3` 在 CHANGELOG 无对应段（最新 0.5.1，余在 Unreleased），无 link-ref | 切 `## [0.5.3]` 段并加 link-ref |
| QA-ts-007 | P1 | open | `ai-lib-ts/README.md:66,393-418` | README 停留 V0.4.0，完全未述 `core`/`contact` 导入故事 | 更新版本/特性，加导入路径表 |
| QA-go-012 | P1 | open | `ai-lib-go/README.md:130` vs `pkg/ailib/errors.go:39-46` | README 称 E2002 retryable=Yes，代码 `IsRetryableCode` 返回 false | 与宪法对齐后修 README（或代码）并加 fixture |
| QA-go-013 | P2 | open | `ai-lib-go/README.md:170-178,115-117` | 包布局遗漏 `pkg/streaming`；"V0.5.0 includes…" 陈旧（实 v0.6.0） | 更新文档 |
| QA-protocol-007 | P1 | open | `ai-protocol/package.json:3` vs `CHANGELOG.md:5,34` | 版本 0.8.4 但 CHANGELOG 无 0.8.2/0.8.3/0.8.4 段（Unreleased→0.8.1） | 回填 changelog 或将 Unreleased 提为 0.8.4 |
| QA-protocol-008 | P1 | open | `ai-protocol/validate.js:344`；`validate.yml:44-47` | `examples/` 仅 `--examples` 时校验，CI 裸 `npm run validate` 不校验 → 坏示例（如 `function_calling.yaml` 顶层 `auth`）从不被 schema 检查 | CI 加 `validate:examples` 或修/删示例 |
| QA-protocol-011 | P2 | open | `ai-protocol/README.md:47,21-34` | README 称 "6 V2 provider"（实 12），schema 清单漏 6 个 | 更新计数与 schema 清单 |
| QA-protocol-012 | P2 | open | `ai-protocol/tests/compliance/README.md:43-82` | 文档化的多个 fixtures/cases 实不存在 | 据实际目录重生成 |
| QA-protocol-013 | P2 | open | `ai-protocol/PROVIDER_MANIFEST_AUDIT_REPORT.md:4-5`；`RELEASE_NOTES_*` | 陈旧审计（v0.4.0/31 provider）与发版说明滞后（≤v0.7.4） | 标注历史/补当前发版说明 |
| QA-velaclaw-001 | P2 | open | `velaclaw/CHANGELOG.md`（deps） | 可选依赖 `ai-lib-rust` 仍 0.9.4，实发 0.9.6 | 评估升级或文档化兼容窗口 |
| QA-ailibinfo-001 | P1 | open | `ailib.info/src/content/docs/*`（HEAD `ab86b8f`，版本矩阵末次同步 2026-05-07） | 文档站版本矩阵/安装命令较各运行时实发（rust 0.9.6、go 0.6.0、ts 0.5.3、py 0.8.5）可能滞后 | 1.0 sign-off 时同步版本矩阵并核安装命令可复现 |
| QA-memory-001 | P1 | open | `ai-lib-plans/memory/*`、`MEMORY.md` | 缺 v1.0 defer + PT-073g 引用的决策记录（准入条件之一） | sign-off 时写入 MEMORY 决策记录 |

---

## 5. 覆盖缺口（必须由有权限节点补审）

| 范围 | 缺口 | 影响维度 | 处置 |
|------|------|----------|------|
| **eos**（`hiddenpath/eos` 私有） | 本端 cloud token 无访问权限（clone 报 not found） | Dim 5（密钥/proxy/BIZ-004 区域路由/密文落盘）、Dim 6（README↔部署） | 由 LAN 内有权限节点按 `SYNC_BASELINE` `eos=1427438` 补 `D5-D6-eos.md`；作为 v1.0 准入未尽项跟踪 |

---

## 6. 证据附录

```bash
# 无硬编码密钥（rust/go/python/protocol）
rg -ni "(api[_-]?key|secret|token)\s*[:=]\s*[\"'][A-Za-z0-9_-]{20,}" \
   ai-lib-rust/crates ai-lib-go/pkg ai-lib-python/src ai-protocol/v2   # 0
# TS mock 重定向优先级
sed -n '135,154p' ai-lib-ts/src/transport/index.ts   # MOCK_HTTP_URL > proxyUrl > manifest
# Python trust_env opt-in
sed -n '43,45p' ai-lib-python/src/ai_lib_python/transport/http.py
```

## 7. 签核

| 角色 | 姓名 | 日期 | 结论 |
|------|------|------|------|
| 审查人 | cursor | 2026-06-30 | PASS_WITH_FIXES（+ eos 补审） |
| Maintainer | | | 待评审 |

## 变更记录
| 日期 | 变更 |
|------|------|
| 2026-06-30 | 初稿（eos 因权限未覆盖） |
