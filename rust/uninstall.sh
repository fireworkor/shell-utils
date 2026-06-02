#!/bin/bash
# Rust 卸载脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="rust"
DISPLAY_NAME="Rust"

echo "正在卸载 Rust..."

echo -e "${YELLOW}警告: 将删除 Rust 及相关数据${NC}"
read -p "确认卸载? [y/N] " confirm
[ "$confirm" != "y" ] && { echo "取消卸载"; exit 0; }

# 备份数据
if [ -d "/opt/rust" ] || [ -d "/var/lib/rust" ]; then
    echo "备份数据..."
    bash "$SCRIPT_DIR/backup.sh" all 2>/dev/null || true
fi

# 停止服务
sudo systemctl stop rust 2>/dev/null || true

# 卸载软件
if command -v apt &>/dev/null; then
    sudo apt remove -y rust 2>/dev/null || true
elif command -v yum &>/dev/null; then
    sudo yum remove -y rust 2>/dev/null || true
fi

# 删除目录
sudo rm -rf /opt/rust /var/log/rust /var/lib/rust 2>/dev/null || true

echo -e "${GREEN}Rust 卸载完成${NC}"
