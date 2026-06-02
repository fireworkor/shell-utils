#!/bin/bash
# Docker Manager 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="docker-manager"
DISPLAY_NAME="Docker Manager"

echo -e "${BLUE}=== Docker Manager 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: docker-manager"
echo "  默认端口: 9000"
echo "  安装目录: /opt/docker-manager"
echo "  配置目录: /etc/docker-manager"
echo "  日志目录: /var/log/docker-manager"
echo "  数据目录: /var/lib/docker-manager"
echo ""

# 检查安装状态
if command -v docker-manager &>/dev/null || [ -d "/opt/docker-manager" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v docker-manager &>/dev/null; then
        which docker-manager
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
