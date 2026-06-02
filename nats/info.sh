#!/bin/bash
# NATS 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="nats"
DISPLAY_NAME="NATS"

echo -e "${BLUE}=== NATS 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: nats"
echo "  默认端口: 4222,8222"
echo "  安装目录: /opt/nats"
echo "  配置目录: /etc/nats"
echo "  日志目录: /var/log/nats"
echo "  数据目录: /var/lib/nats"
echo ""

# 检查安装状态
if command -v nats &>/dev/null || [ -d "/opt/nats" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v nats &>/dev/null; then
        which nats
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
