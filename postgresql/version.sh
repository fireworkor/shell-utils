#!/bin/bash
# PostgreSQL 版本管理脚本
# 支持查看、切换、列出可用版本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="postgresql"
SOFTWARE_NAME="postgresql"
DISPLAY_NAME="PostgreSQL"
SCRIPT_DIR_REF="$SCRIPT_DIR"

# 显示当前版本
show_current_version() {
    if command -v ${SERVICE_NAME} &>/dev/null; then
        local version=$(${SERVICE_NAME} --version 2>&1 | head -1 || echo "未知")
        echo -e "${GREEN}当前版本:${NC} $version"
    else
        echo -e "${YELLOW}软件未安装${NC}"
    fi
}

# 列出可用版本
list_versions() {
    echo -e "${BLUE}=== 可用版本 ===${NC}"
    echo "  1.0.0"
    echo "  1.5.0"
    echo "  2.0.0"
    echo "  latest"
}

# 切换版本
switch_version() {
    local version=$1
    if [ -z "$version" ]; then
        print_error "请指定要切换的版本"
        return 1
    fi

    if ! command -v ${SERVICE_NAME} &>/dev/null; then
        print_error "${DISPLAY_NAME} 未安装"
        return 1
    fi

    print_warning "切换版本将需要先卸载当前版本"
    if confirm "确认切换到版本 $version?"; then
        bash "$SCRIPT_DIR_REF/uninstall.sh" || true
        bash "$SCRIPT_DIR_REF/install.sh" "$version"
        print_success "版本切换完成"
    fi
}

case "${1:-show}" in
    show|status)
        show_current_version
        ;;
    list|ls)
        list_versions
        ;;
    switch|set)
        switch_version "$2"
        ;;
    *)
        show_current_version
        echo ""
        echo "用法: $0 {show|list|switch <version>}"
        ;;
esac
