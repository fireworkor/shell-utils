#!/bin/bash
# Rust 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="rust"
DISPLAY_NAME="Rust"

echo -e "${BLUE}=== Rust 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: rust"
echo "  默认端口: "
echo "  安装目录: /opt/rust"
echo "  配置目录: /etc/rust"
echo "  日志目录: /var/log/rust"
echo "  数据目录: /var/lib/rust"
echo ""

# 检查安装状态
if command -v rust &>/dev/null || [ -d "/opt/rust" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v rust &>/dev/null; then
        which rust
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
