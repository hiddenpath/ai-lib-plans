#!/usr/bin/env bash
# ubuntu_dev_disk_cleanup.sh — Ubuntu 开发机短期、可重复磁盘清理
# 参照 win_dev_disk_cleanup.ps1 设计：默认演练、白名单路径、前后对比
# 融合 ~/cleansnapd.sh 的 snap 旧版本清理功能
set -uo pipefail

SCRIPT_VERSION="1.0.0"
DRY_RUN=1
INCLUDE_SYSTEM_TMP=0
INCLUDE_OLD_KERNELS=0
INCLUDE_SNAP_DISABLED=0
INCLUDE_TRASH=0
INCLUDE_NPM_CACHE=0
INCLUDE_PIP_CACHE=0
INCLUDE_CARGO_CACHE=0
INCLUDE_GO_CACHE=0
INCLUDE_PLAYWRIGHT_CACHE=0
INCLUDE_CHROME_CACHE=0
INCLUDE_THUMBNAILS=0
INCLUDE_APT_CACHE=0
INCLUDE_JOURNAL=0
INCLUDE_USER_TEMP=0
INCLUDE_JETBRAINS_OLD=0
INCLUDE_FONT_CACHE=0
INCLUDE_NODE_GYP_CACHE=0
ALL=0
YES=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

usage() {
cat <<EOF
${BOLD}ubuntu_dev_disk_cleanup.sh${NC} v${SCRIPT_VERSION}
Ubuntu 开发机短期磁盘清理（安全、可重复）

${BOLD}用法${NC}:
  $0 [选项]

${BOLD}安全模型${NC}:
  默认为 ${YELLOW}演练模式${NC}（只统计、不删除）。加 ${GREEN}--execute${NC} 才真正清理。
  仅清理白名单路径，不触碰项目仓库、.rustup/toolchains、IDE 扩展等。

${BOLD}选项${NC}:
  --execute                 真实执行清理（默认只演练）
  --all                     启用所有清理项（不含 --execute）
  -y / --yes                跳过执行前确认提示

${BOLD}清理项（默认均不启用，按需指定或用 --all）${NC}:
  --user-temp               清理用户临时目录 /tmp 下属于当前用户的子项
  --system-tmp              清理 /var/tmp（需 sudo）
  --apt-cache               清理 apt 下载缓存（sudo apt clean）
  --old-kernels             清理残余内核包（dpkg -l '^rc' + autoremove，需 sudo）
  --journal                 轮转并限制 systemd 日志至 7 天（需 sudo）
  --snap-disabled           移除 snap 旧版本（源自 ~/cleansnapd.sh，需关闭对应 snap）
  --trash                   清空用户回收站
  --npm-cache               清理 npm 缓存（npm cache clean --force）
  --pip-cache               清理 pip 缓存（pip cache purge）
  --cargo-cache             清理 Cargo 注册表缓存（~/.cargo/registry/cache）
  --go-cache                清理 Go 构建缓存（go clean -cache）
  --playwright-cache        清理 Playwright 浏览器驱动缓存（~/.cache/ms-playwright）
  --chrome-cache            清理 Google Chrome 缓存（~/.cache/google-chrome）
  --thumbnails              清理缩略图缓存（~/.cache/thumbnails）
  --jetbrains-old           清理旧版 PyCharm 本地数据（~/.local/share/JetBrains/PyCharmCE* 非最新版）
  --font-cache              清理字体缓存（~/.cache/fontconfig，fc-cache -f 重建）
  --node-gyp-cache          清理 node-gyp 缓存（~/.cache/node-gyp）

${BOLD}示例${NC}:
  演练全部:        $0 --all
  执行全部:        $0 --all --execute
  仅清理缓存类:    $0 --npm-cache --pip-cache --cargo-cache --go-cache --execute
  安全项执行:      $0 --user-temp --trash --thumbnails --apt-cache --execute
  含内核清理:      $0 --old-kernels --snap-disabled --apt-cache --journal --execute

${BOLD}风险提示${NC}:
  --execute 前建议关闭 IDE 和浏览器；--old-kernels 会 purging 残余内核包；
  --snap-disabled 需先关闭对应 snap 应用；--playwright-cache 删除后下次运行需重新下载驱动。
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --execute)       DRY_RUN=0 ;;
            --all)           ALL=1 ;;
            -y|--yes)        YES=1 ;;
            --user-temp)     INCLUDE_USER_TEMP=1 ;;
            --system-tmp)    INCLUDE_SYSTEM_TMP=1 ;;
            --apt-cache)     INCLUDE_APT_CACHE=1 ;;
            --old-kernels)   INCLUDE_OLD_KERNELS=1 ;;
            --journal)       INCLUDE_JOURNAL=1 ;;
            --snap-disabled) INCLUDE_SNAP_DISABLED=1 ;;
            --trash)         INCLUDE_TRASH=1 ;;
            --npm-cache)     INCLUDE_NPM_CACHE=1 ;;
            --pip-cache)     INCLUDE_PIP_CACHE=1 ;;
            --cargo-cache)   INCLUDE_CARGO_CACHE=1 ;;
            --go-cache)      INCLUDE_GO_CACHE=1 ;;
            --playwright-cache) INCLUDE_PLAYWRIGHT_CACHE=1 ;;
            --chrome-cache)  INCLUDE_CHROME_CACHE=1 ;;
            --thumbnails)    INCLUDE_THUMBNAILS=1 ;;
            --jetbrains-old) INCLUDE_JETBRAINS_OLD=1 ;;
            --font-cache)    INCLUDE_FONT_CACHE=1 ;;
            --node-gyp-cache) INCLUDE_NODE_GYP_CACHE=1 ;;
            -h|--help)       usage; exit 0 ;;
            *) echo "未知参数: $1"; usage; exit 1 ;;
        esac
        shift
    done

    if [[ $ALL -eq 1 ]]; then
        INCLUDE_USER_TEMP=1
        INCLUDE_SYSTEM_TMP=1
        INCLUDE_APT_CACHE=1
        INCLUDE_OLD_KERNELS=1
        INCLUDE_JOURNAL=1
        INCLUDE_SNAP_DISABLED=1
        INCLUDE_TRASH=1
        INCLUDE_NPM_CACHE=1
        INCLUDE_PIP_CACHE=1
        INCLUDE_CARGO_CACHE=1
        INCLUDE_GO_CACHE=1
        INCLUDE_PLAYWRIGHT_CACHE=1
        INCLUDE_CHROME_CACHE=1
        INCLUDE_THUMBNAILS=1
        INCLUDE_JETBRAINS_OLD=1
        INCLUDE_FONT_CACHE=1
        INCLUDE_NODE_GYP_CACHE=1
    fi
}

