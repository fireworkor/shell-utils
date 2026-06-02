#!/bin/bash
# Ruby 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="ruby"
DISPLAY_NAME="Ruby"

echo -e "${BLUE}=== Ruby 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: ruby"
echo "  默认端口: "
echo "  安装目录: /opt/ruby"
echo "  配置目录: /etc/ruby"
echo "  日志目录: /var/log/ruby"
echo "  数据目录: /var/lib/ruby"
echo ""

# 检查安装状态
if command -v ruby &>/dev/null || [ -d "/opt/ruby" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v ruby &>/dev/null; then
        which ruby
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
