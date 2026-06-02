#!/bin/bash
# Cleanup 备份脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="cleanup"
DISPLAY_NAME="Cleanup"

BACKUP_ROOT="/var/backups/shell-utils/${SOFTWARE_NAME}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

do_backup() {
    mkdir -p "$BACKUP_ROOT"
    local backup_dir="$BACKUP_ROOT/backup_$TIMESTAMP"
    mkdir -p "$backup_dir"
    
    # 备份配置
    if [ -d "/opt/cleanup/etc" ]; then
        cp -r /opt/cleanup/etc "$backup_dir/" 2>/dev/null
        echo -e "${GREEN}配置备份完成${NC}"
    elif [ -d "/etc/cleanup" ]; then
        cp -r /etc/cleanup "$backup_dir/" 2>/dev/null
        echo -e "${GREEN}配置备份完成${NC}"
    fi
    
    # 打包
    tar czf "$BACKUP_ROOT/backup_${TIMESTAMP}.tar.gz" -C "$BACKUP_ROOT" "backup_$TIMESTAMP" 2>/dev/null
    rm -rf "$backup_dir"
    
    echo -e "${GREEN}备份完成: $BACKUP_ROOT/backup_${TIMESTAMP}.tar.gz${NC}"
}

list_backups() {
    echo "Cleanup 的备份列表:"
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
