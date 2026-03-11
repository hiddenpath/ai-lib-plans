# tools 工具索引

> 用于沉淀可复用的脚本与程序，避免重复造轮子。

## 使用约定

- 新增工具时，必须同步更新本索引。
- 工具说明需包含：用途、输入参数、示例、风险提示。
- 涉及破坏性操作（如 `reset --hard` / `clean -fd`）必须明确标注。
- 与 ai-lib 生态相关的工具优先放在 `ai-lib-plans/tools/` 统一管理。

## 工具列表

## `sync_ai_lib_plans.sh`
- **路径**: `tools/sync_ai_lib_plans.sh`
- **用途**: 同步 `ai-lib-plans` 本地与远程仓库（`fetch -> pull --rebase`，可选 `push`）
- **网络策略**: 脚本内显式注入代理（默认 `192.168.2.13:8887`），不依赖 `~/.bashrc` 全局代理
- **对应自动化规则**:
  - 开始编制计划前执行：`--mode pre-plan`
  - 文档变更并提交后执行：`--mode post-doc-change --push-if-ahead`
- **示例**:
  - 计划前同步：`bash tools/sync_ai_lib_plans.sh --mode pre-plan`
  - 文档变更后同步并推送：`bash tools/sync_ai_lib_plans.sh --mode post-doc-change --push-if-ahead`
  - 自定义代理端口：`bash tools/sync_ai_lib_plans.sh --mode manual --http-proxy-port 8887 --https-proxy-port 8887`
  - 不注入代理：`bash tools/sync_ai_lib_plans.sh --mode manual --no-explicit-proxy`
  - 演练模式：`bash tools/sync_ai_lib_plans.sh --mode pre-plan --dry-run`
- **风险提示**:
  - 脚本使用 `pull --rebase --autostash`，在复杂冲突场景下需要人工处理 rebase 冲突。

## `sync_repos_serial.sh`
- **路径**: `tools/sync_repos_serial.sh`
- **用途**: 串行同步多个仓库到各自上游分支（`fetch -> reset --hard -> clean -> status`）
- **网络策略**: 脚本内显式注入代理（默认 `192.168.2.13:8887`），不依赖 `~/.bashrc` 全局代理
- **特点**:
  - 串行执行，避免批处理卡死影响全局
  - 支持 `fetch` 超时与重试
  - 支持 `--dry-run` 与 `--no-clean`
- **默认仓库**:
  - `/home/alex/ai-lib-go`
  - `/home/alex/ailib.info`
  - `/home/alex/ai-lib-constitution`
  - `/home/alex/ai-lib-plans`
  - `/home/alex/ai-lib-python`
  - `/home/alex/ai-lib-rust`
  - `/home/alex/ai-lib-ts`
  - `/home/alex/ai-protocol`
  - `/home/alex/ai-protocol-mock`
- **示例**:
  - 全量同步：`bash tools/sync_repos_serial.sh`
  - 单仓库同步：`bash tools/sync_repos_serial.sh --repo /home/alex/ai-lib-go`
  - 自定义代理端口：`bash tools/sync_repos_serial.sh --http-proxy-port 8887 --https-proxy-port 8887`
  - 不注入代理：`bash tools/sync_repos_serial.sh --no-explicit-proxy`
  - 保留未跟踪文件：`bash tools/sync_repos_serial.sh --no-clean`
  - 演练模式：`bash tools/sync_repos_serial.sh --dry-run`
- **风险提示**:
  - 默认会执行 `reset --hard` 和 `clean -fd`，会丢弃本地未提交改动和未跟踪文件。
