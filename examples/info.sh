#!/bin/bash
# Examples 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="examples"
DISPLAY_NAME="Examples"

echo -e "${BLUE}=== Examples 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: examples"
echo "  默认端口: "
echo "  安装目录: /opt/examples"
echo "  配置目录: /etc/examples"
echo "  日志目录: /var/log/examples"
echo "  数据目录: /var/lib/examples"
echo ""

# 检查安装状态
if command -v examples &>/dev/null || [ -d "/opt/examples" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v examples &>/dev/null; then
        which examples
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
