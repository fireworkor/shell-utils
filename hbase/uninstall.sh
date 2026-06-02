#!/bin/bash
# HBase 卸载脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="hbase"
DISPLAY_NAME="HBase"

echo "正在卸载 HBase..."

echo "${YELLOW}警告: 将删除 /opt/hbase 和相关目录${NC}"
read -p "确认卸载? [y/N] " confirm
[ "$confirm" != "y" ] && { echo "取消卸载"; exit 0; }

# 停止服务
sudo systemctl stop hbase 2>/dev/null || true

# 删除目录
sudo rm -rf /opt/hbase /var/log/hbase /var/lib/hbase

echo "${GREEN}HBase 卸载完成${NC}"
