#!/bin/bash
# Kernel Tuner 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="tune-kernel"
DISPLAY_NAME="Kernel Tuner"

echo -e "${BLUE}=== Kernel Tuner 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: tune-kernel"
echo "  默认端口: "
echo "  安装目录: /opt/tune-kernel"
echo "  配置目录: /etc/tune-kernel"
echo "  日志目录: /var/log/tune-kernel"
echo "  数据目录: /var/lib/tune-kernel"
echo ""

# 检查安装状态
if command -v tune-kernel &>/dev/null || [ -d "/opt/tune-kernel" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v tune-kernel &>/dev/null; then
        which tune-kernel
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
