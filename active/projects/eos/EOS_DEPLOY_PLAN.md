# Eos（逸思）部署与功能上线计划

> 版本：v1.1
> 日期：2026-05-11（执行回填：2026-05-28）
> 决策背景：先生（Alex）× Spider 讨论
> 先决条件：香港云服务器（免备案）、国际域名 eos.ailib.info、公网 IP
> **执行状态**：**completed** — 块 A–E 已落地；生产 `https://eos.ailib.info` 已确认 **`main@299575a`**（alex，2026-05-28）；自动化脚本 `ai-lib-plans/tools/deploy_eos.sh`。

---

## 0. 架构总览

```
用户浏览器（香港设备或海外） ─── HTTPS ───→ eos-server (香港云服务器)
                                                    │
                                                   ├── /v1/models / /v1/chat/completions (EOS-P2-005-R2, #19)
                                                   ├── /api/proxy / /api/proxy/stream  → Provider API (OpenAI/DeepSeek/...)
                                                   ├── /api/models / /health
                                                   ├── /api/web-search (新增)           → Tavily/SerpAPI
                                                   ├── /api/upload (新增)               → 文件存储/转发多模态
                                                   ├── /api/images/generations (新增)   → Flux/DALL-E
                                                   ├── / (静态文件: index.html + WASM)
                                                   └── Eos UI (HTMX + Alpine.js + WASM)
```

**技术栈不变**：WASM (wasm-bindgen) + Axum (Rust) + HTMX + Alpine.js / 纯 JS
**所有新增 API 路由**实现在 `eos-server`（产品层），gateway 逻辑保持在 `prism-core`

---

## 1. 项目分片（5 个块）

| 块 | 名称 | 时间线 | 产出 |
|----|------|--------|------|
| **A** | 香港云服务器开通 | Day 1 | 服务器就绪，Docker 可运行 |
| **B** | Web Search 功能 | Day 1-3 | 前端搜索开关 + 后端 Tavily 集成 |
| **C** | 文件上传功能 | Day 2-4 | 前端上传按钮 + 后端 multipart 处理 |
| **D** | 图像生成 + 模型账户准备 | Day 3-5 | 图像生成切换模式 + Provider API Key 集成 |
| **E** | Docker 部署 + 内测上线 | Day 5-7 | Docker 镜像编译、部署运行、功能验证 |

---

## 2. 块 A：香港云服务器开通

### 2.1 选型建议

| 供应商 | 推荐配置 | 预估价格 | 备注 |
|--------|---------|---------|------|
| **腾讯云香港** | 2C4G 轻量 | ~¥120/月 | 国内厂商，控制面板中文，支持微信支付 |
| **阿里云香港** | 2C4G ECS | ~¥80-150/月 | 稳定，带宽可选 |
| **Hetzner** | CX22 (2C4G) | ~€6/月 | 价格最优，但在德国/芬兰，香港访问延迟高 |
| **Vultr SG/JPN** | $12/m 2C4G | ~$12/月 | 新加坡/日本机房，延迟尚可 |

**建议：腾讯云香港轻量服务器 2C4G**，延迟低、支付方便、控制面板全中文。

### 2.2 服务器初始化

```bash
# 基础环境
apt update && apt upgrade -y
apt install -y docker.io docker-compose-v2 curl git tmux htop

# 可选：安装 Rust 工具链（本地开发用，非部署必需）
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### 2.3 网络防火墙开放

| 端口 | 用途 | 注意 |
|------|------|------|
| 22 | SSH | 限制来源 IP 或使用密钥登录 |
| 3000 | Eos HTTP | 内测阶段临时开放，上 Caddy 后关闭 |
| 80 / 443 | Caddy HTTP/S | 上线后启用 |

---

## 3. 块 B：Web Search 功能

### 3.1 后端

**新增路由** `POST /api/web-search`

```rust
// crates/eos-server/src/routes.rs
// 新增模块 routes/search.rs

