# Manifest Distribution Resilience — 机场订阅模式经验迁移

> 提案日期: 2026-06-16  
> 来源: subcon 项目与 grempt/jmssub 机场订阅系统的交互经验  
> 状态: proposal

## 背景

subcon 项目在维护过程中经历了 grempt 机场多次协议切换：

| 时间 | 协议 | 字段变化 |
|------|------|------|
| ~~2026-05~~ | VLESS (REALITY) | 62 节点 |
| 2026-05 | Shadowsocks | `type: ss`，VLESS 全量移除 |
| 2026-06 | Trojan + anytls | 新增 `sni` 字段，42 anytls 不可用 |

同时发现该机场对同一订阅 URL 返回**不同格式**取决于 User-Agent：
- `clash-verge/2.0` → 433KB Clash YAML（20 节点）
- `v2rayN/6.0` → 14KB base64 链接（20 节点）  
- `python-requests/default` → 712B 元数据占位（0 节点）

这些现象与 ai-lib 的 manifest 分发有结构性相似——Provider 的端点、能力、认证方式同样会随时间变化，客户端需要容忍未知字段、格式迁移和内容协商。

## 提案一：内容协商（Accept-Manifest）

### 现状

ai-lib 的 `capability_profile` 机制是**客户端声明自己的能力级别**（`ios_v1` / `iospc_v1`），服务端根据声明返回匹配的 manifest。但这不是真正的协商——它是"客户端说我是谁"，而不是"客户端说我能接受什么"。

### 建议

引入 `Accept-Manifest: v2,v3` 请求头语义：

```yaml
# 客户端请求
GET /manifests/anthropic.yaml
Accept-Manifest: v2,v3

# 服务端行为：
# - 如果最新版本是 v3：返回 v3 manifest
# - 如果客户端只支持 v2：返回最新的 v2 manifest
# - 如果客户端只支持 v1：服务端可以选择返回 v1 或返回 406 Not Acceptable
```

与现有 `capability_profile` 的关系：`capability_profile` 声明**能力范围**（能做什么），`Accept-Manifest` 声明**格式版本**（能解析什么）。两者正交，互不取代。

### 价值评估

| 维度 | 评分 | 说明 |
|------|------|------|
| 协议稳定性 | ★★★★★ | v3 推出不影响 v2 客户端，零破坏性 |
| 实现成本 | ★★☆ | `ProtocolLoader` 需加请求头 + manifest 分发端需识别 |
| 紧急程度 | ★★☆ | v1→v2 迁移已基本完成，下一次 migration 才是刚需 |
| 对齐 ARCH-001 | ★★★★ | "一切配置皆协议" 延伸到"配置的格式本身也是协议" |

## 提案二：非结构化退化（Unknown Field Tolerance）

### 现状

`ProtocolLoader` 使用 `serde` struct 反序列化 manifest。当 ai-protocol 给 manifest 增加新字段时（如 `reasoning_effort`、`max_context_window`），老版本 `ai-lib-rust` 的 struct 因为没有该字段而导致反序列化失败。

### 机场的做法

subcon 重构后使用 `serde_yaml::Value`——任何未知字段自动忽略，anytls 协议静默跳过，新增 `sni` 字段不需要改代码。

### 建议

manifest 核心字段保持 struct（保证类型安全），扩展字段用 `HashMap<String, Value>` 兜底：

```rust
#[derive(Deserialize)]
struct ProviderManifest {
    // 核心字段：struct 保证正确性
    name: String,
    endpoint: Endpoint,
    capabilities: Capabilities,

    // 扩展字段：任何新 key 都进这里，不报错
    #[serde(flatten)]
    extensions: HashMap<String, serde_yaml::Value>,
}
```

运行时通过 `manifest.extensions.get("reasoning_effort")` 按需读取新字段，字段不存在时不报错。

### 价值评估

| 维度 | 评分 | 说明 |
|------|------|------|
| 向前兼容 | ★★★★★ | manifest 加字段不会让老运行时崩 |
| 实现成本 | ★★☆ | 四个运行时各改一处 struct |
| 紧急程度 | ★★★ | 已有的 v1→v2 迁移依赖多，下次加字段就是现在做 |
| 对齐 ARCH-003 | ★★★★ | 跨运行时一致性——Rust 不报错、Python 也不该报错 |

