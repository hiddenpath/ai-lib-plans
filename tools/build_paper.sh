#!/bin/bash
# build_paper.sh - 论文 LaTeX 项目编译脚本
# 遵循 DOC-003 学术论文工作流规范
#
# 用途：编译 papers 仓库下的 LaTeX 论文项目
# 编译器：pdflatex（无 shell-escape，无 minted）
# 编译序列：pdflatex → bibtex → pdflatex → pdflatex
#
# 示例：
#   bash tools/build_paper.sh /home/alex/papers/EN/paper1_cursor
#   bash tools/build_paper.sh /home/alex/papers/EN/paper1_cursor --clean
#   bash tools/build_paper.sh /home/alex/papers/EN/paper1_cursor --check-deps

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependencies() {
    local missing=0
    
    log_info "检查 LaTeX 编译依赖..."
    
    if ! command -v pdflatex &> /dev/null; then
        log_error "pdflatex 未安装"
        log_info "安装建议: sudo apt install texlive-latex-recommended"
        missing=1
    else
        log_info "✓ pdflatex 已安装"
    fi
    
    if ! command -v bibtex &> /dev/null; then
        log_error "bibtex 未安装"
        log_info "安装建议: sudo apt install texlive-bibtex-extra"
        missing=1
    else
        log_info "✓ bibtex 已安装"
    fi
    
    # 检查 lmodern 字体包（可选，main.tex 已有 fallback）
    if ! kpsewhich lmodern.sty &> /dev/null 2>&1; then
        log_warn "lmodern.sty 未找到（将使用默认 CM 字体）"
        log_info "安装建议: sudo apt install texlive-fonts-recommended"
    else
        log_info "✓ lmodern 字体包可用"
    fi
    
    # 检查 microtype（可选）
    if ! kpsewhich microtype.sty &> /dev/null 2>&1; then
        log_warn "microtype.sty 未找到（可选）"
        log_info "安装建议: sudo apt install texlive-latex-extra"
    else
        log_info "✓ microtype 包可用"
    fi
    
    # 检查 tikz（论文必需）
    if ! kpsewhich tikz.sty &> /dev/null 2>&1; then
        log_warn "tikz.sty 未找到（论文图形需要）"
        log_info "安装建议: sudo apt install texlive-pictures"
    else
        log_info "✓ tikz 包可用"
    fi
    
    # 检查 subcaption（可选）
    if ! kpsewhich subcaption.sty &> /dev/null 2>&1; then
        log_warn "subcaption.sty 未找到（子图需要）"
    else
        log_info "✓ subcaption 包可用"
    fi
    
    # 检查 enumitem（可选但常见）
    if ! kpsewhich enumitem.sty &> /dev/null 2>&1; then
        log_warn "enumitem.sty 未找到（列表定制需要）"
        log_info "安装建议: sudo apt install texlive-latex-extra"
    else
        log_info "✓ enumitem 包可用"
    fi
    
    # 检查 cleveref（引用增强）
    if ! kpsewhich cleveref.sty &> /dev/null 2>&1; then
        log_warn "cleveref.sty 未找到（智能引用）"
        log_info "安装建议: sudo apt install texlive-latex-extra"
    else
        log_info "✓ cleveref 包可用"
    fi
    
    if [ $missing -eq 1 ]; then
        log_error "缺少必要依赖，请先安装"
        return 1
    fi
    
    log_info "所有依赖检查通过"
    return 0
}

# 清理中间文件
clean_aux_files() {
    local dir="$1"
    log_info "清理中间文件..."
    
    rm -f "$dir"/*.aux "$dir"/*.log "$dir"/*.bbl "$dir"/*.blg \
          "$dir"/*.out "$dir"/*.toc "$dir"/*.lof "$dir"/*.lot \
          "$dir"/*.fls "$dir"/*.fdb_latexmk "$dir"/*.synctex.gz
    
    log_info "清理完成"
}

# 编译论文
build_paper() {
    local dir="$1"
    local main_tex="$dir/main.tex"
    
    if [ ! -f "$main_tex" ]; then
        log_error "未找到 main.tex: $main_tex"
        return 1
    fi
    
    log_info "开始编译: $main_tex"
    cd "$dir"
    
    # 第一次 pdflatex
    log_info "第一次 pdflatex 运行..."
    pdflatex -interaction=nonstopmode main.tex > /dev/null 2>&1
    # 检查是否生成了 PDF
    if [ ! -f "main.pdf" ]; then
        log_error "第一次 pdflatex 失败（未生成 PDF）"
        return 1
    fi
    
    # bibtex
    log_info "运行 bibtex..."
    if [ -f "bibliography/refs.bib" ]; then
        bibtex main > /dev/null 2>&1 || log_warn "bibtex 运行有问题（可能无引用）"
    else
        log_info "跳过 bibtex（无参考文献文件）"
    fi
    
    # 第二次 pdflatex
    log_info "第二次 pdflatex 运行..."
    pdflatex -interaction=nonstopmode main.tex > /dev/null 2>&1
    
    # 第三次 pdflatex（确保引用正确）
    log_info "第三次 pdflatex 运行..."
    pdflatex -interaction=nonstopmode main.tex > /dev/null 2>&1
    
    log_info "编译完成: $dir/main.pdf"
    
    # 显示 PDF 信息
    if [ -f "$dir/main.pdf" ]; then
        local size=$(du -h "$dir/main.pdf" | cut -f1)
        log_info "PDF 大小: $size"
    fi
    
    return 0
}

# 主函数
main() {
    local paper_dir=""
    local clean=0
    local check_only=0
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean)
                clean=1
                shift
                ;;
            --check-deps)
                check_only=1
                shift
                ;;
            *)
                if [ -z "$paper_dir" ]; then
                    paper_dir="$1"
                else
                    log_error "未知参数: $1"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # 仅检查依赖模式
    if [ $check_only -eq 1 ]; then
        check_dependencies
        exit $?
    fi
    
    # 验证目录
    if [ -z "$paper_dir" ]; then
        log_error "请指定论文目录"
        echo "用法: $0 <paper_directory> [--clean] [--check-deps]"
        echo "示例: $0 /home/alex/papers/EN/paper1_cursor"
        exit 1
    fi
    
    if [ ! -d "$paper_dir" ]; then
        log_error "目录不存在: $paper_dir"
        exit 1
    fi
    
    # 检查依赖
    if ! check_dependencies; then
        exit 1
    fi
    
    # 清理模式
    if [ $clean -eq 1 ]; then
        clean_aux_files "$paper_dir"
    fi
    
    # 编译
    if build_paper "$paper_dir"; then
        log_info "✓ 论文编译成功"
        exit 0
    else
        log_error "✗ 论文编译失败"
        exit 1
    fi
}

main "$@"
