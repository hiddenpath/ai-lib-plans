#!/usr/bin/env bash
# ==========================================================================
# Spider Review Module
# Usage in OpenClaw session:
#   source /home/alex/ai-lib-plans/active/projects/ai-protocol/templates/SPIDER_REVIEW_MODULE.sh
#   spider_review "ai-lib-rust" "feat/pt-074-rust-credential-chain"
#
# Environment:
#   GITHUB_TOKEN - PAT for PR comment posting (optional for local review)
# ==========================================================================

set -euo pipefail

# Colors for output readability
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ─── Configuration ──────────────────────────────────────────────────────
AI_LIB_PLANS="/home/alex/ai-lib-plans"
WORKSPACE="/home/alex/.openclaw/workspace"

# ─── Functions ──────────────────────────────────────────────────────────

# Detect review depth based on diff content
# Returns: "deep" for core logic changes, "medium" for config changes, "shallow" for docs
detect_depth() {
    local repo="$1"
    local branch="$2"
    local base="${3:-main}"

    local changed_files
    changed_files=$(git -C "$repo" diff "$base".."$branch" --name-only)

    if echo "$changed_files" | grep -qE '\.rs$' && ! echo "$changed_files" | grep -qE '^CHANGELOG|^README|^docs/'; then
        echo "deep"
    elif echo "$changed_files" | grep -qE '\.yaml$|\.json$|Cargo\.toml'; then
        echo "medium"
    else
        echo "shallow"
    fi
}

# Check if a branch exists locally, fetch if not
ensure_branch() {
    local repo="$1"
    local branch="$2"

    echo -e "${CYAN}ℹ Ensuring branch: $branch${NC}"

    # Fetch with proxy
    if command -v http_proxy &>/dev/null || [ -n "${http_proxy:-}" ]; then
        git -C "$repo" fetch origin "$branch" 2>/dev/null || true
    else
        http_proxy=http://192.168.2.13:8887 https_proxy=http://192.168.2.13:8887 \
            git -C "$repo" fetch origin "$branch" 2>/dev/null || true
    fi

    # Check if branch exists
    if git -C "$repo" rev-parse --verify "origin/$branch" &>/dev/null; then
        # Checkout
        git -C "$repo" checkout -B "$branch" "origin/$branch" 2>/dev/null || \
            git -C "$repo" checkout "$branch" 2>/dev/null || \
            git -C "$repo" switch -c "$branch" "origin/$branch" 2>/dev/null
        return 0
    else
        echo -e "${RED}✗ Branch $branch not found in origin${NC}"
        return 1
    fi
}

# Run standard validation suite
run_validation() {
    local repo="$1"
    local depth="$2"
    local results=()

    echo -e "\n${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${CYAN}   Validation Suite${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"

    if [ "$depth" = "shallow" ]; then
        echo -e "${GREEN}→ Shallow review: skipping full tests, checking only format${NC}"
        if cargo fmt --all -- --check 2>&1; then
            results+=("PASS")
        else
            results+=("FAIL")
        fi
        echo "| cargo fmt | ${results[0]} |"
        return
    fi

    # Check 1: cargo fmt
    echo -ne "${CYAN}[1/4]${NC} cargo fmt --all -- --check ... "
    if cargo fmt --all -- --check 2>/dev/null; then
        echo -e "${GREEN}PASS${NC}"
        results+=("PASS")
    else
        echo -e "${RED}FAIL${NC}"
        results+=("FAIL")
    fi

    # Check 2: clippy
    echo -ne "${CYAN}[2/4]${NC} cargo clippy -Dwarnings ... "
    if cargo clippy --all-targets -- -D warnings 2>/dev/null; then
        echo -e "${GREEN}PASS${NC}"
        results+=("PASS")
    else
        echo -e "${RED}FAIL${NC}"
        results+=("FAIL")
    fi

    # Check 3: tests
    echo -ne "${CYAN}[3/4]${NC} cargo test -p ai-lib-core ... "
    local test_out
    test_out=$(cargo test -p ai-lib-core 2>&1 || true)
    if echo "$test_out" | grep -q 'test result: ok'; then
        local passed ignored
        passed=$(echo "$test_out" | grep 'test result: ok' | sed -n 's/.* \([0-9]*\) passed.*/\1/p')
        ignored=$(echo "$test_out" | grep 'test result: ok' | sed -n 's/.* \([0-9]*\) ignored.*/\1/p')
        echo -e "${GREEN}PASS (${passed} passed, ${ignored} ignored)${NC}"
        results+=("PASS")
    else
        echo -e "${RED}FAIL${NC}"
        results+=("FAIL")
    fi

    # Check 4: no-default-features (only when deep)
    if [ "$depth" = "deep" ]; then
        echo -ne "${CYAN}[4/4]${NC} cargo build --no-default-features ... "
        if cargo build -p ai-lib-core --no-default-features 2>/dev/null; then
            echo -e "${GREEN}PASS${NC}"
            results+=("PASS")
        else
            echo -e "${RED}FAIL${NC}"
            results+=("FAIL")
        fi
    else
        results+=("SKIP")
    fi

    # Summary
    echo -e "\n${CYAN}Validation Summary:${NC}"
    local checks=("fmt" "clippy" "test" "no-default-features")
    for i in "${!checks[@]}"; do
        if [ "${results[$i]}" = "PASS" ]; then
            echo -e "  ${GREEN}✅${NC} ${checks[$i]}"
        elif [ "${results[$i]}" = "SKIP" ]; then
            echo -e "  ${YELLOW}⏭${NC} ${checks[$i]}"
        else
            echo -e "  ${RED}❌${NC} ${checks[$i]}"
        fi
    done
}

