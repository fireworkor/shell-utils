#!/bin/bash
# Vault 健康检查脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="vault"
DISPLAY_NAME="Vault"

echo -e "${BLUE}=== Vault 健康检查 ===${NC}"

if [ -d "/opt/vault" ]; then
    echo -e "${GREEN}✓ 安装目录存在${NC}"
else
    echo -e "${RED}✗ 安装目录不存在${NC}"
fi

if [ -d "/var/log/vault" ]; then
    echo -e "${GREEN}✓ 日志目录存在${NC}"
else
    echo -e "${YELLOW}⚠ 日志目录不存在${NC}"
fi

echo -e "${GREEN}健康检查完成${NC}"
