#!/bin/bash
# Mirror 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="mirror"
DISPLAY_NAME="Mirror"

echo -e "${BLUE}=== Mirror 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: mirror"
echo "  默认端口: 8080"
echo "  安装目录: /opt/mirror"
echo "  配置目录: /etc/mirror"
echo "  日志目录: /var/log/mirror"
echo "  数据目录: /var/lib/mirror"
echo ""

# 检查安装状态
if command -v mirror &>/dev/null || [ -d "/opt/mirror" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v mirror &>/dev/null; then
        which mirror
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
