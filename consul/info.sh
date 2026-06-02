#!/bin/bash
# Consul 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="consul"
DISPLAY_NAME="Consul"

echo -e "${BLUE}=== Consul 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: consul"
echo "  默认端口: 8300,8500"
echo "  安装目录: /opt/consul"
echo "  配置目录: /etc/consul"
echo "  日志目录: /var/log/consul"
echo "  数据目录: /var/lib/consul"
echo ""

# 检查安装状态
if command -v consul &>/dev/null || [ -d "/opt/consul" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v consul &>/dev/null; then
        which consul
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
