#!/bin/bash
# FTP 卸载脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="ftp"
DISPLAY_NAME="FTP"

echo "正在卸载 FTP..."

echo -e "${YELLOW}警告: 将删除 FTP 及相关数据${NC}"
read -p "确认卸载? [y/N] " confirm
[ "$confirm" != "y" ] && { echo "取消卸载"; exit 0; }

# 备份数据
if [ -d "/opt/ftp" ] || [ -d "/var/lib/ftp" ]; then
    echo "备份数据..."
    bash "$SCRIPT_DIR/backup.sh" all 2>/dev/null || true
fi

# 停止服务
sudo systemctl stop vsftpd 2>/dev/null || true

# 卸载软件
if command -v apt &>/dev/null; then
    sudo apt remove -y vsftpd 2>/dev/null || true
elif command -v yum &>/dev/null; then
    sudo yum remove -y vsftpd 2>/dev/null || true
fi

# 删除目录
sudo rm -rf /opt/ftp /var/log/ftp /var/lib/ftp 2>/dev/null || true

echo -e "${GREEN}FTP 卸载完成${NC}"
