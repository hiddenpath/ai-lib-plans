#!/usr/bin/env bash
# deploy_prism_gateway.sh — Prism gateway docker-compose deploy (PR-P1-006 / P1-C prep)
#
# Does NOT modify Eos /api/proxy or eos.ailib.info. Target: future api.prism.ailib.info host.
set -euo pipefail

GATEWAY_REPO="${GATEWAY_REPO:-/home/alex/ai-lib-gateway}"
REMOTE_HOST="${REMOTE_HOST:-}"
REMOTE_USER="${REMOTE_USER:-root}"
REMOTE_PASS="${REMOTE_PASS:-}"
REMOTE_DIR="${REMOTE_DIR:-/opt/ai-lib-gateway}"
REMOTE_ENV_FILE="${REMOTE_ENV_FILE:-${REMOTE_DIR}/.env}"
REMOTE_NETRC="${REMOTE_NETRC:-${REMOTE_DIR}/.netrc.local}"
COMPOSE_PROFILE="${COMPOSE_PROFILE:-}" # set to "tls" to enable Caddy profile
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
  --skip-pull         Skip local git pull
  --skip-build        Skip docker compose build on remote
  --skip-restart      Skip compose up
  --dry-run           Print steps only
  -h, --help          Show help

Prerequisites (remote):
  - git, docker, docker compose plugin
  - ${REMOTE_NETRC} with GitHub read on hiddenpath/eos
  - ${REMOTE_ENV_FILE} with provider keys + PRISM_GATEWAY_API_KEY / PRISM_ADMIN_TOKEN

Example:
  bash tools/deploy_prism_gateway.sh --remote 1.2.3.4 --remote-pass '***'
  bash tools/deploy_prism_gateway.sh --remote 1.2.3.4 --profile tls --dry-run
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
    --skip-pull) SKIP_PULL=1; shift ;;
    --skip-build) SKIP_BUILD=1; shift ;;
    --skip-restart) SKIP_RESTART=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ ! -d "${GATEWAY_REPO}" ]]; then
  echo "ERROR: gateway repo not found: ${GATEWAY_REPO}" >&2
  exit 1
fi

if [[ -z "${REMOTE_HOST}" && "$DRY_RUN" == "0" ]]; then
  echo "ERROR: --remote HOST is required" >&2
  exit 1
fi

log "=== Prism Gateway Deploy ==="
log "repo=${GATEWAY_REPO} remote=${REMOTE_USER}@${REMOTE_HOST:-?} dir=${REMOTE_DIR}"

if [[ "$SKIP_PULL" == "0" ]]; then
  step "Local git pull (rebase)"
  run_cmd git -C "${GATEWAY_REPO}" pull --rebase --autostash origin main
else
  log "Skipping local git pull"
fi

step "Sync repo to remote"
run_cmd remote_ssh "mkdir -p '${REMOTE_DIR}'"
run_cmd remote_rsync "${GATEWAY_REPO}"

if [[ "$SKIP_BUILD" == "0" || "$SKIP_RESTART" == "0" ]]; then
  profile_arg=""
  if [[ "${COMPOSE_PROFILE}" == "tls" ]]; then
    profile_arg="--profile tls"
  fi

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
export COMPOSE_PROFILE='${COMPOSE_PROFILE}'
if [[ '${SKIP_BUILD}' == '0' ]]; then
  docker compose ${profile_arg} build
fi
if [[ '${SKIP_RESTART}' == '0' ]]; then
  docker compose ${profile_arg} up -d
fi
for i in \$(seq 1 15); do
  if curl -sf http://127.0.0.1:8080/health >/dev/null 2>&1; then
    echo "Health check PASSED"
    exit 0
  fi
  sleep 2
done
echo "WARN: health check timed out"
REMOTE
fi

log "=== Deploy complete ==="
