#!/bin/bash
# Perl 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="perl"
DISPLAY_NAME="Perl"

echo -e "${BLUE}=== Perl 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: perl"
echo "  默认端口: "
echo "  安装目录: /opt/perl"
echo "  配置目录: /etc/perl"
echo "  日志目录: /var/log/perl"
echo "  数据目录: /var/lib/perl"
echo ""

# 检查安装状态
if command -v perl &>/dev/null || [ -d "/opt/perl" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v perl &>/dev/null; then
        which perl
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
