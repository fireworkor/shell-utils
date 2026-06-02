#!/bin/bash
# Dev Tools 卸载脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="dev-tools"
DISPLAY_NAME="Dev Tools"

echo "正在卸载 Dev Tools..."

echo -e "${YELLOW}警告: 将删除 Dev Tools 及相关数据${NC}"
read -p "确认卸载? [y/N] " confirm
[ "$confirm" != "y" ] && { echo "取消卸载"; exit 0; }

# 备份数据
if [ -d "/opt/dev-tools" ] || [ -d "/var/lib/dev-tools" ]; then
    echo "备份数据..."
    bash "$SCRIPT_DIR/backup.sh" all 2>/dev/null || true
fi

# 停止服务
sudo systemctl stop dev-tools 2>/dev/null || true

# 卸载软件
if command -v apt &>/dev/null; then
    sudo apt remove -y dev-tools 2>/dev/null || true
elif command -v yum &>/dev/null; then
    sudo yum remove -y dev-tools 2>/dev/null || true
fi

# 删除目录
sudo rm -rf /opt/dev-tools /var/log/dev-tools /var/lib/dev-tools 2>/dev/null || true

echo -e "${GREEN}Dev Tools 卸载完成${NC}"
