#!/bin/bash
# Firewall 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="firewall"
DISPLAY_NAME="Firewall"

echo -e "${BLUE}=== Firewall 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: firewall"
echo "  默认端口: "
echo "  安装目录: /opt/firewall"
echo "  配置目录: /etc/firewall"
echo "  日志目录: /var/log/firewall"
echo "  数据目录: /var/lib/firewall"
echo ""

# 检查安装状态
if command -v firewall &>/dev/null || [ -d "/opt/firewall" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v firewall &>/dev/null; then
        which firewall
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
