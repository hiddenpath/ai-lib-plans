#!/usr/bin/env bash
# deploy_prism_gateway.sh — Prism gateway docker-compose deploy (PR-P1-006 / PR-P1-017)
#
# Does NOT modify Eos /api/proxy or eos.ailib.info. Path B1 adds api.prism.ailib.info via host Caddy.
set -euo pipefail

GATEWAY_REPO="${GATEWAY_REPO:-/home/alex/ai-lib-gateway}"
REMOTE_HOST="${REMOTE_HOST:-}"
REMOTE_USER="${REMOTE_USER:-root}"
REMOTE_PASS="${REMOTE_PASS:-}"
REMOTE_DIR="${REMOTE_DIR:-/opt/ai-lib-gateway}"
REMOTE_ENV_FILE="${REMOTE_ENV_FILE:-${REMOTE_DIR}/.env}"
REMOTE_NETRC="${REMOTE_NETRC:-${REMOTE_DIR}/.netrc.local}"
COMPOSE_PROFILE="${COMPOSE_PROFILE:-}"
PRODUCTION=0
PATH_B1=0
COMPOSE_FILES="-f docker-compose.yml"
PRISM_PUBLIC_DOMAIN="${PRISM_PUBLIC_DOMAIN:-api.prism.ailib.info}"
PRISM_LOOPBACK_PORT="${PRISM_LOOPBACK_PORT:-18080}"
DRY_RUN=0
SKIP_PULL=0
SKIP_BUILD=0
SKIP_RESTART=0

usage() {
  cat <<'EOF'
Usage: deploy_prism_gateway.sh [options]

Prism gateway deploy: local git pull → remote sync → docker compose up --build

Options:
  --repo PATH         Local ai-lib-gateway clone (default: /home/alex/ai-lib-gateway)
  --remote HOST       Remote VPS (required unless --dry-run with checks only)
  --remote-user USER  SSH user (default: root)
  --remote-pass PASS  SSH password (or REMOTE_PASS env; prefer SSH keys)
  --remote-dir PATH   Remote install dir (default: /opt/ai-lib-gateway)
  --remote-env PATH   Remote .env path (default: $REMOTE_DIR/.env)
  --remote-netrc PATH Remote git credentials for docker build (default: $REMOTE_DIR/.netrc.local)
  --profile tls       Enable docker compose tls profile (Caddy)
  --production        Path A: production overlay + tls profile
  --path-b1           Path B1: shared VPS — loopback :18080, no Caddy container
  --domain HOST       Public hostname for HTTPS health check (default: api.prism.ailib.info)
  --skip-pull         Skip local git pull
  --skip-build        Skip docker compose build on remote
  --skip-restart      Skip compose up
  --dry-run           Print steps only
  -h, --help          Show help

Prerequisites (remote):
  - git, docker, docker compose plugin
  - ${REMOTE_NETRC} with GitHub read on hiddenpath/eos
  - ${REMOTE_ENV_FILE} — copy from .env.production.example to .env (see deploy/DEPLOY.md)

Example:
  bash tools/deploy_prism_gateway.sh --remote 1.2.3.4 --production
  bash tools/deploy_prism_gateway.sh --remote 43.159.226.236 --path-b1
EOF
}

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
step() { log "▶ $*"; }

run_cmd() {
  if [[ "$DRY_RUN" == "1" ]]; then
    log "DRY-RUN: $*"
    return 0
  fi
  "$@"
}

remote_ssh() {
  if [[ -n "${REMOTE_PASS}" ]]; then
    sshpass -p "${REMOTE_PASS}" ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" "$@"
  else
    ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" "$@"
  fi
}

remote_rsync() {
  local src="$1"
  if [[ -n "${REMOTE_PASS}" ]]; then
    sshpass -p "${REMOTE_PASS}" rsync -az --delete \
      --exclude target --exclude .git --exclude prism_usage.db \
      -e "ssh -o StrictHostKeyChecking=no" \
      "${src}/" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"
  else
    rsync -az --delete \
      --exclude target --exclude .git --exclude prism_usage.db \
      -e "ssh -o StrictHostKeyChecking=no" \
      "${src}/" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) GATEWAY_REPO="$2"; shift 2 ;;
    --remote) REMOTE_HOST="$2"; shift 2 ;;
    --remote-user) REMOTE_USER="$2"; shift 2 ;;
    --remote-pass) REMOTE_PASS="$2"; shift 2 ;;
    --remote-dir) REMOTE_DIR="$2"; shift 2 ;;
    --remote-env) REMOTE_ENV_FILE="$2"; shift 2 ;;
    --remote-netrc) REMOTE_NETRC="$2"; shift 2 ;;
    --profile) COMPOSE_PROFILE="$2"; shift 2 ;;
    --production) PRODUCTION=1; shift ;;
    --path-b1) PATH_B1=1; shift ;;
    --domain) PRISM_PUBLIC_DOMAIN="$2"; shift 2 ;;
    --skip-pull) SKIP_PULL=1; shift ;;
    --skip-build) SKIP_BUILD=1; shift ;;
    --skip-restart) SKIP_RESTART=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ "$PRODUCTION" == "1" && "$PATH_B1" == "1" ]]; then
  echo "ERROR: --production and --path-b1 are mutually exclusive" >&2
  exit 1
fi

if [[ ! -d "${GATEWAY_REPO}" ]]; then
  echo "ERROR: gateway repo not found: ${GATEWAY_REPO}" >&2
  exit 1
