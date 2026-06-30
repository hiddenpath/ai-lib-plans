# PT-073g 跨仓库质量审查 — 汇总与 v1.0.0 准入建议

<!-- AUDIT_META: dimension=SUMMARY repo=cross-repo auditor=cursor date=2026-06-30 task=PT-073g status=final -->

> **任务**: [PT-073g](../../active/projects/ai-protocol/tasks/PT-073g-cross-repo-quality-audit.yaml)
> **审查人**: cursor（cloud agent）· **日期**: 2026-06-30
> **基线**: [PT-073g-SYNC_BASELINE.md](../../active/projects/ai-protocol/PT-073g-SYNC_BASELINE.md) §2（本端 7 仓 HEAD 全部对齐）
> **维度报告**: [D1-D2-*](.) · [D3-D4-*](.) · [D5-D6-cross-repo.md](./D5-D6-cross-repo.md)

---

## 1. 总裁定

> **建议：HOLD —— 暂不打 v1.0.0 tag。** 需先关闭下列 **P0**，并就 3 项 **P0 候选** 取得 maintainer 裁定；其余 P1 须修复或书面 defer（含截止条件）。
>
> 工程合规矩阵（PT-073 §1–§5）确为真实基线，**E/P 架构边界在 Rust/Python/Go 三运行时是真正干净的**，安全姿态整体稳健（四运行时源码零硬编码密钥、无 TLS 关闭、凭据可脱敏、manifest 全官方域）。但本审查发现两类结构性风险，使"1.0 = 对外稳定 + 可维护 + 可安全部署"的语义尚未达成：①TS 已发布的 E/P 子路径**不可用**；②"跨运行时合规已证明"这一 PT-073 核心论断，被**合规用例在测试内自我实现 + CI 浮动 ref + 死门控**显著削弱。

---

## 2. 发现计分卡

### 2.1 按维度（仓库 × 维度，🔴=有P0 / ⚠️=有P1 / ✅=仅P2或通过 / ➖=不适用 / ❔=未覆盖）

| 仓库 | D1 API | D2 E/P | D3 代码 | D4 测试 | D5 安全 | D6 文档 |
|------|----|----|----|----|----|----|
| ai-protocol | ✅ | ✅ | ⚠️ | ⚠️(P0候选) | ✅ | ⚠️ |
| ai-lib-rust | ⚠️ | ✅ | ⚠️ | ⚠️ | ✅ | ✅ |
| ai-lib-python | ⚠️ | ✅ | ⚠️ | ⚠️ | ✅ | ⚠️ |
| ai-lib-ts | 🔴 | 🔴 | ✅ | ⚠️ | ⚠️ | ⚠️ |
| ai-lib-go | ✅ | ⚠️ | ⚠️(P0候选) | ⚠️ | ⚠️ | ⚠️ |
| velaclaw | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| ailib.info | ➖ | ➖ | ➖ | ➖ | ✅ | ⚠️ |
| **eos** | ❔ | ❔ | ❔ | ❔ | **❔** | **❔** |

### 2.2 按严重度

| 级别 | 数量 | 分布 |
|------|------|------|
| **P0（确认）** | **3** | 全部 ai-lib-ts（QA-ts-001/002/003） |
| **P0 候选（待裁定）** | **3** | QA-protocol-006、QA-protocol-005、QA-go-006 |
| P1 | 20 | 见 §4 |
| P2 | 16 | 记入 backlog（见各维度报告） |
| 覆盖缺口 | 1 | eos 未审（无访问权限） |

---

## 3. P0 — 发布阻断（必须修复后复审）

| ID | 仓库 | 问题 | 一句话影响 |
|----|------|------|-----------|
| QA-ts-001 | ai-lib-ts | `package.json` 宣告 `./core`/`./contact`，但 tsup 仅构建 `index`，`dist/core.*`/`dist/contact.*` 从不产出 | 子路径 import 运行时 `ERR_MODULE_NOT_FOUND`——已发布的公共 API 直接报错 |
| QA-ts-002 | ai-lib-ts | `src/contact.ts` 源文件不存在 | 宣告的 P 层公共面**根本未定义** |
| QA-ts-003 | ai-lib-ts | E-only `core` 经 `transport` 传递性 import P 层 `resilience` | 已发布的 E/P 边界与架构承诺不符（与其自身注释矛盾） |

