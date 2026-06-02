#!/bin/bash
# Spark 卸载脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="spark"
DISPLAY_NAME="Spark"

echo "正在卸载 Spark..."

echo "${YELLOW}警告: 将删除 /opt/spark 和相关目录${NC}"
read -p "确认卸载? [y/N] " confirm
[ "$confirm" != "y" ] && { echo "取消卸载"; exit 0; }

# 停止服务
sudo systemctl stop spark 2>/dev/null || true

# 删除目录
sudo rm -rf /opt/spark /var/log/spark /var/lib/spark

echo "${GREEN}Spark 卸载完成${NC}"