format_bytes() {
    local bytes=$1
    if [[ $bytes -ge 1073741824 ]]; then
        echo "$(awk "BEGIN{printf \"%.2f\", $bytes/1073741824}") GB"
    elif [[ $bytes -ge 1048576 ]]; then
        echo "$(awk "BEGIN{printf \"%.1f\", $bytes/1048576}") MB"
    elif [[ $bytes -ge 1024 ]]; then
        echo "$(awk "BEGIN{printf \"%.1f\", $bytes/1024}") KB"
    else
        echo "$bytes B"
    fi
}

format_kb() {
    local kb=$1
    if [[ $kb -ge 1048576 ]]; then
        echo "$(awk "BEGIN{printf \"%.2f\", $kb/1048576}") GB"
    elif [[ $kb -ge 1024 ]]; then
        echo "$(awk "BEGIN{printf \"%.1f\", $kb/1024}") MB"
    else
        echo "$kb KB"
    fi
}

get_free_space_kb() {
    local mount_point="${1:-/}"
    df --output=avail "$mount_point" | tail -1 | tr -d ' '
}

du_sh_safe() {
    local path="$1"
    if [[ -e "$path" ]]; then
        du -sb "$path" 2>/dev/null | awk '{print $1}'
    else
        echo 0
    fi
}

du_sh_kb() {
    local path="$1"
    if [[ -e "$path" ]]; then
        du -sk "$path" 2>/dev/null | awk '{print $1}'
    else
        echo 0
    fi
}

total_reclaimable=0

