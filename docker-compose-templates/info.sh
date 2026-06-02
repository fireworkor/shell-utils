#!/bin/bash
# Docker Compose Templates 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="docker-compose-templates"
DISPLAY_NAME="Docker Compose Templates"

echo -e "${BLUE}=== Docker Compose Templates 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: docker-compose"
echo "  默认端口: "
echo "  安装目录: /opt/docker-compose-templates"
echo "  配置目录: /etc/docker-compose-templates"
echo "  日志目录: /var/log/docker-compose-templates"
echo "  数据目录: /var/lib/docker-compose-templates"
echo ""

# 检查安装状态
if command -v docker-compose &>/dev/null || [ -d "/opt/docker-compose-templates" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v docker-compose &>/dev/null; then
        which docker-compose
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