请求体: { "query": "string", "max_results": 5 }
响应体: { "results": [ { "title": "...", "url": "...", "snippet": "..." } ] }

// 集成 Tavily Search API (推荐)
// Tavily 免费层: 1000 请求/月
// API: POST https://api.tavily.com/search
// env: EOS_TAVILY_API_KEY
```

**SSE 混合搜索流**：用户在聊天中勾选 Web Search 后，前端发送请求时附带 `web_search: true`。后端逻辑：

1. 服务端收到 search flag → 先调 Tavily 搜索
2. 搜索结果格式化注入 system message
3. 连同原始请求一起转发给 Provider
4. SSE 流式返回模型输出（含搜索结果上下文）

### 3.2 前端

- 输入框上方新增 🌐 **Web Search** 切换按钮（切换开关）
- 状态用 `x-data` 管理：`searchEnabled: false`
- 发送请求时根据开关状态设置 `search_body` 字段
- 后端处理完 SSE 返回后，前端正常流式渲染（用户无感知搜索过程）

### 3.3 API Key 成本

| 搜索服务 | 免费额度 | 超出费用 | 推荐？ |
|---------|---------|---------|:------:|
| Tavily | 1000 次/月 | $0.50/1000 次 | ✅ 首推 |
| SerpAPI | 100 次/月 | $0.01/次 | 次选 |

---

## 4. 块 C：文件上传功能

### 4.1 后端

**新增路由** `POST /api/upload`

```rust
// crates/eos-server/src/routes/upload.rs

接受 multipart/form-data，字段:
  - file: 文件（仅图片，max 10MB）
  - model: 目标模型 ID

