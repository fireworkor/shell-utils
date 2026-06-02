#!/bin/bash
# Deploy Platform 卸载脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="deploy-platform"
DISPLAY_NAME="Deploy Platform"

echo "正在卸载 Deploy Platform..."

echo -e "${YELLOW}警告: 将删除 Deploy Platform 及相关数据${NC}"
read -p "确认卸载? [y/N] " confirm
[ "$confirm" != "y" ] && { echo "取消卸载"; exit 0; }

# 备份数据
if [ -d "/opt/deploy-platform" ] || [ -d "/var/lib/deploy-platform" ]; then
    echo "备份数据..."
    bash "$SCRIPT_DIR/backup.sh" all 2>/dev/null || true
fi

# 停止服务
sudo systemctl stop deploy-platform 2>/dev/null || true

# 卸载软件
if command -v apt &>/dev/null; then
    sudo apt remove -y deploy-platform 2>/dev/null || true
elif command -v yum &>/dev/null; then
    sudo yum remove -y deploy-platform 2>/dev/null || true
fi

# 删除目录
sudo rm -rf /opt/deploy-platform /var/log/deploy-platform /var/lib/deploy-platform 2>/dev/null || true

echo -e "${GREEN}Deploy Platform 卸载完成${NC}"
