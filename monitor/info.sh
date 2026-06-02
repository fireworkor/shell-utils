#!/bin/bash
# Monitor 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="monitor"
DISPLAY_NAME="Monitor"

echo -e "${BLUE}=== Monitor 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: monitor"
echo "  默认端口: 3000,9090"
echo "  安装目录: /opt/monitor"
echo "  配置目录: /etc/monitor"
echo "  日志目录: /var/log/monitor"
echo "  数据目录: /var/lib/monitor"
echo ""

# 检查安装状态
if command -v monitor &>/dev/null || [ -d "/opt/monitor" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v monitor &>/dev/null; then
        which monitor
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
