# Eos × ai-lib — 上下文策略层边界说明（浏览器 SKU）

**日期**：2026-05-22  
**状态**：规划基线（与 `MEMORY.md` 同日条目对齐）  
**关联任务**：`tasks/EOS-P2-001-context-strategy-browser.yaml`，上游 `active/projects/ai-protocol/tasks/PT-075-*`、`active/projects/ai-lib-rust/tasks/ALR-P2-001-*`

---

## 1. 要解决什么问题

- 用户在同一会话中切换模型或由编排器分拆子任务时，**小窗口模型**会因历史 + **tool output 膨胀**而溢出。
- 仅靠「LLM 总结历史」易产生质量与 **compaction 循环** 风险；应在运行时优先用 **确定性** 手段控体积。

---

## 2. 分层职责（必须与 Velaclaw / Prism 解耦）

| 层 | 职责 | 不写什么 |
|----|------|----------|
| **ai-protocol（模型元数据）** | `context_window`、`max_output`（等价 token 上限）等与 **提供商文档对齐**的数字；校验与合规测试 | 不定义裁剪算法、不写 `ContextProfile` |
| **共享运行时（如 ai-lib-rust）** | `ContextBudget`、消息组装管线、确定性截断规则、可选 token 计数策略 | 不绑定 Eos 前端框架 |
| **Eos 浏览器宿主（JS + 可选 WASM 纯函数）** | **镜像/索引**：事件 append、artifact ID、配额与淘汰；在读盘侧 **拼装** messages 再交给现有 WASM `build_request` | WASM 不负责 OPFS 直接 IO（除非日后显式引入同步 FS API） |
| **Prism（未来若接入路由）** | 按容量与成本的 **服务端路由** 可与本产品并行演进；Eos Phase 可先 **仅用 manifest 容量** 做本地筛选 | — |

---

## 3. 浏览器 SKU 特有两条底线

1. **状态与载荷分离**：DAG / checkpoint **小**；大段 tool 输出只保留 **引用**（路径或 ID），按需拉取切块。
2. **容量上限**：单源镜像可加硬顶（例如产品内定几百 MB）；**配额失败**须有可观测降级（丢弃最旧块、阻止发送等），写进验收而非静默丢数据。

---

## 4. 执行顺序建议

参见 `MEMORY.md`（2026-05-22）任务链：**PT-075 → ALR-P2-001 → EOS-P2-001**。

---

## 5. Phase 路线图对照

`project-overview.md` 中 Phase 2（云历史/RAC 等）可与本策略 **并行占位**：先入协议与共享组装模块，再在 Eos 前端接 OPFS/mock，避免在缺 manifest 字段时铺开 UI 魔法数。
