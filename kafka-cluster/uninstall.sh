#!/bin/bash
# Kafka Cluster 卸载脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="kafka-cluster"
DISPLAY_NAME="Kafka Cluster"

echo "正在卸载 Kafka Cluster..."
echo -e "${YELLOW}警告: 将删除相关目录${NC}"
read -p "确认卸载? [y/N] " confirm
[ "$confirm" != "y" ] && { echo "取消卸载"; exit 0; }

sudo systemctl stop kafka-cluster 2>/dev/null || true
sudo rm -rf /opt/kafka-cluster /var/log/kafka-cluster /var/lib/kafka-cluster 2>/dev/null || true

echo -e "${GREEN}Kafka Cluster 卸载完成${NC}"
