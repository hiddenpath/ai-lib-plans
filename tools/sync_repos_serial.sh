#!/usr/bin/env bash
set -euo pipefail

# 串行同步多个仓库到各自上游分支，支持超时与重试。

DEFAULT_REPOS=(
  "/home/alex/ai-lib-go"
  "/home/alex/ailib.info"
  "/home/alex/ai-lib-constitution"
  "/home/alex/ai-lib-plans"
  "/home/alex/ai-lib-python"
  "/home/alex/ai-lib-rust"
  "/home/alex/ai-lib-ts"
  "/home/alex/ai-protocol"
  "/home/alex/ai-protocol-mock"
)

FETCH_TIMEOUT_SECONDS="${FETCH_TIMEOUT_SECONDS:-60}"
FETCH_RETRIES="${FETCH_RETRIES:-2}"
USE_EXPLICIT_PROXY="${USE_EXPLICIT_PROXY:-1}"
PROXY_HOST="${PROXY_HOST:-192.168.2.13}"
HTTP_PROXY_PORT="${HTTP_PROXY_PORT:-8887}"
HTTPS_PROXY_PORT="${HTTPS_PROXY_PORT:-8887}"

usage() {
  cat <<'EOF'
Usage:
  sync_repos_serial.sh [--repo /abs/path]... [--no-clean] [--dry-run]
                       [--proxy-host HOST] [--http-proxy-port PORT] [--https-proxy-port PORT]
                       [--no-explicit-proxy]

Options:
  --repo PATH   Sync only the specified repo(s). Can be repeated.
  --no-clean    Skip git clean -fd (keep untracked files).
  --dry-run     Print actions only, do not modify repos.
  --proxy-host HOST Proxy host for explicit per-command proxy env.
  --http-proxy-port PORT  Proxy port used for http_proxy/HTTP_PROXY.
  --https-proxy-port PORT Proxy port used for https_proxy/HTTPS_PROXY.
  --no-explicit-proxy     Do not inject proxy env in git commands.
  -h, --help    Show this help.

Environment:
  FETCH_TIMEOUT_SECONDS   Timeout for each fetch command (default: 60)
  FETCH_RETRIES           Retries for timed-out/failed fetch (default: 2)
  USE_EXPLICIT_PROXY      Inject explicit proxy env per git command (default: 1)
  PROXY_HOST              Proxy host for explicit mode (default: 192.168.2.13)
  HTTP_PROXY_PORT         HTTP proxy port for explicit mode (default: 8887)
  HTTPS_PROXY_PORT        HTTPS proxy port for explicit mode (default: 8887)
EOF
}

log() {
  printf '[%s] %s\n' "$(date '+%F %T')" "$*"
}

run_cmd() {
  local dry_run="$1"
  shift
  if [[ "$dry_run" == "1" ]]; then
    log "DRY-RUN: $*"
    return 0
  fi
  "$@"
}

run_git() {
  local dry_run="$1"
  shift
  if [[ "${USE_EXPLICIT_PROXY}" == "1" ]]; then
    local http_proxy_url="http://${PROXY_HOST}:${HTTP_PROXY_PORT}"
    local https_proxy_url="http://${PROXY_HOST}:${HTTPS_PROXY_PORT}"
    run_cmd "$dry_run" env \
      GIT_TERMINAL_PROMPT=0 \
      http_proxy="${http_proxy_url}" \
      https_proxy="${https_proxy_url}" \
      HTTP_PROXY="${http_proxy_url}" \
      HTTPS_PROXY="${https_proxy_url}" \
      git "$@"
  else
    run_cmd "$dry_run" env GIT_TERMINAL_PROMPT=0 git "$@"
  fi
}

fetch_with_retry() {
  local repo="$1"
  local dry_run="$2"
  local attempt=1
  while (( attempt <= FETCH_RETRIES )); do
    log "fetch: ${repo} (attempt ${attempt}/${FETCH_RETRIES})"
    if [[ "$dry_run" == "1" ]]; then
      run_git "$dry_run" -C "$repo" fetch --all --prune
      return 0
    fi
    if timeout "${FETCH_TIMEOUT_SECONDS}s" bash -lc "set -euo pipefail; \
      if [[ \"${USE_EXPLICIT_PROXY}\" == \"1\" ]]; then \
        http_proxy_url=\"http://${PROXY_HOST}:${HTTP_PROXY_PORT}\"; \
        https_proxy_url=\"http://${PROXY_HOST}:${HTTPS_PROXY_PORT}\"; \
        env GIT_TERMINAL_PROMPT=0 http_proxy=\"${http_proxy_url}\" https_proxy=\"${https_proxy_url}\" HTTP_PROXY=\"${http_proxy_url}\" HTTPS_PROXY=\"${https_proxy_url}\" git -C \"$repo\" fetch --all --prune; \
      else \
        env GIT_TERMINAL_PROMPT=0 git -C \"$repo\" fetch --all --prune; \
      fi"; then
      return 0
    fi
    log "WARN: fetch failed or timed out for ${repo}"
    attempt=$((attempt + 1))
  done
  return 1
}

repos=()
clean_untracked=1
dry_run=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      repos+=("$2")
      shift 2
      ;;
    --no-clean)
      clean_untracked=0
      shift
      ;;
    --dry-run)
      dry_run=1
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

if [[ "${#repos[@]}" -eq 0 ]]; then
  repos=("${DEFAULT_REPOS[@]}")
fi

log "Starting serial repo sync (repos=${#repos[@]}, dry_run=${dry_run}, clean=${clean_untracked})"
if [[ "${USE_EXPLICIT_PROXY}" == "1" ]]; then
  log "proxy=http://${PROXY_HOST}:${HTTP_PROXY_PORT} / http://${PROXY_HOST}:${HTTPS_PROXY_PORT}"
fi

failed=0
for repo in "${repos[@]}"; do
  log "=== ${repo} ==="

  if [[ ! -d "${repo}/.git" ]]; then
    log "SKIP: not a git repo"
    continue
  fi

  branch="$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  upstream="$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)"
  log "branch=${branch:-<unknown>} upstream=${upstream:-<none>}"

  if [[ -z "$upstream" ]]; then
    log "WARN: no upstream branch, skip reset/clean"
    continue
  fi

  if ! fetch_with_retry "$repo" "$dry_run"; then
    log "ERROR: fetch failed after retries, continue next repo"
    failed=$((failed + 1))
    continue
  fi

  run_git "$dry_run" -C "$repo" reset --hard "$upstream"
  if [[ "$clean_untracked" == "1" ]]; then
    run_git "$dry_run" -C "$repo" clean -fd
  fi
  run_git "$dry_run" -C "$repo" status -sb
done

if (( failed > 0 )); then
  log "Completed with failures: ${failed}"
  exit 1
fi

log "All repositories synced successfully."
