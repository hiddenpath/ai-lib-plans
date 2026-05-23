#!/usr/bin/env bash
set -euo pipefail

# Eos 一键部署脚本：拉取代码 → 构建镜像 → 导出 → 上传 → 远程加载+重启

# ── 默认配置 ──
EOS_REPO="${EOS_REPO:-/home/alex/eos}"
IMAGE_NAME="${IMAGE_NAME:-eos}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
REMOTE_HOST="${REMOTE_HOST:-43.159.226.236}"
REMOTE_USER="${REMOTE_USER:-root}"
REMOTE_PASS="${REMOTE_PASS:-}"
REMOTE_ENV_FILE="${REMOTE_ENV_FILE:-/opt/eos/.env.production}"
REMOTE_UPLOAD_DIR="${REMOTE_UPLOAD_DIR:-/opt/eos}"
REMOTE_UPLOAD_PATH="${REMOTE_UPLOAD_DIR}/eos-image.tar.gz"
CONTAINER_NAME="${CONTAINER_NAME:-eos}"
CONTAINER_PORT="${CONTAINER_PORT:-3000}"
HOST_PORT="${HOST_PORT:-3000}"
LOCAL_IMAGE_PATH="${LOCAL_IMAGE_PATH:-/tmp/eos-image.tar.gz}"
PROXY_HOST="${PROXY_HOST:-192.168.2.13}"
HTTP_PROXY_PORT="${HTTP_PROXY_PORT:-8887}"
HTTPS_PROXY_PORT="${HTTPS_PROXY_PORT:-8887}"
DRY_RUN=0
SKIP_PULL=0
SKIP_BUILD=0
SKIP_UPLOAD=0
SKIP_RESTART=0

# ── 工具函数 ──
usage() {
  cat <<'EOF'
Usage:
  deploy_eos.sh [options]

Eos 一键部署：git pull → docker build → docker save → scp → remote docker load + restart

Options:
  --skip-pull       Skip git pull step
  --skip-build      Skip docker build step (use existing image)
  --skip-upload     Skip scp upload step (image already on server)
  --skip-restart    Skip remote container restart step
  --dry-run         Print actions only, do not execute
  --repo PATH       Local eos repo path (default: /home/alex/eos)
  --image NAME      Docker image name (default: eos)
  --tag TAG         Docker image tag (default: latest)
  --remote HOST     Remote server host (default: 43.159.226.236)
  --remote-user USER  Remote SSH user (default: root)
  --remote-pass PASS  Remote SSH password (or set REMOTE_PASS env)
  --host-port PORT  Host port mapping (default: 3000)
  --container-port PORT  Container port (default: 3000)
  --proxy-host HOST Proxy host for docker build (default: 192.168.2.13)
  --http-proxy-port PORT  HTTP proxy port (default: 8887)
  --https-proxy-port PORT HTTPS proxy port (default: 8887)
  -h, --help        Show this help

Environment:
  EOS_REPO          Local eos repo path
  REMOTE_PASS       Remote SSH password (sshpass -p)
  PROXY_HOST        Build proxy host
  HTTP_PROXY_PORT   Build proxy HTTP port
  HTTPS_PROXY_PORT  Build proxy HTTPS port

Examples:
  # Full deploy (default)
  deploy_eos.sh

  # Skip git pull, rebuild + upload only
  deploy_eos.sh --skip-pull

  # Dry run to preview steps
  deploy_eos.sh --dry-run

  # Custom remote server
  deploy_eos.sh --remote 1.2.3.4 --remote-pass mypass

  # Rebuild only (skip upload, assume image already on server)
  deploy_eos.sh --skip-upload --skip-restart
EOF
}

log() {
  printf '[%s] %s\n' "$(date '+%F %T')" "$*"
}

step() {
  log "▶ $*"
}

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

remote_scp() {
  local src="$1" dst="$2"
  if [[ -n "${REMOTE_PASS}" ]]; then
    sshpass -p "${REMOTE_PASS}" scp -o StrictHostKeyChecking=no "$src" "${REMOTE_USER}@${REMOTE_HOST}:${dst}"
  else
    scp -o StrictHostKeyChecking=no "$src" "${REMOTE_USER}@${REMOTE_HOST}:${dst}"
  fi
}

# ── 参数解析 ──
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-pull)     SKIP_PULL=1; shift ;;
    --skip-build)    SKIP_BUILD=1; shift ;;
    --skip-upload)   SKIP_UPLOAD=1; shift ;;
    --skip-restart)  SKIP_RESTART=1; shift ;;
    --dry-run)       DRY_RUN=1; shift ;;
    --repo)          EOS_REPO="$2"; shift 2 ;;
    --image)         IMAGE_NAME="$2"; shift 2 ;;
    --tag)           IMAGE_TAG="$2"; shift 2 ;;
    --remote)        REMOTE_HOST="$2"; shift 2 ;;
    --remote-user)   REMOTE_USER="$2"; shift 2 ;;
    --remote-pass)   REMOTE_PASS="$2"; shift 2 ;;
    --host-port)     HOST_PORT="$2"; shift 2 ;;
    --container-port) CONTAINER_PORT="$2"; shift 2 ;;
    --proxy-host)    PROXY_HOST="$2"; shift 2 ;;
    --http-proxy-port) HTTP_PROXY_PORT="$2"; shift 2 ;;
    --https-proxy-port) HTTPS_PROXY_PORT="$2"; shift 2 ;;
    -h|--help)       usage; exit 0 ;;
    *)               echo "Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

