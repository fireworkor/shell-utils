#!/bin/bash
# Airflow 卸载脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="airflow"
DISPLAY_NAME="Airflow"

echo "正在卸载 Airflow..."
echo -e "${YELLOW}警告: 将删除相关目录${NC}"
read -p "确认卸载? [y/N] " confirm
[ "$confirm" != "y" ] && { echo "取消卸载"; exit 0; }

sudo systemctl stop airflow 2>/dev/null || true
sudo rm -rf /opt/airflow /var/log/airflow /var/lib/airflow 2>/dev/null || true

echo -e "${GREEN}Airflow 卸载完成${NC}"
