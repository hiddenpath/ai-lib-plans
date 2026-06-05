# LAN 基础设施规划与管理规则

生效日期：2026-06-05

## 1. 设备命名与角色

| 主机名 | IP | 硬件 | 角色 |
|--------|----|------|------|
| `alex-S8` | — | x86 PC | 开发终端（不保留代码仓库） |
| `piubt` | 192.168.2.13 | RPi 4B rev 1.5 / 3.7G | Proxy + 工具 + 轻量CI Runner + VelaClaw（将来） |
| `git-server` | 192.168.2.22 | RPi 4B rev 1.1 / 1.8G | Git 主仓库 + 轻量CI Runner + 备份脚本 |

> `git-server` 是本机名，因涉及多处治理依赖（SSH config、remote URL、mDNS、文档引用），**不改名**。

## 2. 仓库管理规则

### 2.1 真相来源（Source of Truth）
- **`git-server` 上的裸仓库是唯一主仓库**，所有私有代码以 LAN 为真相来源。
- 开发终端（`alex-S8`）不再保留仓库副本——每次开发从 LAN clone，完成后 push，本地清理。
- GitHub `hiddenpath` 私有仓库**不再维护**，已有仓库可归档或删除。

### 2.2 公开代码发布
- 开源代码通过 GitHub `ailib-official` 组织发布。
- 发布流程：LAN 主仓库 → 推送到 `ailib-official`（定期手动或脚本触发）。
- LAN 主仓库与 GitHub 公开仓库之间**不做自动同步**，避免意外泄露私有代码。

### 2.3 仓库列表（LAN `git-server`）
- `ai-lib-constitution.git` — 治理规则
- `ai-lib-plans.git` — 项目计划
- `papers.git` — 论文
- `pifan.git` — 风扇控制系统
- `ai-lib-gateway.git` — Prism 网关（待推送）
- `eos.git` — EOS 项目（待推送）
- `tempmon.git` — 温度监控（待推送）

## 3. CI 分层策略

| 层级 | 运行位置 | 内容 | 资源需求 |
|------|---------|------|---------|
| **轻量 CI** | `piubt`（或 `git-server`） | `cargo fmt`、`clippy`、单元测试、git hook 校验 | 低（秒级） |
| **重型 CI** | GitHub Actions | `cargo build --release`、WASM 构建、跨平台测试、release 打包 | 高（云资源） |

**规则**：
- 私有仓库的验证性构建（"能编译过"）在 LAN 上由轻量 CI 完成。
- 公开发布的重型构建走 GitHub Actions，避免占用本地 CPU/内存影响 proxy。
- CI Runner 安装在哪台 rpi 上不限制——仓库在 `git-server` 上，LAN 内网 1ms 延迟，克隆如同本地。

## 4. 备份规则

### 4.1 架构
`git-server` 作为主仓库，**双重异地备份**（方案由先生落地）。

### 4.2 备份内容
- 所有裸仓库（`/srv/git/repos/*.git`）
- 配置文件（SSH、系统配置）
- 若有其他持久化数据则一并纳入

### 4.3 备份频率
- 每次重大 commit 后或每日（以方案实施为准）

## 5. 开发工作流

```
# 1. 克隆（新项目）
git clone git@git-server.local:/srv/git/repos/<repo>.git

# 2. 开发 → 提交
cd <repo>
# ... 修改代码 ...
git add -A
git commit -m "feat: xxx"

# 3. 推送到 LAN 主仓库
git push origin main

# 4. 备份（手动或自动）
# 备份脚本在 git-server 上由 cron 执行

# 5. 公开发布（仅开源项目）
git remote add github git@github.com:ailib-official/<repo>.git
git push github main
```

---

## 变更历史
- 2026-06-05：初版，由先生与 Spider 讨论确立。
