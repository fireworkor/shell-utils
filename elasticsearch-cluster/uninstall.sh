#!/bin/bash
# Elasticsearch Cluster 卸载脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="elasticsearch-cluster"
DISPLAY_NAME="Elasticsearch Cluster"

echo "正在卸载 Elasticsearch Cluster..."
echo -e "${YELLOW}警告: 将删除相关目录${NC}"
read -p "确认卸载? [y/N] " confirm
[ "$confirm" != "y" ] && { echo "取消卸载"; exit 0; }

sudo systemctl stop elasticsearch-cluster 2>/dev/null || true
sudo rm -rf /opt/elasticsearch-cluster /var/log/elasticsearch-cluster /var/lib/elasticsearch-cluster 2>/dev/null || true

echo -e "${GREEN}Elasticsearch Cluster 卸载完成${NC}"
