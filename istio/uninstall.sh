#!/bin/bash
# Istio 卸载脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="istio"
DISPLAY_NAME="Istio"

echo "正在卸载 Istio..."

echo -e "${YELLOW}警告: 将删除 Istio 及相关数据${NC}"
read -p "确认卸载? [y/N] " confirm
[ "$confirm" != "y" ] && { echo "取消卸载"; exit 0; }

# 备份数据
if [ -d "/opt/istio" ] || [ -d "/var/lib/istio" ]; then
    echo "备份数据..."
    bash "$SCRIPT_DIR/backup.sh" all 2>/dev/null || true
fi

# 停止服务
sudo systemctl stop istio 2>/dev/null || true

# 卸载软件
if command -v apt &>/dev/null; then
    sudo apt remove -y istio 2>/dev/null || true
elif command -v yum &>/dev/null; then
    sudo yum remove -y istio 2>/dev/null || true
fi

# 删除目录
sudo rm -rf /opt/istio /var/log/istio /var/lib/istio 2>/dev/null || true

echo -e "${GREEN}Istio 卸载完成${NC}"
