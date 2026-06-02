#!/bin/bash
# SSL 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="ssl"
DISPLAY_NAME="SSL"

echo -e "${BLUE}=== SSL 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: ssl"
echo "  默认端口: "
echo "  安装目录: /opt/ssl"
echo "  配置目录: /etc/ssl"
echo "  日志目录: /var/log/ssl"
echo "  数据目录: /var/lib/ssl"
echo ""

# 检查安装状态
if command -v ssl &>/dev/null || [ -d "/opt/ssl" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v ssl &>/dev/null; then
        which ssl
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
