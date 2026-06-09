#!/bin/bash
# MariaDB 数据库备份脚本
# MariaDB 与 MySQL 高度兼容，使用类似的备份方式

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 配置参数
BACKUP_ROOT="/var/backups/mariadb"
INCREMENTAL_DIR="$BACKUP_ROOT/incremental"
FULL_DIR="$BACKUP_ROOT/full"
LOG_FILE="$BACKUP_ROOT/mariadb_backup.log"

MARIADB_USER="${MARIADB_USER:-root}"
MARIADB_PASSWORD="${MARIADB_PASSWORD:-}"
MARIADB_HOST="${MARIADB_HOST:-localhost}"
MARIADB_PORT="${MARIADB_PORT:-3306}"

# 保留天数
INCREMENTAL_RETENTION=7
FULL_RETENTION=30

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_info() {
    echo -e "\033[0;34m[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1\033[0m"
    log "INFO: $1"
}

log_success() {
    echo -e "\033[0;32m[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1\033[0m"
    log "SUCCESS: $1"
}

log_error() {
    echo -e "\033[0;31m[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1\033[0m"
    log "ERROR: $1"
}

# 初始化目录
init_dirs() {
    mkdir -p "$INCREMENTAL_DIR"
    mkdir -p "$FULL_DIR"
    touch "$LOG_FILE"
}

# 构建 mysql 命令
build_mysql_cmd() {
    local cmd="mysql -u$MARIADB_USER"
    [ -n "$MARIADB_PASSWORD" ] && cmd="$cmd -p$MARIADB_PASSWORD"
    [ "$MARIADB_HOST" != "localhost" ] && cmd="$cmd -h$MARIADB_HOST -P$MARIADB_PORT"
    echo "$cmd"
}

# 构建 mysqldump 命令
build_mysqldump_cmd() {
    local cmd="mysqldump -u$MARIADB_USER"
    [ -n "$MARIADB_PASSWORD" ] && cmd="$cmd -p$MARIADB_PASSWORD"
    [ "$MARIADB_HOST" != "localhost" ] && cmd="$cmd -h$MARIADB_HOST -P$MARIADB_PORT"
    echo "$cmd"
}

# 获取当前二进制日志位置
get_binlog_pos() {
    local cmd=$(build_mysql_cmd)
    $cmd -e "SHOW MASTER STATUS\G" 2>/dev/null | grep -E "(File|Position)" | awk '{print $2}' | tr '\n' ' '
}

# 全量备份
do_full_backup() {
    log_info "开始 MariaDB 全量备份..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$FULL_DIR/full_$timestamp.sql.gz"
    
    local cmd=$(build_mysqldump_cmd)
    
    # 使用 mysqldump 进行全量备份
    $cmd --all-databases \
        --single-transaction \
        --master-data=2 \
        --flush-logs \
        --triggers \
        --routines \
        --events \
        --max-allowed-packet=512M \
        2>/dev/null | gzip > "$backup_file"
    
    if [ $? -eq 0 ] && [ -s "$backup_file" ]; then
        local size=$(du -h "$backup_file" | cut -f1)
        log_success "全量备份完成: $backup_file (大小: $size)"
        
        # 创建备份信息文件
        cat > "${backup_file}.info" <<EOF
备份时间: $(date '+%Y-%m-%d %H:%M:%S')
备份类型: 全量
主机名: $(hostname)
MariaDB版本: $(mysql --version 2>/dev/null | awk '{print $5}')
备份大小: $size
EOF
    else
        log_error "全量备份失败"
        rm -f "$backup_file"
        return 1
    fi
}