## 提案三：带内元数据（`_meta` 段）

### 现状

当 provider 行为变更时（如 API 路径迁移、认证方式升级），ai-lib 缺乏带内通知机制。开发者需要关注 GitHub release notes 或 changelog 才能知道 manifest 结构发生了变化。

### 机场的做法

机场在节点列表中嵌入"流量未使用"/"订阅到期"等提示信息，客户端解析时识别并展示给用户。

### 建议

manifest 增加 `_meta` 段：

```yaml
_meta:
  deprecation_notice: "此 manifest 将于 2026-Q4 迁移到 v3 格式"
  suggested_migration: "v3"
  migration_docs: "https://docs.ailib.info/manifest-migration-v3"
  maintainer_contact: "protocol@ailib.info"
```

运行时加载时检测到 `_meta` 后：
- 非空 `deprecation_notice` → `log::warn!()` 输出
- 不影响功能，不抛异常

### 价值评估

| 维度 | 评分 | 说明 |
|------|------|------|
| 运维可观测性 | ★★★★ | manifest 变更不再依赖外部文档 |
| 实现成本 | ★☆☆ | schema 加一个 `_meta` 段，四个运行时处理 |
| 紧急程度 | ★★ | 锦上添花，非 blocker |
| 对齐 BIZ-005 | ★★★ | Phase gate discipline——迁移通知应该在 manifest 里，不是 changelog 里 |

## 商业价值分析

### 1. 降低集成运维成本（Customer Success / DevRel）

机场模式的核心商业逻辑：**一次接入，自动适配。** 用户不需要升级客户端就能使用新协议，无需手动下载新配置。

对 ai-lib 的意义相同：
- 企业客户部署了 `ai-lib-rust v0.9.0`，ai-protocol 发布 v2 manifest——客户**不需要升级 runtime 就能用新 provider**
- 对比竞品（LangChain / OpenAI SDK）：schema 变了必须升级 SDK，生产环境升级周期 2-4 周
- **TCO 优势**：运维成本从"每次 manifest 更新都要协调生产升级"降到"零"

### 2. 防御性产品策略（Competitive Moat）

机场可以随时换协议（VLESS→SS→Trojan）而客户端不需要改动。类比：
- ai-lib 的 OpenAI-compatible driver 如果因为 OpenAI 改 API 而挂了，客户会怪 ai-lib
- 如果 provider manifest 支持运行时协商——"你支持 v1 还是 v2 的 endpoint schema？"——OpenAI 加了一个 `reasoning_effort` 字段不会导致老客户端崩溃
- **竞争护城河**：竞品 SDK 遇到 API 变更→报错/panic；ai-lib→日志 warning + 继续运行

### 3. 多产品线复用（Eos / Vela / Gateway）

Eos（消费者）、Vela（Web 客户端）、ai-lib-gateway（企业代理）共用同一套 manifest。如果 manifest 格式进化：
- 老产品继续用 v2 格式→零影响
- 新产品直接用 v3 格式→零等待
- Gateway 可以同时服务 v2 和 v3 客户端→平滑过渡

**规模效应**：manifest 分发中心的投入（1x）在 N 个产品线上复用（Nx）。

### 4. 开源社区信号（Adoption Funnel）

对开源用户：manifest 格式稳定、不会因为升级 ai-protocol 就 break 现有代码——这降低试用门槛。

对商业客户：manifest `_meta` 段的 deprecation 通知表明"我们有计划的迁移路径"，不是"突然就变了"——这提高企业采购信心。

### 总结

| 提案 | 商业价值 | 实施建议 |
|------|------|------|
| Accept-Manifest | 降低客户运维成本，竞品差异化 | 下一次 manifest 大版本迁移时启用 |
| Unknown Field Tolerance | 防御性产品策略，多产品线兼容 | **立即实施**——改动小，收益大 |
| `_meta` 带内通知 | 开源社区信号，企业采购信心 | 随下一次 manifest schema 更新一起做 |
