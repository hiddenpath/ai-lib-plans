# 内网 Git 协作规范（GOV-004）

> **Effective**: 2026-06-05  
> **Status**: 试运行（trial）  
> **Audience**: 人类开发者、编程代理  
> **Rule**: `ai-lib-constitution/rules/governance/GOV-004-lan-git-dual-remote.yaml`

---

## 背景

闭源仓库（constitution、plans、papers、eos、gateway）**不得**放在 `ailib-official`（GOV-001）。  
自 2026-06-05 起，**日常协作**改以内网 bare 服务器为主；GitHub `hiddenpath/*` 私有仓**保留**，试运行期间**不删除、不归档、不清空**。

| 角色 | Remote 名 | 用途 |
|------|-----------|------|
| **主（日常）** | `lan` | 内网 fetch / push / clone |
| **次（备份/CI）** | `origin` | GitHub hiddenpath；eos 等需 CI 时用于 PR/Actions |

公开运行时仓库（ai-protocol、ai-lib-rust 等）**不适用**本文；仍按 [REMOTE_MIGRATION.md](./REMOTE_MIGRATION.md) 使用 `ailib-official`。

---

## 服务器与 URL

| 项 | 值 |
|----|-----|
| 主机名 | `git-server.local`（=`192.168.2.22`） |
| SSH 用户 | `git` |
| Bare 根目录 | `/srv/git/repos/` |
| URL 模板 | `ssh://git@git-server.local/srv/git/repos/<repo>.git` |
| SSH 别名 | `lan-git`（见 `~/.ssh/config`） |
| 密钥 | `~/.ssh/id_ed25519_lan_git` |

### 仓库矩阵

| 仓库 | 日常模式 | CI |
|------|----------|-----|
| ai-lib-constitution | 仅 `lan` | 无 |
| ai-lib-plans | 仅 `lan` | 无 |
| papers | 仅 `lan` | 无 |
| **eos** | **`lan` + `origin` 双头** | GitHub Actions |
| ai-lib-gateway | 仅 `lan`（待首次 commit） | 无（未来若加 CI 则升双头） |

---

## 首次配置

### 1. SSH

`~/.ssh/config` 示例：

```
Host git-server.local lan-git 192.168.2.22
  HostName git-server.local
  User git
  IdentityFile ~/.ssh/id_ed25519_lan_git
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new
```

公钥部署：运行 `ai-lib-plans/tools/push_private_repos_to_lan_git.py`，或请管理员写入服务器 `~git/.ssh/authorized_keys`。

### 2. 已有克隆：添加 `lan` remote

```bash
git remote add lan ssh://git@git-server.local/srv/git/repos/<REPO>.git
git fetch lan
```

### 3. 新克隆（推荐）

```bash
git clone git@git-server.local:/srv/git/repos/<REPO>.git
cd <REPO>
# 若需双头（eos）：
git remote add origin https://github.com/hiddenpath/<REPO>.git
```

---

## 日常流程

### 文档/治理仓（constitution、plans、papers）

```bash
git pull lan
# ... 编辑、提交 ...
git push lan main
```

`origin` 推送：**可选**冷备份，不必每次 commit 都推。

### eos（双头 + CI）

**日常开发（内网协作）：**

```bash
git pull lan
git push lan <feature-branch>
```

**需要跑 GitHub CI 时：**

```bash
git push origin <feature-branch>   # 开 PR
# CI 绿 → merge on GitHub
git pull origin main               # 或 fetch + merge
git push lan main                  # 同步回内网（必须）
git push lan <feature-branch>      # 可选：同步已合并分支
```

**原则：** `lan` = 团队真相源；`origin` = CI 网关 + 离网备份。合并后 **必须** 把 main 推回 `lan`。

---

## 代理 / 自动化约定

- 改 constitution、plans、papers：**只 push `lan`**，除非用户明确要求备份到 GitHub。
- 改 eos 且涉及 PR/CI：按 GOV-003 走 GitHub PR；合并后 **push `lan`**。
- **禁止**在试运行期删除或清空 `hiddenpath` 私有仓。
- **禁止**将 in-scope 私有仓 `origin` 指到 `ailib-official`。

---

## 工具

| 工具 | 用途 |
|------|------|
| `tools/push_private_repos_to_lan_git.py` | 初始化 bare 仓、部署 SSH 公钥、批量推送（eos 默认 `--all`） |
| `tools/INDEX.md` | 工具索引 |

---

## 试运行退出条件（GOV-004）

满足以下条件后，由 maintainer 记录决策并可将 GOV-004 从 `trial` 升为 `active`：

1. 全员稳定使用 `lan` ≥ 4 周  
2. 备份或内网 CI 已替代对 GitHub 的硬依赖（如 eos）  
3. MEMORY.md 记录 promotion 或修订  
4. 若归档 GitHub 私有仓：同步更新 GOV-001、REMOTE_MIGRATION、任务 YAML 中的 URL

---

## 相关文档

- GOV-004: `ai-lib-constitution/rules/governance/GOV-004-lan-git-dual-remote.yaml`
- GOV-001: 公开仓 `ailib-official`；私有仓不得公开  
- GOV-003: PR 审查与合并（eos CI 仍走 GitHub）  
- MEMORY.md: 「2026-06-05 — 内网 Git 服务器」  
- REMOTE_MIGRATION.md: 公开仓 hiddenpath → ailib-official（与本文互补）
