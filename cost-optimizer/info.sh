#!/bin/bash
# Cost Optimizer 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="cost-optimizer"
DISPLAY_NAME="Cost Optimizer"

echo -e "${BLUE}=== Cost Optimizer 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: cost-optimizer"
echo "  默认端口: 8080"
echo "  安装目录: /opt/cost-optimizer"
echo "  配置目录: /etc/cost-optimizer"
echo "  日志目录: /var/log/cost-optimizer"
echo "  数据目录: /var/lib/cost-optimizer"
echo ""

# 检查安装状态
if command -v cost-optimizer &>/dev/null || [ -d "/opt/cost-optimizer" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v cost-optimizer &>/dev/null; then
        which cost-optimizer
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
