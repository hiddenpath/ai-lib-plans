# PR-V1-001 前置依赖分析 — Vela Web 启动前需要什么

> **日期**: 2026-06-21  
> **分析人**: Spider (sisyphus)  
> **目的**: 供 Cursor 讨论决策，确认前置项后开工  
> **状态**: 分析完成，等待决策

---

## 1. 当前现状

| 检查项 | 状态 | 备注 |
|--------|:----:|------|
| Prism 生产 API | ✅ live | `https://api.prism.ailib.info`，5 provider，chat 验证通过 |
| `ailib-official/vela` 仓库 | ❌ 未创建 | project-overview.md 标注 "to be created" |
| `@ailib/prism-sdk` npm 包 | ❌ 不存在 | 无仓库、无代码、无 task YAML |
| `@ailib-official/prism-sdk` | ❌ 不存在 | 同上 |
| npm automation token | ✅ 已有 | 仅授权 `@ailib-official` scope（见 MEMORY.md § npm token） |
| prism-sdk 独立 task | ❌ 无 | V1-001 描述了 "Prism SDK integration" 但未拆分为独立任务 |

---

## 2. PR-V1-001 对自己的依赖声明

PR-V1-001 task YAML (`tasks/PR-V1-001-web-skeleton.yaml`):

```yaml
depends_on: ["PR-P1-006"]  # Docker 部署 — 已完成
description: |
  - Prism SDK integration (`@ailib/prism-sdk`) for API calls
  - Project scaffold: React or Vanilla JS + Vite
  - Chat UI: message input, response display, streaming support
```

**问题**: V1-001 隐含依赖了尚不存在的 `@ailib/prism-sdk`，但该包无独立 task YAML，也未出现在任何依赖链中。

---

## 3. prism-sdk 最小范围评估

Prism API 是标准 OpenAI-compatible 接口 (`/v1/chat/completions`, `/v1/models`)，无需复杂客户端。最小 SDK 仅需：

| 模块 | 行数估计 | 说明 |
|------|:-------:|------|
| `PrismClient` 类（baseUrl + Bearer auth） | ~30 行 | `new PrismClient({ apiKey, baseUrl })` |
| `chat.completions.create()` | ~20 行 | POST + JSON body，返回 OpenAI 格式 |
| SSE streaming helper | ~30 行 | `for await (const chunk of stream)` 包装 |
| `models.list()` | ~10 行 | GET `/v1/models` |
| TypeScript 类型 | ~20 行 | `ChatMessage`, `ChatRequest`, `ChatResponse` 等 |
| `package.json` + `tsconfig.json` + build | ~30 行 | tsup / unbuild 打包 |
| **总计** | **~140 行** | 纯 fetch 封装，零运行时依赖 |

**不依赖 ai-lib-ts**：Prism SDK 是 Prism Gateway 的薄客户端，不需要 ai-lib-ts 的 provider negotiation、pipeline、telemetry 等重量功能。ai-lib-ts 是给直接连 provider 的场景用的。

---

## 4. npm Scope 命名分析

### 4.1 现状

```
现有 npm 包:
  @ailib-official/ai-lib-ts       v0.5.3
  @ailib-official/ai-protocol     v0.8.4

npm automation token:
  仅授权 @ailib-official scope（repo secret NPM_TOKEN）
```

### 4.2 V1-001 的写法

```yaml
# PR-V1-001-web-skeleton.yaml 第14行:
- Prism SDK integration (`@ailib/prism-sdk`) for API calls
```

### 4.3 选项对比

| | `@ailib-official/prism-sdk` | `@ailib/prism-sdk` |
|---|---|---|
| 对齐现有规范 | ✅ 一致 | ❌ 不一致 |
| npm token 可用 | ✅ 直接用 | ❌ 需新 scope + 新 token |
| 品牌简洁度 | 🟡 略长 | ✅ 短 |
| 用户 import | `import { PrismClient } from '@ailib-official/prism-sdk'` | `import { PrismClient } from '@ailib/prism-sdk'` |

### 4.4 建议

**推荐 `@ailib-official/prism-sdk`**：
- 对齐 MEMORY.md 已记录的 `@ailib-official/*` 命名体系
- 复用现有 npm token，无需新建 scope
- 后续如需缩短品牌名，可做 `@ailib/prism-sdk` 别名包（depends on → 主包）

---

## 5. 仓库结构选项

### 选项 A: 独立仓库

```
ailib-official/prism-sdk/     ← 独立 npm 包
ailib-official/vela/          ← Vela web 应用（依赖 prism-sdk）
```

- ✅ 职责分离清晰
- ✅ prism-sdk 可被其他项目独立引用
- ❌ 两个仓库需分别 CI/CD

