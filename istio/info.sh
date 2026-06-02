#!/bin/bash
# Istio 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="istio"
DISPLAY_NAME="Istio"

echo -e "${BLUE}=== Istio 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: istio"
echo "  默认端口: 15001,15006"
echo "  安装目录: /opt/istio"
echo "  配置目录: /etc/istio"
echo "  日志目录: /var/log/istio"
echo "  数据目录: /var/lib/istio"
echo ""

# 检查安装状态
if command -v istio &>/dev/null || [ -d "/opt/istio" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v istio &>/dev/null; then
        which istio
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
