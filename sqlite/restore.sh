#!/bin/bash
# SQLite 恢复脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="sqlite"
DISPLAY_NAME="SQLite"

BACKUP_ROOT="/var/backups/shell-utils/${SOFTWARE_NAME}"

list_available() {
    echo "可用的备份:"
    ls -1 "$BACKUP_ROOT"/*.db 2>/dev/null | head -10 || echo "  暂无备份"
}

do_restore() {
    local backup_file="$1"
    local target_db="${2:-}"
    
    [ -z "$backup_file" ] && { echo "请指定备份文件"; return 1; }
    
    if [ ! -f "$backup_file" ]; then
        backup_file="$BACKUP_ROOT/$backup_file"
    fi
    
    [ ! -f "$backup_file" ] && { echo "备份文件不存在"; return 1; }
    
    # 如果没有指定目标，恢复到原位置
    if [ -z "$target_db" ]; then
        # 从备份文件名解析原数据库名
        local backup_name=$(basename "$backup_file")
        target_db="/var/lib/sqlite/${backup_name%%_*}"
    fi
    
    # 恢复备份
    cp "$backup_file" "$target_db"
    echo -e "${GREEN}已恢复: $backup_file -> $target_db${NC}"
}

case "${1:-list}" in
    list)
        list_available
        ;;
    *)
        do_restore "$@"
        ;;
esac
