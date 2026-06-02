#!/bin/bash
# Hadoop 恢复脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="hadoop"
DISPLAY_NAME="Hadoop"

BACKUP_ROOT="/var/backups/shell-utils/${SOFTWARE_NAME}"

list_available() {
    ls -1 "$BACKUP_ROOT"/backup_*.tar.gz 2>/dev/null | head -10 || echo "暂无备份"
}

do_restore() {
    local backup_file="$1"
    [ -z "$backup_file" ] && { echo "请指定备份文件"; return 1; }
    
    if [ ! -f "$backup_file" ]; then
        backup_file="$BACKUP_ROOT/$backup_file"
    fi
    
    [ ! -f "$backup_file" ] && { echo "备份文件不存在"; return 1; }
    
    local temp_dir=$(mktemp -d)
    tar xzf "$backup_file" -C "$temp_dir"
    
    # 恢复配置
    if [ -d "$temp_dir/backup_*/etc" ]; then
        cp -r "$temp_dir"/backup_*/etc/* /opt/hadoop/etc/
        echo "${GREEN}配置恢复完成${NC}"
    fi
    
    rm -rf "$temp_dir"
}

case "${1:-list}" in
    list)
        list_available
        ;;
    *)
        do_restore "$@"
        ;;
esac
