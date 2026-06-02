#!/bin/bash
# SQLite 备份脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="sqlite"
DISPLAY_NAME="SQLite"

BACKUP_ROOT="/var/backups/shell-utils/${SOFTWARE_NAME}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

do_backup() {
    local db_file="${1:-}"
    
    mkdir -p "$BACKUP_ROOT"
    
    if [ -z "$db_file" ]; then
        echo "备份所有 SQLite 数据库..."
        # 备份 /var/lib/sqlite 下的所有数据库
        for db in /var/lib/sqlite/*.db /var/lib/sqlite/*.sqlite3 2>/dev/null; do
            [ -f "$db" ] || continue
            local db_name=$(basename "$db")
            local backup_file="$BACKUP_ROOT/${db_name}_${TIMESTAMP}.db"
            sqlite3 "$db" ".backup '$backup_file'"
            echo -e "${GREEN}已备份: $db_name -> ${db_name}_${TIMESTAMP}.db${NC}"
        done
    else
        if [ ! -f "$db_file" ]; then
            echo -e "${RED}数据库文件不存在: $db_file${NC}"
            return 1
        fi
        local db_name=$(basename "$db_file")
        local backup_file="$BACKUP_ROOT/${db_name}_${TIMESTAMP}.db"
        sqlite3 "$db_file" ".backup '$backup_file'"
        echo -e "${GREEN}已备份: $db_name -> ${db_name}_${TIMESTAMP}.db${NC}"
    fi
    
    echo -e "${GREEN}备份完成，位置: $BACKUP_ROOT${NC}"
}

list_backups() {
    echo "${DISPLAY_NAME} 的备份列表:"
    ls -lt "$BACKUP_ROOT"/*.db 2>/dev/null | head -10 || echo "  暂无备份"
}

case "${1:-all}" in
    all)
        do_backup
        ;;
    list)
        list_backups
        ;;
    *)
        do_backup "$1"
        ;;
esac
