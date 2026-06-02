#!/bin/bash
# SQLite 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="sqlite"
DISPLAY_NAME="SQLite"

echo -e "${BLUE}=== SQLite 信息 ===${NC}"
echo "  软件名称: $DISPLAY_NAME"
echo "  数据目录: /var/lib/sqlite"
echo "  备份目录: /var/backups/shell-utils/sqlite"
echo ""

# 检查安装状态
if command -v sqlite3 &>/dev/null; then
    echo -e "${GREEN}状态: 已安装${NC}"
    echo "  版本: $(sqlite3 --version | head -1)"
    echo "  路径: $(which sqlite3)"
else
    echo -e "${RED}状态: 未安装${NC}"
fi

echo ""
echo -e "${BLUE}数据库文件列表:${NC}"
if [ -d "/var/lib/sqlite" ]; then
    ls -lh /var/lib/sqlite/*.db /var/lib/sqlite/*.sqlite3 2>/dev/null || echo "  暂无数据库文件"
else
    echo "  数据目录不存在"
fi
