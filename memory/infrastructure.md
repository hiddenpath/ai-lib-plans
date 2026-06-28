# Memory — Infrastructure & Operations

> VPS access, SSH configs, deployment commands, CI setup.
> Complete chronological record: [`log.md`](./log.md)
> Loading strategy: [`INDEX.md`](./INDEX.md)

**Last updated**: 2026-06-28

---

## VPS — Eos / Prism (Hong Kong)

### SSH Access

```bash
ssh eos-hk   # Alias: ubuntu@43.159.226.236, key ~/.ssh/id_ed25519_eos_hk
```

| Field | Value |
|-------|-------|
| IP | 43.159.226.236 |
| Domain (Eos) | eos.ailib.info |
| Domain (Prism) | api.prism.ailib.info |
| OS | Ubuntu 24.04.4 LTS |
| User | ubuntu |
| Password | eUMxUa-8.9wa3x2 |
| Specs | 2C / 3.6GB / 50GB (Tencent Cloud Lighthouse HK) |
| SSH Config | `~/.ssh/config` Host `eos-hk` |

→ Source: [`log.md` § Eos 腾讯云香港服务器](./log.md)

## npm Publish — `@ailib-official/prism-sdk`

| Field | Value |
|-------|-------|
| Package | `@ailib-official/prism-sdk` |
| Repo | `ailib-official/vela` (`packages/prism-sdk`) |
| Workflow | `.github/workflows/publish-prism-sdk.yml` |
| Secret | `NPM_TOKEN` on `ailib-official/vela` (Automation, bypass 2FA, `@ailib-official` publish) |
| First publish | **0.1.0** — 2026-06-21 (workflow_dispatch run `27911434037`) |

```bash
# Rotate token (do not paste into plans/docs)
gh secret set NPM_TOKEN --repo ailib-official/vela

# Publish next version (bump packages/prism-sdk/package.json first)
gh workflow run publish-prism-sdk.yml --repo ailib-official/vela -f version=0.1.1
# or: git tag prism-sdk-v0.1.1 && git push origin prism-sdk-v0.1.1

npm view @ailib-official/prism-sdk version
```

→ Source: [`log.md` § 2026-06-21 prism-sdk npm](./log.md)

### Deploy Architecture

```
Internet → Caddy (:443/:80, systemd)
  ├── eos.ailib.info      → 127.0.0.1:3000  (eos-server binary, nohup)
  └── api.prism.ailib.info → 127.0.0.1:18080 (docker compose ai-lib-gateway)
                              ↓
                         xray (:10808 SOCKS, systemd) → VMess/SS outbound → AI APIs
```

### Prism Gateway Deploy

**Path**: `/opt/ai-lib-gateway` on VPS, docker compose (loopback 127.0.0.1:18080)

```bash
# Deploy from workstation
cd /home/alex/ai-lib-gateway && git pull --rebase origin main
rsync -az --exclude target --exclude .git -e "ssh eos-hk" . ubuntu@eos-hk:/opt/ai-lib-gateway/
ssh eos-hk "cd /opt/ai-lib-gateway && sudo docker compose up -d --build"

# Add site to Caddy
ssh eos-hk "cd /opt/ai-lib-gateway && sudo bash scripts/add-prism-to-eos-caddy.sh"

# Verify
ssh eos-hk "cd /opt/ai-lib-gateway && bash scripts/verify-production.sh"
curl https://api.prism.ailib.info/health
```

**Credentials**: `/opt/ai-lib-gateway/.env` (PRISM_GATEWAY_API_KEY, PRISM_ADMIN_TOKEN, provider keys)

### Caddy Config

```
/etc/caddy/Caddyfile:
  eos.ailib.info { reverse_proxy 127.0.0.1:3000 }
  api.prism.ailib.info { reverse_proxy 127.0.0.1:18080 }
```

Reload: `sudo systemctl reload caddy` (systemd service)

### xray

- Config synced from RPi `pi@192.168.2.13:/usr/local/etc/xray/config.json`
- 63 nodes (57 SS + 2 VLESS + 4 VMess)
- Logs: `/var/log/xray/`, logrotate daily 7d

### Eos (eos-server) Deploy

```bash
# Build + scp binary
cargo build --release -p eos-server
scp target/release/eos-server ubuntu@eos-hk:/opt/eos-v2/eos-server
ssh eos-hk "pkill eos-server; cd /opt/eos-v2 && nohup ./eos-server &"
```

