# tools 工具索引

> 用于沉淀可复用的脚本与程序，避免重复造轮子。

## 使用约定

- 新增工具时，必须同步更新本索引。
- 工具说明需包含：用途、输入参数、示例、风险提示。
- 涉及破坏性操作（如 `reset --hard` / `clean -fd`）必须明确标注。
- 与 ai-lib 生态相关的工具优先放在 `ai-lib-plans/tools/` 统一管理。

## 治理文档

## `docs/engineering/VENDORED_BUILD_TOOL_BINARIES.md`

- **用途**: 记录在 Git 内嵌 **构建工具二进制**（如 wasm-pack / wasm-bindgen）时的必选元数据：平台、上游版本、SHA-256、更新流程；（规则编号 **PL-ENGINE-019**）
- **适用范围**: eos、Prism 侧构建链及任何为解决 CI 网络所做的 vendoring
- **落地示例**: `hiddenpath/eos` 根目录 `wasm-pack-bin` / `wasm-bindgen-bin`（见 `docs/engineering/VENDORED_BUILD_TOOL_BINARIES.md`）

## `active/projects/infra/LAN_INFRA.md`

- **用途**: GOV-005 基础设施详表——设备、bare 仓清单、CI 分层、双重备份架构
- **任务索引**: `active/projects/infra/TASKS_INDEX.md`
- **关联**: GOV-005-lan-infra.yaml、LAN_GIT.md

## `docs/governance/LAN_GIT.md`

- **用途**: 闭源/内网仓库日常协作规范（GOV-004 试运行）：`lan` 主 remote、`origin` 备份/CI 双头（eos）
- **适用范围**: ai-lib-constitution, ai-lib-plans, papers, eos, ai-lib-gateway
- **规则**: `ai-lib-constitution/rules/governance/GOV-004-lan-git-dual-remote.yaml`
- **关联**: GOV-001（公开仓 ailib-official）、REMOTE_MIGRATION.md（公开仓迁移）

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

## `ubuntu_dev_disk_cleanup.sh`

- **路径**: `tools/ubuntu_dev_disk_cleanup.sh`
- **用途**: Ubuntu 开发机 **短期、可重复** 腾出磁盘空间；面向开发机：用户临时目录、apt 缓存、残余内核包、snap 旧版本、包管理器缓存（npm/pip/cargo/go）、浏览器缓存（Chrome/Playwright）、回收站、systemd journal、缩略图、JetBrains 旧版数据、字体缓存、node-gyp 缓存。仅白名单路径（不碰仓库、`.rustup/toolchains`、IDE 扩展树等）。融合 `~/cleansnapd.sh` 的 snap 旧版本清理功能。
- **安全模型**:
  - **默认演练**（不加 `--execute`）：只统计体积并报告可用空间，**不删除**。
  - **真实清理**需 **`--execute`**；执行前有确认提示（`-y` 跳过）。
  - **验证**: 对分区 `/` 读取可用空间前后对比并打印 **Delta**。
- **前置**: **bash 4+**、Ubuntu 22.04/24.04；部分操作需 `sudo`（apt clean、残余内核包、journal、/var/tmp）。
- **示例**:
  - 演练全部：`bash tools/ubuntu_dev_disk_cleanup.sh --all`
  - 执行全部：`bash tools/ubuntu_dev_disk_cleanup.sh --all --execute`
  - 仅缓存类：`bash tools/ubuntu_dev_disk_cleanup.sh --npm-cache --pip-cache --cargo-cache --go-cache --execute`
  - 安全项执行：`bash tools/ubuntu_dev_disk_cleanup.sh --user-temp --trash --thumbnails --apt-cache --execute`
  - 含内核清理：`bash tools/ubuntu_dev_disk_cleanup.sh --old-kernels --snap-disabled --apt-cache --journal --execute -y`
- **风险提示**:
  - `--execute` 前建议关闭 IDE 和浏览器；`--old-kernels` 会 purging 残余内核包（dpkg rc 状态）；`--snap-disabled` 需先关闭对应 snap 应用；`--playwright-cache` 删除后下次运行需重新下载驱动。

## `win_dev_disk_cleanup.ps1`

- **路径**: `tools/win_dev_disk_cleanup.ps1`
- **用途**: Windows 本机 **短期、可重复** 腾出 C:（或其它盘报表）空间；面向开发机：**用户 Temp、可选系统 Temp、npm/pip 缓存、可选 AWS CLI / NuGet HTTP 缓存、可选回收站**；**可选高烈度**：**Windows.old**（旧系统目录）、**DISM** 收缩 WinSxS、**卷影副本（还原点）**、传递优化缓存、**WU `SoftwareDistribution\Download`**。
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
  - **激进（须管理员 `-Execute`）示例**：旧系统 + WinSxS + 还原点 + 传递优化 + WU 下载缓存：  
    `powershell.exe -NoProfile -ExecutionPolicy Bypass -File D:\ai-lib-plans\tools\win_dev_disk_cleanup.ps1 -Execute -IncludeWindowsOldRemoval -IncludeDismComponentCleanup -IncludeVolumeShadowCopies -IncludeDeliveryOptimizationCache -IncludeWindowsUpdateDownloadCache`
  - **更激进 WinSxS**（清理后通常无法卸载此前累积更新）：追加 `-IncludeDismResetBase`（可替代单独 `IncludeDismComponentCleanup`，或与之一同用时以 ResetBase 为准）。
