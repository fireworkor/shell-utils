#!/bin/bash
# Flume 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="flume"
DISPLAY_NAME="Flume"

echo -e "${BLUE}=== Flume 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  安装目录: /opt/flume"
echo "  日志目录: /var/log/flume"
echo "  数据目录: /var/lib/flume"
echo "  默认端口: 44444"
echo ""

if [ -d "/opt/flume" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
else
    echo -e "${RED}状态: 未安装${NC}"
fi
