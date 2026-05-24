# Eos 区域合规路由策略

**日期**：2026-05-24  
**状态**：架构决策记录  
**关联讨论**：Eos 产品架构规划（prism-core / Eos 双入口路由合规性）
**上游**：`active/projects/eos/brand-rationale.md`、`MEMORY.md`（2026-05-10 Eos 仓库归属、2026-05-22 context capacity）

---

## 1. 背景与问题

Eos（逸思）作为 ai-lib 生态的 To C 消费者平台，未来需要分发和路由多模型能力。这带来一个核心合规问题：

> **Eos 能否让中国用户调用未经中国监管备案的海外模型（如 Gemini、GPT-5.5、Claude）？**

此前分析（2026-05-24 讨论）从三个层面逐级深入：

1. **基础设施层**（prism-core 开源 crate）：作为通用 AI 网关/反向代理，技术中立，不负部署者行为之责 —— 合规 ✅
2. **聚合平台层**（OpenRouter 模式）：以官方 API 客户身份调用模型厂商已公开的国际 endpoint，不属"穿透封锁" —— 合规 ✅
3. **服务平台层**（Eos 作为运营方）：直接向中国境内公众提供未经备案的模型能力 —— **不合规 ❌**

### 1.1 法律框架概要

| 法规 | 核心要求 | 对 Eos 的影响 |
|------|---------|-------------|
| 《生成式人工智能服务管理暂行办法》（2023.8） | 向境内公众提供生成式 AI 服务须**模型备案** | 未备案模型不得路由给中国用户 |
| 《数据出境安全评估办法》 | 重要数据/个人信息出境须安全评估 | 中国用户数据发往境外模型触发评估义务 |
| 《网络安全法》《数据安全法》《个人信息保护法》 | 网络运营者义务、数据安全保护 | 作为服务提供者须建立合规框架 |

截至 2026 年 2 月，全国累计 796 款模型完成备案。Gemini、GPT-5.5、Claude 4.6 等均不在其中。

---

## 2. 架构决策：区域隔离双栈（方案 B）

在三层可选路径中，选择**方案 B — 双入口区域隔离**：

| 路径 | 描述 | 合规性 | 选择 |
|------|------|--------|:----:|
| **A — 纯国内合规** | 只分发已备案模型（DeepSeek/Qwen/GLM/MiniMax） | ✅ 完全合规 | — |
| **B — 区域隔离双栈** | zh-cn 入口 → 仅已备案模型；global 入口 → 全球模型 | ✅ 各自合规 | **✅ 选定** |
| **C — 开发者工具声明** | BYOK + 平台声明不担责 | ⚠️ 灰色地带 | — |

### 2.1 决策理由

- **法理清晰**：两个入口分别面向不同法域的用户群体，各自遵守所在地法律
- **零灰色地带**：不依赖"执法容忍度"，降低长期经营风险
- **代码复用率 95%**：两入口共享同一代码库和 manifest，差异仅在 P 层的区域滤镜规则
- **与 E/P 分离架构一致**：合规策略闭源在 P 层（Contact），E 层（prism-core）开源不受影响
- **与已备案模型增长兼容**：未来更多模型完成备案后，仅需更新 manifest 的 region 字段，无需改代码

### 2.2 不选择其他路径的理由

**方案 A** 会完全放弃海外用户市场和全球模型能力，不符合 Eos 作为"入口曙光"的品牌定位。
**方案 C** 将合规风险转嫁给用户但平台仍可能被追责，且规模增长后执法关注度必然上升，不可持续。

---

## 3. 数据模型设计

### 3.1 Manifest Region 字段

基于 ai-protocol v2-alpha manifest 结构扩展：

```yaml
# provider 级区域声明
provider:
  id: qwen
  region:
    cn:
      available: true
     备案编号: "BL-xxxxx"       # 已备案模型必填
      endpoint: https://dashscope.aliyuncs.com
      data_residency: cn-beijing
    global:
      available: true
      endpoint: https://dashscope-intl.aliyuncs.com
      data_residency: sg

# model 级覆盖（更细粒度，处理混部场景）
models:
  - id: qwen3.7-max
    region:
      cn:
        endpoint: https://dashscope.aliyuncs.com/compatible-mode/v1
       备案编号: "BL-xxxxx"
      global:
        endpoint: https://dashscope-intl.aliyuncs.com/compatible-mode/v1
```

关键设计原则：
- `region` 是**声明式**的，E 层的 router 不做策略判断，只按标签过滤
- 备案编号字段为合规审计提供溯源能力
- 同一模型在不同 region 可有不同 endpoint、定价、能力集

### 3.2 动态模型清单

