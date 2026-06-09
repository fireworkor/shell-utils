#!/bin/bash
# MySQL 增量备份脚本
# 每天执行增量备份，基于二进制日志

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 配置参数
BACKUP_ROOT="/var/backups/mysql"
INCREMENTAL_DIR="$BACKUP_ROOT/incremental"
FULL_DIR="$BACKUP_ROOT/full"
LOG_FILE="$BACKUP_ROOT/mysql_backup.log"

MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-}"
MYSQL_HOST="${MYSQL_HOST:-localhost}"
MYSQL_PORT="${MYSQL_PORT:-3306}"

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

# 获取当前二进制日志位置
get_binlog_pos() {
    local cmd="mysql -u$MYSQL_USER"
    [ -n "$MYSQL_PASSWORD" ] && cmd="$cmd -p$MYSQL_PASSWORD"
    [ "$MYSQL_HOST" != "localhost" ] && cmd="$cmd -h$MYSQL_HOST -P$MYSQL_PORT"
    
    $cmd -e "SHOW MASTER STATUS\G" 2>/dev/null | grep -E "(File|Position)" | awk '{print $2}' | tr '\n' ' '
}

# 增量备份（基于二进制日志）
do_incremental_backup() {
    log_info "开始 MySQL 增量备份..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$INCREMENTAL_DIR/incremental_$timestamp.sql"
    
    # 检查是否启用了二进制日志
    local binlog_info=$(get_binlog_pos)
    if [ -z "$binlog_info" ]; then
        log_error "MySQL 未启用二进制日志，无法进行增量备份"
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
    
    # 如果是首次增量备份，从最早的二进制日志开始
    if [ -z "$from_file" ]; then
        # 获取最早的二进制日志
        local cmd="mysql -u$MYSQL_USER"
        [ -n "$MYSQL_PASSWORD" ] && cmd="$cmd -p$MYSQL_PASSWORD"
        [ "$MYSQL_HOST" != "localhost" ] && cmd="$cmd -h$MYSQL_HOST -P$MYSQL_PORT"
        
        from_file=$($cmd -e "SHOW BINARY LOGS" 2>/dev/null | grep -v "Log_name" | head -1 | awk '{print $1}')
        from_pos=4
    fi
    
    # 使用 mysqlbinlog 导出增量数据
    local cmd="mysqlbinlog"
    [ -n "$MYSQL_USER" ] && cmd="$cmd -u$MYSQL_USER"
    [ -n "$MYSQL_PASSWORD" ] && cmd="$cmd -p$MYSQL_PASSWORD"
    [ "$MYSQL_HOST" != "localhost" ] && cmd="$cmd -h$MYSQL_HOST -P$MYSQL_PORT"
    $cmd --start-position=$from_pos "$from_file" > "$backup_file" 2>/dev/null
    
    if [ $? -eq 0 ] && [ -s "$backup_file" ]; then
        gzip "$backup_file"
        echo "$binlog_file $binlog_pos" > "$last_pos_file"
        log_success "增量备份完成: ${backup_file}.gz"
    else
        log_error "增量备份失败"
        rm -f "$backup_file"
        return 1
    fi
}

# 全量备份
do_full_backup() {
    log_info "开始 MySQL 全量备份..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$FULL_DIR/full_$timestamp.sql.gz"
    
    local cmd="mysqldump -u$MYSQL_USER"
    [ -n "$MYSQL_PASSWORD" ] && cmd="$cmd -p$MYSQL_PASSWORD"
    [ "$MYSQL_HOST" != "localhost" ] && cmd="$cmd -h$MYSQL_HOST -P$MYSQL_PORT"
    
    $cmd --all-databases --single-transaction --master-data=2 --flush-logs 2>/dev/null | gzip > "$backup_file"
    
    if [ $? -eq 0 ] && [ -s "$backup_file" ]; then
        local size=$(du -h "$backup_file" | cut -f1)
        log_success "全量备份完成: $backup_file (大小: $size)"
    else
        log_error "全量备份失败"
        rm -f "$backup_file"
        return 1
    fi
}

# 清理旧备份
cleanup_old_backups() {
    log_info "清理 ${INCREMENTAL_RETENTION} 天前的增量备份..."
    find "$INCREMENTAL_DIR" -name "incremental_*.sql.gz" -mtime +$INCREMENTAL_RETENTION -delete 2>/dev/null
    
    log_info "清理 ${FULL_RETENTION} 天前的全量备份..."
    find "$FULL_DIR" -name "full_*.sql.gz" -mtime +$FULL_RETENTION -delete 2>/dev/null
    
    log_success "旧备份清理完成"
}

# 显示备份列表
list_backups() {
    echo "=== MySQL 全量备份 ==="
    ls -lt "$FULL_DIR"/full_*.sql.gz 2>/dev/null | head -10 || echo "  暂无全量备份"
    
    echo ""
    echo "=== MySQL 增量备份 ==="
    ls -lt "$INCREMENTAL_DIR"/incremental_*.sql.gz 2>/dev/null | head -10 || echo "  暂无增量备份"
}

# 主函数
main() {
    init_dirs
    
    case "$1" in
        incremental)
            do_incremental_backup
            ;;
        full)
            do_full_backup
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
            echo "用法: $0 {incremental|full|cleanup|all|list}"
            echo "  incremental - 执行增量备份"
            echo "  full        - 执行全量备份"
            echo "  cleanup     - 清理旧备份"
            echo "  all         - 执行增量备份并清理"
            echo "  list        - 列出备份"
            ;;
    esac
}

main "$@"