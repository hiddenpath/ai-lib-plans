# Eos（逸思）— Phase 1 开发计划

> **版本**：v2.0
> **日期**：2026-04-30
> **作者**：Spider 🕷️
> **定位**：ai-lib 生态的 To C 消费者平台网站（浏览即用，区别于 Vela 的客户端侧应用）
> **品牌文件**：`active/projects/eos/brand-rationale.md`
> **基础项目**：[`ailib-official/ailib-wasm-test`](https://github.com/ailib-official/ailib-wasm-test) — WASM 协议运行时演示项目
> **前置依赖**：Prism Gateway（P 层）或直连 Provider

---

## 0. 关键认识：Eos = ailib-wasm-test rebrand + 功能扩展

**Eos 不是从零开始。** `ailib-wasm-test` 已经完成了：

| 已有产物 | 说明 |
|---------|------|
| **WASM 浏览器模块** (`crates/wasm-browser`) | wasm-bindgen 封装，暴露 `build_chat_request()` / `parse_chat_response()`，在浏览器端完成协议执行 |
| **后端代理** (`crates/server`) | Axum 服务器：`/api/proxy` 转发、`/api/proxy/stream` SSE 流式、`/health`、静态文件服务、libcurl TLS 指纹支持 |
| **聊天 Demo UI** (`static/index.html`) | 已有：多 Provider 切换、WASM 加载状态、消息列表、流式渲染、New Chat |
| **Provider 直连** | 已有 4 个 Provider：Groq / DeepSeek / OpenAI / NVIDIA |

**Phase 1 任务 = rebrand + 功能扩展 + 部署上线**，不是重写。

---

## 1. 产品定位

### 1.1 Eos vs Vela 边界

| 维度 | Eos（逸思） | Vela（船帆） |
|------|-----------|-------------|
| **形态** | 网站（浏览器即用） | 客户端应用（可安装/SDK 嵌入/WASM） |
| **目标用户** | 大众消费者（非技术） | 技术用户/开发者 |
| **核心价值** | "我想要的 AI 能力，直接就能用" | "帮我选最好的模型，数据留在本地" |
| **复杂度** | 低（面向通用场景） | 高（可定制路由/协议级控制） |
| **依赖关系** | 直连 Provider API（Phase 1）或 Prism API（后期） | 通过 Prism SDK 接入 Prism |
| **Phase 1 范围** | rebrand → 扩展功能 → 部署上线 | 最小聊天 UI（验证 Prism） |

### 1.2 三品牌服务链

```
                     用户
                       │
                  ┌────▼────┐
                  │   Eos   │ ← 消费者直接访问的 AI 服务平台
                  │ （逸思）  │    （AI 能力超市）
                  └────┬────┘
                       │
                  ┌────▼────┐
                  │  Prism  │ ← 平台侧路由/Key池/Provider 管理
                  │ （棱镜）  │    （企业级后台，用户无感知）
                  └────┬────┘
                       │
               ┌───────┴───────┐
               ▼               ▼
          Provider APIs     Provider APIs
          (OpenAI/Claude)   (DeepSeek/Qwen)
```

### 1.3 Phase 1 范围（最小闭环）

| 范围 | 内容 |
|------|------|
| **包含** | Rebrand（Eos 品牌 UI）+ WASM 协议执行 + 聊天/流式 + 多 Provider + Web Search + 文件上传 + 图像生成 + 导出 + Docker 部署 |
| **不包含** | 用户注册/登录、付费、历史同步、智能路由、Prism 集成 |
| **技术栈** | **保持现有**：WASM (wasm-bindgen) + Axum (Rust) + 静态 HTML/JS/CSS |
| **部署形态** | `eos.ailib.info` 子域名，Docker Compose |
| **Provider 策略** | Phase 1 = 后端代理直连 Provider API（已有），后续可切 Prism |

---

## 2. 功能需求（最小闭环）

### 2.1 Rebrand + UI 升级（P0）

| ID | 功能 | 描述 | 优先级 |
|----|------|------|:------:|
| R1 | 品牌替换 `ailib-wasm-test` → **Eos** | 页面标题、Logo、页眉文案替换为 Eos（逸思） | P0 |
| R2 | UI 主题改造 | 从深色科技风改为 Eos 品牌色调（晨曦暖色系），整体视觉升级 | P0 |
| R3 | 中文首页默认 | HTML `lang="zh-CN"`，全部 UI 文字中文化 | P0 |
| R4 | 中英文切换 | 保留英文版本，Header 加语言切换开关 | P1 |

### 2.2 核心聊天增强（P0）

| ID | 功能 | 描述 | 优先级 |
|----|------|------|:------:|
| C1 | 保持 WASM 协议执行 | `wasm-browser` 模块继续可用，请求在浏览器 WASM 中构建 | P0 |
| C2 | 多轮对话上下文 | 前端维护对话历史数组，SSE 请求携带消息历史；支持清空/新建对话 | P0 |
| C3 | Markdown 渲染优化 | 代码块 highlight.js / LaTeX（可选） | P1 |
| C4 | 模型列表动态获取 | 后端 `/api/models` 返回可用模型列表，前端下拉动态加载 | P1 |

### 2.3 功能面板扩展（P1）

| ID | 功能 | 描述 | 优先级 |
|----|------|------|:------:|
| F1 | Web Search 按钮 | 搜索开关（后端集成 Tavily/SerpAPI），搜索结果注入模型上下文 | P1 |
| F2 | 文件上传 | 图片上传（支持多模态模型），输入框旁加上传按钮 | P1 |
| F3 | 图像生成模式 | 切换至图像生成模式，输入 prompt 调用 Flux/DALL-E，展示生成结果 | P1 |

### 2.4 导出与分享（P2）

| ID | 功能 | 描述 | 优先级 |
|----|------|------|:------:|
| E1 | 对话导出 | 导出 Markdown / PDF（html2pdf.js） | P2 |
| E2 | 对话复制 | 一键复制全部对话到剪贴板 | P2 |
| E3 | 对话截图 | 生成截图（html2canvas），可分享社交 | P2 |

### 2.5 基础设施（P0）

| ID | 功能 | 描述 | 优先级 |
|----|------|------|:------:|
| I1 | 扩展后端路由 | 新增 `/api/models`、`/api/web-search`、`/api/upload`、`/api/images/generations` | P0 |
| I2 | Web Search 集成 | 后端集成搜索 API，SSE 混合搜索+模型输出 | P1 |
| I3 | 文件上传处理 | 后端接收文件，判断类型/大小，转发多模态模型 | P1 |
| I4 | 图像生成代理 | 后端转发 Flux/DALL-E API，返回图像 URL 或 Base64 | P1 |
| I5 | 限流中间件 | IP-based rate limiting | P1 |
| I6 | Provider 配置外部化 | Provider Key/Endpoint 从 `.env` 文件读取（而非硬编码 env var 匹配） | P0 |

---

## 3. 技术架构（保持现有）

```
浏览器
   │
   ├── WASM (ailib-wasm-browser)
   │      ├── build_chat_request()  ← 在浏览器 WASM 中构建请求
   │      └── parse_chat_response() ← 在浏览器 WASM 中解析响应
   │
   ▼ HTTPS
Eos 后端代理 (Axum, 已有 crates/server)
   ├── /api/proxy                ← 非流式转发
   ├── /api/proxy/stream         ← SSE 流式转发
   ├── /api/models               ← (新增) 模型列表
   ├── /api/web-search           ← (新增) Web Search
   ├── /api/upload               ← (新增) 文件上传
   ├── /api/images/generations   ← (新增) 图像生成
   ├── /health                   ← 健康检查
   └── /                         ← 静态文件（Eos UI）
          │
          ▼ (libcurl)
Provider APIs (OpenAI / DeepSeek / Anthropic / Groq / NVIDIA / ...)
```

### WASM vs 非 WASM 两线策略

```
┌─────────────────────────────────────────────────────────┐
│                     Eos Frontend                          │
│                                                           │
│  ├── WASM 模式（默认）：请求构建在浏览器 WASM 中完成     │
│  │    - build_chat_request() / parse_chat_response()       │
│  │    - 调用 ai-lib-core 协议逻辑（标准化/一致性）        │
│  │    - 证明 WASM 协议运行时可以在浏览器端运行             │
│  │                                                          │
│  ├── 非 WASM 模式（fallback）：直接通过后端转发            │
│  │    - 浏览器不支持 WASM 时自动降级                       │
│  │    - 后端直接构建请求转发给 Provider                    │
│  │    - 对用户透明                                         │
│  │                                                          │
│  └── Provider/模型切换入口对两种模式保持一致               │
└─────────────────────────────────────────────────────────┘
```

Phase 1 不重写 WASM 层。`crates/wasm-browser` 和 WASM 部分保持原样，只在前端 UI 叠加功能。

---

## 4. 依赖关系

| 依赖 | 类型 | 状态 | 说明 |
|------|------|------|------|
| `ailib-official/ailib-wasm-test` 代码 | 强依赖 | ✅ 已本地 | Eos 从此 fork/rename |
| WASM 工具链 (`wasm-pack`, `wasm-bindgen`) | 构建依赖 | ✅ 已有 | ai-lib-rust 已集成 |
| Provider API Keys | 运营依赖 | ⚠️ 需准备 | OpenAI / DeepSeek / Anthropic / Groq / NVIDIA |
| 域名 `eos.ailib.info` | 运营依赖 | ⚠️ 需配置 | |

### Eos Phase 1 与 Prism Phase 1 并行

```
Prism Phase 1 (3 weeks)       Eos Phase 1 (3 weeks)
───────────────────────        ──────────────────────
Week 1: 核心代理 + Key池       Week 1: Rebrand + Web Search + 文件上传
Week 2: 用量 + 降级 + Docker   Week 2: 功能完善 + 图像生成 + 导出 + 部署
Week 3: 管理API + 联调         Week 3: 集成测试 + 上线
```

**完全并行** — Eos 直连 Provider（如现有 ailib-wasm-test），不依赖 Prism。后续迁 Prism 是 Phase 2。

---

## 5. 任务包

### Rebrand（EOS-P1-R*）

| 任务 ID | 名称 | 预估 |
|---------|------|:----:|
| EOS-P1-R1 | Fork ailib-wasm-test 为新仓库 `eos` | 0.5d |
| EOS-P1-R2 | HTML 页面文案替换（标题/页眉/描述 → Eos 逸思） | 0.5d |
| EOS-P1-R3 | UI 主题色/品牌色替换（css 变量改色） | 1d |
| EOS-P1-R4 | Full Chinese localization + language switch | 1.5d |

### Frontend 增强（EOS-P1-F*）

| 任务 ID | 名称 | 描述 | 依赖 | 预估 |
|---------|------|------|------|:----:|
| EOS-P1-F1 | 多轮对话上下文 | 前端维护 `messages[]`，SSE 携带历史；New Chat 按钮 | — | 1d |
| EOS-P1-F2 | Markdown 渲染增强 | 集成 highlight.js 语法高亮 | EOS-P1-F1 | 0.5d |
| EOS-P1-F3 | Web Search 开关 UI | 输入框上方搜索切换按钮 | — | 1d |
| EOS-P1-F4 | 文件上传按钮 | 上传图标按钮 + 文件选择器 | — | 1.5d |
| EOS-P1-F5 | 图像生成模式切换 | 模式切换按钮（聊天↔图像生成），图像展示区 | — | 1.5d |
| EOS-P1-F6 | 导出/复制/截图 | Markdown 导出、一键复制、html2canvas 截图 | EOS-P1-F1 | 1.5d |
| EOS-P1-F7 | 模型下拉动态加载 | 调用 `/api/models` 填充下拉列表 | — | 0.5d |

### Backend 扩展（EOS-P1-B*）

| 任务 ID | 名称 | 描述 | 依赖 | 预估 |
|---------|------|------|------|:----:|
| EOS-P1-B1 | `/api/models` 端点 | 返回可用 Provider/模型列表（可从 config/env 加载） | — | 0.5d |
| EOS-P1-B2 | Web Search 集成 | Tavily/SerpAPI 搜索 + 结果注入，支持 SSE 混合流式 | — | 1.5d |
| EOS-P1-B3 | 文件上传处理 | 接收 multipart，类型/大小校验，转发多模态模型 | — | 1.5d |
| EOS-P1-B4 | 图像生成代理 | 转发 Flux/DALL-E API，返回图像 | — | 1d |
| EOS-P1-B5 | 限流中间件 | IP-based token bucket | — | 0.5d |
| EOS-P1-B6 | Provider 配置外部化 | `AILIB_WASM_*.env` → 统一 `EOS_*.env` 配置 | — | 0.5d |

### 部署（EOS-P1-D*）

| 任务 ID | 名称 | 描述 | 依赖 | 预估 |
|---------|------|------|------|:----:|
| EOS-P1-D1 | Dockerfile 更新 | 多阶段：WASM 编译 → Rust 编译 → 静态文件打包 | — | 0.5d |
| EOS-P1-D2 | Docker Compose | `docker-compose.yml` + Caddy TLS | EOS-P1-D1 | 0.5d |
| EOS-P1-D3 | 域名配置 | `eos.ailib.info` DNS + Caddy | EOS-P1-D2 | 1d |
| EOS-P1-D4 | E2E 集成测试 | 浏览器打开→输入→发送→接收→导出全链路 | EOS-P1-D3 | 1d |

---

## 6. 里程碑

| 里程碑 | 时间 | 验收标准 |
|--------|------|---------|
| **M1: Rebranded + Core Chat** | Week 1 末 | `eos.ailib.info` (开发) 可访问，Eos 品牌 UI + 多轮对话 + WASM 执行 + markdown 渲染 |
| **M2: Feature Complete** | Week 2 末 | Web Search + 文件上传 + 图像生成 + 导出全部可用 |
| **M3: Live** | Week 3 末 | `eos.ailib.info` 正式上线 + 限流保护 + Docker 部署自动 |

---

## 7. 风险与缓解

| 风险 | 影响 | 概率 | 缓解 |
|------|------|:----:|------|
| WASM 编译兼容性（浏览器版本） | 部分用户无法使用 WASM | 低 | 提供非 WASM fallback |
| 文件上传后端处理复杂 | 文件上传延期 | 中 | Phase 1 仅支持图片 |
| 图像生成 API 不稳定 | 用户体验差 | 低 | 错误提示友好 |
| Provider Key 过期/不足 | 部分模型不可用 | 中 | 后端 clear 错误提示，UI 友好降级 |
| ailib-wasm-test 未公开到 ailib-official | fork 阻塞 | 中 | 先本地开发，上线前再公开 |
