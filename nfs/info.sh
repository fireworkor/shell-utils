#!/bin/bash
# NFS 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="nfs"
DISPLAY_NAME="NFS"

echo -e "${BLUE}=== NFS 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: nfs"
echo "  默认端口: 2049"
echo "  安装目录: /opt/nfs"
echo "  配置目录: /etc/nfs"
echo "  日志目录: /var/log/nfs"
echo "  数据目录: /var/lib/nfs"
echo ""

# 检查安装状态
if command -v nfs &>/dev/null || [ -d "/opt/nfs" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v nfs &>/dev/null; then
        which nfs
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
