#!/bin/bash
# Hive 卸载脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="hive"
DISPLAY_NAME="Hive"

echo "正在卸载 Hive..."

echo "${YELLOW}警告: 将删除 /opt/hive 和相关目录${NC}"
read -p "确认卸载? [y/N] " confirm
[ "$confirm" != "y" ] && { echo "取消卸载"; exit 0; }

# 停止服务
sudo systemctl stop hive 2>/dev/null || true

# 删除目录
sudo rm -rf /opt/hive /var/log/hive /var/lib/hive

echo "${GREEN}Hive 卸载完成${NC}"
