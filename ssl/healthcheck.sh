#!/bin/bash
# SSL 健康检查脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="ssl"
DISPLAY_NAME="SSL"

echo -e "${BLUE}=== SSL 健康检查 ===${NC}"

# 检查安装
if command -v ssl &>/dev/null || [ -d "/opt/ssl" ]; then
    echo -e "${GREEN}✓ SSL 已安装${NC}"
else
    echo -e "${RED}✗ SSL 未安装${NC}"
fi

# 检查配置目录
if [ -d "/opt/ssl" ] || [ -d "/etc/ssl" ]; then
    echo -e "${GREEN}✓ 配置目录存在${NC}"
else
    echo -e "${YELLOW}⚠ 配置目录不存在${NC}"
fi

echo -e "${GREEN}健康检查完成${NC}"
