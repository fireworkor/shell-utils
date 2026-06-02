#!/bin/bash
# MySQL Cluster 端口管理脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

DEFAULT_PORTS="3306"

show_ports() {
    echo -e "${BLUE}=== MySQL Cluster 端口配置 ===${NC}"
    echo "  默认端口: $DEFAULT_PORTS"
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