fi

if [[ -z "${REMOTE_HOST}" && "$DRY_RUN" == "0" ]]; then
  echo "ERROR: --remote HOST is required" >&2
  exit 1
fi

log "=== Prism Gateway Deploy ==="
log "repo=${GATEWAY_REPO} remote=${REMOTE_USER}@${REMOTE_HOST:-?} dir=${REMOTE_DIR} path_b1=${PATH_B1}"

if [[ "$SKIP_PULL" == "0" ]]; then
  step "Local git pull (rebase)"
  run_cmd git -C "${GATEWAY_REPO}" pull --rebase --autostash lan main 2>/dev/null \
    || run_cmd git -C "${GATEWAY_REPO}" pull --rebase --autostash origin main
else
  log "Skipping local git pull"
fi

if [[ "$PATH_B1" == "1" ]]; then
  COMPOSE_FILES="-f docker-compose.yml"
  COMPOSE_PROFILE=""
  log "Path B1: gateway on 127.0.0.1:${PRISM_LOOPBACK_PORT}, no tls profile"
elif [[ "$PRODUCTION" == "1" ]]; then
  COMPOSE_FILES="-f docker-compose.yml -f docker-compose.production.yml"
  if [[ -z "${COMPOSE_PROFILE}" ]]; then
    COMPOSE_PROFILE="tls"
  fi
fi

step "Sync repo to remote"
run_cmd remote_ssh "mkdir -p '${REMOTE_DIR}'"
run_cmd remote_rsync "${GATEWAY_REPO}"

if [[ "$PATH_B1" == "1" ]]; then
  step "Patch remote .env for Path B1"
  run_cmd remote_ssh bash -s <<REMOTE
set -euo pipefail
cd '${REMOTE_DIR}'
touch '${REMOTE_ENV_FILE}'
set_kv() {
  local key="\$1" val="\$2" file="\$3"
  if grep -q "^\${key}=" "\$file" 2>/dev/null; then
    sed -i "s|^\${key}=.*|\${key}=\${val}|" "\$file"
  else
    echo "\${key}=\${val}" >> "\$file"
  fi
}
set_kv GATEWAY_HOST_PORT "127.0.0.1:${PRISM_LOOPBACK_PORT}:8080" '${REMOTE_ENV_FILE}'
set_kv GATEWAY_CONFIG "./config/production.toml" '${REMOTE_ENV_FILE}'
set_kv COMPOSE_PROFILE "" '${REMOTE_ENV_FILE}'
sed -i '/^COMPOSE_FILE=.*production/d' '${REMOTE_ENV_FILE}' 2>/dev/null || true
REMOTE
fi

if [[ "$SKIP_BUILD" == "0" || "$SKIP_RESTART" == "0" ]]; then
  step "Remote docker compose up --build"
  run_cmd remote_ssh bash -s <<REMOTE
set -euo pipefail
cd '${REMOTE_DIR}'
if [[ ! -f '${REMOTE_NETRC}' ]]; then
  echo "ERROR: missing ${REMOTE_NETRC} (GitHub PAT for hiddenpath/eos docker build)" >&2
  exit 1
fi
if [[ ! -f '${REMOTE_ENV_FILE}' ]]; then
  echo "ERROR: missing ${REMOTE_ENV_FILE}" >&2
  exit 1
fi
export GIT_CREDENTIALS_FILE='${REMOTE_NETRC}'
compose_files='${COMPOSE_FILES}'
profile_arg=""
if [[ -n '${COMPOSE_PROFILE}' ]]; then
  profile_arg="--profile ${COMPOSE_PROFILE}"
fi
if [[ '${SKIP_BUILD}' == '0' ]]; then
  docker compose \${compose_files} \${profile_arg} build
fi
if [[ '${SKIP_RESTART}' == '0' ]]; then
  docker compose \${compose_files} \${profile_arg} up -d
fi
health_ok=0
loopback_url="http://127.0.0.1:${PRISM_LOOPBACK_PORT}/health"
default_url="http://127.0.0.1:8080/health"
for url in "\${loopback_url}" "\${default_url}"; do
  for i in \$(seq 1 15); do
    if curl -sf "\${url}" >/dev/null 2>&1; then
      echo "Health check PASSED (\${url})"
      health_ok=1
      break 2
    fi
    sleep 2
  done
done
if [[ \${health_ok} -eq 0 && '${PRODUCTION}' == '1' ]]; then
  for i in \$(seq 1 30); do
    if curl -sf "https://${PRISM_PUBLIC_DOMAIN}/health" >/dev/null 2>&1; then
      echo "Health check PASSED (https://${PRISM_PUBLIC_DOMAIN})"
      health_ok=1
      break
    fi
    sleep 4
  done
fi
if [[ \${health_ok} -eq 0 ]]; then
  echo "WARN: health check timed out"
fi
REMOTE
fi

if [[ "$PATH_B1" == "1" ]]; then
  log "Path B1 complete: Prism on loopback :${PRISM_LOOPBACK_PORT}"
  log "Next on VPS: sudo bash ${REMOTE_DIR}/scripts/add-prism-to-eos-caddy.sh"
  log "Then: PRISM_PATH_B1=1 bash ${REMOTE_DIR}/scripts/verify-production.sh"
else
  log "HTTPS target: https://${PRISM_PUBLIC_DOMAIN}/health (after DNS + Caddy)"
fi

log "=== Deploy complete ==="
