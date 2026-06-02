#!/bin/bash
# SQLite 健康检查脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="sqlite"
DISPLAY_NAME="SQLite"

echo -e "${BLUE}=== SQLite 健康检查 ===${NC}"

# 检查安装
if command -v sqlite3 &>/dev/null; then
    echo -e "${GREEN}✓ SQLite 已安装${NC}"
    sqlite3 --version
else
    echo -e "${RED}✗ SQLite 未安装${NC}"
fi

# 检查数据目录
if [ -d "/var/lib/sqlite" ]; then
    echo -e "${GREEN}✓ 数据目录存在${NC}"
    db_count=$(ls /var/lib/sqlite/*.db /var/lib/sqlite/*.sqlite3 2>/dev/null | wc -l)
    echo "  数据库文件数量: $db_count"
else
    echo -e "${YELLOW}⚠ 数据目录不存在${NC}"
fi

# 测试基本功能
if command -v sqlite3 &>/dev/null; then
    test_result=$(sqlite3 :memory: "SELECT 1+1;" 2>/dev/null)
    if [ "$test_result" = "2" ]; then
        echo -e "${GREEN}✓ 基本功能正常${NC}"
    else
        echo -e "${RED}✗ 基本功能异常${NC}"
    fi
fi

echo -e "${GREEN}健康检查完成${NC}"
