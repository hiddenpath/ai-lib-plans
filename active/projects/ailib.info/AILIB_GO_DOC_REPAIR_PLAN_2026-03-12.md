# ailib.info Go 文档修复执行计划（2026-03-12）

## 1. 背景与目标

基于本轮严格审查，`ailib.info` 中 Go 运行时内容存在多处高风险偏差：  
- Go 页面串入 Rust 文案、链接和示例代码；  
- Go 文档示例 API 与 `ai-lib-go` 公开接口不一致；  
- 版本信息前后冲突，影响发布可信度。  

本计划目标是完成一次“事实一致性修复”闭环：页面文案、代码示例、导航链接、版本描述与 `ai-lib-go` 当前发布基线对齐，并可通过构建验证。

## 2. 治理约束

- [DOC-001] 内部执行文档使用中文；对外文档内容需准确可用。  
- [DOC-002] 计划/执行记录仅保留在 `ai-lib-plans`。  
- [ARCH-003] 跨运行时描述必须保持一致口径，不制造虚假能力差异。  

## 3. 范围定义

### 3.1 In Scope（本次必须完成）

1. Go 首页（EN/ZH/JA/ES）修复：  
   - 标题/描述中的 Rust 残留清理；  
   - Quick Start/CTA 路径从 `/rust/...` 改为 `/go/...`；  
   - 示例代码替换为真实 Go 代码片段；  
   - 模块介绍中 Rust 专有词（如 `reqwest`、`trait`）替换为 Go 对应语义。  

2. Go 文档核心页修复（四语种）：  
   - `quickstart.md`  
   - `client.md`  
   - 与真实 API 不一致的关键片段统一替换为 `pkg/ailib` 用法。  

3. 版本口径统一：  
   - 页面与文档中对 Go 版本表达保持一致（发布版 `v0.0.1` 与“能力开发状态”分开描述）。  

4. 验证与回填：  
   - `npm run build` 通过；  
   - 回填任务执行证据与已改文件清单。  

### 3.2 Out of Scope（后续批次）

- guides 页签体系新增 Go Tab 的全量扩展（作为第二批次）；  
- 更细粒度术语润色和营销文案优化。  

## 4. 执行分批

### 批次 A（立即执行）

- 修复 `src/pages/**/go/index.astro` 的串台问题。  
- 修复 `src/content/docs/**/go/quickstart.md`。  
- 修复 `src/content/docs/**/go/client.md`。  
- 构建验证并记录。  

### 批次 B（紧随其后）

- 深修 `streaming.md` / `resilience.md` / `advanced.md` 的 API 真实性。  
- 扩展 guides 的 Go 示例（若确认本轮继续）。  

## 5. 验收标准

1. Go 页面不再出现 Rust 路径与 Rust 代码。  
2. 示例代码可映射到 `ai-lib-go/pkg/ailib` 实际接口。  
3. 四语种关键页面语义一致。  
4. 构建通过，且无新增阻断问题。  

## 6. 风险与回滚

- 风险：多语种批量替换易产生局部遗漏。  
- 控制：先统一结构化替换，再逐文件抽检。  
- 回滚：按文件粒度回退（不做破坏性仓库级回退）。  

## 7. 当前进度

- [x] 预同步 `ai-lib-plans`（pre-plan）  
- [x] 审查确认问题清单  
- [x] 任务 `AILIB-002` 置为 `in_progress` 并补齐执行人信息  
- [x] 批次 A 代码修复  
- [x] 构建验证与证据回填  
- [x] 批次 B 已启动（`streaming.md` / `advanced.md` 四语种已完成第一轮纠偏）  
- [ ] 版本口径统一与 guides Go Tab 扩展决策  

