#!/bin/bash
# HBase 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="hbase"
DISPLAY_NAME="HBase"

echo -e "${BLUE}=== HBase 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  安装目录: /opt/hbase"
echo "  日志目录: /var/log/hbase"
echo "  数据目录: /var/lib/hbase"
echo ""

# 检查状态
if [ -d "/opt/hbase" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
else
    echo -e "${RED}状态: 未安装${NC}"
fi