# Print structured review report
print_report() {
    local repo="$1"
    local branch="$2"
    local depth="$3"
    local issues_file="$4"

    local head_sha
    head_sha=$(git -C "$repo" rev-parse HEAD 2>/dev/null || echo "unknown")
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M %Z')"

    cat <<EOF
## Review Report

<!-- REVIEW_META: {"branch":"${branch}","base":"main","head_sha":"${head_sha}","depth":"${depth}","reviewer":"Spider","timestamp":"${timestamp}"} -->

### Summary

Review of \`${branch}\` on \`${repo}\` (HEAD: \`${head_sha:0:7}\`). Depth level: **${depth}**.

### Issues

| ID | Severity | File | Issue | Status |
|----|----------|------|-------|--------|
EOF
    cat "$issues_file"
}

# Generate review issues from git diff + logical checks
# This is a stub that expects Spider to fill in via analysis
# Returns: markdown table lines to a temp file
analyze_diff() {
    local repo="$1"
    local branch="$2"
    local depth="$3"
    local output_file="$4"

    local base="${5:-main}"
    local diff_stats
    diff_stats=$(git -C "$repo" diff "$base".."$branch" --stat)

    # Write header for the issues (to be filled by Spider's LLM analysis)
    cat > "$output_file" <<EOF
| I1 | ℹ️ | (auto-detected) | Review \`git diff ${base}..${branch}\` to identify issues | ⏳ |
| I2 | ℹ️ | (auto-detected) | Check for common patterns: unconditional deps, test gaps, missing docs | ⏳ |
EOF

    # Auto-detection: check for unconditional keyring (common issue)
    if git -C "$repo" show HEAD:Cargo.toml 2>/dev/null | grep -qP '^keyring\s*=' && \
       ! git -C "$repo" show HEAD:Cargo.toml 2>/dev/null | grep -qP 'optional\s*=\s*true'; then
        sed -i '1s/.*/I1 | 🔴 | Cargo.toml | keyring 必须是可选的 feature flag（opt-in），不是 unconditional 硬依赖 | ⏳ |/' "$output_file"
    fi

    # Check for test files
    local test_count
    test_count=$(git -C "$repo" diff "$base".."$branch" --name-only | grep -c '_test\|test_' 2>/dev/null || echo "0")
    if [ "$test_count" -eq 0 ] && [ "$depth" = "deep" ]; then
        sed -i '2s/.*/I2 | 🟡 | (new code) | 深度变更应包含对应测试覆盖 | ⏳ |/' "$output_file"
    fi
}

# ─── Main Function ──────────────────────────────────────────────────────

spider_review() {
    local repo_name="${1:-}"
    local branch="${2:-}"

    if [ -z "$repo_name" ] || [ -z "$branch" ]; then
        echo -e "${RED}Usage: spider_review <repo_name> <branch>${NC}"
        echo -e "  e.g., spider_review ai-lib-rust feat/pt-074-rust-credential-chain"
        return 1
    fi

    # Resolve repo path
    local repo
    case "$repo_name" in
        ai-lib-rust) repo="$WORKSPACE/../ai-lib-rust" ;;
        ai-lib-rust) repo="/home/alex/ai-lib-rust" ;;
        ai-lib-python) repo="/home/alex/ai-lib-python" ;;
        ai-lib-ts) repo="/home/alex/ai-lib-ts" ;;
        ai-lib-go) repo="/home/alex/ai-lib-go" ;;
        ai-protocol) repo="/home/alex/ai-protocol" ;;
        ai-protocol-mock) repo="/home/alex/ai-protocol-mock" ;;
        *) echo -e "${RED}Unknown repo: $repo_name${NC}"; return 1 ;;
    esac

    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${CYAN}   Spider Review${NC}"
    echo -e "${CYAN}   Repo: ${repo_name}${NC}"
    echo -e "${CYAN}   Branch: ${branch}${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"

    # Step 1: Ensure branch
    ensure_branch "$repo" "$branch" || return 1

    # Step 2: Detect depth
    local depth
    depth=$(detect_depth "$repo" "$branch" "main")
    echo -e "${CYAN}→ Review depth: ${depth}${NC}"

    # Step 3: Analyze diff
    local issues_file
    issues_file=$(mktemp /tmp/spider-review-XXXXXX.md)
    analyze_diff "$repo" "$branch" "$depth" "$issues_file" "main"

    # Step 4: Print structured report
    print_report "$repo" "$branch" "$depth" "$issues_file"
    rm -f "$issues_file"

    # Step 5: Run validation
    cd "$repo"
    run_validation "$repo" "$depth"

    echo -e "\n${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${CYAN}   Review Complete${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "Report written to session output. Copy and post as PR comment."
}

# Export for use in session
export -f spider_review ensure_branch detect_depth run_validation analyze_diff print_report

echo -e "${GREEN}✅ Spider Review Module loaded${NC}"
echo -e "Usage: ${CYAN}spider_review <repo_name> <branch>${NC}"
echo -e "  e.g., ${YELLOW}spider_review ai-lib-rust feat/pt-074-rust-credential-chain${NC}"
