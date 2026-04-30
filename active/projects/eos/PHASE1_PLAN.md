# Eos（逸思）— Phase 1 开发计划

> **版本**：v1.0  
> **日期**：2026-04-30  
> **作者**：Spider 🕷️  
> **定位**：ai-lib 生态的 To C 消费者平台网站（浏览即用，区别于 Vela 的客户端侧应用）  
> **品牌文件**：`active/projects/eos/brand-rationale.md`  
> **前置依赖**：Prism Gateway（P 层）可用，或采用 Proxy 直连模式  

---

## 1. 产品定位

### 1.1 Eos vs Vela 边界

| 维度 | Eos（逸思） | Vela（船帆） |
|------|-----------|-------------|
| **形态** | 网站（浏览器即用） | 客户端应用（可安装/SDK 嵌入/WASM） |
| **目标用户** | 大众消费者（非技术） | 技术用户/开发者 |
| **核心价值** | "我想要的 AI 能力，直接就能用" | "帮我选最好的模型，数据留在本地" |
| **复杂度** | 低（面向通用场景） | 高（可定制路由/协议级控制） |
| **依赖关系** | 直接调用 Prism API 或 Provider API | 通过 Prism SDK 接入 Prism |
| **Phase 1 范围** | 最小可用网站（聊天+多模型+功能面板） | 最小聊天 UI（验证 Prism） |

### 1.2 三品牌服务链

```
                     用户
                       │
                  ┌────▼────┐
                  │   Eos   │ ← 消费者直接访问的 AI 服务平台
                  │ （逸思）  │    （AI 能力超市，要什么有什么）
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

**核心原则**：不重 UI、不搞花哨、不装用户管理。做到"用户在浏览器里打开就能用 AI"即完成。

| 范围 | 内容 |
|------|------|
| **包含** | 通用聊天 + 多模型切换 + 功能面板 + Web Search + 文件上传 + 图像生成 + 导出 |
| **不包含** | 用户注册/登录、付费、历史同步、智能路由、客户端 WASM |
| **技术栈建议** | 纯前端（HTMX / Alpine.js 或 Vanilla JS）或轻量框架，后端薄代理 |
| **部署形态** | `eos.ailib.info` 子域名，静态站点或简单容器 |
| **Provider 策略** | Phase 1 调用 Prism API（见依赖关系） |

---

## 2. 功能需求（最小闭环）

### 2.1 核心聊天（P0）

| 需求 ID | 功能 | 描述 | 优先级 |
|---------|------|------|:------:|
| EOS-P1-001 | 聊天界面 | 标准对话式 UI：输入框 + 消息列表 + 滚动加载 | P0 |
| EOS-P1-002 | 流式输出 | SSE / WebSocket 实时流式输出文字 | P0 |
| EOS-P1-003 | 多模型切换 | 下拉框或按钮组选择不同 Provider/模型 | P0 |
| EOS-P1-004 | 对话上下文 | 多轮对话保持上下文（当前 session 内） | P0 |
| EOS-P1-005 | 模型列表动态获取 | 从后端 API 获取可用模型列表（无需硬编码） | P1 |
| EOS-P1-006 | Markdown 渲染 | 代码块语法高亮、表格、列表渲染 | P1 |
| EOS-P1-007 | 对话历史列表（本地存储） | 当前 session 内可回溯历史消息 | P1 |

### 2.2 功能面板（P1）

| 需求 ID | 功能 | 描述 | 优先级 |
|---------|------|------|:------:|
| EOS-P1-008 | Web Search 功能 | 对话中调用搜索 API 获取实时信息（可选配置） | P1 |
| EOS-P1-009 | 文件上传（图片/文档） | 支持常见格式上传到支持多模态的模型 | P1 |
| EOS-P1-010 | 图像生成 | 调用 Flux/DALL-E API 生成图像并展示 | P1 |

### 2.3 导出与分享（P2）

| 需求 ID | 功能 | 描述 | 优先级 |
|---------|------|------|:------:|
| EOS-P1-011 | 对话导出 | 支持导出为 Markdown / PDF / TXT | P2 |
| EOS-P1-012 | 对话复制 | 一键复制对话内容到剪贴板 | P2 |
| EOS-P1-013 | 对话截图 | 生成对话截图（分享到社交） | P2 |

### 2.4 基础设施（P0）

| 需求 ID | 功能 | 描述 | 优先级 |
|---------|------|------|:------:|
| EOS-P1-014 | Eos 后端代理 | 后端薄代理层：转发请求到 Prism API + CORS + 限流 | P0 |
| EOS-P1-015 | CORS 安全 | 浏览器安全策略，限制来源 | P1 |
| EOS-P1-016 | 速率限制 | 防止滥用（单 IP/会话限流） | P1 |
| EOS-P1-017 | 域名 + HTTPS | `eos.ailib.info` + Caddy 自动 TLS | P0 |
| EOS-P1-018 | 监控 + 日志 | 基础错误日志 + 请求统计 | P2 |

---

## 3. 技术架构

### 3.1 整体架构

```
用户浏览器
    │
    ├── HTTPS ──► Eos Web Frontend (eos.ailib.info)
    │                  │
    │                  ▼
    │           Eos Backend Proxy (轻量)
    │             (Axum / Go / Python FastAPI)
    │                  │
    │                  ▼
    │            Prism API (api.prism.ailib.info)
    │                  │
    │                  ▼
    │           Provider APIs (OpenAI / DeepSeek / ...)
    │

