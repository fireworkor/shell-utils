#!/bin/bash
# Flink 备份脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="flink"
DISPLAY_NAME="Flink"

BACKUP_ROOT="/var/backups/shell-utils/${SOFTWARE_NAME}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

do_backup() {
    mkdir -p "$BACKUP_ROOT"
    
    local backup_dir="$BACKUP_ROOT/backup_$TIMESTAMP"
    mkdir -p "$backup_dir"
    
    # 备份配置
    if [ -d "/opt/flink/etc" ]; then
        cp -r /opt/flink/etc "$backup_dir/"
        echo "${GREEN}配置备份完成${NC}"
    fi
    
    # 打包
    tar czf "$BACKUP_ROOT/backup_${TIMESTAMP}.tar.gz" -C "$BACKUP_ROOT" "backup_$TIMESTAMP"
    rm -rf "$backup_dir"
    
    echo "${GREEN}备份完成: $BACKUP_ROOT/backup_${TIMESTAMP}.tar.gz${NC}"
}

list_backups() {
    echo "${display_name} 的备份列表:"
    ls -lt "$BACKUP_ROOT"/backup_*.tar.gz 2>/dev/null | head -10 || echo "  暂无备份"
}

case "${1:-all}" in
    all|config)
        do_backup
        ;;
    list)
        list_backups
        ;;
    *)
        do_backup
        ;;
esac
