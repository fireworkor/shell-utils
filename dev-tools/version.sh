#!/bin/bash
# Dev Tools 版本管理脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

show_current_version() {
    if command -v dev-tools &>/dev/null; then
        echo -e "${GREEN}当前版本:${NC}"
        dev-tools --version 2>/dev/null || echo "版本信息不可用"
    else
        echo -e "${YELLOW}Dev Tools 未安装${NC}"
    fi
}

case "${1:-show}" in
    show|status)
        show_current_version
        ;;
    *)
        show_current_version
        echo "用法: $0 {show}"
        ;;
esac
