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

## `url_reference_hygiene.py`
- **路径**: `tools/url_reference_hygiene.py`
- **用途**: 扫描并可选修复公开 URL 中的 `hiddenpath` 残留，统一到 `ailib-official`
- **默认检查模式**:
  - 检测以下公共 URL 前缀：
    - `https://github.com/hiddenpath/`
    - `https://raw.githubusercontent.com/hiddenpath/`
    - `https://api.github.com/repos/hiddenpath/`
  - 默认排除：`.github/workflows/**`、`**/go.mod`（开发侧例外）
- **示例**:
  - 仅检查（失败返回非 0）：`python tools/url_reference_hygiene.py .`
  - 自动修复：`python tools/url_reference_hygiene.py . --fix`
  - 指定目录：`python tools/url_reference_hygiene.py ../ai-protocol ../ai-lib-rust`
- **配套模板**:
  - `templates/ci/url-reference-hygiene.yml`（PR/Push 检查 + 手动触发 autofix）
- **风险提示**:
  - `--fix` 会原地改写文件，建议在独立分支执行并通过 PR 合并。

## `build_paper.sh`

- **路径**: `tools/build_paper.sh`
- **用途**: 论文 LaTeX 项目编译脚本，遵循 DOC-003 规范
- **编译器**: `pdflatex`（无 shell-escape，无 minted）
- **编译序列**: `pdflatex → bibtex → pdflatex → pdflatex`
- **适用项目**: `papers` 仓库下的论文目录
- **示例**:
  - 编译 paper1：`bash tools/build_paper.sh /home/alex/papers/EN/paper1_cursor`
  - 清理后编译：`bash tools/build_paper.sh /home/alex/papers/EN/paper1_cursor --clean`
  - 仅检查依赖：`bash tools/build_paper.sh /home/alex/papers/EN/paper1_cursor --check-deps`
- **前置依赖**:
  - `pdflatex` (texlive-latex-recommended)
  - `bibtex` (texlive-bibtex-extra)
  - `lmodern` (texlive-fonts-recommended)
- **风险提示**:
  - `--clean` 会删除 `*.aux`, `*.log`, `*.bbl`, `*.blg`, `*.out`, `*.toc` 等中间文件
