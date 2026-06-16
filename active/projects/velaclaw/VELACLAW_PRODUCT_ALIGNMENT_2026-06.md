# VelaClaw × 总体产品规划对照（2026-06-09）

> **目的**：将 VL-ARCH-001 / Phase EVO 与三品牌矩阵、Prism/Vela/Eos 规划对照，标注一致、需澄清、已废止项。  
> **真源**：本文件 + `VL-ARCH-001-execution-strategy-boundary.md`

---

## 1. 产品矩阵中的位置

### 1.1 三品牌 + 矩阵（BIZ-001 / brand-rationale）

| 产品 | 层 | To B / To C | 执行面 | 与 VL-ARCH-001 |
|------|-----|-------------|--------|----------------|
| **Prism** | P | ToB Enterprise / ToB API | `ai-lib-gateway` HTTP + prism-core | 陌生 provider **路由策略**来源；BYOK **不托管** VelaClaw 密钥 |
| **Vela** | A | Vela Pro / Vela | **Prism SDK → HTTP** `api.prism.ailib.info` | **不同 SKU**；Web 导航客户端，非 VelaClaw |
| **Eos** | To C 网站 | 逸思 | 浏览器 WASM + 宿主 | 桌面 session 策略不同；见 CONTEXT_STRATEGY_BOUNDARY |
| **VelaClaw** | A（Claw 生态） | 开源桌面/CLI agent | **进程内** AiClient + 内嵌 prism-core | **VL-ARCH-001 适用对象** |

**结论**：VelaClaw **不是** Vela 品牌本体（`PR-V1-*` Web 客户端）。二者并行：

- **Vela** = 轻量 Web UI + Prism HTTP API（Phase 1 demo）
- **VelaClaw** = Rust agent 产品（BYOK 直连 + 内嵌 prism-core）

**待办（治理）**：VelaClaw 未写入 BIZ-001 原始 2×2 矩阵；建议在 `MEMORY.md` 记为 **「Claw 生态开源 agent SKU」**，与 Vela/Eos 并列说明，避免与「Vela 客户端核心」混称。BIZ-002 中「Vela client core」指 **Vela 仓库**（`ailib-official/vela`），**不包含** VelaClaw 代码库。

### 1.2 MEMORY「成熟度验证」表述

| 旧表述 | 修订理解 |
|--------|----------|
| 「VelaClaw 迁移 = 成熟度验证，不是替代主线」 | 指 **ai-lib-rust 消费者集成验证**（ZS-ML），不是指 VelaClaw 为临时仓库 |
| VL-ARCH-001 后 | VelaClaw 是 **长期 Rust-only 产品 SKU**；验证完成后仍持续演进（Phase EVO） |

**无矛盾**：验证对象是 **ai-lib 集成模式**，不是产品寿命。

---

## 2. Prism 规划对照

### 2.1 Phase 1 / Gateway HTTP（Prism P1）

| 规划项 | 内容 | 与 VelaClaw |
|--------|------|-------------|
| PR-P1-002 | Gateway OpenAI `/v1/*` | ✅ **外部客户端**（Vela SDK、curl、ToB）；VelaClaw **不依赖** |
| PR-P1-016（修订后） | VelaClaw **内嵌** prism-core | ✅ 与废止的「Vela HTTP → Gateway」主路径一致 |
| NEAR_TERM P1-D | PR-V1 依赖 P1-B `/v1` API | ✅ 仅 **Vela Web**；与 VelaClaw EVO 并行 |

### 2.2 Phase 2「BYOK mode」（Prism 营销）

存在 **两种 BYOK**，需并存、不混用术语：

| 模式 | 谁 | 密钥在哪 | 执行 |
|------|-----|----------|------|
| **Client-local BYOK** | VelaClaw | 本机 env/keyring | AiClient **直连** provider |
| **Gateway-hosted BYOK** | Vela / 外部 HTTP 客户端 | Gateway 配置/TOML（Phase 2） | HTTP → Gateway → provider |

VL-ARCH-001 D2/D5 仅规范 **Client-local BYOK**。Prism Phase 2 BYOK **不推翻** VL-ARCH-001，而是服务 **HTTP 产品面**。

### 2.3 Phase 2 Smart routing / PT-073

| 项 | 关系 |
|----|------|
| PT-073 | Gate **Prism Phase 2 智能路由**（Contact 等） |
| VL-EVO-002 | 内嵌 prism-core **P1 router/fallback**（A-band，已完成库） |
| 边界 | VelaClaw EVO-2 用 **A-band 基础路由**；Phase 2「auto 智能路由」= C-band/Prism 产品策略，**不**在 EVO-2 默认 scope |

---

## 3. 技术栈对照

### 3.1 双执行栈（已知张力，非逻辑矛盾）

| 路径 | 栈 | 规划依据 |
|------|-----|----------|
| BYOK 直连 | ai-lib-rust（ARCH-001/002 pipeline） | ZS-ML 迁移主线 |
| 陌生 provider | prism-core（libcurl proxy/router） | P1 prism-core A-band；2026-06-04 决策 |

