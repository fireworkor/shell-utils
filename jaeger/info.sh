#!/bin/bash
# Jaeger 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="jaeger"
DISPLAY_NAME="Jaeger"

echo -e "${BLUE}=== Jaeger 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: jaeger"
echo "  默认端口: 16686,14268"
echo "  安装目录: /opt/jaeger"
echo "  配置目录: /etc/jaeger"
echo "  日志目录: /var/log/jaeger"
echo "  数据目录: /var/lib/jaeger"
echo ""

# 检查安装状态
if command -v jaeger &>/dev/null || [ -d "/opt/jaeger" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v jaeger &>/dev/null; then
        which jaeger
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