- **风险提示**:
  - `-Execute` 前建议关闭 IDE/安装程序；`-ClearRecycleBin` 会清空该盘回收站。
  - `-IncludeWindowsOldRemoval`：无法再回滚到上一版本 Windows；`-IncludeVolumeShadowCopies`：删除该盘 **全部** 还原点；`-IncludeDismResetBase`：WinSxS 极简基底，**丢卸载更新能力**；`-IncludeWindowsUpdateDownloadCache`：勿在系统正在安装更新时执行。

## `win_appdata_relocate_to_drive.ps1`

- **路径**: `tools/win_appdata_relocate_to_drive.ps1`
- **用途**: 把 **Cursor / VS Code Roaming / Chrome User Data / OpenCode 桌面 Roaming / `.rustup`+`.cargo`** 从 C: **迁到 D:**（或任意 `TargetRoot`）：除 Rust 外均为 **目录联接（junction）**；Rust 用环境变量。
- **与 WinSxS**: **不能把** `C:\Windows\WinSxS` 整体迁盘；仅能 **提升权限** 后用 `win_dev_disk_cleanup.ps1` 的 `-IncludeDismComponentCleanup` / `-IncludeDismResetBase` **收缩**（不能当「搬家」）。
- **安全模型**: 默认 **演练**；**`-Execute`** 才 `robocopy`、重命名原目录为 `*_relocate_backup_*`、`mklink /J`（或写环境变量）。执行前须 **退出** 对应程序（可用 `-SkipProcessCheck` 跳过检查，不推荐）。
- **已知坑**: 见配套文档 [`APPDATA_RELOCATE_LESSONS.md`](APPDATA_RELOCATE_LESSONS.md)
  - Electron WAL 模式 SQLite：进程未退出时复制导致 DB 损坏
  - CacheStorage NTFS 特殊权限：`takeown` + `icacls` 也无法删除，须用全新路径
  - 迁移后自动清理 `*-shm`/`*-wal`/`LOCK` 残留
- **示例**:
  - 演练：`powershell.exe -NoProfile -ExecutionPolicy Bypass -File D:\ai-lib-plans\tools\win_appdata_relocate_to_drive.ps1 -TargetRoot D:\ProfileMigrate -All`
  - 执行：`... -TargetRoot D:\ProfileMigrate -All -Execute`
  - 单项：`-Cursor`、`-VSCode`、`-ChromeUserData`、`-MigrateOpenCode`、`-Rust`
- **风险提示**: 先 **DRY-RUN**；`robocopy`/联接失败会尝试恢复原名；确认 Cursor/Chrome/编译正常后再 **手动删** `*_relocate_backup_*` 以真正释放 C:；Rust 后需 **重新登录或新开终端** 再运行 `where.exe rustc`。

## `deploy_eos.sh`

- **路径**: `tools/deploy_eos.sh`
- **用途**: Eos（逸思）一键 Docker 部署脚本，自动化完整部署流水线：git pull → docker build → docker save → scp 上传 → 远程 docker load + 容器重启 + 健康检查
- **目标服务器**: `43.159.226.236`（CentOS 7），Caddy 反代 `eos.ailib.info`
- **网络策略**: Docker 构建注入代理（默认 `192.168.2.13:8887`），CN 镜像源（aliyun apt、USTC cargo/rustup）已在 Dockerfile 中固化
- **步骤**:
  1. `git pull --rebase --autostash` 拉取最新代码
  2. `docker build` 带 proxy build-arg 构建镜像
  3. `docker save | gzip` 导出镜像到本地临时文件
  4. `scp` 上传镜像到远程服务器
  5. SSH 远程执行：`docker load` → 停止旧容器 → `docker run` 启动新容器 → 健康检查 `/health` → 清理远程镜像文件
  6. 清理本地临时镜像文件
- **示例**:
  - 完整部署：`bash tools/deploy_eos.sh`
  - 跳过 git pull：`bash tools/deploy_eos.sh --skip-pull`
  - 演练模式：`bash tools/deploy_eos.sh --dry-run`
  - 自定义远程服务器：`bash tools/deploy_eos.sh --remote 1.2.3.4 --remote-pass mypass`
  - 仅重新构建（不上传）：`bash tools/deploy_eos.sh --skip-upload --skip-restart`
