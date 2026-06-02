#!/bin/bash
# Flink 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="flink"
DISPLAY_NAME="Flink"

echo -e "${BLUE}=== Flink 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  安装目录: /opt/flink"
echo "  日志目录: /var/log/flink"
echo "  数据目录: /var/lib/flink"
echo ""

# 检查状态
if [ -d "/opt/flink" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
else
    echo -e "${RED}状态: 未安装${NC}"
fi
