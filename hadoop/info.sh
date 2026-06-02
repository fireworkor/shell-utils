#!/bin/bash
# Hadoop 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="hadoop"
DISPLAY_NAME="Hadoop"

echo -e "${BLUE}=== Hadoop 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  安装目录: /opt/hadoop"
echo "  日志目录: /var/log/hadoop"
echo "  数据目录: /var/lib/hadoop"
echo ""

# 检查状态
if [ -d "/opt/hadoop" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
else
    echo -e "${RED}状态: 未安装${NC}"
fi
