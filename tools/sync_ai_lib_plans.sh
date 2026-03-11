#!/usr/bin/env bash
set -euo pipefail

# 同步 ai-lib-plans 远程与本地（安全模式：fetch + pull --rebase + 可选 push）。

MODE="manual"
DRY_RUN=0
PUSH_IF_AHEAD=0
PULL_RETRIES="${PULL_RETRIES:-3}"
PULL_BACKOFF_SECONDS="${PULL_BACKOFF_SECONDS:-5}"
USE_HTTP11_FALLBACK="${USE_HTTP11_FALLBACK:-1}"
USE_EXPLICIT_PROXY="${USE_EXPLICIT_PROXY:-1}"
PROXY_HOST="${PROXY_HOST:-192.168.2.13}"
HTTP_PROXY_PORT="${HTTP_PROXY_PORT:-8887}"
HTTPS_PROXY_PORT="${HTTPS_PROXY_PORT:-8887}"

usage() {
  cat <<'EOF'
Usage:
  sync_ai_lib_plans.sh [--mode pre-plan|post-doc-change|manual] [--push-if-ahead] [--dry-run]
                       [--proxy-host HOST] [--http-proxy-port PORT] [--https-proxy-port PORT]
                       [--no-explicit-proxy]

Options:
  --mode MODE       Sync scenario marker. Default: manual
  --push-if-ahead   Push local commits when branch is ahead after pull.
  --dry-run         Print actions only, do not change repository.
  --proxy-host HOST Proxy host for explicit per-command proxy env.
  --http-proxy-port PORT  Proxy port used for http_proxy/HTTP_PROXY.
  --https-proxy-port PORT Proxy port used for https_proxy/HTTPS_PROXY.
  --no-explicit-proxy     Do not inject proxy env in git commands.
  -h, --help        Show this help.

Scenarios:
  pre-plan          Use before drafting/updating planning documents.
  post-doc-change   Use after documentation changes are committed.

Environment:
  PULL_RETRIES         Pull retry count on transient failures (default: 3)
  PULL_BACKOFF_SECONDS Base backoff seconds between retries (default: 5)
  USE_HTTP11_FALLBACK  Retry with git -c http.version=HTTP/1.1 (default: 1)
  USE_EXPLICIT_PROXY   Inject explicit proxy env per git command (default: 1)
  PROXY_HOST           Proxy host for explicit mode (default: 192.168.2.13)
  HTTP_PROXY_PORT      HTTP proxy port for explicit mode (default: 8887)
  HTTPS_PROXY_PORT     HTTPS proxy port for explicit mode (default: 8887)
EOF
}

log() {
  printf '[%s] %s\n' "$(date '+%F %T')" "$*"
}

run_cmd() {
  if [[ "$DRY_RUN" == "1" ]]; then
    log "DRY-RUN: $*"
    return 0
  fi
  "$@"
}

run_git() {
  if [[ "${USE_EXPLICIT_PROXY}" == "1" ]]; then
    local http_proxy_url="http://${PROXY_HOST}:${HTTP_PROXY_PORT}"
    local https_proxy_url="http://${PROXY_HOST}:${HTTPS_PROXY_PORT}"
    run_cmd env \
      GIT_TERMINAL_PROMPT=0 \
      http_proxy="${http_proxy_url}" \
      https_proxy="${https_proxy_url}" \
      HTTP_PROXY="${http_proxy_url}" \
      HTTPS_PROXY="${https_proxy_url}" \
      git "$@"
  else
    run_cmd env GIT_TERMINAL_PROMPT=0 git "$@"
  fi
}

