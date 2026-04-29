# tools 工具索引

> 用于沉淀可复用的脚本与程序，避免重复造轮子。

## 使用约定

- 新增工具时，必须同步更新本索引。
- 工具说明需包含：用途、输入参数、示例、风险提示。
- 涉及破坏性操作（如 `reset --hard` / `clean -fd`）必须明确标注。
- 与 ai-lib 生态相关的工具优先放在 `ai-lib-plans/tools/` 统一管理。

## 治理文档

## `docs/governance/REMOTE_MIGRATION.md`
- **用途**: 远端迁移指令（GOV-001 v2）——所有编程代理在操作公开仓库前必须检查 `origin` 是否指向 `ailib-official/*`，若仍指向 `hiddenpath/*` 则立即重指向
- **适用范围**: ai-protocol, ai-lib-rust, ai-lib-python, ai-lib-ts, ai-lib-go, ai-protocol-mock
- **不适用**: ai-lib-constitution, ai-lib-plans, papers（保持 hiddenpath；papers 为私有论文仓）
- **关联规则**: GOV-001 v2.0, TEST-002 v2.0, AGENTS.md

## 工具列表

## `sync_ai_lib_plans.sh`
- **路径**: `tools/sync_ai_lib_plans.sh`（仓库根为 `ai-lib-plans` 时也可用绝对路径，例如 Windows：`bash "D:/ai-lib-plans/tools/sync_ai_lib_plans.sh"`）
- **用途**: 同步 `ai-lib-plans` 本地与远程仓库（`fetch -> pull --rebase`，可选 `push`）
- **网络策略**: 脚本内显式注入代理（默认 `192.168.2.13:8887`），不依赖 `~/.bashrc` 全局代理
- **对应自动化规则**:
  - 开始编制计划前执行：`--mode pre-plan`
  - 文档变更并提交后执行：`--mode post-doc-change --push-if-ahead`
- **示例**:
  - 计划前同步：`bash tools/sync_ai_lib_plans.sh --mode pre-plan`
  - 文档变更后同步并推送：`bash tools/sync_ai_lib_plans.sh --mode post-doc-change --push-if-ahead`
  - Windows（Git Bash，无脚本内显式代理）：`bash tools/sync_ai_lib_plans.sh --mode post-doc-change --push-if-ahead --no-explicit-proxy`
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

## `slack_file_tool.py`

- **路径**: `tools/slack_file_tool.py`
- **用途**: 从Slack下载文件附件
- **功能**:
  - 列出最近的文件
  - 下载指定文件
  - 获取文件详细信息
- **依赖**:
  - Python 3.12+
  - `slack_sdk` (已安装)
  - `requests` (已安装)
- **前置要求**:
  - Slack Bot需要 `files:read` 权限（当前缺失，需在Slack管理界面添加）
- **示例**:
  - 列出最近10个文件：`source tools/venv/bin/activate && python tools/slack_file_tool.py list --limit 10`
  - 下载文件：`source tools/venv/bin/activate && python tools/slack_file_tool.py download <file_id>`
  - 获取文件信息：`source tools/venv/bin/activate && python tools/slack_file_tool.py info <file_id>`
- **风险提示**:
  - 需要Slack Bot权限配置，否则会返回 `missing_scope` 错误
  - 下载的文件默认保存到 `/home/alex/Downloads/slack/`

## `browser_automation.js`
- **路径**: `tools/browser_automation.js`
- **用途**: Playwright 浏览器自动化，用于动态网页访问、表单交互、截图、内容提取
- **功能**:
  - 动态网页渲染（JavaScript SPA 支持）
  - 表单填写与提交
  - 页面截图（全页面或部分）
  - 内容提取（文本、HTML、属性）
  - JavaScript 执行
  - 网络请求监控
  - Cookie 与存储管理
- **依赖**:
  - Node.js 18+
  - `playwright` npm 包
  - Chromium 驱动（约 280MB）
- **安装**:
  ```bash
  cd /path/to/project
  npm install playwright
  npx playwright install chromium
  ```
- **示例**:
  ```javascript
  const { BrowserAutomation } = require('./browser_automation.js');
  
  async function demo() {
    const browser = new BrowserAutomation();
    await browser.launch();
    const page = await browser.newPage();
    
    // 访问网页
    await browser.goto(page, 'https://example.com');
    
    // 提取内容
    const text = await browser.getText(page, 'h1');
    
    // 截图
    await browser.screenshot(page, '/tmp/screenshot.png');
    
    await browser.close();
  }
  ```
- **便捷函数**:
  - 快速截图：`quickScreenshot(url, outputPath)`
  - 快速提取：`quickScrape(url, selector)`
- **风险提示**:
  - 无法绕过 CAPTCHA 验证码
  - 登录网站需额外配置凭证
  - 部分网站有反爬虫机制
  - 驱动文件较大（~280MB）

## `win_dev_disk_cleanup.ps1`

- **路径**: `tools/win_dev_disk_cleanup.ps1`
- **用途**: Windows 本机 **短期、可重复** 腾出 C:（或其它盘报表）空间；面向开发机：**用户 Temp、可选系统 Temp、npm/pip 缓存、可选 AWS CLI / NuGet HTTP 缓存、可选回收站**。仅白名单路径（不碰仓库、`.rustup`、IDE 扩展树等）。
- **安全模型**:
  - **默认演练**（不加 `-Execute`）：只统计体积并报告可用空间，**不删除**、不执行 `npm cache clean` / `pip cache purge`。
  - **真实清理**需 **`-Execute`**；临时目录只删子项，**锁定的文件会跳过**。
- **验证**: 对指定盘符读取 **FreeSpace** 前后对比并打印 **Delta**。
- **前置**: **Windows PowerShell 5.1+**（`powershell.exe`）；脚本 `#requires 5.1`。未单独安装 **PowerShell 7** 时 **没有 `pwsh` 命令**，请用下面 `powershell.exe` 行。
- **示例**（路径按本机修改；在 `ai-lib-plans` 根目录可用 `tools\win_dev_disk_cleanup.ps1`）:
  - 演练：`powershell.exe -NoProfile -ExecutionPolicy Bypass -File D:\ai-lib-plans\tools\win_dev_disk_cleanup.ps1`
  - 已安装 PS7 时可选：`pwsh -NoProfile -File D:\ai-lib-plans\tools\win_dev_disk_cleanup.ps1`
  - 执行 + 回收站：`powershell.exe -NoProfile -ExecutionPolicy Bypass -File D:\ai-lib-plans\tools\win_dev_disk_cleanup.ps1 -Execute -ClearRecycleBin`
  - 可选：`-IncludeAwsCliCache`、`-IncludeNuGetHttpCache`、管理员下 `-IncludeWindowsTemp`、`-DriveLetter D`
- **风险提示**:
  - `-Execute` 前建议关闭 IDE/安装程序；`-ClearRecycleBin` 会清空该盘回收站。
