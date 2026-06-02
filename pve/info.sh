#!/bin/bash
# Proxmox VE 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="pve"
DISPLAY_NAME="Proxmox VE"

echo -e "${BLUE}=== Proxmox VE 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: pve"
echo "  默认端口: 8006"
echo "  安装目录: /opt/pve"
echo "  配置目录: /etc/pve"
echo "  日志目录: /var/log/pve"
echo "  数据目录: /var/lib/pve"
echo ""

# 检查安装状态
if command -v pve &>/dev/null || [ -d "/opt/pve" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v pve &>/dev/null; then
        which pve
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
