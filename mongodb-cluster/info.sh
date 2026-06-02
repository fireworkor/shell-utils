#!/bin/bash
# MongoDB Cluster 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="mongodb-cluster"
DISPLAY_NAME="MongoDB Cluster"

echo -e "${BLUE}=== MongoDB Cluster 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  安装目录: /opt/mongodb-cluster"
echo "  日志目录: /var/log/mongodb-cluster"
echo "  数据目录: /var/lib/mongodb-cluster"
echo "  默认端口: 27017"
echo ""

if [ -d "/opt/mongodb-cluster" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
else
    echo -e "${RED}状态: 未安装${NC}"
fi