**说明**：Prism P1 刻意 **不** 依赖 ai-lib-core（D6 2026-06-04）。VelaClaw 因此短期存在 **AiClient + prism-core** 双栈；Phase 2+ PT-073 可能收敛，EVO 计划需在 VL-EVO-002 注明「不阻塞 PT-073」。

### 3.2 凭证链（PT-074）

| PT-074 合同 | VL-ARCH-001 |
|-------------|-------------|
| manifest env → conventional env → keyring | ✅ D2 BYOK 应 **消费** CredentialResolver，不在 VelaClaw 重复造表 |
| VelaClaw downstream smoke | ✅ VL-TRIAL-001 已验证 |

**建议**：VL-EVO-001 验收增加「credential 走 ai-lib 链，无平行 credential 表」。

---

## 4. HTTP 使用的精确边界

VL-ARCH-001「非默认 HTTP Gateway 客户端」指 **chat/completions 执行**，以下 **允许** HTTP：

| 用途 | HTTP 目标 | 任务 |
|------|-----------|------|
| BYOK 直连 chat | ❌ 不经 Gateway | EVO-0/1 |
| 陌生 provider chat | ❌ 内嵌 prism-core | EVO-2 |
| **Usage 遥测** | ✅ `api.prism.ailib.info` 或配置 endpoint | EVO-3 |
| 可选 Prism 账户/配额查询 | ✅ 未来 C-band API | 未立项 |

---

## 5. 陌生 provider「走 Prism」的语义

| 误解 | 正解（VL-ARCH-001 + 用户决策） |
|------|-------------------------------|
| VelaClaw 把 chat HTTP 发到 Gateway | ❌ 废止 |
| 内嵌 prism-core router 在进程内选 provider/key | ✅ EVO-2 |
| Prism **云端**代管用户 BYOK key | ❌ BYOK key 仍本机；云端仅 **路由策略 + 计量** |
| 完全离线、无 Prism 账户也可 BYOK 直连 | ✅ 默认路径 |

---

## 6. 已发现并需修正的文档笔误

| 位置 | 问题 | 修正 |
|------|------|------|
| MEMORY §2026-05-10 接入路径末句 | 「不再以 HTTP Gateway 为 **Vela** 主路径」 | 应为 **VelaClaw** |
| VL-ARCH-001 D6 | 「非 Vela 主路径」易与 Vela 品牌混淆 | 改为「非 Vela **Claw** / 非 Gateway HTTP 客户端主路径」 |

---

## 7. 一致项清单（无矛盾）

- ✅ BIZ-002：prism-core A-band 可嵌入 VelaClaw；Gateway shell C-band 独立
- ✅ GOV-001 / api.ailib.info：Gateway 部署与 VelaClaw 内嵌执行正交
- ✅ Eos `/api/proxy` 不在 ai-lib 产品 scope（NEAR_TERM_EXECUTION）
- ✅ DOC-002：冒烟在 plans，公开仓仅 BYOK 用户文档
- ✅ CONTEXT_STRATEGY_BOUNDARY：上下文策略在策略层，与 VL-ARCH 执行层正交
- ✅ Python/TS：各 runtime SDK 自建 agent；VelaClaw 不覆盖（D7）
- ✅ PR-V1-* 与 VL-EVO-* 依赖不同、可并行

---

## 8. 建议的下一步规划动作

1. **MEMORY**：补 VelaClaw SKU 矩阵定位一句；修正 Vela/VelaClaw 笔误  
2. **VL-ARCH-001**：增 §「产品矩阵与双 BYOK」；明确 telemetry HTTP 例外  
3. **VL-EVO-001**：acceptance 引用 PT-074 credential chain  
4. **VL-EVO-002**：scope 限定 A-band P1 router；Phase 2 auto 路由单独立项  
5. **BIZ-001 跟进**（可选）：owner 确认是否将 VelaClaw 写入 PRODUCT_PLAN 附录  

---

## 9. 对照总表

| 维度 | 总体产品规划 | VL-ARCH-001 / EVO | 判定 |
|------|--------------|-------------------|------|
| VelaClaw 主执行 | （原 PR-P1-016 HTTP）→ **已修订** | 进程内 AiClient + prism-core | ✅ 已对齐 |
| Vela Web 主执行 | Prism SDK HTTP | 不涉及 VelaClaw | ✅ 并行 |
| Prism Gateway | ToB/外部 `/v1` | VelaClaw 不依赖 | ✅ |
| BYOK 密钥 | Phase2 Gateway BYOK **另轨** | 本机 only | ✅ 双轨并存 |
| 三品牌 | Prism/Eos/Vela | VelaClaw = Claw SKU | ⚠️ 需矩阵补录 |
| ai-lib 主线 | E-layer 开源 | VelaClaw 消费 ai-lib-rust | ✅ |
| 成熟度验证 | 消费者集成验证 | 产品长期演进 | ✅ 语义澄清 |

**verdict**：VL-ARCH-001 与总体产品规划 **无硬冲突**；主要风险是 **品牌命名（Vela vs VelaClaw）**、**双 BYOK 术语**、**BIZ-001 矩阵未收录 VelaClaw**。上述待办写入后即可进入 EVO-1 实现。
