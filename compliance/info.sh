#!/bin/bash
# Compliance 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="compliance"
DISPLAY_NAME="Compliance"

echo -e "${BLUE}=== Compliance 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: compliance"
echo "  默认端口: "
echo "  安装目录: /opt/compliance"
echo "  配置目录: /etc/compliance"
echo "  日志目录: /var/log/compliance"
echo "  数据目录: /var/lib/compliance"
echo ""

# 检查安装状态
if command -v compliance &>/dev/null || [ -d "/opt/compliance" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v compliance &>/dev/null; then
        which compliance
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
