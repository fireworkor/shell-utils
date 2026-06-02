#!/bin/bash
# Linkerd 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="linkerd"
DISPLAY_NAME="Linkerd"

echo -e "${BLUE}=== Linkerd 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: linkerd"
echo "  默认端口: 8086"
echo "  安装目录: /opt/linkerd"
echo "  配置目录: /etc/linkerd"
echo "  日志目录: /var/log/linkerd"
echo "  数据目录: /var/lib/linkerd"
echo ""

# 检查安装状态
if command -v linkerd &>/dev/null || [ -d "/opt/linkerd" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v linkerd &>/dev/null; then
        which linkerd
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
