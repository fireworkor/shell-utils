#!/bin/bash
# SQLite 端口管理脚本
# SQLite 是嵌入式数据库，不需要网络端口

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

show_ports() {
    echo -e "${BLUE}=== SQLite 端口配置 ===${NC}"
    echo "  SQLite 是嵌入式数据库"
    echo "  不需要网络端口"
    echo "  通过文件直接访问数据库"
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
