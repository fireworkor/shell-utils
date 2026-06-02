#!/bin/bash
# Cleanup 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="cleanup"
DISPLAY_NAME="Cleanup"

echo -e "${BLUE}=== Cleanup 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: cleanup"
echo "  默认端口: "
echo "  安装目录: /opt/cleanup"
echo "  配置目录: /etc/cleanup"
echo "  日志目录: /var/log/cleanup"
echo "  数据目录: /var/lib/cleanup"
echo ""

# 检查安装状态
if command -v cleanup &>/dev/null || [ -d "/opt/cleanup" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v cleanup &>/dev/null; then
        which cleanup
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
