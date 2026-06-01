#!/bin/bash
# 描述：备份数据库

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

backup_db() {
    check_root
    check_os
    
    echo -e "${BLUE}备份数据库...${NC}"
    
    local BACKUP_DIR="/var/backups/databases"
    mkdir -p $BACKUP_DIR
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    # MySQL/MariaDB 备份
    if command -v mysqldump &>/dev/null; then
        echo "备份 MySQL/MariaDB..."
        mkdir -p $BACKUP_DIR/mysql
        mysqldump --all-databases --single-transaction --quick --lock-tables=false \
            > $BACKUP_DIR/mysql/all_databases_${timestamp}.sql 2>/dev/null || true
        gzip $BACKUP_DIR/mysql/all_databases_${timestamp}.sql
        print_success "MySQL/MariaDB 已备份"
    fi
    
    # PostgreSQL 备份
    if command -v pg_dumpall &>/dev/null; then
        echo "备份 PostgreSQL..."
        mkdir -p $BACKUP_DIR/postgresql
        sudo -u postgres pg_dumpall > $BACKUP_DIR/postgresql/all_postgres_${timestamp}.sql 2>/dev/null || true
        gzip $BACKUP_DIR/postgresql/all_postgres_${timestamp}.sql
        print_success "PostgreSQL 已备份"
    fi
    
    # 清理 7 天前的备份
    find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
    
    print_success "数据库备份完成"
    echo ""
    echo "备份位置: $BACKUP_DIR"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    backup_db
fi
