#!/bin/bash
# Samba 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="samba"
DISPLAY_NAME="Samba"

echo -e "${BLUE}=== Samba 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: smbd"
echo "  默认端口: 139,445"
echo "  安装目录: /opt/samba"
echo "  配置目录: /etc/samba"
echo "  日志目录: /var/log/samba"
echo "  数据目录: /var/lib/samba"
echo ""

# 检查安装状态
if command -v smbd &>/dev/null || [ -d "/opt/samba" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v smbd &>/dev/null; then
        which smbd
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
