#!/bin/bash
# Dev Tools 健康检查脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="dev-tools"
DISPLAY_NAME="Dev Tools"

echo -e "${BLUE}=== Dev Tools 健康检查 ===${NC}"

# 检查安装
if command -v dev-tools &>/dev/null || [ -d "/opt/dev-tools" ]; then
    echo -e "${GREEN}✓ Dev Tools 已安装${NC}"
else
    echo -e "${RED}✗ Dev Tools 未安装${NC}"
fi

# 检查配置目录
if [ -d "/opt/dev-tools" ] || [ -d "/etc/dev-tools" ]; then
    echo -e "${GREEN}✓ 配置目录存在${NC}"
else
    echo -e "${YELLOW}⚠ 配置目录不存在${NC}"
fi

echo -e "${GREEN}健康检查完成${NC}"