pull_with_retry() {
  local repo_root="$1"
  local attempt=1
  while (( attempt <= PULL_RETRIES )); do
    log "pull attempt ${attempt}/${PULL_RETRIES}"
    if run_git -C "${repo_root}" pull --rebase --autostash; then
      return 0
    fi

    if [[ "${USE_HTTP11_FALLBACK}" == "1" ]]; then
      log "retry with HTTP/1.1 fallback (attempt ${attempt}/${PULL_RETRIES})"
      if [[ "${USE_EXPLICIT_PROXY}" == "1" ]]; then
        local http_proxy_url="http://${PROXY_HOST}:${HTTP_PROXY_PORT}"
        local https_proxy_url="http://${PROXY_HOST}:${HTTPS_PROXY_PORT}"
        if run_cmd env \
          GIT_TERMINAL_PROMPT=0 \
          http_proxy="${http_proxy_url}" \
          https_proxy="${https_proxy_url}" \
          HTTP_PROXY="${http_proxy_url}" \
          HTTPS_PROXY="${https_proxy_url}" \
          git -c http.version=HTTP/1.1 -C "${repo_root}" pull --rebase --autostash; then
          return 0
        fi
      elif run_cmd env GIT_TERMINAL_PROMPT=0 git -c http.version=HTTP/1.1 -C "${repo_root}" pull --rebase --autostash; then
        return 0
      fi
    fi

    if (( attempt < PULL_RETRIES )); then
      local sleep_seconds=$((PULL_BACKOFF_SECONDS * attempt))
      log "WARN: pull failed, backoff ${sleep_seconds}s then retry"
      sleep "${sleep_seconds}"
    fi
    attempt=$((attempt + 1))
  done
  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="$2"
      shift 2
      ;;
    --push-if-ahead)
      PUSH_IF_AHEAD=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --proxy-host)
      PROXY_HOST="$2"
      shift 2
      ;;
    --http-proxy-port)
      HTTP_PROXY_PORT="$2"
      shift 2
      ;;
    --https-proxy-port)
      HTTPS_PROXY_PORT="$2"
      shift 2
      ;;
    --no-explicit-proxy)
      USE_EXPLICIT_PROXY=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

case "$MODE" in
  pre-plan|post-doc-change|manual) ;;
  *)
    echo "Invalid --mode: $MODE" >&2
    exit 2
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ ! -d "${REPO_ROOT}/.git" ]]; then
  echo "Not a git repository: ${REPO_ROOT}" >&2
  exit 2
fi

log "sync_ai_lib_plans start (mode=${MODE}, push_if_ahead=${PUSH_IF_AHEAD}, dry_run=${DRY_RUN})"
log "repo=${REPO_ROOT}"
if [[ "${USE_EXPLICIT_PROXY}" == "1" ]]; then
  log "proxy=http://${PROXY_HOST}:${HTTP_PROXY_PORT} / http://${PROXY_HOST}:${HTTPS_PROXY_PORT}"
fi

upstream="$(git -C "${REPO_ROOT}" rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)"
if [[ -z "${upstream}" ]]; then
  echo "No upstream branch configured. Please set upstream first." >&2
  exit 2
fi
log "upstream=${upstream}"

# Always fetch first to refresh remote tracking refs.
run_git -C "${REPO_ROOT}" fetch --all --prune

# Pull latest remote updates safely; autostash handles temporary local unstaged changes.
if [[ "${DRY_RUN}" == "1" ]]; then
  if [[ "${USE_EXPLICIT_PROXY}" == "1" ]]; then
    log "DRY-RUN: env ...proxy... git -C ${REPO_ROOT} pull --rebase --autostash"
  else
    log "DRY-RUN: env GIT_TERMINAL_PROMPT=0 git -C ${REPO_ROOT} pull --rebase --autostash"
  fi
  if [[ "${USE_HTTP11_FALLBACK}" == "1" ]]; then
    log "DRY-RUN: fallback enabled -> git -c http.version=HTTP/1.1 pull --rebase --autostash"
  fi
else
  pull_with_retry "${REPO_ROOT}"
fi

status_line="$(git -C "${REPO_ROOT}" status -sb | sed -n '1p')"
ahead_count="$(echo "${status_line}" | sed -n 's/.*ahead \([0-9]\+\).*/\1/p')"

if [[ -z "${ahead_count}" ]]; then
  ahead_count=0
fi

if [[ "${PUSH_IF_AHEAD}" == "1" && "${ahead_count}" -gt 0 ]]; then
  run_git -C "${REPO_ROOT}" push
fi

run_cmd git -C "${REPO_ROOT}" status -sb
log "sync_ai_lib_plans finished."
