#!/bin/bash
# Kafka Cluster 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="kafka-cluster"
DISPLAY_NAME="Kafka Cluster"

echo -e "${BLUE}=== Kafka Cluster 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  安装目录: /opt/kafka-cluster"
echo "  日志目录: /var/log/kafka-cluster"
echo "  数据目录: /var/lib/kafka-cluster"
echo "  默认端口: 9092"
echo ""

if [ -d "/opt/kafka-cluster" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
else
    echo -e "${RED}状态: 未安装${NC}"
fi
