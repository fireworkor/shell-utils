#!/bin/bash
# MinIO 健康检查脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="minio"
DISPLAY_NAME="MinIO"

echo -e "${BLUE}=== MinIO 健康检查 ===${NC}"

if [ -d "/opt/minio" ]; then
    echo -e "${GREEN}✓ 安装目录存在${NC}"
else
    echo -e "${RED}✗ 安装目录不存在${NC}"
fi

if [ -d "/var/log/minio" ]; then
    echo -e "${GREEN}✓ 日志目录存在${NC}"
else
    echo -e "${YELLOW}⚠ 日志目录不存在${NC}"
fi

echo -e "${GREEN}健康检查完成${NC}"
