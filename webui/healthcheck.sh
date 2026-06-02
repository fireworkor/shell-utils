#!/bin/bash
# WebUI 健康检查脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="webui"
DISPLAY_NAME="WebUI"

echo -e "${BLUE}=== WebUI 健康检查 ===${NC}"

# 检查安装
if command -v webui &>/dev/null || [ -d "/opt/webui" ]; then
    echo -e "${GREEN}✓ WebUI 已安装${NC}"
else
    echo -e "${RED}✗ WebUI 未安装${NC}"
fi

# 检查配置目录
if [ -d "/opt/webui" ] || [ -d "/etc/webui" ]; then
    echo -e "${GREEN}✓ 配置目录存在${NC}"
else
    echo -e "${YELLOW}⚠ 配置目录不存在${NC}"
fi

echo -e "${GREEN}健康检查完成${NC}"
