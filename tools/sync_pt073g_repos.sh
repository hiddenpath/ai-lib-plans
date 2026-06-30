#!/usr/bin/env bash
# PT-073g multi-executor repo sync: align lan/origin (private) and origin/main (public).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLANS="${PLANS_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

if [[ -n "${WORKSPACE_ROOT:-}" ]]; then
  ROOT="${WORKSPACE_ROOT}"
else
  ROOT="/home/alex"
fi

DRY_RUN=0
NO_CLEAN=0

usage() {
  cat <<EOF
Usage: sync_pt073g_repos.sh [--dry-run] [--no-clean]

Align PT-073g audit repos for multi-machine execution.
Private: bidirectional lan <-> origin. Public: reset --hard origin/main.

Env:
  WORKSPACE_ROOT   e.g. /home/alex or /d/rustapp (Git Bash)
  PLANS_ROOT       ai-lib-plans path (default: parent of tools/)
  STRICT_BASELINE=1  fail if HEAD != PT-073g-SYNC_BASELINE.md table
EOF
}

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }

run_git() {
  local repo="$1"; shift
  if [[ "$DRY_RUN" == "1" ]]; then
    log "DRY-RUN: git -C $repo $*"
    return 0
  fi
  git -C "$repo" "$@"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --no-clean) NO_CLEAN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown: $1" >&2; usage; exit 2 ;;
  esac
done

resolve_path() {
  local name="$1"
  case "$name" in
    ai-lib-plans) echo "${PLANS}" ;;
    ai-lib-constitution)
      [[ -d "${ROOT}/ai-lib-constitution/.git" ]] && echo "${ROOT}/ai-lib-constitution" && return
      [[ -d "${ROOT}/../ai-lib-constitution/.git" ]] && echo "${ROOT}/../ai-lib-constitution" && return
      echo "${ROOT}/ai-lib-constitution"
      ;;
    eos)
      [[ -d "${ROOT}/eos/.git" ]] && echo "${ROOT}/eos" && return
      [[ -d "${ROOT}/rustapp/eos/.git" ]] && echo "${ROOT}/rustapp/eos" && return
      echo "${ROOT}/eos"
      ;;
    *)
      [[ -d "${ROOT}/rustapp/${name}/.git" ]] && echo "${ROOT}/rustapp/${name}" && return
      [[ -d "${ROOT}/${name}/.git" ]] && echo "${ROOT}/${name}" && return
      echo "${ROOT}/rustapp/${name}"
      ;;
  esac
}

declare -A BASELINE=(
  [ai-lib-plans]=e0afebf
  [ai-lib-constitution]=081bc81
  [eos]=1427438
  [ai-protocol]=65857ef
  [ai-lib-rust]=2f331b4
  [ai-lib-python]=c3f4d53
  [ai-lib-ts]=aa3f5fa
  [ai-lib-go]=2cf42c6
  [velaclaw]=d6e8f6a
  [ailib.info]=ab86b8f
  [ai-lib-benchmark]=e65830a
)

DUAL_REPOS=(ai-lib-plans ai-lib-constitution eos)
PUBLIC_REPOS=(ai-protocol ai-lib-rust ai-lib-python ai-lib-ts ai-lib-go velaclaw ailib.info ai-lib-benchmark)

check_baseline() {
  local name="$1" path="$2"
  local short base
  short="$(git -C "$path" rev-parse --short HEAD)"
  base="${BASELINE[$name]:-}"
  if [[ -n "$base" && "$short" != "$base" ]]; then
    log "WARN: $name HEAD=$short baseline=$base"
    [[ "${STRICT_BASELINE:-0}" == "1" ]] && return 1
  else
    log "OK: $name @ $short"
  fi
  run_git "$path" status -sb
}

sync_dual() {
  local name="$1" path
  path="$(resolve_path "$name")"
  log "=== $name (dual) $path ==="
  [[ -d "$path/.git" ]] || { log "SKIP: missing $path"; return 0; }

  run_git "$path" fetch --all --prune

  if git -C "$path" rev-parse lan/main &>/dev/null && git -C "$path" rev-parse origin/main &>/dev/null; then
    local ahead_lan ahead_origin
    ahead_lan="$(git -C "$path" rev-list --count origin/main..lan/main 2>/dev/null || echo 0)"
    ahead_origin="$(git -C "$path" rev-list --count lan/main..origin/main 2>/dev/null || echo 0)"
    if [[ "$ahead_lan" -gt 0 && "$ahead_origin" -eq 0 ]]; then
      log "push origin ($ahead_lan commits from lan)"
      run_git "$path" push origin lan/main:main
    elif [[ "$ahead_origin" -gt 0 && "$ahead_lan" -eq 0 ]]; then
      log "push lan ($ahead_origin commits from origin)"
      run_git "$path" push lan origin/main:main
    elif [[ "$ahead_lan" -gt 0 && "$ahead_origin" -gt 0 ]]; then
      log "ERROR: $name lan/origin diverged"
      return 1
    fi
    run_git "$path" checkout main 2>/dev/null || true
    run_git "$path" reset --hard lan/main
  elif git -C "$path" rev-parse lan/main &>/dev/null; then
    run_git "$path" reset --hard lan/main
  else
    run_git "$path" reset --hard origin/main
  fi

  [[ "$NO_CLEAN" == "0" ]] && run_git "$path" clean -fd
  check_baseline "$name" "$path"
}

sync_public() {
  local name="$1" path
  path="$(resolve_path "$name")"
  log "=== $name (public) $path ==="
  [[ -d "$path/.git" ]] || { log "SKIP: missing $path"; return 0; }
  run_git "$path" fetch origin --prune
  run_git "$path" checkout main 2>/dev/null || true
  run_git "$path" reset --hard origin/main
  [[ "$NO_CLEAN" == "0" ]] && run_git "$path" clean -fd
  check_baseline "$name" "$path"
}

failed=0
for name in "${DUAL_REPOS[@]}"; do
  sync_dual "$name" || failed=$((failed + 1))
done
for name in "${PUBLIC_REPOS[@]}"; do
  sync_public "$name" || failed=$((failed + 1))
done

if [[ "$failed" -gt 0 ]]; then
  log "Completed with $failed failure(s)"
  exit 1
fi
log "PT-073g repos aligned."
