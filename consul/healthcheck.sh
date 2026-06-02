#!/bin/bash
# Consul 健康检查脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="consul"
DISPLAY_NAME="Consul"

echo -e "${BLUE}=== Consul 健康检查 ===${NC}"

# 检查安装
if command -v consul &>/dev/null || [ -d "/opt/consul" ]; then
    echo -e "${GREEN}✓ Consul 已安装${NC}"
else
    echo -e "${RED}✗ Consul 未安装${NC}"
fi

# 检查配置目录
if [ -d "/opt/consul" ] || [ -d "/etc/consul" ]; then
    echo -e "${GREEN}✓ 配置目录存在${NC}"
else
    echo -e "${YELLOW}⚠ 配置目录不存在${NC}"
fi

echo -e "${GREEN}健康检查完成${NC}"
