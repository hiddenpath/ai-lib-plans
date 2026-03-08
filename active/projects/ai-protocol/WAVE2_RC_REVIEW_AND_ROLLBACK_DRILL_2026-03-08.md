# Wave-2 RC Review & Rollback Drill（2026-03-08）

## 1. RC Scope

- 范围：`PT-025` ~ `PT-029` 交付链路（protocol gate、load compliance、manifest shape、mock lifecycle、CI governance）
- 目标：形成可审计的 go/hold/no-go 输入，并完成至少 1 次可复盘回滚演练

## 2. RC Checklist

### 2.1 Protocol / Governance

- [x] `ai-protocol` drift 检测支持 report-first，报告可归档
- [x] `ai-protocol` release gate 支持 report-first，报告可归档
- [x] CI workflow 已接入治理报告任务（`governance-report.yml`）

### 2.2 Runtime Alignment（Rust / Python / TS）

- [x] `load-*` compliance 在三运行时均进入可执行强校验路径
- [x] V2 manifest shape 兼容矩阵在三运行时有测试覆盖并通过
- [x] latest generative manifest consumption 回归持续通过

### 2.3 Mock / Docs

- [x] 视频生命周期含 `succeeded/failed/cancelled` 终态语义
- [x] 终态控制头与文档说明已更新
- [x] mock 全量测试通过（含新增终态用例）

## 3. Rollback Drill Record

### 3.1 Drill Goal

验证“门禁阻断 -> 降级到 report-only -> 保持证据归档”的闭环可执行性。

### 3.2 Drill Timeline

1. **T0**：执行阻断场景（故意失败输入）  
   命令：`node scripts/release-gate.js --input=scripts/release-gate-input.rollback-drill.json`  
   结果：`exit_code=1`，`status=blocked`
2. **T1**：执行回滚降级（report-only）  
   命令：`node scripts/release-gate.js --input=scripts/release-gate-input.rollback-drill.json --report-only`  
   结果：`exit_code=0`，`status=blocked`（仅报告，不阻断）
3. **T2**：验证基线输入  
   命令：`node scripts/release-gate.js --report-only`  
   结果：`status=pass`

### 3.3 Evidence

- `ai-protocol/reports/release-gates/release-gate-2026-03-07T17-54-57-182Z.json`（阻断场景）
- `ai-protocol/reports/release-gates/release-gate-2026-03-07T17-55-15-051Z.json`（回滚降级）
- `ai-protocol/reports/release-gates/release-gate-2026-03-07T17-53-55-884Z.json`（基线通过）

## 4. Risk Classification（Go/Hold/No-Go Inputs）

- **Go**
  - PT-025/026/027/028/029 关键验收链路已具备证据
  - report-first 治理模式可运行且可回放
- **Hold**
  - `PT-030` 后续周次仍需滚动补齐“真实发布窗口”演练样本
- **No-Go Trigger**
  - 任一关键链路（manifest consumption / load compliance / drift gate）连续失败且超 48h 未闭环

## 5. Recommendation

- 建议当前结论：**Go（with report-first policy）**
- 下阶段策略：保持 report-first 两个稳定周期，再评估 `required` 升级窗口