> 三者为一组连贯修复：tsup 多入口 + 新增 `src/contact.ts` + 拆分 transport（纯 E HTTP/SSE + P 层 resilience 装饰器）。

---

## 4. P0 候选与 P1 清单

### 4.1 P0 候选（建议 maintainer 评审升级）

| ID | 仓库 | 为何可能是 P0 | 处置 |
|----|------|---------------|------|
| QA-protocol-006 | ai-protocol | 跨运行时合规门指向 CI 不存在的兄弟仓 → 本仓 CI **从不执行合规用例**（死门/假绿），直接动摇"合规真源"保证 | 要么 required 模式硬失败，要么明确"强制在运行时仓"并加本仓用例 linter |
| QA-protocol-005 | ai-protocol | mock fixture 与依赖它的 P0 用例（gen-001/003/007）矛盾 → 用例空洞或失败 | 对齐 mock 或改用真实 manifest |
| QA-go-006 | ai-lib-go | 重试复用已消费 request，重试 POST 发空 body（数据正确性，需 runtime 复验） | runtime 确认；每次重建 request 或用 `GetBody` |

### 4.2 跨切面 P1（最重要——影响 PT-073 §1 论断可信度）

| 主题 | 涉及 | 说明 |
|------|------|------|
| **合规用例在测试内自我实现** | rust(QA-rust-003)、python(QA-python-004)、go(QA-go-008) | 多数 `run_*` 重实现 retry/fallback/message/stream/event/tool 逻辑而非调用生产代码 → "绿"不证明运行时合规 |
| **CI 浮动 ref** | rust(005)、python(007)、ts(006)、go(009) | 四运行时 checkout `ailib-official/ai-protocol` 均无 `ref:` → 不可复现、上游变更红/绿静默翻转 |
| **fixture 缺失静默通过** | rust(004)、python(005/006) | 目录缺失早退 + 断言 `failed==0`（0 例也算过）→ 假绿 |

### 4.3 单仓 P1

| ID | 仓库 | 摘要 |
|----|------|------|
| QA-rust-001 | rust | 多路由末位返回可重试状态时传输层 `expect` panic（远端可触发） |
| QA-rust-002 | rust | README 宣传已移除的 `circuit_breaker_default()` 等 API（示例不编译） |
| QA-python-010 | python | fallback 改写共享 `self._model_id/_manifest`，并发 `chat()` 竞争 |
| QA-python-002 | python | 文档化 `[contact]` extra 未定义，`pip install ...[contact]` 失败 |
| QA-python-001 | python | `__version__`(0.7.5) ≠ dist(0.8.5) |
| QA-python-003 | python | README 调用不存在的 `client.report_feedback(...)` |
| QA-python-008 | python | 内部 report 文件泄漏 `/home/alex` 路径与废弃 `hiddenpath` org（DOC-002，无实活密钥） |
| QA-go-004 | go | 流式 `ExecutionMetadata.Usage` 始终空，测试不断言（假绿） |
| QA-go-011 | go | builder 无 `WithHTTPClient`/proxy 选项，README 过度承诺（出口控制缺失） |
| QA-go-012 | go | README E2002 retryable 与代码不符 |
| QA-ts-008 | ts | `MOCK_HTTP_URL` 在所有环境优先重定向全部流量（含 auth 头） |
| QA-ts-005/007 | ts | 0.5.3 无 CHANGELOG 段；README 停留 V0.4.0 |
| QA-protocol-001/002 | protocol | P0 用例 gen-005 描述↔断言矛盾；能力守卫错用 E1005 |
| QA-protocol-003/004 | protocol | 用例 schema 陈旧且不强制；e_only 漏分类目录 10/11 |
| QA-protocol-007/008 | protocol | CHANGELOG 缺 0.8.2-0.8.4；examples 不在 CI 校验 |
| QA-ailibinfo-001 | ailib.info | 版本矩阵/安装命令可能滞后于实发 |
| QA-memory-001 | plans | 缺 v1.0 defer + PT-073g 的 MEMORY 决策记录 |

---

## 5. 优势（已验证，避免重复劳动）

