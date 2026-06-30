#!/usr/bin/env bash
# PT-073g multi-executor repo sync (GOV-002 aware).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLANS="${PLANS_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
CONFLICT_RUNBOOK="active/projects/ai-protocol/PT-073g-CONFLICT-RUNBOOK.md"

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

Align PT-073g audit repos. True divergence stops with GOV-002 runbook pointer.
See: ${PLANS}/${CONFLICT_RUNBOOK}
EOF
}

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }

gov002_stop() {
  log "GOV-002: $1"
  log "See: ${PLANS}/${CONFLICT_RUNBOOK}"
  return 1
}

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
  [ai-lib-plans]=c55b9dc
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

check_git_quiet() {
  local path="$1"
  [[ -f "${path}/.git/MERGE_HEAD" ]] && { gov002_stop "${path}: merge in progress"; return 1; }
  [[ -d "${path}/.git/rebase-merge" || -d "${path}/.git/rebase-apply" ]] && { gov002_stop "${path}: rebase in progress"; return 1; }
  if git -C "$path" diff 2>/dev/null | grep -q '^<<<<<<< '; then
    gov002_stop "${path}: conflict markers in working tree"
    return 1
  fi
  return 0
}

working_tree_dirty() {
  local path="$1"
  [[ -n "$(git -C "$path" status --porcelain 2>/dev/null)" ]]
}

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
  check_git_quiet "$path" || return 1

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
      git -C "$path" log --oneline --left-right lan/main...origin/main | head -20 || true
      gov002_stop "$name lan/origin both ahead — manual merge per runbook section 2"
      return 1
    fi
    if working_tree_dirty "$path"; then
      log "WARN: dirty working tree — skip reset (commit/stash first)"
    else
      run_git "$path" checkout main 2>/dev/null || true
      run_git "$path" reset --hard lan/main
    fi
  elif git -C "$path" rev-parse lan/main &>/dev/null; then
    if ! working_tree_dirty "$path"; then
      run_git "$path" checkout main 2>/dev/null || true
      run_git "$path" reset --hard lan/main
    fi
  else
    if ! working_tree_dirty "$path"; then
      run_git "$path" checkout main 2>/dev/null || true
      run_git "$path" reset --hard origin/main
    fi
  fi

  [[ "$NO_CLEAN" == "0" ]] && run_git "$path" clean -fd
  check_baseline "$name" "$path"
}

sync_public() {
  local name="$1" path ahead behind
  path="$(resolve_path "$name")"
  log "=== $name (public) $path ==="
  [[ -d "$path/.git" ]] || { log "SKIP: missing $path"; return 0; }
  check_git_quiet "$path" || return 1

  run_git "$path" fetch origin --prune
  run_git "$path" checkout main 2>/dev/null || true

  ahead="$(git -C "$path" rev-list --count origin/main..HEAD 2>/dev/null || echo 0)"
  behind="$(git -C "$path" rev-list --count HEAD..origin/main 2>/dev/null || echo 0)"

  if git -C "$path" diff --quiet origin/main..HEAD 2>/dev/null; then
    log "tree matches origin/main (ahead=$ahead behind=$behind) — reset OK"
    run_git "$path" reset --hard origin/main
  elif [[ "$ahead" -gt 0 ]]; then
    git -C "$path" diff origin/main..HEAD --stat | head -30 || true
    gov002_stop "$name local tree differs from origin/main — runbook section 3"
    return 1
  else
    run_git "$path" reset --hard origin/main
  fi

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
  log "Completed with $failed failure(s) — resolve via GOV-002 runbook"
  exit 1
fi
log "PT-073g repos aligned."
