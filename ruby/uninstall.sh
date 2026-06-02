#!/bin/bash
# Ruby 卸载脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="ruby"
DISPLAY_NAME="Ruby"

echo "正在卸载 Ruby..."

echo -e "${YELLOW}警告: 将删除 Ruby 及相关数据${NC}"
read -p "确认卸载? [y/N] " confirm
[ "$confirm" != "y" ] && { echo "取消卸载"; exit 0; }

# 备份数据
if [ -d "/opt/ruby" ] || [ -d "/var/lib/ruby" ]; then
    echo "备份数据..."
    bash "$SCRIPT_DIR/backup.sh" all 2>/dev/null || true
fi

# 停止服务
sudo systemctl stop ruby 2>/dev/null || true

# 卸载软件
if command -v apt &>/dev/null; then
    sudo apt remove -y ruby 2>/dev/null || true
elif command -v yum &>/dev/null; then
    sudo yum remove -y ruby 2>/dev/null || true
fi

# 删除目录
sudo rm -rf /opt/ruby /var/log/ruby /var/lib/ruby 2>/dev/null || true

echo -e "${GREEN}Ruby 卸载完成${NC}"