- **E/P 架构边界真实可靠**：Rust core 零依赖 contact、wasm 仅依赖 core、contact 无 driver 逻辑；Python E→P 仅经 `importlib` 动态 opt-in；Go 依赖方向 E←P 正确。
- **安全姿态稳健**：四运行时源码零硬编码密钥、无 `verify=False`/`InsecureSkipVerify`；Python `trust_env` opt-in + 凭据脱敏；ai-protocol manifest 全官方域 + PT-053 hygiene 门控。
- **代码卫生**：四运行时 driver 均按 manifest/style 分派而非硬编码 slug（ARCH-001 基本达标，少量 fallback 例外已记 P2）；TS strict 全开、零 `@ts-ignore`；Rust core 无 `unsafe`、TODO/FIXME≈0。
- **velaclaw** 下游迁移健康（protocol-first 默认、CHANGELOG breaking 记录完整、具 deny.toml/SECURITY.md）。

---

## 6. v1.0.0 准入清单（映射 PT-073 §6 release train）

| 准入条件 | 当前 | 阻塞项 |
|----------|------|--------|
| P0 = 0 open | ❌ | QA-ts-001/002/003 |
| P0 候选已裁定 | ❌ | QA-protocol-006/005、QA-go-006 |
| 合规可信度收口（§4.2 三主题） | ❌ | 至少：CI pin ref + fixture fail-closed；合规自实现转调用生产代码（可分批，但 1.0 前须有计划+ owner） |
| eos 覆盖缺口关闭 | ❌ | 由有权限节点补 `D5-D6-eos.md` |
| MEMORY 决策记录 | ❌ | QA-memory-001 |
| P1 全部修复或书面 defer | ❌ | §4 共 20 项 |

**结论**：§6 release train（tag ai-protocol→core→contact→各运行时→wasm→mock）**继续阻塞于 PT-073g-R6 sign-off**。

---

## 7. 建议修复顺序（供 owner 分派）

```text
批次 1（解锁 1.0 复审，P0）
  ai-lib-ts: tsup 多入口 + 新增 src/contact.ts + 拆分 transport（QA-ts-001/002/003）
  maintainer 裁定 QA-protocol-006/005、QA-go-006 级别

批次 2（合规可信度，跨切面 P1）
  四运行时 CI: pin ai-protocol checkout ref（rust/python/ts/go）
  合规 fixture fail-closed（断言最小用例数；缺目录硬失败）
  合规自实现 → 调用生产代码（rust/python/go，可按用例族分批）
  ai-protocol: 用例 schema 强制 + e_only 分类 10/11 + 修 gen-005/能力守卫码

批次 3（正确性与安全 P1）
  rust 传输 panic；python fallback 竞争；go 重试体/流式 usage；ts MOCK_HTTP_URL 守卫

批次 4（文档/版本/卫生 P1+P2）
  各仓 CHANGELOG/README/版本统一；python 内部 report 清理（DOC-002）；
  ailib.info 版本矩阵；MEMORY v1.0 决策记录

批次 5（覆盖缺口）
  eos D5-D6 补审（有权限节点）

批次 6（maintainer sign-off → PT-073 §6 release train）
```

---

## 8. 后续动作

1. 本审查报告随分支 PR 提交 `ai-lib-plans`，并按 GOV-004 双推 `lan`+`origin`。
2. 建议据 §7 批次在各 **运行时仓** 开修复 PR；P0 修复合并后回到 PT-073g-R6 复审。
3. eos 补审为显式未尽项，纳入准入清单跟踪。
4. maintainer 就 §4.1 三项 P0 候选给出裁定，写入本文件 §1 与 MEMORY。

---

## 9. 签核

| 角色 | 姓名 | 日期 | 结论 |
|------|------|------|------|
| 审查人 | cursor | 2026-06-30 | **HOLD** — 3 P0 + 3 P0候选 + 20 P1 待处置，eos 待补审 |
| Maintainer | | | 待裁定（P0 候选定级 / defer 批准 / sign-off） |

## 变更记录
| 日期 | 变更 |
|------|------|
| 2026-06-30 | 初稿（cloud agent 一次性跨 7 仓审查；eos 因权限未覆盖） |
