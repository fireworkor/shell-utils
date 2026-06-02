#!/bin/bash
# HAProxy 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="haproxy"
DISPLAY_NAME="HAProxy"

echo -e "${BLUE}=== HAProxy 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  安装目录: /opt/haproxy"
echo "  日志目录: /var/log/haproxy"
echo "  数据目录: /var/lib/haproxy"
echo "  默认端口: 80,443"
echo ""

if [ -d "/opt/haproxy" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
else
    echo -e "${RED}状态: 未安装${NC}"
fi
