#!/bin/bash
# MariaDB 数据库恢复脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 配置参数
BACKUP_ROOT="/var/backups/mariadb"
INCREMENTAL_DIR="$BACKUP_ROOT/incremental"
FULL_DIR="$BACKUP_ROOT/full"
LOG_FILE="$BACKUP_ROOT/mariadb_restore.log"

MARIADB_USER="${MARIADB_USER:-root}"
MARIADB_PASSWORD="${MARIADB_PASSWORD:-}"
MARIADB_HOST="${MARIADB_HOST:-localhost}"
MARIADB_PORT="${MARIADB_PORT:-3306}"

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

# 初始化
init() {
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

# 列出备份
list_backups() {
    echo "=== MariaDB 全量备份列表 ==="
    ls -lt "$FULL_DIR"/full_*.sql.gz 2>/dev/null | head -20 || echo "  暂无全量备份"
    
    echo ""
    echo "=== MariaDB 增量备份列表 ==="
    ls -lt "$INCREMENTAL_DIR"/incremental_*.sql.gz 2>/dev/null | head -20 || echo "  暂无增量备份"
}

# 验证备份文件
verify_backup() {
    local backup_file="$1"
    
    log_info "验证备份文件: $backup_file"
    
    if [ ! -f "$backup_file" ]; then
        log_error "备份文件不存在: $backup_file"
        return 1
    fi
    
    gunzip -t "$backup_file" 2>/dev/null
    if [ $? -eq 0 ]; then
        log_success "备份文件验证通过: $backup_file"
        return 0
    else
        log_error "备份文件损坏: $backup_file"
        return 1
    fi
}

# 从全量备份恢复
restore_full() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        backup_file=$(ls -t "$FULL_DIR"/full_*.sql.gz 2>/dev/null | head -1)
        if [ -z "$backup_file" ]; then
            log_error "没有找到可用的全量备份"
            return 1
        fi
        log_info "使用最新的全量备份: $backup_file"
    fi
    
    log_info "开始从全量备份恢复..."
    
    # 验证备份文件
    verify_backup "$backup_file" || return 1
    
    # 创建临时目录
    local tmp_dir=$(mktemp -d)
    
    # 解压备份文件
    log_info "解压备份文件..."
    gunzip -c "$backup_file" > "$tmp_dir/full_restore.sql"
    
    # 执行恢复
    log_info "正在恢复数据..."
    local cmd=$(build_mysql_cmd)
    $cmd < "$tmp_dir/full_restore.sql" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "全量备份恢复成功"
    else
        log_error "全量备份恢复失败"
        rm -rf "$tmp_dir"
        return 1
    fi
    
    rm -rf "$tmp_dir"
    return 0
}

# 从增量备份恢复
restore_incremental() {
    local full_backup="$1"
    local incremental_backup="$2"
    
    if [ -z "$full_backup" ]; then
        full_backup=$(ls -t "$FULL_DIR"/full_*.sql.gz 2>/dev/null | head -1)
        if [ -z "$full_backup" ]; then
            log_error "没有找到可用的全量备份"
            return 1
        fi
    fi
    
    if [ -z "$incremental_backup" ]; then
        incremental_backup=$(ls -t "$INCREMENTAL_DIR"/incremental_*.sql.gz 2>/dev/null | head -1)
        if [ -z "$incremental_backup" ]; then
            log_error "没有找到可用的增量备份"
            return 1
        fi
    fi
    
    log_info "开始增量恢复..."
    log_info "全量备份: $full_backup"
    log_info "增量备份: $incremental_backup"
    
    local tmp_dir=$(mktemp -d)
    local cmd=$(build_mysql_cmd)
    
    # 解压并恢复全量备份
    log_info "应用全量备份..."
    gunzip -c "$full_backup" > "$tmp_dir/full.sql"
    $cmd < "$tmp_dir/full.sql" 2>/dev/null
    
    # 解压并恢复增量备份
    log_info "应用增量备份..."
    gunzip -c "$incremental_backup" > "$tmp_dir/incremental.sql"
    $cmd < "$tmp_dir/incremental.sql" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "增量备份恢复成功"
    else
        log_error "增量备份恢复失败"
        rm -rf "$tmp_dir"
        return 1
    fi
    
    rm -rf "$tmp_dir"
    return 0
}

# 从物理备份恢复（mariabackup）
restore_physical() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        backup_file=$(ls -t "$FULL_DIR"/physical_*.tar.gz 2>/dev/null | head -1)
        if [ -z "$backup_file" ]; then
            log_error "没有找到可用的物理备份"
            return 1
        fi
    fi
    
    if ! command -v mariabackup &> /dev/null; then
        log_error "mariabackup 命令不可用"
        return 1
    fi
    
    log_info "开始从物理备份恢复..."
    
    local tmp_dir=$(mktemp -d)
    
    # 解压备份
    log_info "解压备份文件..."
    tar xzf "$backup_file" -C "$tmp_dir"
    
    local backup_dir=$(ls "$tmp_dir" | head -1)
    
    # 准备备份
    log_info "准备备份..."
    mariabackup --prepare --target-dir="$tmp_dir/$backup_dir" 2>/dev/null
    
    # 停止 MariaDB
    log_info "停止 MariaDB 服务..."
    systemctl stop mariadb 2>/dev/null || service mysql stop 2>/dev/null
    
    # 恢复数据
    log_info "恢复数据文件..."
    mariabackup --copy-back --target-dir="$tmp_dir/$backup_dir" 2>/dev/null
    
    # 设置权限
    chown -R mysql:mysql /var/lib/mysql
    
    # 启动 MariaDB
    log_info "启动 MariaDB 服务..."
    systemctl start mariadb 2>/dev/null || service mysql start 2>/dev/null
    
    rm -rf "$tmp_dir"
    log_success "物理备份恢复完成"
}

# 恢复单个数据库
restore_database() {
    local backup_file="$1"
    local db_name="$2"
    
    if [ -z "$backup_file" ] || [ -z "$db_name" ]; then
        log_error "请指定备份文件和数据库名"
        return 1
    fi
    
    log_info "恢复数据库: $db_name"
    
    local tmp_dir=$(mktemp -d)
    gunzip -c "$backup_file" > "$tmp_dir/restore.sql"
    
    local cmd=$(build_mysql_cmd)
    $cmd "$db_name" < "$tmp_dir/restore.sql" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "数据库 $db_name 恢复成功"
    else
        log_error "数据库 $db_name 恢复失败"
        rm -rf "$tmp_dir"
        return 1
    fi
    
    rm -rf "$tmp_dir"
    return 0
}

# 显示帮助
show_help() {
    echo "MariaDB 数据库恢复脚本"
    echo ""
    echo "用法: $0 {full|incremental|physical|list|verify|help}"
    echo ""
    echo "命令:"
    echo "  full [备份文件]           - 从全量备份恢复"
    echo "  incremental [全量] [增量] - 从增量备份恢复"
    echo "  physical [备份文件]       - 从物理备份恢复"
    echo "  database <备份> <数据库>  - 恢复单个数据库"
    echo "  list                      - 列出所有备份"
    echo "  verify [备份文件]         - 验证备份文件"
    echo "  help                      - 显示帮助"
}

# 主函数
main() {
    init
    
    case "$1" in
        full)
            restore_full "$2"
            ;;
        incremental)
            restore_incremental "$2" "$3"
            ;;
        physical)
            restore_physical "$2"
            ;;
        database)
            restore_database "$2" "$3"
            ;;
        list)
            list_backups
            ;;
        verify)
            verify_backup "$2"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            show_help
            ;;
    esac
}

main "$@"