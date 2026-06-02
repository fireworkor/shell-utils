#!/bin/bash
# Flink 健康检查脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="flink"
DISPLAY_NAME="Flink"

echo -e "${BLUE}=== Flink 健康检查 ===${NC}"

# 检查安装
if [ -d "/opt/flink" ]; then
    echo -e "${GREEN}✓ 安装目录存在${NC}"
else
    echo -e "${RED}✗ 安装目录不存在${NC}"
fi

# 检查日志目录
if [ -d "/var/log/flink" ]; then
    echo -e "${GREEN}✓ 日志目录存在${NC}"
else
    echo -e "${YELLOW}⚠ 日志目录不存在${NC}"
fi

echo -e "${GREEN}健康检查完成${NC}"
