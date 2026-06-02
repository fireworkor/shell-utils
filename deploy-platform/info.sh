#!/bin/bash
# Deploy Platform 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="deploy-platform"
DISPLAY_NAME="Deploy Platform"

echo -e "${BLUE}=== Deploy Platform 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: deploy-platform"
echo "  默认端口: 8080"
echo "  安装目录: /opt/deploy-platform"
echo "  配置目录: /etc/deploy-platform"
echo "  日志目录: /var/log/deploy-platform"
echo "  数据目录: /var/lib/deploy-platform"
echo ""

# 检查安装状态
if command -v deploy-platform &>/dev/null || [ -d "/opt/deploy-platform" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v deploy-platform &>/dev/null; then
        which deploy-platform
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