- **前置依赖**: `docker`, `sshpass`（若用密码认证）, `scp`, `ssh`, `git`
- **风险提示**:
  - 远程部署会 `docker stop/rm` 同名容器，短暂服务中断
  - `--remote-pass` 参数会出现在进程列表中，生产环境建议使用 SSH key 认证（设 `REMOTE_PASS` 环境变量或省略以用 key）
  - 健康检查最多等待 10 秒，超时仅警告不阻断

## `deploy_prism_gateway.sh`

- **路径**: `tools/deploy_prism_gateway.sh`
- **用途**: Prism **ai-lib-gateway** compose 部署（PR-P1-006 / P1-C）：本地 `git pull --rebase` → rsync 到远程 → `docker compose up --build`
- **与 Eos 区别**: 不部署 `eos.ailib.info` / `/api/proxy`；目标目录默认 `/opt/ai-lib-gateway`
- **前置**: 远程 `.netrc.local`（hiddenpath/eos docker build）、`.env`（provider keys + gateway/admin token）
- **示例**:
  - `bash tools/deploy_prism_gateway.sh --remote 1.2.3.4`
  - `bash tools/deploy_prism_gateway.sh --remote 1.2.3.4 --profile tls --production`
  - `bash tools/deploy_prism_gateway.sh --remote 43.159.226.236 --path-b1`（PR-P1-017：与 Eos 共享 VPS，loopback :18080 + 主机 Caddy）
  - `bash tools/deploy_prism_gateway.sh --remote 1.2.3.4 --profile tls --dry-run`
- **风险提示**: 远程 `docker compose up` 会重启 gateway；生产 Path A 用 `--production`；共享 VPS 用 `--path-b1` 后需 `scripts/add-prism-to-eos-caddy.sh`；HTTPS 验收依赖 PR-P1-013 DNS

## `sync_compliance_registry.py`

- **路径**: `tools/sync_compliance_registry.py`
- **用途**: 校验 `data/compliance/registered_models.yaml` 结构（EOS-ARCH-R5）；Phase 1 为手工维护 + 校验，不抓取 CAC 页面
- **示例**: `python tools/sync_compliance_registry.py`
- **自定义路径**: `python tools/sync_compliance_registry.py --path data/compliance/registered_models.yaml`
- **依赖**: PyYAML (`pip install pyyaml`)
- **风险提示**: 无网络/写操作；校验失败时退出码 1

## `email_skill.py` / `send_outbox_email.py` / `tools/outbox/`

- **用途**: 从 `tools/outbox/*.txt` 发送运营/前置清单邮件（默认收件人见 `email_skill.DEFAULT_RECIPIENT`）
- **依赖**: Linux/WSL 上 `/home/alex/send_mail_simple.py`（Windows 本机若无 Python3 请在 WSL 执行）
- **示例**:
  - `cd tools && python3 send_outbox_email.py outbox/EMAIL_manual-prerequisites_2026-06-04_prism-p1.txt --subject '[ai-lib] Prism P1 线下前置清单 (2026-06-04)'`
- **outbox 约定**: 文件名 `EMAIL_<topic>_<YYYY-MM-DD>_<tag>.txt`；正文 UTF-8

## `push_private_repos_to_lan_git.py`

- **路径**: `tools/push_private_repos_to_lan_git.py`
- **用途**: 将闭源仓库（constitution / plans / papers / eos / gateway）初始化 bare 仓并推送到内网 Git 服务器（默认 `git-server.local`，用户 `git`）；自动部署 SSH 公钥到服务器 `authorized_keys`，本地添加 `lan` remote
- **示例**: `python tools/push_private_repos_to_lan_git.py`
- **Remote 格式**: `ssh://git@git-server.local/srv/git/repos/<name>.git`（服务器 bare 根目录 `/srv/git/repos/`；别名 `lan-git` / `192.168.2.22` 同主机）
- **后续推送**: `git push lan <branch>`（需 `GIT_SSH_COMMAND='ssh -i ~/.ssh/id_ed25519_lan_git -o IdentitiesOnly=yes'` 或配置 `~/.ssh/config`）
- **风险提示**: 首次运行会在服务器创建 bare 仓并写入 SSH 公钥；无 commit 的仓库（如 ai-lib-gateway）会跳过

## `APPDATA_RELOCATE_LESSONS.md`

- **路径**: `tools/APPDATA_RELOCATE_LESSONS.md`
- **用途**: 2026-05-10 实战经验总结。记录迁移 Cursor/VS Code/Chrome/OpenCode User Data 时的关键坑：WAL 模式 SQLite、CacheStorage NTFS、robocopy 引号、`ai.opencode.desktop` 与 `Split-Path -Leaf` 绑定异常等；含安全迁移流程与验证清单。
