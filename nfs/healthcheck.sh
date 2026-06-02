#!/bin/bash
# NFS 健康检查脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="nfs"
DISPLAY_NAME="NFS"

echo -e "${BLUE}=== NFS 健康检查 ===${NC}"

# 检查安装
if command -v nfs &>/dev/null || [ -d "/opt/nfs" ]; then
    echo -e "${GREEN}✓ NFS 已安装${NC}"
else
    echo -e "${RED}✗ NFS 未安装${NC}"
fi

# 检查配置目录
if [ -d "/opt/nfs" ] || [ -d "/etc/nfs" ]; then
    echo -e "${GREEN}✓ 配置目录存在${NC}"
else
    echo -e "${YELLOW}⚠ 配置目录不存在${NC}"
fi

echo -e "${GREEN}健康检查完成${NC}"