# 增量备份（基于二进制日志）
do_incremental_backup() {
    log_info "开始 MariaDB 增量备份..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$INCREMENTAL_DIR/incremental_$timestamp.sql.gz"
    
    # 检查是否启用了二进制日志
    local binlog_info=$(get_binlog_pos)
    if [ -z "$binlog_info" ]; then
        log_error "MariaDB 未启用二进制日志，无法进行增量备份"
        return 1
    fi
    
    local binlog_file=$(echo "$binlog_info" | awk '{print $1}')
    local binlog_pos=$(echo "$binlog_info" | awk '{print $2}')
    
    # 检查上次备份位置
    local last_pos_file="$INCREMENTAL_DIR/last_position.txt"
    local from_file=""
    local from_pos=""
    
    if [ -f "$last_pos_file" ]; then
        read from_file from_pos < "$last_pos_file"
        log_info "从上次位置继续备份: $from_file:$from_pos"
    fi
    
    # 如果是首次增量备份
    if [ -z "$from_file" ]; then
        local cmd=$(build_mysql_cmd)
        from_file=$($cmd -e "SHOW BINARY LOGS" 2>/dev/null | grep -v "Log_name" | head -1 | awk '{print $1}')
        from_pos=4
    fi
    
    # 使用 mysqlbinlog 导出增量数据
    local cmd="mysqlbinlog"
    [ -n "$MARIADB_USER" ] && cmd="$cmd -u$MARIADB_USER"
    [ -n "$MARIADB_PASSWORD" ] && cmd="$cmd -p$MARIADB_PASSWORD"
    [ "$MARIADB_HOST" != "localhost" ] && cmd="$cmd -h$MARIADB_HOST -P$MARIADB_PORT"
    $cmd --start-position=$from_pos "$from_file" 2>/dev/null | gzip > "$backup_file"
    
    if [ $? -eq 0 ] && [ -s "$backup_file" ]; then
        echo "$binlog_file $binlog_pos" > "$last_pos_file"
        local size=$(du -h "$backup_file" | cut -f1)
        log_success "增量备份完成: $backup_file (大小: $size)"
    else
        log_error "增量备份失败"
        rm -f "$backup_file"
        return 1
    fi
}

# 使用 mariabackup 进行物理备份（如果可用）
do_physical_backup() {
    if ! command -v mariabackup &> /dev/null; then
        log_error "mariabackup 命令不可用，请安装 MariaDB-backup 包"
        return 1
    fi
    
    log_info "开始 MariaDB 物理备份（mariabackup）..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$FULL_DIR/physical_$timestamp"
    
    mkdir -p "$backup_dir"
    
    # 执行备份
    mariabackup --backup \
        --user="$MARIADB_USER" \
        ${MARIADB_PASSWORD:+--password="$MARIADB_PASSWORD"} \
        --host="$MARIADB_HOST" \
        --port="$MARIADB_PORT" \
        --target-dir="$backup_dir" \
        2>/dev/null
    
    if [ $? -eq 0 ]; then
        # 压缩备份
        tar czf "$backup_dir.tar.gz" -C "$FULL_DIR" "physical_$timestamp"
        rm -rf "$backup_dir"
        
        local size=$(du -h "$backup_dir.tar.gz" | cut -f1)
        log_success "物理备份完成: $backup_dir.tar.gz (大小: $size)"
    else
        log_error "物理备份失败"
        rm -rf "$backup_dir"
        return 1
    fi
}

# 清理旧备份
cleanup_old_backups() {
    log_info "清理 ${INCREMENTAL_RETENTION} 天前的增量备份..."
    find "$INCREMENTAL_DIR" -name "incremental_*.sql.gz" -mtime +$INCREMENTAL_RETENTION -delete 2>/dev/null
    
    log_info "清理 ${FULL_RETENTION} 天前的全量备份..."
    local latest_backup=$(ls -t "$FULL_DIR"/full_*.sql.gz 2>/dev/null | head -1)
    
    find "$FULL_DIR" -name "full_*.sql.gz" -mtime +$FULL_RETENTION | while read backup; do
        if [ "$backup" != "$latest_backup" ]; then
            rm -f "$backup" "${backup}.info"
            log_info "已删除: $backup"
        fi
    done
    
    log_success "旧备份清理完成"
}

# 显示备份列表
list_backups() {
    echo "=== MariaDB 全量备份 ==="
    ls -lt "$FULL_DIR"/full_*.sql.gz 2>/dev/null | head -10 || echo "  暂无全量备份"
    
    echo ""
    echo "=== MariaDB 增量备份 ==="
    ls -lt "$INCREMENTAL_DIR"/incremental_*.sql.gz 2>/dev/null | head -10 || echo "  暂无增量备份"
}

# 主函数
main() {
    init_dirs
    
    case "$1" in
        full)
            do_full_backup
            ;;
        incremental)
            do_incremental_backup
            ;;
        physical)
            do_physical_backup
            ;;
        cleanup)
            cleanup_old_backups
            ;;
        all)
            do_incremental_backup
            cleanup_old_backups
            ;;
        list)
            list_backups
            ;;
        *)
            echo "用法: $0 {full|incremental|physical|cleanup|all|list}"
            echo "  full        - 执行全量备份（逻辑备份）"
            echo "  incremental - 执行增量备份"
            echo "  physical    - 执行物理备份（mariabackup）"
            echo "  cleanup     - 清理旧备份"
            echo "  all         - 执行增量备份并清理"
            echo "  list        - 列出备份"
            ;;
    esac
}

main "$@"