Eos Frontend:
├── 静态 HTML + JS/CSS（无 SSR，纯客户端渲染）
├── SSE 流式接收
├── IndexedDB for localStorage 对话保留
└── 通用组件（聊天消息、代码高亮、上传、图片展示）

Eos Backend Proxy:
├── 轻量反向代理（转发请求到 Prism API）
├── 请求合并/重写（如需要）
├── CORS 策略管理
├── 速率限制（IP-based）
└── 静态文件服务
```

### 3.2 技术选型建议

| 层 | 推荐 | 替代 | 理由 |
|----|------|------|------|
| **前端框架** | **HTMX + Alpine.js** | React / Vue / Svelte | 最小化依赖，极简 UI，快速上线。Phase 1 不搞 SPA 架构 |
| **后端代理** | **Axum（Rust）** | Go / Python FastAPI | 与 ai-lib 生态一致，Rust 原生性能 |
| **流式协议** | SSE 标准 | WebSocket | Phase 1 SSE 够用，Prism API 原生支持 |
| **部署** | **Docker Compose** | Vercel / Fly.io | 自控制，与 Prism 同栈 |
| **域名** | `eos.ailib.info` | `eos.ai`（待争取） | 统一子域名策略 |

### 3.3 为什么选择 HTMX + Alpine.js？

1. **最小化前端** — Phase 1 不需要 SPA 状态管理、路由、组件树
2. **快速迭代** — 改 HTML 即可，无需构建工具链
3. **后端渲染友好** — SSE 流式输出 + HTMX 的 SSE 扩展天然配对
4. **低心智负担** — 先生可以快速理解和修改

---

## 4. 依赖关系

### 4.1 外部依赖

| 依赖 | 类型 | 状态 | 说明 |
|------|------|------|------|
| Prism API（`api.prism.ailib.info`） | 强依赖 | Phase 1 规划中 | Eos 后端代理转发到 Prism |
| ai-lib-core v0.9.4+ | 强依赖 | ✅ 已发布 | Prism 构建基础 |
| 5 个 P0 Provider（OpenAI/Anthropic/Gemini/DeepSeek/Qwen） | 强依赖 | ✅ 已有 | Prism Phase 1 目标 |
| Provider API Keys | 运营依赖 | ⚠️ 需要准备 | 先生需确认 Key 来源 |

### 4.2 与 Prism Phase 1 的配合

```
Prism Phase 1 (3 weeks)         Eos Phase 1 (可并行或与 Prism Phase 1 重叠)
───────────────────────          ──────────────────────────────────────
Week 1: P1-01~P1-03             Week 1: Mock Provider 模式下开发前端
  (骨架 + 核心代理 + Key池)         (EOS-P1-001~004, 008~009)
                                 
