#!/bin/bash
# WebUI 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="webui"
DISPLAY_NAME="WebUI"

echo -e "${BLUE}=== WebUI 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: webui"
echo "  默认端口: 5000"
echo "  安装目录: /opt/webui"
echo "  配置目录: /etc/webui"
echo "  日志目录: /var/log/webui"
echo "  数据目录: /var/lib/webui"
echo ""

# 检查安装状态
if command -v webui &>/dev/null || [ -d "/opt/webui" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v webui &>/dev/null; then
        which webui
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