### 选项 B: Monorepo（推荐）

```
ailib-official/vela/
  ├── packages/
  │   └── prism-sdk/          ← npm 包 @ailib-official/prism-sdk
  ├── apps/
  │   └── web/                ← Vela web SPA
  ├── package.json            ← workspace root
  └── pnpm-workspace.yaml
```

- ✅ 一个仓库，开发体验统一
- ✅ prism-sdk 仍可独立 publish 到 npm
- ✅ Vela 本地开发时直接 link workspace 包
- 🟡 需要 pnpm workspaces 或 npm workspaces 配置

### 选项 C: 零仓库（SDK 内联）

```
ailib-official/vela/
  └── src/
      └── lib/
          └── prism-client.ts  ← 内联在 Vela 里，不独立发包
```

- ✅ 最简单，一个文件搞定
- ❌ prism-sdk 不独立发布，其他项目无法 npm install
- ❌ 与 V1-001 描述的 `@ailib/prism-sdk` 语义矛盾

---

## 6. 建议执行顺序

```
Step 0 (本分析):    决策 scope 命名 + 仓库结构 + 是否拆分 task
                    ↓
Step 1:            创建 ailib-official/vela 仓库
                    ↓
Step 2:            创建 prism-sdk 最小包（决定放 vela monorepo 还是独立仓库）
                    ↓ (如果需要独立 task)
Step 2b:           写 PR-V0-001-prism-sdk.yaml（或直接作为 V1-001 的 Step 0）
                    ↓
Step 3:            npm publish @ailib-official/prism-sdk@0.1.0
                    ↓
Step 4:            PR-V1-001: Vela web skeleton（npm install + chat UI）
                    ↓
Step 5:            PR-V1-002: 本地历史
                    ↓
Step 6:            PR-V1-003: 模型导航 UI
```

---

## 7. 待决策项（给 Cursor）

| # | 问题 | 推荐 | 需要确认 |
|---|------|------|:------:|
| D1 | npm scope 用 `@ailib-official` 还是 `@ailib`？ | `@ailib-official` | ✅ |
| D2 | prism-sdk 放 vela monorepo 还是独立仓库？ | vela monorepo `packages/prism-sdk` | ✅ |
| D3 | prism-sdk 是否需要独立 task YAML？ | 作为 V1-001 的 Step 0，不另建 YAML | ✅ |
| D4 | Vela 技术栈：React + Vite 还是 Vanilla + Vite？ | 待讨论（V1-001 写的是 "React or Vanilla JS"） | ✅ |
| D5 | Vela 的 Prism endpoint 用生产 `api.prism.ailib.info` 还是支持可配置？ | 支持可配置（dev 可用 localhost） | — |

---

## 8. 附录

### 8.1 Prism API 参考

```bash
# Health
curl https://api.prism.ailib.info/health

# Models
curl https://api.prism.ailib.info/v1/models \
  -H "Authorization: Bearer $PRISM_GATEWAY_API_KEY"

# Chat (non-streaming)
curl https://api.prism.ailib.info/v1/chat/completions \
  -H "Authorization: Bearer $PRISM_GATEWAY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"deepseek-chat","messages":[{"role":"user","content":"hi"}]}'

# Chat (streaming) — 加 "stream": true
```

### 8.2 prism-sdk 最小 API 设计草案

```typescript
// 用户代码
import { PrismClient } from '@ailib-official/prism-sdk';

const prism = new PrismClient({
  apiKey: 'psk-...',
  baseUrl: 'https://api.prism.ailib.info', // 默认值
});

// 非流式
const res = await prism.chat.completions.create({
  model: 'deepseek-chat',
  messages: [{ role: 'user', content: 'Hello' }],
});
console.log(res.choices[0].message.content);

// 流式
const stream = prism.chat.completions.createStream({
  model: 'deepseek-chat',
  messages: [{ role: 'user', content: 'Hello' }],
});
for await (const chunk of stream) {
  process.stdout.write(chunk.choices[0]?.delta?.content ?? '');
}
```

### 8.3 相关文件索引

| 文件 | 内容 |
|------|------|
| `active/projects/vela/project-overview.md` | Vela 项目总览，含架构和三区对齐 |
| `active/projects/vela/tasks/PR-V1-001-web-skeleton.yaml` | 原始 task（依赖 PR-P1-006，隐含依赖 prism-sdk） |
| `active/projects/vela/TASKS_INDEX.md` | Vela 任务索引（3 个 task） |
| `MEMORY.md` L487 | npm token 仅授权 `@ailib-official` scope |
| `MEMORY.md` L95 | npm 命名约定 `@ailib-official/*` |
| `active/projects/prism/TASKS_INDEX.md` | Prism 全部完成（M1/M2/M3 ✅） |