流程:
  1. 校验文件类型 (image/*)
  2. 校验文件大小 (≤ 10MB)
  3. 保存到 /tmp/eos/uploads/{uuid}.{ext}
  4. 返回文件访问 URL: /api/files/{uuid}.{ext}
  5. 前端后续将图片 URL 加入用户消息

// 文件服务路由（静态）
GET /api/files/{filename} → 从 /tmp/eos/uploads/ 提供文件
```

**Phase 1 限制：仅支持图片上传**。文字提取、PDF 解析等排到 Phase 2。

### 4.2 前端

- 输入框左侧新增 📎 上传按钮
- 点击唤起文件选择器（`accept="image/*"`）
- 上传时显示进度（可采用 Alpine.js 的状态管理）
- 上传成功后：URL 自动填充到当前消息的 image 字段
- 支持拖拽/多图上传（Phase 2）

### 4.3 安全注意事项

- 文件类型校验在后端做（不能只靠前端 accept）
- 文件名防注入（UUID 重命名）
- 限制上传频率（复用限流中间件）

---

## 5. 块 D：图像生成 + 模型账户

### 5.1 图像生成后端

**新增路由** `POST /api/images/generations`

```rust
// crates/eos-server/src/routes/images.rs

请求体: { "prompt": "string", "model": "string", "n": 1, "size": "1024x1024" }

流程:
  1. 根据 model 选择 Provider
  2. 转发到图片生成 API (OpenAI DALL-E 3 / Flux)
  3. 返回图像 URL

配置 env:
  EOS_OPENAI_API_KEY   (DALL-E 3)
  (后续) EOS_FLUX_API_KEY
```

### 5.2 前端

- 聊天输入框上方新增模式切换按钮：💬 **聊天** / 🎨 **图像生成**
- 图像生成模式下：
  - 输入 prompt
  - 选择模型（Flux / DALL-E 3 等）
  - 选择尺寸（512x512 / 1024x1024）
  - 发送后展示生成的图片（并排缩略图 + 点击放大）

### 5.3 模型账户采购清单

| Provider | 用途 | 费用类型 | 需要采购？ |
|----------|------|---------|:---------:|
| OpenAI | GPT-4o mini (聊天) + DALL-E 3 (图像) | Pay-as-you-go ✅ ✅ | **需要充值** |
| DeepSeek | DeepSeek Chat (聊天) | Pay-as-you-go ✅ | **建议开通** |
| Anthropic | Claude (长文本/推理) | Pay-as-you-go ❓ | 可选（Phase 2） |
| Groq | Llama (低延迟聊天) | 免费层 | 已有（NVIDIA 路线替代） |
| NVIDIA | GLM-5.1 (聊天) | Pay-as-you-go ❓ | 可选 |
| **Tavily** | Web Search | 1000次/月免费 | **需要注册** |
| **Stability AI** | Flux (图像) | Pay-as-you-go ❓ | 可选替换 DALL-E |

**最小采购清单（上线必需）：**

| # | 服务 | 最低充值 | 用途 |
|---|------|---------|------|
| 1 | OpenAI API | $20 | 聊天(GPT-4o-mini) + 图像(DALL-E 3) |
| 2 | DeepSeek API | ¥50 | 低成本聊天主力 |
| 3 | Tavily | 免费注册 | Web Search |

**可选补充：**

| # | 服务 | 费用 | 考虑理由 |
|---|------|------|---------|
| 4 | Anthropic | $20 | Claude 长文本推理质量高 |
| 5 | Flux (via Together/BFL) | $10 | 开源图像生成，比 DALL-E 灵活 |

---

## 6. 块 E：Docker 部署 + 内测上线

### 6.1 Dockerfile 完善

当前仓库已是三阶段镜像（WASM → Rust → 运行时）。上线前仍需：
- ✅ 已有三阶段构建（WASM → Rust → 运行时）
- ⚠️ Docker build 必须在有 Docker 的环境实际验证
- ❌ 静态资源复制策略仍只覆盖当前最小文件；若增加 CSS/JS/assets 需同步 Dockerfile
- ❌ `.env.production` 注入机制需由部署脚本/Compose 提供，禁止提交真实密钥
- ❌ 缺少 Caddy 配置（上线阶段加）

### 6.2 Docker Compose 配置

新增 `docker-compose.yml`：

```yaml
version: "3.9"
services:
  eos:
    build: .
    ports:
      - "3000:3000"
    env_file:
      - .env.production
    volumes:
      - eos_uploads:/tmp/eos/uploads
    restart: unless-stopped

volumes:
  eos_uploads:
```

生成 `.env.production` —— 生产环境配置（不提交 git）：

```env
EOS_OPENAI_API_KEY=sk-xxx
EOS_DEEPSEEK_API_KEY=sk-xxx
EOS_TAVILY_API_KEY=tvly-xxx
EOS_BIND_ADDR=0.0.0.0
EOS_PORT=3000
EOS_UPLOAD_DIR=/tmp/eos/uploads
EOS_TRUST_PROXY_HEADERS=true  # 仅当 Caddy/可信反代覆盖 X-Forwarded-For 时启用
# EOS_GROQ_API_KEY=   # 可用则填
# EOS_NVIDIA_API_KEY=  # 可用则填
```

### 6.3 编译与部署流程

```bash
# 在本地（开发机）或 CI
cd /home/alex/eos

# 编译 WASM
wasm-pack build crates/eos-wasm-browser --target web --out-dir ../../static/wasm --release

# 构建 Docker 镜像
docker build -t eos:latest .

# 保存镜像（给服务器用）
docker save eos:latest | gzip > eos-image.tar.gz

# 传输到服务器
scp eos-image.tar.gz user@server-ip:~
# 或在服务器直接 git clone + build
```

### 6.4 服务器端部署

```bash
# 服务器上
docker load < eos-image.tar.gz

# 创建目录
mkdir -p /opt/eos/uploads
cd /opt/eos

# 复制 .env.production
# 用 scp 或直接 vi 创建

# 启动
docker run -d \
  --name eos \
  -p 3000:3000 \
  --env-file .env.production \
  -v /opt/eos/uploads:/tmp/eos/uploads \
  --restart unless-stopped \
  eos:latest

# 验证
curl http://localhost:3000/health
# → {"status":"ok","version":"0.1.0"}
```

### 6.5 内测验证清单

| # | 检查项 | 预期结果 |
|---|--------|---------|
| 1 | `GET /health` | `{"status":"ok"}` |
| 2 | `GET / ` → index.html | 页面加载，显示 Eos 品牌 UI |
| 3 | WASM 模块加载 | 控制台无错误，状态显示 "WASM Ready" |
| 4 | `/api/models` | 返回配置的 Provider/模型列表 |
| 5 | 发送聊天消息 | 消息发送成功，SSE 流式输出 |
| 6 | 多轮对话 | 连续发送消息，上下文保持 |
| 7 | New Chat 清空 | 清除历史消息 |
| 8 | Web Search 开关 | 开启后搜索结果注入上下文中 |
| 9 | 文件上传 | 选择图片 → 上传成功 → 可在聊天中使用 |
| 10 | 图像生成 | 切换模式 → 输入 prompt → 生成图片展示 |

---

## 7. 时间线（规划）

| 工作日 | 内容 | 产出 |
|--------|------|------|
| Day 1 | 开通香港服务器 + Web Search 后端代码 | 服务器就续、搜索 API 集成 |
| Day 2 | Web Search 前端 + 文件上传后端 | 搜索开关 UI 完成、上传路由可用 |
| Day 3 | 文件上传前端 + Provider 账户开通充值 | 上传功能可用、OpenAI/DeepSeek/Tavily 就续 |
| Day 4 | 图像生成后端+前端 | 图像生成可用、模型配置完成 |
| Day 5 | Docker Compose + 编译部署 + 内测 | 线上可访问、全功能验证 |
| Day 6-7 | 缓冲区 + 域名单选方案 | Bug 修复、体验打磨 |

---

## 8. 域名单选方案（后续上线）

当内测通过后，上线域名方案：

| 方案 | 操作 | 成本 |
|------|------|------|
| **A：Caddy 自签 HTTPS** | Caddy 反向代理，自签证书，先不用 DNS | 免费，但浏览器提示不安全 |
| **B：Caddy + DNS** | 解析 eos.ailib.info → IP + Let's Encrypt | 免费 TLS |
| **C：Cloudflare Tunnel** | Cloudflare Tunnel 无需开放端口 | 免费，但需 NS 托管 |

**推荐路径：** 本机/内网用 HTTP 跑通功能 → 公网内测直接使用方案 B（Caddy + Let's Encrypt）；自签仅用于无法配置 DNS 的临时排障，不作为用户可访问入口。

---

## 9. 下一步行动项

先生确认后，我按以下顺序启动：

1. 你决定云服务器厂商和配置 → 我出开通指南
2. 你开通服务器 → 我远程连进去初始化环境
3. 我开始编码 Web Search（块 B）→ 边编边等你开通完成
4. 你开完服务器 → 我把代码推送，部署验证
5. 边用边补文件上传和图像生成

---

## 10. 备忘录：blocking 决策记录

| ID | 决策 | 理由 |
|----|------|------|
| D1 | 香港服务器，免备案 | 国内备案周期 10-20 工作日，与"先跑起来"矛盾 |
| D2 | 公网内测也走 Caddy + Let's Encrypt；仅本机/内网调试可用 HTTP | 聊天内容、上传图片与 Provider 代理请求都可能敏感，公网明文不作为上线方案 |
| D3 | Web Search 用 Tavily (1000次/月免费) | 最小成本验证搜索功能 |
| D4 | Phase 1 仅支持图片上传 | 文字提取/PDF 等在 Phase 2 |
| D5 | 不自带编排模型服务器 | 用 API 小模型替代，后续按需再加 |
| D6 | Provider 配置走 .env（已有模式） | 保持与 ailib-wasm-test 一致的简化管理 |
