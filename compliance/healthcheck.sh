#!/bin/bash
# Compliance 健康检查脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="compliance"
DISPLAY_NAME="Compliance"

echo -e "${BLUE}=== Compliance 健康检查 ===${NC}"

# 检查安装
if command -v compliance &>/dev/null || [ -d "/opt/compliance" ]; then
    echo -e "${GREEN}✓ Compliance 已安装${NC}"
else
    echo -e "${RED}✗ Compliance 未安装${NC}"
fi

# 检查配置目录
if [ -d "/opt/compliance" ] || [ -d "/etc/compliance" ]; then
    echo -e "${GREEN}✓ 配置目录存在${NC}"
else
    echo -e "${YELLOW}⚠ 配置目录不存在${NC}"
fi

echo -e "${GREEN}健康检查完成${NC}"
