# Eos 上下文架构 Phase 2+ — 动态分层结构化 & 外部文档化

> **版本**: v1.0
> **日期**: 2026-06-02
> **来源**: 先生（Alex）与 Spider 讨论
> **状态**: 远期架构规划（尚未分配给 Phase 2 task）

## 1. 核心动机

当前 Phase 2 已完成的能力：

| 组件 | 能力 | 限制 |
|------|------|------|
| `ContextBudget` | 按 token budget 倒序截断（linear flat + tool folding） | 无消息层级，一刀切 |
| `MessageAssembler` | 保证最小尾消息数，folding 大 tool 块 | 不区分消息重要性 |
| `SessionMirror` | 浏览器端会话镜像，ArtifactRef 大块引用 | 仅有存储抽象，无智能召回 |

先生（2026-06-02）指出的方向：

> **动态分层结构化**：按角色、权重、类型对消息分层，组装时按层级优先级裁剪，不是简单从尾巴往前砍。
>
> **外部文档化**：对话历史可以作为结构化文档持久化、可检索、可注入。新会话可以加载旧会话的决策摘要；长对话可以归档成外部文档，只带索引进当前上下文。

## 2. 设计原则

1. **分层 > 截断**：消息不只有"时间顺序"，还有"重要性层级"
2. **检索 > 保留**：尽量按需召回，不要盲目全量携带
3. **确定性 > 黑盒**：分层逻辑可控可测，完全避开 LLM compaction 风险
4. **渐进落地**：先从浏览器端索引做起，再扩展服务端

## 3. 消息分层模型

每条消息（或消息块）携带一个 `Priority` 标签，用于组装时的决策：

```
Layer 0 — System:    不可裁剪（system prompt, 工具定义, 行为约束）
Layer 1 — Active:    当前 round 刚发的消息（完整保留）
Layer 2 — Relevant:  被当前问题引用的历史消息（带召回信号，完整保留）
Layer 3 — Summary:   已归档的外部摘要文档（注入为 system，极简）
Layer 4 — Background:普通历史对话（按 budget 倒序保留，可选折叠）
Layer 5 — Archive:   已归档的长对话（提供索引/引用，不展开）
```

**组装策略**：从 Layer 0 → Layer 4 依次填充，直到触达 `ContextBudget` 上限。
Layer 5 不展开，仅提供 ArtifactRef 供搜索召回。

## 4. 外部文档化

### 4.1 文档存储

```
对话历史
 ├─ 活跃会话（浏览器 IndexedDB / OPFS）
 │   ├─ messages.json（元数据 + 头部/尾部消息）
 │   └─ artifacts/（大块 tool 输出、图片 base64、长代码）
 ├─ 外部文档（持久化存储，可选云端）
 │   ├─ {session_id}.summary.yaml（结构化摘要）
 │   ├─ {session_id}.full.jsonl（全量归档 JSONL）
 │   └─ {session_id}.artifacts/（大块引用）
 └─ 索引（关键词 → session_id + message_id）
```

### 4.2 摘要文档生成（未来）

当对话达到一定规模时，可选（用户触发或自动）生成对话摘要文档：

```yaml
# session_summary.yaml
session_id: "eos-xxxxx"
created_at: "2026-06-02T10:00:00Z"
provider: "deepseek"
model: "deepseek-chat"
message_count: 47
token_total: ~32000
topics:
  - "架构设计讨论"
  - "Prism 路由策略"
decisions:
  - topic: "路由插件化方案"
    consensus: "WASM first"
    ref: ["msg-23", "msg-25", "msg-28"]
attachments:
  - type: "code"
    path: "artifacts/prism-route-trait.rs"
    ref: "msg-31"
```

这个摘要文档本身可以注入为新会话的 system prompt 前缀（Layer 3），让新对话"知道谈过什么"。

### 4.3 外部文档召回（Phase 3+）

在新对话中，如果用户提问触发了关键词匹配，可以选择性地将历史对话的 **相关片段** 召回注入当前上下文：

```
用户: "上次我们讨论的路由策略方案，最终选了哪个？"
     ↓
查询索引 → 匹配 session=xxx 的 decision 条目
     ↓
召回包含 msg-23/25/28 的压缩消息块
     ↓
注入到当前请求 `messages` 的 Layer 2（Relevant）
```

## 5. Eos / Vela / Prism 中的职责

| 产品 | 职责 |
|------|------|
| **Eos 浏览器端** | IndexedDB 存储、SessionMirror 扩展（Priority 标注）、摘要生成触发 |
| **Vela 客户端** | 同上 + 可选 E2E 加密同步到云端（Phase 3） |
| **Prism** | 不存储对话内容。仅元数据（UsageRecord）涉及 token 统计。外部文档化完全是客户端侧业务 |
| **ai-lib-rust** | `MessageAssembler` 可选接受 Priority 标注输入（trait 扩展点），但核心不绑定分层模型 |

## 6. 分阶段落地路径

| 阶段 | 内容 | 依赖 |
|------|------|------|
| **Phase 2 Immediate** | `SessionMirror` priority 字段 + `MessageAssembler` 接收 priority-aware 裁剪信号 | 已完成（EOS-P2-001） |
| **Phase 2+ | A** | 消息 Priority 标注 UI（用户可标记"这条重要"）+ 自动标注（代码、决策语句） | Phase 2.5 |
| **Phase 2+ | B** | 摘要文档生成（前端触发）+ 外部文档存储索引 | Phase 2.5 |
| **Phase 3 | A** | 外部文档检索注入（检索→召回→注入 Layer 2） | Phase 3 |
| **Phase 3 | B** | 跨会话上下文继承（新对话加载旧摘要） | Phase 3 |

## 7. 不做的事情

- ❌ LLM 生成对话总结（用确定性摘要，避免质量波动和 compaction loop）
- ❌ Prism 存储对话内容（客户端责任）
- ❌ JavaScript 中的 Token 计数精确到字节（用 ai-lib-rust WASM 提供的 `estimate_tokens` 即可）

## 8. 验收准则（远期）

- 一次 200 轮的对话，`ContextBudget` 组装后 < 16K tokens，但关键决策点不丢失
- 新对话输入"上次那个方案选的是什么"，能召回历史相关片段
- 浏览器 IndexedDB 存储 100+ 长对话无性能退化
