#!/bin/bash
# Zeppelin 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="zeppelin"
DISPLAY_NAME="Zeppelin"

echo -e "${BLUE}=== Zeppelin 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: zeppelin"
echo "  默认端口: 8080"
echo "  安装目录: /opt/zeppelin"
echo "  配置目录: /etc/zeppelin"
echo "  日志目录: /var/log/zeppelin"
echo "  数据目录: /var/lib/zeppelin"
echo ""

# 检查安装状态
if command -v zeppelin &>/dev/null || [ -d "/opt/zeppelin" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v zeppelin &>/dev/null; then
        which zeppelin
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
