#!/bin/bash
# MySQL 数据库恢复脚本
# 支持从全量备份和增量备份恢复

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 配置参数
BACKUP_ROOT="/var/backups/mysql"
INCREMENTAL_DIR="$BACKUP_ROOT/incremental"
FULL_DIR="$BACKUP_ROOT/full"
LOG_FILE="$BACKUP_ROOT/mysql_restore.log"

MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-}"
MYSQL_HOST="${MYSQL_HOST:-localhost}"
MYSQL_PORT="${MYSQL_PORT:-3306}"

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

# 列出可用的全量备份
list_full_backups() {
    echo "=== MySQL 全量备份列表 ==="
    echo ""

    if [ -d "$FULL_DIR" ]; then
        local backups=$(ls -lt "$FULL_DIR"/full_*.sql.gz 2>/dev/null)
        if [ -z "$backups" ]; then
            echo "  暂无全量备份"
        else
            echo "$backups" | head -20
        fi
    else
        echo "  备份目录不存在: $FULL_DIR"
    fi
}

# 列出可用的增量备份
list_incremental_backups() {
    echo "=== MySQL 增量备份列表 ==="
    echo ""

    if [ -d "$INCREMENTAL_DIR" ]; then
        local backups=$(ls -lt "$INCREMENTAL_DIR"/incremental_*.sql.gz 2>/dev/null)
        if [ -z "$backups" ]; then
            echo "  暂无增量备份"
        else
            echo "$backups" | head -20
        fi
    else
        echo "  备份目录不存在: $INCREMENTAL_DIR"
    fi
}

# 列出所有备份
list_backups() {
    list_full_backups
    echo ""
    list_incremental_backups
}

# 验证备份文件
verify_backup() {
    local backup_file="$1"

    log_info "验证备份文件: $backup_file"

    if [ ! -f "$backup_file" ]; then
        log_error "备份文件不存在: $backup_file"
        return 1
    fi

    # 检查 gzip 文件完整性
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
        # 自动选择最新的全量备份
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

    if [ ! -s "$tmp_dir/full_restore.sql" ]; then
        log_error "备份文件解压失败或为空"
        rm -rf "$tmp_dir"
        return 1
    fi

    # 停止 MySQL 服务（如果需要）
    log_info "准备恢复数据..."

    # 构建恢复命令
    local cmd="mysql -u$MYSQL_USER"
    [ -n "$MYSQL_PASSWORD" ] && cmd="$cmd -p$MYSQL_PASSWORD"
    [ "$MYSQL_HOST" != "localhost" ] && cmd="$cmd -h$MYSQL_HOST -P$MYSQL_PORT"

    # 执行恢复
    log_info "正在恢复数据..."
    $cmd < "$tmp_dir/full_restore.sql" 2>/dev/null

    if [ $? -eq 0 ]; then
        log_success "全量备份恢复成功"
    else
        log_error "全量备份恢复失败"
        rm -rf "$tmp_dir"
        return 1
    fi

    # 清理临时目录
    rm -rf "$tmp_dir"

    return 0
}

# 从增量备份恢复（需要配合全量备份）
restore_incremental() {
    local full_backup="$1"
    local incremental_backup="$2"

    # 获取全量备份
    if [ -z "$full_backup" ]; then
        full_backup=$(ls -t "$FULL_DIR"/full_*.sql.gz 2>/dev/null | head -1)
        if [ -z "$full_backup" ]; then
            log_error "没有找到可用的全量备份"
            return 1
        fi
    fi

    # 获取增量备份
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

    # 创建临时目录
    local tmp_dir=$(mktemp -d)

    # 解压全量备份
    log_info "解压全量备份..."
    gunzip -c "$full_backup" > "$tmp_dir/full.sql"

    # 解压增量备份
    log_info "解压增量备份..."
    gunzip -c "$incremental_backup" > "$tmp_dir/incremental.sql"

    # 按顺序执行恢复
    log_info "应用全量备份..."
    local cmd="mysql -u$MYSQL_USER"
    [ -n "$MYSQL_PASSWORD" ] && cmd="$cmd -p$MYSQL_PASSWORD"
    [ "$MYSQL_HOST" != "localhost" ] && cmd="$cmd -h$MYSQL_HOST -P$MYSQL_PORT"

    $cmd < "$tmp_dir/full.sql" 2>/dev/null

    if [ $? -ne 0 ]; then
        log_error "全量备份应用失败"
        rm -rf "$tmp_dir"
        return 1
    fi

    log_info "应用增量备份..."
    $cmd < "$tmp_dir/incremental.sql" 2>/dev/null

    if [ $? -eq 0 ]; then
        log_success "增量备份恢复成功"
    else
        log_error "增量备份应用失败"
        rm -rf "$tmp_dir"
        return 1
    fi

    # 清理临时目录
    rm -rf "$tmp_dir"

    return 0
}

