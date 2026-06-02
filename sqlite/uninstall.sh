#!/bin/bash
# SQLite 卸载脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="sqlite"
DISPLAY_NAME="SQLite"

echo "正在卸载 SQLite..."

echo -e "${YELLOW}警告: 将删除 SQLite 及相关数据${NC}"
read -p "确认卸载? [y/N] " confirm
[ "$confirm" != "y" ] && { echo "取消卸载"; exit 0; }

# 备份数据
if [ -d "/var/lib/sqlite" ]; then
    echo "备份数据..."
    bash "$SCRIPT_DIR/backup.sh" all
fi

# 卸载软件包
if [ -f /etc/redhat-release ]; then
    sudo yum remove -y sqlite sqlite-devel
elif [ -f /etc/debian_version ]; then
    sudo apt remove -y sqlite3 libsqlite3-dev
fi

# 删除数据目录
sudo rm -rf /var/lib/sqlite

echo -e "${GREEN}SQLite 卸载完成${NC}"
