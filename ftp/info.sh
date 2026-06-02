#!/bin/bash
# FTP 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="ftp"
DISPLAY_NAME="FTP"

echo -e "${BLUE}=== FTP 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: vsftpd"
echo "  默认端口: 21"
echo "  安装目录: /opt/ftp"
echo "  配置目录: /etc/ftp"
echo "  日志目录: /var/log/ftp"
echo "  数据目录: /var/lib/ftp"
echo ""

# 检查安装状态
if command -v vsftpd &>/dev/null || [ -d "/opt/ftp" ]; then
    echo -e "${GREEN}状态: 已安装${NC}"
    if command -v vsftpd &>/dev/null; then
        which vsftpd
    fi
else
    echo -e "${RED}状态: 未安装${NC}"
fi