# ── 前置检查 ──
if [[ ! -d "${EOS_REPO}" ]]; then
  echo "ERROR: eos repo not found: ${EOS_REPO}" >&2
  exit 1
fi

if ! command -v docker &>/dev/null; then
  echo "ERROR: docker not found in PATH" >&2
  exit 1
fi

FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
HTTP_PROXY_URL="http://${PROXY_HOST}:${HTTP_PROXY_PORT}"
HTTPS_PROXY_URL="http://${PROXY_HOST}:${HTTPS_PROXY_PORT}"

log "=== Eos Deploy Start ==="
log "repo=${EOS_REPO} image=${FULL_IMAGE} remote=${REMOTE_USER}@${REMOTE_HOST}"
log "proxy=${HTTP_PROXY_URL} dry_run=${DRY_RUN}"

# ── Step 1: Git Pull ──
if [[ "$SKIP_PULL" == "0" ]]; then
  step "Git pull latest code"
  run_cmd git -C "${EOS_REPO}" pull --rebase --autostash
  log "Git pull done."
else
  log "Skipping git pull (--skip-pull)"
fi

# ── Step 2: Docker Build ──
if [[ "$SKIP_BUILD" == "0" ]]; then
  step "Docker build ${FULL_IMAGE}"
  run_cmd docker build \
    --build-arg HTTP_PROXY="${HTTP_PROXY_URL}" \
    --build-arg HTTPS_PROXY="${HTTPS_PROXY_URL}" \
    --build-arg NO_PROXY=localhost,127.0.0.1,192.168.0.0/16 \
    -t "${FULL_IMAGE}" \
    "${EOS_REPO}"
  log "Docker build done."
else
  log "Skipping docker build (--skip-build)"
fi

# ── Step 3: Export Image ──
step "Export docker image to ${LOCAL_IMAGE_PATH}"
run_cmd docker save "${FULL_IMAGE}" | gzip > "${LOCAL_IMAGE_PATH}"
LOCAL_SIZE=$(du -h "${LOCAL_IMAGE_PATH}" | cut -f1)
log "Image exported: ${LOCAL_IMAGE_PATH} (${LOCAL_SIZE})"

# ── Step 4: Upload to Remote ──
if [[ "$SKIP_UPLOAD" == "0" ]]; then
  step "Upload image to ${REMOTE_HOST}:${REMOTE_UPLOAD_PATH}"
  # Ensure remote upload directory exists
  run_cmd remote_ssh "mkdir -p ${REMOTE_UPLOAD_DIR}"
  run_cmd remote_scp "${LOCAL_IMAGE_PATH}" "${REMOTE_UPLOAD_PATH}"
  log "Upload done."
else
  log "Skipping upload (--skip-upload)"
fi

# ── Step 5: Remote Load + Restart ──
if [[ "$SKIP_RESTART" == "0" ]]; then
  step "Remote: load image and restart container"
  run_cmd remote_ssh bash -s <<REMOTE_SCRIPT
set -e
echo "[\$(date '+%F %T')] Loading docker image..."
docker load < ${REMOTE_UPLOAD_PATH}
echo "[\$(date '+%F %T')] Image loaded."

echo "[\$(date '+%F %T')] Stopping old container..."
docker stop ${CONTAINER_NAME} 2>/dev/null || true
docker rm ${CONTAINER_NAME} 2>/dev/null || true

echo "[\$(date '+%F %T')] Starting new container..."
docker run -d \
  --name ${CONTAINER_NAME} \
  -p ${HOST_PORT}:${CONTAINER_PORT} \
  --env-file ${REMOTE_ENV_FILE} \
  -v ${REMOTE_UPLOAD_DIR}/uploads:/tmp/eos/uploads \
  --restart unless-stopped \
  ${FULL_IMAGE}

echo "[\$(date '+%F %T')] Container ${CONTAINER_NAME} started."

# Health check (wait up to 10s)
echo "[\$(date '+%F %T')] Health check..."
for i in \$(seq 1 10); do
  if curl -sf http://localhost:${HOST_PORT}/health > /dev/null 2>&1; then
    echo "[\$(date '+%F %T')] Health check PASSED ✓"
    break
  fi
  if [ "\$i" -eq 10 ]; then
    echo "[\$(date '+%F %T')] WARN: Health check timed out (container may still be starting)"
  fi
  sleep 1
done

# Clean up remote image file
rm -f ${REMOTE_UPLOAD_PATH}
echo "[\$(date '+%F %T')] Remote image file cleaned up."
REMOTE_SCRIPT
  log "Remote deploy done."
else
  log "Skipping remote restart (--skip-restart)"
fi

# ── Step 6: Local Cleanup ──
step "Clean up local image file"
run_cmd rm -f "${LOCAL_IMAGE_PATH}"
log "Local image file cleaned up."

log "=== Eos Deploy Complete ==="
