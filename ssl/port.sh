#!/bin/bash
# SSL 端口管理脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

show_ports() {
    echo -e "${BLUE}=== SSL 端口配置 ===${NC}"
    echo "  SSL 不需要网络端口"
    echo "  或端口由配置文件动态指定"
}

case "${1:-show}" in
    show|list)
        show_ports
        ;;
    *)
        show_ports
        echo "用法: $0 {show}"
        ;;
esac