add_estimate() {
    local label="$1"
    local path="$2"
    local bytes
    bytes=$(du_sh_safe "$path")
    total_reclaimable=$((total_reclaimable + bytes))
    if [[ $bytes -gt 0 ]]; then
        printf "  %-42s %s\n" "$label" "$(format_bytes $bytes)"
    fi
}

add_estimate_kb() {
    local label="$1"
    local kb="$2"
    total_reclaimable=$((total_reclaimable + kb * 1024))
    if [[ $kb -gt 0 ]]; then
        printf "  %-42s %s\n" "$label" "$(format_kb $kb)"
    fi
}

print_header() {
    echo ""
    echo -e "${BOLD}${CYAN}=== $1 ===${NC}"
}

print_section() {
    echo ""
    echo -e "${BOLD}-- $1 --${NC}"
}

report_estimate() {
    echo ""
    print_header "ubuntu_dev_disk_cleanup v${SCRIPT_VERSION}"
    local mount="/"
    local free_kb
    free_kb=$(get_free_space_kb "$mount")
    local total_kb
    total_kb=$(df --output=size "$mount" | tail -1 | tr -d ' ')
    local used_pct
    used_pct=$(df --output=pcent "$mount" | tail -1 | tr -d ' %')
    echo "  分区 / : 总 $(format_kb $total_kb) | 已用 ${used_pct}% | 可用 $(format_kb $free_kb)"
    if [[ $DRY_RUN -eq 1 ]]; then
        echo -e "  模式: ${YELLOW}DRY-RUN（只统计，不删除）${NC}"
    else
        echo -e "  模式: ${RED}EXECUTE（将执行真实清理）${NC}"
    fi

    print_section "可回收空间估算"

    # 1. 用户临时目录 /tmp 下当前用户的子项
    if [[ $INCLUDE_USER_TEMP -eq 1 ]]; then
        local tmp_user_kb=0
        if [[ -d /tmp ]]; then
            for d in /tmp/*/; do
                [[ -d "$d" ]] || continue
                local owner
                owner=$(stat -c '%U' "$d" 2>/dev/null || true)
                if [[ "$owner" == "$(id -un)" ]]; then
                    local s
                    s=$(du -sk "$d" 2>/dev/null | awk '{print $1}')
                    tmp_user_kb=$((tmp_user_kb + s))
                fi
            done
        fi
        add_estimate_kb "/tmp (用户文件)" "$tmp_user_kb"
    fi

    # 2. /var/tmp
    if [[ $INCLUDE_SYSTEM_TMP -eq 1 ]]; then
        add_estimate "/var/tmp" "/var/tmp"
    fi

    # 3. apt 缓存
    if [[ $INCLUDE_APT_CACHE -eq 1 ]]; then
        local apt_kb=0
        if [[ -d /var/cache/apt/archives ]]; then
            apt_kb=$(du -sk /var/cache/apt/archives 2>/dev/null | awk '{print $1}')
        fi
        add_estimate_kb "apt 缓存 (/var/cache/apt/archives)" "$apt_kb"
    fi

    # 4. 残余内核包
    if [[ $INCLUDE_OLD_KERNELS -eq 1 ]]; then
        local rc_count
        rc_count=$(dpkg -l 'linux-image-*' 'linux-headers-*' 'linux-modules-*' 'linux-modules-extra-*' 2>/dev/null | grep -c '^rc' || true)
        if [[ $rc_count -gt 0 ]]; then
            add_estimate_kb "残余内核/模块包 (rc 状态, ${rc_count} 个)" "$((rc_count * 250000))"
        fi
    fi

    # 5. systemd journal
    if [[ $INCLUDE_JOURNAL -eq 1 ]]; then
        local journal_kb=0
        if [[ -d /var/log/journal ]]; then
            journal_kb=$(du -sk /var/log/journal 2>/dev/null | awk '{print $1}')
        fi
        add_estimate_kb "systemd journal (/var/log/journal)" "$journal_kb"
    fi

    # 6. snap 旧版本
    if [[ $INCLUDE_SNAP_DISABLED -eq 1 ]]; then
        local snap_disabled_kb=0
        local snap_tmp_file
        snap_tmp_file=$(mktemp)
        snap list --all 2>/dev/null | awk '/disabled/{print $1, $3}' > "$snap_tmp_file" || true
        while IFS=' ' read -r snap_name rev; do
            [[ -n "$snap_name" && -n "$rev" ]] || continue
            local snap_dir="/snap/${snap_name}/${rev}"
            if [[ -d "$snap_dir" ]]; then
                local s
                s=$(du -sk "$snap_dir" 2>/dev/null | awk '{print $1+0}')
                snap_disabled_kb=$((snap_disabled_kb + s))
            fi
        done < "$snap_tmp_file"
        rm -f "$snap_tmp_file"
        add_estimate_kb "snap 旧版本 (disabled revisions)" "$snap_disabled_kb"
    fi

    # 7. 回收站
    if [[ $INCLUDE_TRASH -eq 1 ]]; then
        add_estimate "回收站" "${HOME}/.local/share/Trash"
    fi

    # 8. npm 缓存
    if [[ $INCLUDE_NPM_CACHE -eq 1 ]]; then
        add_estimate "npm 缓存 (~/.npm)" "${HOME}/.npm"
    fi

    # 9. pip 缓存
    if [[ $INCLUDE_PIP_CACHE -eq 1 ]]; then
        add_estimate "pip 缓存 (~/.cache/pip)" "${HOME}/.cache/pip"
    fi

    # 10. Cargo 注册表缓存
    if [[ $INCLUDE_CARGO_CACHE -eq 1 ]]; then
        add_estimate "Cargo 注册表缓存" "${HOME}/.cargo/registry/cache"
    fi

    # 11. Go 构建缓存
    if [[ $INCLUDE_GO_CACHE -eq 1 ]]; then
        add_estimate "Go 构建缓存 (~/.cache/go-build)" "${HOME}/.cache/go-build"
    fi

    # 12. Playwright 浏览器驱动
    if [[ $INCLUDE_PLAYWRIGHT_CACHE -eq 1 ]]; then
        add_estimate "Playwright 浏览器驱动" "${HOME}/.cache/ms-playwright"
    fi

    # 13. Chrome 缓存
    if [[ $INCLUDE_CHROME_CACHE -eq 1 ]]; then
        add_estimate "Chrome 缓存" "${HOME}/.cache/google-chrome"
    fi

    # 14. 缩略图
    if [[ $INCLUDE_THUMBNAILS -eq 1 ]]; then
        add_estimate "缩略图缓存" "${HOME}/.cache/thumbnails"
    fi

    # 15. JetBrains 旧版数据
    if [[ $INCLUDE_JETBRAINS_OLD -eq 1 ]]; then
        local jb_total_bytes=0
        local latest_jb
        latest_jb=$(ls -d "${HOME}/.local/share/JetBrains/PyCharmCE"* 2>/dev/null | sort -V | tail -1 || true)
        for d in "${HOME}/.local/share/JetBrains/PyCharmCE"*; do
            [[ -d "$d" ]] || continue
            if [[ -n "$latest_jb" && "$d" != "$latest_jb" ]]; then
                local s
                s=$(du -sb "$d" 2>/dev/null | awk '{print $1}')
                jb_total_bytes=$((jb_total_bytes + s))
            fi
        done
        add_estimate_kb "JetBrains 旧版数据" "$((jb_total_bytes / 1024))"
    fi

    # 16. 字体缓存
    if [[ $INCLUDE_FONT_CACHE -eq 1 ]]; then
        add_estimate "字体缓存" "${HOME}/.cache/fontconfig"
    fi

    # 17. node-gyp 缓存
    if [[ $INCLUDE_NODE_GYP_CACHE -eq 1 ]]; then
        add_estimate "node-gyp 缓存" "${HOME}/.cache/node-gyp"
    fi

    echo ""
    echo -e "  ${BOLD}估算可回收总量（上界）: $(format_bytes $total_reclaimable)${NC}"
}

execute_cleanup() {
    print_section "执行清理"

    # 1. /tmp 用户文件
    if [[ $INCLUDE_USER_TEMP -eq 1 ]]; then
        echo "[user-temp] 清理 /tmp 下属于 $(id -un) 的文件..."
        find /tmp -maxdepth 1 -user "$(id -un)" -type d -exec rm -rf {} + 2>/dev/null || true
    fi

    # 2. /var/tmp
    if [[ $INCLUDE_SYSTEM_TMP -eq 1 ]]; then
        echo "[system-tmp] 清理 /var/tmp..."
        sudo rm -rf /var/tmp/* 2>/dev/null || true
    fi

    # 3. apt 缓存
    if [[ $INCLUDE_APT_CACHE -eq 1 ]]; then
        echo "[apt-cache] sudo apt clean..."
        sudo apt clean 2>/dev/null || echo "  [warn] apt clean 失败（非 root?）"
    fi

    # 4. 残余内核包
    if [[ $INCLUDE_OLD_KERNELS -eq 1 ]]; then
        echo "[old-kernels] 清理残余内核包 (rc 状态)..."
        local rc_pkgs
        rc_pkgs=$(dpkg -l 'linux-image-*' 'linux-headers-*' 'linux-modules-*' 'linux-modules-extra-*' 2>/dev/null | grep '^rc' | awk '{print $2}' || true)
        if [[ -n "$rc_pkgs" ]]; then
            echo "$rc_pkgs" | xargs sudo dpkg --purge 2>/dev/null || echo "  [warn] 部分包 purge 失败"
        fi
        echo "[old-kernels] sudo apt autoremove -y..."
        sudo apt autoremove -y 2>/dev/null || echo "  [warn] autoremove 失败"
    fi

    # 5. systemd journal
    if [[ $INCLUDE_JOURNAL -eq 1 ]]; then
        echo "[journal] 限制 systemd 日志至 7 天..."
        sudo journalctl --rotate 2>/dev/null || true
        sudo journalctl --vacuum-time=7d 2>/dev/null || echo "  [warn] journal vacuum 失败"
    fi

    # 6. snap 旧版本
    if [[ $INCLUDE_SNAP_DISABLED -eq 1 ]]; then
        echo "[snap-disabled] 移除 snap 旧版本（源自 ~/cleansnapd.sh）..."
        snap list --all 2>/dev/null | awk '/disabled/{print $1, $3}' | while read -r snapname revision; do
            echo "  snap remove \"$snapname\" --revision=\"$revision\""
            snap remove "$snapname" --revision="$revision" 2>/dev/null || echo "  [warn] 移除 $snapname rev $revision 失败"
        done
    fi

    # 7. 回收站
    if [[ $INCLUDE_TRASH -eq 1 ]]; then
        echo "[trash] 清空回收站..."
        rm -rf "${HOME}/.local/share/Trash/files"/* 2>/dev/null || true
        rm -rf "${HOME}/.local/share/Trash/info"/* 2>/dev/null || true
        rm -rf "${HOME}/.local/share/Trash/expunged"/* 2>/dev/null || true
    fi

    # 8. npm 缓存
    if [[ $INCLUDE_NPM_CACHE -eq 1 ]]; then
        echo "[npm-cache] npm cache clean --force..."
        if command -v npm &>/dev/null; then
            npm cache clean --force 2>/dev/null || echo "  [warn] npm cache clean 失败"
        else
            echo "  [skip] npm 未安装"
        fi
    fi

    # 9. pip 缓存
    if [[ $INCLUDE_PIP_CACHE -eq 1 ]]; then
        echo "[pip-cache] pip cache purge..."
        if python3 -m pip cache purge &>/dev/null; then
            :
        elif command -v pip &>/dev/null; then
            pip cache purge 2>/dev/null || echo "  [warn] pip cache purge 失败"
        else
            echo "  [skip] pip 未安装"
        fi
    fi

    # 10. Cargo 注册表缓存
    if [[ $INCLUDE_CARGO_CACHE -eq 1 ]]; then
        echo "[cargo-cache] 清理 ~/.cargo/registry/cache..."
        rm -rf "${HOME}/.cargo/registry/cache"/* 2>/dev/null || true
    fi

    # 11. Go 构建缓存
    if [[ $INCLUDE_GO_CACHE -eq 1 ]]; then
        echo "[go-cache] go clean -cache..."
        if command -v go &>/dev/null; then
            go clean -cache 2>/dev/null || echo "  [warn] go clean 失败"
        else
            echo "  [skip] go 未安装"
            rm -rf "${HOME}/.cache/go-build"/* 2>/dev/null || true
        fi
    fi

    # 12. Playwright 浏览器驱动
    if [[ $INCLUDE_PLAYWRIGHT_CACHE -eq 1 ]]; then
        echo "[playwright-cache] 清理 ~/.cache/ms-playwright..."
        rm -rf "${HOME}/.cache/ms-playwright"/* 2>/dev/null || true
    fi

    # 13. Chrome 缓存
    if [[ $INCLUDE_CHROME_CACHE -eq 1 ]]; then
        echo "[chrome-cache] 清理 ~/.cache/google-chrome..."
        rm -rf "${HOME}/.cache/google-chrome"/* 2>/dev/null || true
    fi

    # 14. 缩略图
    if [[ $INCLUDE_THUMBNAILS -eq 1 ]]; then
        echo "[thumbnails] 清理 ~/.cache/thumbnails..."
        rm -rf "${HOME}/.cache/thumbnails"/* 2>/dev/null || true
    fi

    # 15. JetBrains 旧版数据
    if [[ $INCLUDE_JETBRAINS_OLD -eq 1 ]]; then
        echo "[jetbrains-old] 清理旧版 PyCharm 本地数据..."
        local latest_jb
        latest_jb=$(ls -d "${HOME}/.local/share/JetBrains/PyCharmCE"* 2>/dev/null | sort -V | tail -1 || true)
        for d in "${HOME}/.local/share/JetBrains/PyCharmCE"*; do
            [[ -d "$d" ]] || continue
            if [[ -n "$latest_jb" && "$d" != "$latest_jb" ]]; then
                echo "  rm -rf $d"
                rm -rf "$d"
            fi
        done
    fi

    # 16. 字体缓存
    if [[ $INCLUDE_FONT_CACHE -eq 1 ]]; then
        echo "[font-cache] 清理 ~/.cache/fontconfig..."
        rm -rf "${HOME}/.cache/fontconfig"/* 2>/dev/null || true
        if command -v fc-cache &>/dev/null; then
            echo "  fc-cache -f 重建字体缓存..."
            fc-cache -f 2>/dev/null || true
        fi
    fi

    # 17. node-gyp 缓存
    if [[ $INCLUDE_NODE_GYP_CACHE -eq 1 ]]; then
        echo "[node-gyp-cache] 清理 ~/.cache/node-gyp..."
        rm -rf "${HOME}/.cache/node-gyp"/* 2>/dev/null || true
    fi
}

main() {
    parse_args "$@"

    local free_before_kb
    free_before_kb=$(get_free_space_kb "/")

    report_estimate

    if [[ $DRY_RUN -eq 1 ]]; then
        echo ""
        echo -e "${YELLOW}[DRY-RUN] 未做任何更改。加 --execute 执行真实清理。${NC}"
        echo -e "  例: $0 --all --execute"
        echo -e "  例: $0 --npm-cache --pip-cache --user-temp --apt-cache --execute"
        local free_after_kb
        free_after_kb=$(get_free_space_kb "/")
        echo ""
        echo "  分区 / 可用: $(format_kb $free_after_kb) (前后一致，因演练不删除)"
        exit 0
    fi

    if [[ $YES -eq 0 ]]; then
        echo ""
        echo -e "${RED}即将执行真实清理！请确认已关闭 IDE 和浏览器。${NC}"
        read -rp "继续? [y/N] " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "已取消。"
            exit 0
        fi
    fi

    execute_cleanup

    local free_after_kb
    free_after_kb=$(get_free_space_kb "/")
    local delta_kb=$((free_after_kb - free_before_kb))

    echo ""
    print_header "清理结果"
    echo "  分区 / 可用 (清理前): $(format_kb $free_before_kb)"
    echo "  分区 / 可用 (清理后): $(format_kb $free_after_kb)"
    echo -e "  Delta: ${GREEN}+$(format_kb $delta_kb)${NC}"
    if [[ $delta_kb -lt 0 ]]; then
        echo -e "  ${YELLOW}[warn] 可用空间下降（其他进程可能正在写入）${NC}"
    fi
}

main "$@"