# 从指定时间点恢复（使用 binlog）
restore_point_in_time() {
    local target_time="$1"

    if [ -z "$target_time" ]; then
        log_error "请指定恢复时间点（格式: YYYY-MM-DD HH:MM:SS）"
        return 1
    fi

    log_info "开始时间点恢复到: $target_time"

    # 获取最新的全量备份
    local full_backup=$(ls -t "$FULL_DIR"/full_*.sql.gz 2>/dev/null | head -1)
    if [ -z "$full_backup" ]; then
        log_error "没有找到可用的全量备份"
        return 1
    fi

    # 创建临时目录
    local tmp_dir=$(mktemp -d)

    # 解压全量备份
    log_info "解压全量备份..."
    gunzip -c "$full_backup" > "$tmp_dir/full.sql"

    # 恢复全量备份
    log_info "恢复全量备份..."
    local cmd="mysql -u$MYSQL_USER"
    [ -n "$MYSQL_PASSWORD" ] && cmd="$cmd -p$MYSQL_PASSWORD"
    [ "$MYSQL_HOST" != "localhost" ] && cmd="$cmd -h$MYSQL_HOST -P$MYSQL_PORT"

    $cmd < "$tmp_dir/full.sql" 2>/dev/null

    if [ $? -ne 0 ]; then
        log_error "全量备份恢复失败"
        rm -rf "$tmp_dir"
        return 1
    fi

    # 应用增量备份到指定时间点
    log_info "应用增量备份到指定时间点..."
    local binlog_cmd="mysqlbinlog"
    [ -n "$MYSQL_USER" ] && binlog_cmd="$binlog_cmd -u$MYSQL_USER"
    [ -n "$MYSQL_PASSWORD" ] && binlog_cmd="$binlog_cmd -p$MYSQL_PASSWORD"
    [ "$MYSQL_HOST" != "localhost" ] && binlog_cmd="$binlog_cmd -h$MYSQL_HOST -P$MYSQL_PORT"

    # 获取需要恢复的增量备份
    for inc_backup in $(ls -t "$INCREMENTAL_DIR"/incremental_*.sql.gz 2>/dev/null); do
        $binlog_cmd --stop-datetime="$target_time" "$inc_backup" 2>/dev/null | $cmd
    done

    log_success "时间点恢复完成"

    # 清理临时目录
    rm -rf "$tmp_dir"

    return 0
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
    log_info "备份文件: $backup_file"

    # 创建临时目录
    local tmp_dir=$(mktemp -d)

    # 解压备份
    gunzip -c "$backup_file" > "$tmp_dir/restore.sql"

    # 构建恢复命令
    local cmd="mysql -u$MYSQL_USER"
    [ -n "$MYSQL_PASSWORD" ] && cmd="$cmd -p$MYSQL_PASSWORD"
    [ "$MYSQL_HOST" != "localhost" ] && cmd="$cmd -h$MYSQL_HOST -P$MYSQL_PORT"

    # 执行恢复
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
    echo "MySQL 数据库恢复脚本"
    echo ""
    echo "用法: $0 {full|incremental|point|list|verify|help}"
    echo ""
    echo "命令:"
    echo "  full [备份文件]           - 从全量备份恢复（不指定则使用最新的）"
    echo "  incremental [全量] [增量] - 从增量备份恢复（需要全量+增量）"
    echo "  point <时间点>            - 恢复到指定时间点（格式: YYYY-MM-DD HH:MM:SS）"
    echo "  database <备份> <数据库>  - 恢复单个数据库"
    echo "  list                      - 列出所有可用备份"
    echo "  verify [备份文件]         - 验证备份文件"
    echo "  help                      - 显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 full                                    # 使用最新全量备份恢复"
    echo "  $0 full /var/backups/mysql/full/xxx.sql.gz # 使用指定备份恢复"
    echo "  $0 incremental                             # 使用最新全量和增量备份恢复"
    echo "  $0 point '2024-01-15 10:30:00'            # 恢复到指定时间点"
    echo "  $0 database /path/to/backup.sql.gz mydb    # 恢复指定数据库"
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
        point)
            restore_point_in_time "$2"
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