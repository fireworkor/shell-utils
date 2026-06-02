#!/bin/bash
# Docker Compose Templates 健康检查脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="docker-compose-templates"
DISPLAY_NAME="Docker Compose Templates"

echo -e "${BLUE}=== Docker Compose Templates 健康检查 ===${NC}"

# 检查安装
if command -v docker-compose &>/dev/null || [ -d "/opt/docker-compose-templates" ]; then
    echo -e "${GREEN}✓ Docker Compose Templates 已安装${NC}"
else
    echo -e "${RED}✗ Docker Compose Templates 未安装${NC}"
fi

# 检查配置目录
if [ -d "/opt/docker-compose-templates" ] || [ -d "/etc/docker-compose-templates" ]; then
    echo -e "${GREEN}✓ 配置目录存在${NC}"
else
    echo -e "${YELLOW}⚠ 配置目录不存在${NC}"
fi

echo -e "${GREEN}健康检查完成${NC}"
