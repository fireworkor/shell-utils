#!/bin/bash
# Pulsar 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="pulsar"
DISPLAY_NAME="Pulsar"

echo -e "${BLUE}=== Pulsar 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: pulsar"
echo "  默认端口: 6650,8080"
echo "  安装目录: /opt/pulsar"
echo "  配置目录: /etc/pulsar"
echo "  日志目录: /var/log/pulsar"
echo "  数据目录: /var/lib/pulsar"
echo ""

# 检查安装状态
if command -v pulsar &>/dev/null || [ -d "/opt/pulsar" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v pulsar &>/dev/null; then
        which pulsar
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
