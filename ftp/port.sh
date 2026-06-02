#!/bin/bash
# FTP 端口管理脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

DEFAULT_PORTS="21"

show_ports() {
    echo -e "${BLUE}=== FTP 端口配置 ===${NC}"
    echo "  默认端口: $DEFAULT_PORTS"
    
    # 检查端口监听
    for port in $(echo $DEFAULT_PORTS | tr ',' ' '); do
        if command -v ss &>/dev/null; then
            if ss -tuln | grep -q ":$port "; then
                echo -e "  ${GREEN}✓ 端口 $port 正在监听${NC}"
            else
                echo "  - 端口 $port 未监听"
            fi
        fi
    done
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