Env: `/opt/eos-v2/.env` (EOS_*_API_KEY prefixed, same keys as Prism)

---

## LAN Infrastructure

### Git Server (git-server.local = 192.168.2.22)

- Role: Canonical source for private repos
- SSH: `ssh lan-git` (alias, key `~/.ssh/id_ed25519_lan`)
- Backup: USB → `/mnt/backup/gitmirror01`; mirror → `piubt:/gitmirror02`
- `/etc/fstab` must persist mount; `/etc/hosts` must resolve piubt

### Dual Remote Strategy

| Repo | lan | origin (GitHub) | CI | 
|------|-----|-----------------|----|
| ai-lib-constitution | ✅ primary | optional backup | lan only |
| ai-lib-plans | ✅ primary | optional backup | lan only |
| eos | ✅ mirror | GitHub Actions heavy CI | dual-head |
| ai-lib-gateway | ✅ primary | optional | lan only |
| papers | ✅ primary | optional | lan only |

**Rule**: Private repos push to `lan` daily. `eos` PR merge → must `git push lan main` within 24h.

### piubt (192.168.2.13)

- Light CI runner (fmt/clippy/unit tests)
- xray proxy source
- SSH: `ssh piubt` (alias, key `~/.ssh/id_ed25519_lan`)

### sudoers (AI Agent)

- `/etc/sudoers.d/ai-agent`: read-only queries (blkid, df, dmesg, systemctl status), dir creation, permission fixes
- Mount/service/Docker/apt/reboot require password

→ Source: [`log.md` § Infrastructure](./log.md)

---

## CI & Release

### GitHub PAT — local workstation (2026-06-28 轮换)

**真源文件（仅本机，禁止入 git/plans）**：`Y:\github-token-list.txt`

| 条目 | 用途 |
|------|------|
| `hiddenpath pat` | `hiddenpath/*` 私有仓：`gh`、PR、Actions（如 `hiddenpath/eos`） |
| `ailib-official pat` | `ailib-official/*` 公开仓：`gh pr`、merge、release、跨仓操作 |

**选用规则**

- 目标 URL / `--repo` 为 `ailib-official/...` → 使用 **ailib-official** PAT
- 目标为 `hiddenpath/...` → 使用 **hiddenpath** PAT
- **禁止**将 PAT 明文写入 `ai-lib-plans`、公开仓、聊天记录或 CI 日志

**Agent / 终端用法（示例）**

```powershell
# 按目标 org 从真源文件读取后注入（勿把 token 写进脚本仓库）
$env:GH_TOKEN = (Get-Content Y:\github-token-list.txt | Select-String 'ailib-official pat' -Context 0,1).Context.PostContext[0].Trim()
gh pr checks 9 --repo ailib-official/ai-lib-rust
```

轮换 PAT 时：只更新 `Y:\github-token-list.txt`，并在 `memory/log.md` 记一条日期（不写 token 值）。

### Release Automation

| Runtime | Registry | Workflow | Status |
|---------|----------|----------|--------|
| ai-lib-go | GitHub Release | `release.yml` | ✅ v0.6.0 |
| ai-lib-rust | crates.io | `release-crates.yml` | ✅ v0.9.6 |
| ai-lib-ts | npmjs | `release.yml` | ✅ |
| ai-protocol | npmjs | `release.yml` | ✅ |
| vela (prism-sdk) | npmjs | `publish-prism-sdk.yml` | ✅ v0.1.0 |
| ai-lib-python | PyPI | `ci.yml` OIDC | ⏳ |

**npm token**: Automation (bypass_2fa, `@ailib-official` publish), secret `NPM_TOKEN` on ai-lib-ts, ai-protocol, **ailib-official/vela**.

### Release Process
1. Code merged to main, tests pass
2. `git tag v<version> && git push origin v<version>`
3. CI triggers release workflow → verify + publish + GitHub Release

### AI Agent sudoers policy
- Policy file: `/etc/sudoers.d/ai-agent` (deploy manually to git-server and production)
- Passwordless: read-only queries (blkid, fdisk, df, dmesg, systemctl status, journalctl), dir creation, permission fixes
- Password-required: mount, service start/stop, Docker, apt, reboot
- Deploy: `sudo cp /tmp/ai-agent-sudoers /etc/sudoers.d/ai-agent && sudo chmod 440 /etc/sudoers.d/ai-agent && sudo visudo -c`

→ Source: [`log.md` § CI Release](./log.md)
