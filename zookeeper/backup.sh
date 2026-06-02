#!/bin/bash
# ZooKeeper 备份脚本
# 支持配置、数据、日志的备份

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="zookeeper"
SOFTWARE_NAME="zookeeper"
DISPLAY_NAME="ZooKeeper"
SCRIPT_DIR_REF="$SCRIPT_DIR"

BACKUP_ROOT="/var/backups/shell-utils/${SOFTWARE_NAME}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/backup_$TIMESTAMP"

# 备份类型: config, data, log, all
BACKUP_TYPE="${1:-all}"

# 备份配置文件
backup_config() {
    print_info "备份 ${DISPLAY_NAME} 配置文件..."

    local config_dir="$BACKUP_DIR/config"
    mkdir -p "$config_dir"

    case "$SOFTWARE_NAME" in
        nginx)
            [ -d /etc/nginx ] && cp -r /etc/nginx "$config_dir/" 2>/dev/null
            ;;
        apache)
            [ -d /etc/httpd ] && cp -r /etc/httpd "$config_dir/" 2>/dev/null
            [ -d /etc/apache2 ] && cp -r /etc/apache2 "$config_dir/" 2>/dev/null
            ;;
        mysql|mariadb)
            [ -d /etc/my.cnf.d ] && cp -r /etc/my.cnf.d "$config_dir/" 2>/dev/null
            [ -d /etc/mysql ] && cp -r /etc/mysql "$config_dir/" 2>/dev/null
            [ -f /etc/my.cnf ] && cp /etc/my.cnf "$config_dir/" 2>/dev/null
            ;;
        redis)
            [ -f /etc/redis/redis.conf ] && cp /etc/redis/redis.conf "$config_dir/"
            [ -d /etc/redis ] && cp -r /etc/redis "$config_dir/" 2>/dev/null
            ;;
        *)
            [ -d /etc/${SERVICE_NAME} ] && cp -r /etc/${SERVICE_NAME} "$config_dir/" 2>/dev/null
            ;;
    esac

    print_success "配置备份完成: $config_dir"
}

# 备份数据
backup_data() {
    print_info "备份 ${DISPLAY_NAME} 数据..."

    local data_dir="$BACKUP_DIR/data"
    mkdir -p "$data_dir"

    case "$SOFTWARE_NAME" in
        mysql)
            if command -v mysqldump &>/dev/null; then
                mysqldump --all-databases --single-transaction 2>/dev/null | gzip > "$data_dir/mysql_all_$TIMESTAMP.sql.gz"
                print_success "MySQL 数据备份完成"
            fi
            ;;
        mariadb)
            if command -v mariadb-dump &>/dev/null; then
                mariadb-dump --all-databases --single-transaction 2>/dev/null | gzip > "$data_dir/mariadb_all_$TIMESTAMP.sql.gz"
                print_success "MariaDB 数据备份完成"
            fi
            ;;
        mongodb)
            if command -v mongodump &>/dev/null; then
                mongodump --archive="$data_dir/mongodb_$TIMESTAMP.archive" --gzip 2>/dev/null
                print_success "MongoDB 数据备份完成"
            fi
            ;;
        redis)
            if [ -f /var/lib/redis/dump.rdb ]; then
                cp /var/lib/redis/dump.rdb "$data_dir/redis_$TIMESTAMP.rdb"
                print_success "Redis 数据备份完成"
            fi
            ;;
        *)
            print_info "  无需特别数据备份"
            ;;
    esac
}

# 备份日志
backup_log() {
    print_info "备份 ${DISPLAY_NAME} 日志..."

    local log_dir="$BACKUP_DIR/log"
    mkdir -p "$log_dir"

    case "$SOFTWARE_NAME" in
        nginx)
            [ -d /var/log/nginx ] && cp -r /var/log/nginx "$log_dir/" 2>/dev/null
            ;;
        apache)
            [ -d /var/log/httpd ] && cp -r /var/log/httpd "$log_dir/" 2>/dev/null
            [ -d /var/log/apache2 ] && cp -r /var/log/apache2 "$log_dir/" 2>/dev/null
            ;;
        mysql|mariadb)
            [ -d /var/log/mariadb ] && cp -r /var/log/mariadb "$log_dir/" 2>/dev/null
            [ -d /var/log/mysql ] && cp -r /var/log/mysql "$log_dir/" 2>/dev/null
            ;;
        *)
            [ -d /var/log/${SERVICE_NAME} ] && cp -r /var/log/${SERVICE_NAME} "$log_dir/" 2>/dev/null
            ;;
    esac

    print_success "日志备份完成"
}

# 主备份函数
do_backup() {
    mkdir -p "$BACKUP_ROOT"
    mkdir -p "$BACKUP_DIR"

    print_info "开始备份 ${DISPLAY_NAME} ($BACKUP_TYPE)..."
    print_info "备份目录: $BACKUP_DIR"

    case "$BACKUP_TYPE" in
        config)
            backup_config
            ;;
        data)
            backup_data
            ;;
        log)
            backup_log
            ;;
        all|*)
            backup_config
            backup_data
            backup_log
            ;;
    esac

    # 创建备份信息文件
    cat > "$BACKUP_DIR/backup.info" <<INFOEOF
软件名称: ${DISPLAY_NAME}
软件包名: ${SOFTWARE_NAME}
服务名称: ${SERVICE_NAME}
备份时间: $(date '+%Y-%m-%d %H:%M:%S')
备份类型: ${BACKUP_TYPE}
主机名: $(hostname)
INFOEOF

    # 打包
    local backup_archive="$BACKUP_ROOT/backup_${TIMESTAMP}.tar.gz"
    tar czf "$backup_archive" -C "$BACKUP_ROOT" "backup_$TIMESTAMP" 2>/dev/null
    rm -rf "$BACKUP_DIR"

    if [ -f "$backup_archive" ]; then
        local size=$(du -h "$backup_archive" | cut -f1)
        print_success "备份完成: $backup_archive (大小: $size)"
        echo "$backup_archive"
    else
        print_error "备份失败"
        return 1
    fi
}

# 列出备份
list_backups() {
    print_info "${DISPLAY_NAME} 的备份列表:"
    echo ""

    if [ -d "$BACKUP_ROOT" ]; then
        local backups=$(ls -lt "$BACKUP_ROOT"/backup_*.tar.gz 2>/dev/null)
        if [ -z "$backups" ]; then
            echo "  暂无备份"
        else
            echo "$backups" | head -20 | while read -r backup; do
                local size=$(du -h "$backup" | cut -f1)
                local time=$(stat -c %y "$backup" 2>/dev/null | cut -d. -f1)
                echo "  $backup"
                echo "    大小: $size, 时间: $time"
            done
        fi
    else
        echo "  备份目录不存在: $BACKUP_ROOT"
    fi
}

case "${1:-all}" in
    all|config|data|log)
        do_backup
        ;;
    list|ls)
        list_backups
        ;;
    *)
        print_error "未知类型: $1"
        echo "用法: $0 {all|config|data|log|list}"
        ;;
esac
