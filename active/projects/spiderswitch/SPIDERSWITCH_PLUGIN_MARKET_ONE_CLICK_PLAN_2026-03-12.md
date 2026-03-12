# spiderswitch 插件市场一键安装三阶段实施计划（2026-03-12）

## 目标

将 `spiderswitch` 从“可运行 MCP 服务”提升到“插件市场可一键安装、可快速验证、可回滚”的产品化交付形态。

## 阶段划分

### 阶段一（MS-010）— 安装引导与运维入口标准化

- 交付 `spiderswitch serve/init/doctor` 统一 CLI
- 提供初始化配置模板输出能力（面向 Cursor/Claude/OpenCode）
- 提供可机器消费的健康检查输出（`doctor --json`）

### 阶段二（MS-011）— 插件市场分发包装

- 增加插件市场 manifest（元信息、入口命令、配置项、安装与验证指令）
- 增加一键安装脚本（受控 venv、可重复安装）
- 增加发布打包脚本（统一产物目录，便于上架）

### 阶段三（MS-012）— 高效验证与回归自动化

- 增加市场化 smoke 验证脚本（安装后快速检查）
- 增加 CLI 与 manifest 相关测试
- 将“安装-初始化-验证”闭环固化到文档与 CI 可复用命令

## 验收标准

1. 用户可通过单命令安装脚本完成本地可执行环境准备
2. 用户可通过 `spiderswitch init` 生成 MCP 配置模板
3. 用户可通过 `spiderswitch doctor --json` 获得结构化健康检查结果
4. 仓库包含可上架描述的 manifest 与 release bundle 产物脚本
5. pytest/ruff/mypy 全量通过

## 风险与应对

- 风险：不同平台路径差异导致配置模板不可直接复用  
  - 应对：模板中保留变量占位与明确注释
- 风险：用户环境缺失 `ai-protocol` 导致首次检查失败  
  - 应对：doctor 输出 action hint，不阻断安装流程
- 风险：市场 schema 差异  
  - 应对：manifest 采用“通用字段 + 可扩展字段”并提供校验脚本

## 执行顺序

1. 建立任务卡与 project-overview 跟踪
2. 先做 CLI/doctor/init（阶段一）
3. 再做 manifest/安装脚本/打包脚本（阶段二）
4. 最后做验证脚本与测试补齐（阶段三）
5. 回填任务状态与测试结果，立即同步 `ai-lib-plans` 远程