备案信息动态变化（每季度更新），manifest 不可硬编码：

```
Eos 启动 → 拉取模型清单 → 定时刷新 ← webhook 通知更新
               │
               ▼
        内存中合并 manifest + 备案清单
               │
               ▼
        按 region 标签构建可用模型索引
```

利用 prism-core 已有的 `ConfigProvider trait` 模式注入动态配置源。

---

## 4. 请求生命周期

```
                    ┌──────────────┐
                    │    用户       │
                    │  (浏览器)     │
                    └──────┬───────┘
                           │
              DNS 分流（按域名）
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
        eos.cn       eos.io       api.eos.io
     (中国大陆)      (海外)      (开发者 API)
              │            │            │
              ▼            ▼            ▼
         ┌──────────────────────────────────┐
         │    入口层（P 层 / Contact）        │
         │  - TLS 终止                       │
         │  - 来源识别 → 打 region 标签       │
         │  - 区域合规过滤器                  │
         │    (CN → 仅已备案模型)             │
         │    (Global → 全部模型)             │
         └──────────────┬───────────────────┘
                        │ region=cn 或 region=global
                        ▼
         ┌──────────────────────────────────┐
         │  E 层（prism-core / Eos 内核）      │
         │  - router：按 region 过滤可用     │
         │    endpoints                       │
         │  - key-pool：Key 管理与状态机      │
         │  - proxy：libcurl 转发             │
         └──────────────┬───────────────────┘
                        │
                        ▼
               Provider API 调用
         (国内节点 / 国际节点 / 第三方)
```

### 4.1 各层职责

| 层 | 职责 | 不做什么 |
|----|------|---------|
| **入口层（P 层/闭源）** | 来源识别、region 标签注入、合规滤镜、模型准入 | 不涉及请求转发细节 |
| **router（E 层/开源）** | 按 region 标签 + 状态机过滤可用 endpoint | 不问用户来自哪里 |
| **proxy（E 层/开源）** | 纯 HTTP 转发，libcurl 传输 | 不感知合规策略 |
| **key-pool（E 层/开源）** | API Key 管理、状态切换 | 不关心 region 差异 |

---

## 5. 入口层部署拓扑

```
eos.cn  (中国备案域名)
  DNS → 国内 CDN → 国内服务器（或香港服务器，视备案策略）
  入口配置：region=cn，合规滤镜=仅已备案

eos.io  (国际域名)
  DNS → Cloudflare → 海外服务器（新加坡/弗吉尼亚）
  入口配置：region=global，合规滤镜=全部模型
```

- 同一套代码部署两份，仅在环境配置中区分 region 标签
- 共用同一个 manifest 来源（`region` 字段区分不同配置）
- 国内入口可选部署在香港服务器（免备案），但面向中国用户提供服务仍需模型备案

---

## 6. 对现有架构的影响评估

| 组件 | 影响 | 改动量 |
|------|------|--------|
| **prism-core（E 层）** | router 新增 region 标签过滤参数（可选，默认不过滤） | 小（~20 行） |
| **manifest 格式** | 新增 `region` 结构字段 | 中（schema + 示例） |
| **Eos 后端入口层（P 层）** | 新增区域合规过滤器 + 动态清单同步 | 中（新模块） |
| **Eos 前端** | 根据入口域名自动选择 endpoint | 小（环境变量） |
| **已备案清单同步工具** | 新增工具，从网信办公示同步 | 中（自动化工具） |

**总体评估**：架构影响可控，核心改动集中在 P 层新增的区域合规过滤器。E 层的改动仅在 router 加一个可选 region 过滤参数，保持开源侧通用性。

---

## 7. 执行建议

1. **优先完成 manifest region schema 定义**（与 ai-protocol 对齐）
2. **同步开发已备案清单更新工具**（沉淀到 ai-lib-plans/tools/）
3. **P 层区域合规过滤器**作为独立模块开发，与 E 层 router 解耦
4. **E 层 router 的 region 参数保持可选**，不影响现有单区域部署
5. **文档覆盖合规架构**，明确 E 层与 P 层的法律风险隔离责任

---

## 8. 相关文档

- `active/projects/eos/brand-rationale.md` — 品牌命名决策
- `active/projects/eos/project-overview.md` — 项目总览
- `active/projects/eos/EOS_DEPLOY_PLAN.md` — 部署计划
- `ai-lib-constitution/rules/business/BUSINESS_BOUNDARY_RULES.md` — 商业边界规则（BIZ-001~006）
- `MEMORY.md`（2026-05-10 Eos 仓库归属、2026-05-22 context capacity）
- `docs/governance/REMOTE_MIGRATION.md` — 远端迁移指令
