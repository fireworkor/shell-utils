#!/bin/bash
# Dev Tools 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="dev-tools"
DISPLAY_NAME="Dev Tools"

echo -e "${BLUE}=== Dev Tools 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: dev-tools"
echo "  默认端口: "
echo "  安装目录: /opt/dev-tools"
echo "  配置目录: /etc/dev-tools"
echo "  日志目录: /var/log/dev-tools"
echo "  数据目录: /var/lib/dev-tools"
echo ""

# 检查安装状态
if command -v dev-tools &>/dev/null || [ -d "/opt/dev-tools" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v dev-tools &>/dev/null; then
        which dev-tools
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
