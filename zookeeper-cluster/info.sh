#!/bin/bash
# ZooKeeper Cluster 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="zookeeper-cluster"
DISPLAY_NAME="ZooKeeper Cluster"

echo -e "${BLUE}=== ZooKeeper Cluster 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  安装目录: /opt/zookeeper-cluster"
echo "  日志目录: /var/log/zookeeper-cluster"
echo "  数据目录: /var/lib/zookeeper-cluster"
echo "  默认端口: 2181"
echo ""

if [ -d "/opt/zookeeper-cluster" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
else
    echo -e "${RED}状态: 未安装${NC}"
fi
