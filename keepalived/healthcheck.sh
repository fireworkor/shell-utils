#!/bin/bash
# Keepalived 健康检查脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="keepalived"
DISPLAY_NAME="Keepalived"

echo -e "${BLUE}=== Keepalived 健康检查 ===${NC}"

if [ -d "/opt/keepalived" ]; then
    echo -e "${GREEN}✓ 安装目录存在${NC}"
else
    echo -e "${RED}✗ 安装目录不存在${NC}"
fi

if [ -d "/var/log/keepalived" ]; then
    echo -e "${GREEN}✓ 日志目录存在${NC}"
else
    echo -e "${YELLOW}⚠ 日志目录不存在${NC}"
fi

echo -e "${GREEN}健康检查完成${NC}"
