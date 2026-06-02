#!/bin/bash
# ArgoCD 版本管理脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

show_current_version() {
    echo "ArgoCD 版本管理"
    echo "请手动检查安装的版本"
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
