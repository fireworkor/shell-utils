#!/bin/bash
# PostgreSQL 数据库恢复脚本
# 支持从全量备份和增量备份（WAL）恢复

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 配置参数
BACKUP_ROOT="/var/backups/postgresql"
INCREMENTAL_DIR="$BACKUP_ROOT/incremental"
FULL_DIR="$BACKUP_ROOT/full"
LOG_FILE="$BACKUP_ROOT/postgresql_restore.log"

PG_USER="${PG_USER:-postgres}"
PG_HOST="${PG_HOST:-localhost}"
PG_PORT="${PG_PORT:-5432}"
PG_DATABASE="${PG_DATABASE:-postgres}"

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
    echo "=== PostgreSQL 全量备份列表 ==="
    echo ""

    if [ -d "$FULL_DIR" ]; then
        local backups=$(ls -lt "$FULL_DIR"/full_*.tar.gz 2>/dev/null)
        if [ -z "$backups" ]; then
            backups=$(ls -lt "$FULL_DIR"/base_*.tar 2>/dev/null)
        fi
        if [ -z "$backups" ]; then
            backups=$(ls -lt "$FULL_DIR"/full_*.sql.gz 2>/dev/null)
        fi

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
    echo "=== PostgreSQL 增量备份列表 ==="
    echo ""

    if [ -d "$INCREMENTAL_DIR" ]; then
        local backups=$(ls -lt "$INCREMENTAL_DIR"/incremental_*.tar.gz 2>/dev/null)
        if [ -z "$backups" ]; then
            backups=$(ls -lt "$INCREMENTAL_DIR"/*.wal 2>/dev/null)
        fi

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

    # 检查 tar.gz 文件完整性
    tar tzf "$backup_file" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log_success "备份文件验证通过: $backup_file"
        return 0
    else
        # 尝试检查 gzip 文件
        gunzip -t "$backup_file" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_success "备份文件验证通过: $backup_file"
            return 0
        fi
        log_error "备份文件损坏: $backup_file"
        return 1
    fi
}

# 停止 PostgreSQL 服务
stop_postgres() {
    log_info "停止 PostgreSQL 服务..."

    # 尝试多种方式停止 PostgreSQL
    if command -v pg_ctl &> /dev/null; then
        su - "$PG_USER" -c "pg_ctl stop -D $PG_DATA -m fast" 2>/dev/null
    elif [ -f /etc/init.d/postgresql ]; then
        service postgresql stop 2>/dev/null
    elif [ -f /etc/systemd/system/postgresql.service ]; then
        systemctl stop postgresql 2>/dev/null
    fi

    sleep 2
}

# 启动 PostgreSQL 服务
start_postgres() {
    log_info "启动 PostgreSQL 服务..."

    if command -v pg_ctl &> /dev/null; then
        su - "$PG_USER" -c "pg_ctl start -D $PG_DATA -l $PG_DATA/postgresql.log" 2>/dev/null
    elif [ -f /etc/init.d/postgresql ]; then
        service postgresql start 2>/dev/null
    elif [ -f /etc/systemd/system/postgresql.service ]; then
        systemctl start postgresql 2>/dev/null
    fi

    sleep 2
}

# 获取 PostgreSQL 数据目录
get_pg_data() {
    su - "$PG_USER" -c "psql -U $PG_USER -h $PG_HOST -p $PG_PORT -d $PG_DATABASE -t -c 'show data_directory;'" 2>/dev/null | tr -d ' '
}

# 从全量备份恢复（pg_dumpall 格式）
restore_full_sql() {
    local backup_file="$1"

    if [ -z "$backup_file" ]; then
        # 自动选择最新的 SQL 格式全量备份
        backup_file=$(ls -t "$FULL_DIR"/full_*.sql.gz 2>/dev/null | head -1)
        if [ -z "$backup_file" ]; then
            log_error "没有找到可用的全量备份"
            return 1
        fi
        log_info "使用最新的全量备份: $backup_file"
    fi

    log_info "开始从全量备份恢复（SQL 格式）..."

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

    # 构建恢复命令
    local cmd="psql -U $PG_USER -h $PG_HOST -p $PG_PORT -d $PG_DATABASE"

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

# 从全量备份恢复（pg_basebackup 格式）
restore_full_basebackup() {
    local backup_file="$1"

    if [ -z "$backup_file" ]; then
        # 自动选择最新的 basebackup 格式全量备份
        backup_file=$(ls -t "$FULL_DIR"/full_*.tar.gz 2>/dev/null | head -1)
        if [ -z "$backup_file" ]; then
            log_error "没有找到可用的全量备份"
            return 1
        fi
        log_info "使用最新的全量备份: $backup_file"
    fi

    log_info "开始从全量备份恢复（basebackup 格式）..."

    # 获取 PostgreSQL 数据目录
    local pg_data=$(get_pg_data)
    if [ -z "$pg_data" ]; then
        log_error "无法获取 PostgreSQL 数据目录"
        return 1
    fi

    log_info "PostgreSQL 数据目录: $pg_data"

    # 验证备份文件
    verify_backup "$backup_file" || return 1

    # 停止 PostgreSQL
    stop_postgres

    # 备份当前数据目录
    local backup_old="$pg_data.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "备份当前数据目录到: $backup_old"
    mv "$pg_data" "$backup_old"

    # 创建新的数据目录
    mkdir -p "$pg_data"

    # 解压备份到数据目录
    log_info "解压备份文件..."
    tar xzf "$backup_file" -C "$pg_data"

    # 设置权限
    chown -R "$PG_USER:$PG_USER" "$pg_data"
    chmod 700 "$pg_data"

    # 启动 PostgreSQL
    start_postgres

    log_success "basebackup 格式全量备份恢复完成"
    log_info "旧数据目录已备份到: $backup_old"

    return 0
}

# 从增量备份恢复（WAL）
restore_incremental() {
    local full_backup="$1"
    local incremental_backup="$2"

    # 获取全量备份
    if [ -z "$full_backup" ]; then
        full_backup=$(ls -t "$FULL_DIR"/full_*.tar.gz 2>/dev/null | head -1)
        if [ -z "$full_backup" ]; then
            full_backup=$(ls -t "$FULL_DIR"/full_*.sql.gz 2>/dev/null | head -1)
        fi
        if [ -z "$full_backup" ]; then
            log_error "没有找到可用的全量备份"
            return 1
        fi
    fi

    # 获取增量备份
    if [ -z "$incremental_backup" ]; then
        incremental_backup=$(ls -t "$INCREMENTAL_DIR"/incremental_*.tar.gz 2>/dev/null | head -1)
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

    # 根据全量备份格式选择恢复方式
    if echo "$full_backup" | grep -q "\.sql\.gz$"; then
        # SQL 格式备份
        log_info "检测到 SQL 格式备份"
        restore_full_sql "$full_backup"
        return $?
    else
        # tar.gz 格式备份，需要使用 PITR
        log_info "检测到 basebackup 格式，使用 PITR 恢复..."

        # 获取 PostgreSQL 数据目录
        local pg_data=$(get_pg_data)
        if [ -z "$pg_data" ]; then
            log_error "无法获取 PostgreSQL 数据目录"
            return 1
        fi

        # 停止 PostgreSQL
        stop_postgres

        # 备份当前数据目录
        local backup_old="$pg_data.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "备份当前数据目录到: $backup_old"
        mv "$pg_data" "$backup_old"

        # 创建新的数据目录
        mkdir -p "$pg_data"

        # 解压全量备份
        log_info "解压全量备份..."
        tar xzf "$full_backup" -C "$pg_data"

        # 创建恢复信号文件
        touch "$pg_data/recovery.signal"

        # 解压增量备份（WAL 文件）
        log_info "解压增量备份..."
        mkdir -p "$pg_data/pg_wal"
        tar xzf "$incremental_backup" -C "$pg_data/pg_wal"

        # 设置权限
        chown -R "$PG_USER:$PG_USER" "$pg_data"
        chmod 700 "$pg_data"

        # 启动 PostgreSQL
        start_postgres

        log_success "增量恢复完成"
    fi

    # 清理临时目录
    rm -rf "$tmp_dir"

    return 0
}

# 恢复到指定时间点
restore_point_in_time() {
    local target_time="$1"

    if [ -z "$target_time" ]; then
        log_error "请指定恢复时间点（格式: YYYY-MM-DD HH:MI:SS）"
        return 1
    fi

    log_info "开始时间点恢复到: $target_time"

    # 获取最新的全量备份
    local full_backup=$(ls -t "$FULL_DIR"/full_*.tar.gz 2>/dev/null | head -1)
    if [ -z "$full_backup" ]; then
        full_backup=$(ls -t "$FULL_DIR"/full_*.sql.gz 2>/dev/null | head -1)
    fi
    if [ -z "$full_backup" ]; then
        log_error "没有找到可用的全量备份"
        return 1
    fi

    # 获取 PostgreSQL 数据目录
    local pg_data=$(get_pg_data)
    if [ -z "$pg_data" ]; then
        log_error "无法获取 PostgreSQL 数据目录"
        return 1
    fi

    # 停止 PostgreSQL
    stop_postgres

    # 备份当前数据目录
    local backup_old="$pg_data.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "备份当前数据目录到: $backup_old"
    mv "$pg_data" "$backup_old"

    # 创建新的数据目录
    mkdir -p "$pg_data"

    # 解压全量备份
    log_info "解压全量备份..."
    tar xzf "$full_backup" -C "$pg_data"

    # 创建恢复配置文件
    cat > "$pg_data/postgresql.auto.conf" <<EOF
restore_command = 'cp $INCREMENTAL_DIR/%f %p'
recovery_target_time = '$target_time'
recovery_target_action = 'promote'
EOF

    # 设置权限
    chown -R "$PG_USER:$PG_USER" "$pg_data"
    chmod 700 "$pg_data"

    # 启动 PostgreSQL
    start_postgres

    log_success "时间点恢复已启动"
    log_info "PostgreSQL 将在恢复完成后自动切换到正常模式"

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
    local cmd="psql -U $PG_USER -h $PG_HOST -p $PG_PORT -d $PG_DATABASE"

    # 执行恢复
    $cmd < "$tmp_dir/restore.sql" 2>/dev/null

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
    echo "PostgreSQL 数据库恢复脚本"
    echo ""
    echo "用法: $0 {full|basebackup|incremental|point|list|verify|help}"
    echo ""
    echo "命令:"
    echo "  full [备份文件]           - 从全量备份恢复（SQL格式）"
    echo "  basebackup [备份文件]     - 从全量备份恢复（basebackup格式）"
    echo "  incremental [全量] [增量] - 从增量备份恢复"
    echo "  point <时间点>            - 恢复到指定时间点"
    echo "  database <备份> <数据库>  - 恢复单个数据库"
    echo "  list                      - 列出所有可用备份"
    echo "  verify [备份文件]         - 验证备份文件"
    echo "  help                      - 显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 full                                    # 使用最新全量备份恢复"
    echo "  $0 basebackup /path/to/backup.tar.gz      # 使用指定basebackup恢复"
    echo "  $0 incremental                             # 使用最新全量和增量备份恢复"
    echo "  $0 point '2024-01-15 10:30:00'            # 恢复到指定时间点"
}

# 主函数
main() {
    init

    case "$1" in
        full)
            restore_full_sql "$2"
            ;;
        basebackup)
            restore_full_basebackup "$2"
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