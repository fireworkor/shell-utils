#!/bin/bash
# Proxmox VE 健康检查脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="pve"
DISPLAY_NAME="Proxmox VE"

echo -e "${BLUE}=== Proxmox VE 健康检查 ===${NC}"

# 检查安装
if command -v pve &>/dev/null || [ -d "/opt/pve" ]; then
    echo -e "${GREEN}✓ Proxmox VE 已安装${NC}"
else
    echo -e "${RED}✗ Proxmox VE 未安装${NC}"
fi

# 检查配置目录
if [ -d "/opt/pve" ] || [ -d "/etc/pve" ]; then
    echo -e "${GREEN}✓ 配置目录存在${NC}"
else
    echo -e "${YELLOW}⚠ 配置目录不存在${NC}"
fi

echo -e "${GREEN}健康检查完成${NC}"
