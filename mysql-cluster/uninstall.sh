#!/bin/bash
# MySQL Cluster 卸载脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="mysql-cluster"
DISPLAY_NAME="MySQL Cluster"

echo "正在卸载 MySQL Cluster..."
echo -e "${YELLOW}警告: 将删除相关目录${NC}"
read -p "确认卸载? [y/N] " confirm
[ "$confirm" != "y" ] && { echo "取消卸载"; exit 0; }

sudo systemctl stop mysql-cluster 2>/dev/null || true
sudo rm -rf /opt/mysql-cluster /var/log/mysql-cluster /var/lib/mysql-cluster 2>/dev/null || true

echo -e "${GREEN}MySQL Cluster 卸载完成${NC}"
