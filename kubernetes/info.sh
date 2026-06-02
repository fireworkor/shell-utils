#!/bin/bash
# Kubernetes 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="kubernetes"
DISPLAY_NAME="Kubernetes"

echo -e "${BLUE}=== Kubernetes 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: kubernetes"
echo "  默认端口: 6443,10250"
echo "  安装目录: /opt/kubernetes"
echo "  配置目录: /etc/kubernetes"
echo "  日志目录: /var/log/kubernetes"
echo "  数据目录: /var/lib/kubernetes"
echo ""

# 检查安装状态
if command -v kubernetes &>/dev/null || [ -d "/opt/kubernetes" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v kubernetes &>/dev/null; then
        which kubernetes
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
