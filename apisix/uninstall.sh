#!/bin/bash
# APISIX 卸载脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="apisix"
DISPLAY_NAME="APISIX"

echo "正在卸载 APISIX..."
echo -e "${YELLOW}警告: 将删除相关目录${NC}"
read -p "确认卸载? [y/N] " confirm
[ "$confirm" != "y" ] && { echo "取消卸载"; exit 0; }

sudo systemctl stop apisix 2>/dev/null || true
sudo rm -rf /opt/apisix /var/log/apisix /var/lib/apisix 2>/dev/null || true

echo -e "${GREEN}APISIX 卸载完成${NC}"
