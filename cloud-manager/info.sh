#!/bin/bash
# Cloud Manager 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="cloud-manager"
DISPLAY_NAME="Cloud Manager"

echo -e "${BLUE}=== Cloud Manager 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: cloud-manager"
echo "  默认端口: 8080"
echo "  安装目录: /opt/cloud-manager"
echo "  配置目录: /etc/cloud-manager"
echo "  日志目录: /var/log/cloud-manager"
echo "  数据目录: /var/lib/cloud-manager"
echo ""

# 检查安装状态
if command -v cloud-manager &>/dev/null || [ -d "/opt/cloud-manager" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v cloud-manager &>/dev/null; then
        which cloud-manager
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