Week 2: P1-04~P1-06             Week 2: 后端代理开发 + 前端完善
  (用量 + 降级 + Docker)            (EOS-P1-005~007, 014~015)

Week 3: P1-07~P1-08             Week 3: 联调 + 部署 + 测试
  (管理API + Provider联调)          (EOS-P1-010~018)
```

**建议启动时机**：Prism P1-03 完成后（Week 1 末），或与 Prism 并行以 mock API 开发前端。

### 4.3 无 Prism 的降级方案

如果 Prism 在 Eos Phase 1 开发期间还未上线，Eos 后端代理可直接调用 Provider API：

```
Eos Backend ──► OpenAI API（直连）
             ├── Anthropic API（直连）
             ├── DeepSeek API（直连）
             └── Qwen API（直连）
```

但这不是推荐路线 — 与 Prism 混合后需迁移，且失去 Key 池/降级能力。

---

## 5. 任务包详情

### 5.1 前端任务（EOS-FE-*）

| 任务 ID | 名称 | 描述 | 依赖 | 预估 |
|---------|------|------|------|:----:|
| EOS-FE-001 | 聊天界面骨架 | HTML 页面结构 + CSS + HTMX 集成。消息输入框、发送按钮、消息列表容器 | — | 2 天 |
| EOS-FE-002 | SSE 流式接收 | HTMX SSE 扩展集成，流式消息渲染，光标/加载状态 | EOS-FE-001 | 1 天 |
| EOS-FE-003 | 多模型切换 UI | 模型选择下拉框（动态获取或静态列表），切换后发送请求携带模型参数 | EOS-FE-001 | 1 天 |
| EOS-FE-004 | 多轮对话上下文 | 前端维护对话历史数组，请求时携带消息历史；支持清空/新建对话 | EOS-FE-002 | 1 天 |
| EOS-FE-005 | Markdown 渲染 | 集成 markdown-it 或类似库，代码块语法高亮（highlight.js） | EOS-FE-002 | 1 天 |
| EOS-FE-006 | Web Search 按钮 | 搜索开关/配置入口，请求时添加搜索参数（由后端完成搜索） | EOS-FE-001 | 1 天 |
| EOS-FE-007 | 文件上传 UI | 上传按钮+拖拽区，支持图片/jpg/png 和文档/pdf/txt 上传 | EOS-FE-001 | 1.5 天 |
| EOS-FE-008 | 图像生成入口 | 单独的图像生成界面或按钮 + prompt 输入 + 展示区 | EOS-FE-001 | 1.5 天 |
| EOS-FE-009 | 导出/复制/截图 | 导出 Markdown 按钮、复制对话按钮、截图生成（html2canvas） | EOS-FE-002 | 1.5 天 |

### 5.2 后端任务（EOS-BE-*）

| 任务 ID | 名称 | 描述 | 依赖 | 预估 |
|---------|------|------|------|:----:|
| EOS-BE-001 | 后端代理骨架 | Axum 项目初始化：路由结构 + 配置加载 + 日志 | — | 1 天 |
| EOS-BE-002 | 聊天代理 API | `POST /api/chat` 转发到 Prism API / Provider API，含 SSE 流式透传 | EOS-BE-001 | 1.5 天 |
| EOS-BE-003 | 模型列表 API | `GET /api/models` 返回可用模型列表 | EOS-BE-001 | 0.5 天 |
| EOS-BE-004 | Web Search 集成 | 集成搜索 API（Tavily / SerpAPI / Bing Search），搜索结果作为上下文传递给模型 | EOS-BE-002 | 1 天 |
| EOS-BE-005 | 文件上传处理 | 接收文件，判断类型和大小，转发给支持多模态的模型 | EOS-BE-002 | 1 天 |
| EOS-BE-006 | 图像生成 API | `POST /api/images/generations` 转发到 Prism API / 对应 Provider | EOS-BE-001 | 1 天 |
| EOS-BE-007 | 速率限制 | IP-based 限流中间件（token bucket / sliding window） | EOS-BE-001 | 0.5 天 |
| EOS-BE-008 | CORS 配置 | 安全的跨域策略：仅允许 `eos.ailib.info` 来源 | EOS-BE-001 | 0.5 天 |

### 5.3 部署任务（EOS-DEPLOY-*）

| 任务 ID | 名称 | 描述 | 依赖 | 预估 |
|---------|------|------|------|:----:|
| EOS-DEPLOY-001 | Dockerfile | 多阶段构建：前端静态文件 + 后端二进制 | EOS-BE-008, EOS-FE-009 | 0.5 天 |
| EOS-DEPLOY-002 | Docker Compose | `docker-compose.yml`：Eos 容器 + Caddy 反向代理 | EOS-DEPLOY-001 | 0.5 天 |
| EOS-DEPLOY-003 | 域名 + TLS | 注册/配置 `eos.ailib.info`，Caddy 自动 HTTPS | EOS-DEPLOY-002 | 0.5 天 |
| EOS-DEPLOY-004 | 集成测试 | 端到端验证：前端→后端→Prism→Provider 链路通 | EOS-DEPLOY-003 | 1 天 |
| EOS-DEPLOY-005 | 监控 + 告警 | 基础健康检查端点 + 错误日志 | EOS-DEPLOY-003 | 0.5 天 |

---

## 6. 里程碑

| 里程碑 | 时间 | 验收标准 |
|--------|------|---------|
| **M1: Chat Works** | Week 1 末 | 聊天界面 → 后端代理 → Provider（mock or 直连）链路跑通，支持流式输出 + 多模型切换 |
| **M2: Feature Complete** | Week 2 末 | 功能面板（Web Search + 文件上传 + 图像生成）上线，Markdown 渲染 + 导出可用 |
| **M3: Live** | Week 3 末 | `eos.ailib.info` 外部可访问，所有 P0/P1 功能可用，部署自动化 |

---

## 7. 测试计划

| 类型 | 覆盖范围 | 自动化程度 |
|------|---------|:---------:|
| 后端单元测试 | API handler、流式转发、限流、CORS | ✅ cargo test |
| 后端集成测试 | 与 Prism API 联调（mock Provider） | ⚠️ 需 Prism 环境 |
| 前端可视化测试 | UI 渲染、SSE 流式展示、模型切换 | ❌ Phase 1 手动测试 |
| E2E 测试 | 浏览器打开→输入→发送→接收→导出的完整流程 | ❌ Phase 1 手动测试 |

---

## 8. 风险与缓解

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|:----:|---------|
| Prism Phase 1 延期 | Eos 前端联调受阻 | 中 | 采用直连 Provider 降级方案 |
| HTMX + SSE 兼容性问题 | 流式渲染卡顿/不流畅 | 低 | 备选方案：EventSource polyfill |
| 文件上传后端处理复杂 | 文件上传延期 | 中 | 缩小范围：Phase 1 仅支持图片上传 |
| 图像生成 API 不稳定 | 图像生成用户体验差 | 低 | 错误提示友好，降低用户预期 |
| CORS 配置错误 | 前端无法调用后端 | 低 | Phase 1 开发期间使用宽松策略 |

---

## 9. 后续 Phase 规划（待决）

| Phase | 时间 | 主要交付物 |
|-------|------|-----------|
| **Phase 2** | Phase 1 后 4-6 周 | 用户注册/登录、对话历史云端同步、免费配额、Web Search 增强 |
| **Phase 3** | Phase 2 后 8-12 周 | 订阅套餐、智能路由推荐、本土支付、社区功能 |
