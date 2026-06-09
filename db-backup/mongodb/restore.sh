#!/bin/bash
# MongoDB 数据库恢复脚本
# 支持从全量备份和增量备份恢复

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 配置参数
BACKUP_ROOT="/var/backups/mongodb"
INCREMENTAL_DIR="$BACKUP_ROOT/incremental"
FULL_DIR="$BACKUP_ROOT/full"
LOG_FILE="$BACKUP_ROOT/mongodb_restore.log"

MONGO_HOST="${MONGO_HOST:-localhost}"
MONGO_PORT="${MONGO_PORT:-27017}"
MONGO_USER="${MONGO_USER:-}"
MONGO_PASSWORD="${MONGO_PASSWORD:-}"

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
    echo "=== MongoDB 全量备份列表 ==="
    echo ""

    if [ -d "$FULL_DIR" ]; then
        local backups=$(ls -lt "$FULL_DIR"/full_*.archive* 2>/dev/null)
        if [ -z "$backups" ]; then
            backups=$(ls -lt "$FULL_DIR"/dump 2>/dev/null)
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
    echo "=== MongoDB 增量备份列表 ==="
    echo ""

    if [ -d "$INCREMENTAL_DIR" ]; then
        local backups=$(ls -lt "$INCREMENTAL_DIR"/incremental_*.archive* 2>/dev/null)
        if [ -z "$backups" ]; then
            backups=$(ls -lt "$INCREMENTAL_DIR"/oplog* 2>/dev/null)
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

    # 检查文件是否为空
    if [ ! -s "$backup_file" ]; then
        log_error "备份文件为空: $backup_file"
        return 1
    fi

    log_success "备份文件验证通过: $backup_file"
    return 0
}

# 构建 mongorestore 命令
build_mongorestore_cmd() {
    local cmd="mongorestore --host $MONGO_HOST --port $MONGO_PORT"
    if [ -n "$MONGO_USER" ] && [ -n "$MONGO_PASSWORD" ]; then
        cmd="$cmd -u $MONGO_USER -p $MONGO_PASSWORD"
    fi
    echo "$cmd"
}

# 从全量备份恢复（archive 格式）
restore_full_archive() {
    local backup_file="$1"

    if [ -z "$backup_file" ]; then
        # 自动选择最新的 archive 格式全量备份
        backup_file=$(ls -t "$FULL_DIR"/full_*.archive.gz 2>/dev/null | head -1)
        if [ -z "$backup_file" ]; then
            backup_file=$(ls -t "$FULL_DIR"/full_*.archive 2>/dev/null | head -1)
        fi
        if [ -z "$backup_file" ]; then
            log_error "没有找到可用的全量备份"
            return 1
        fi
        log_info "使用最新的全量备份: $backup_file"
    fi

    log_info "开始从全量备份恢复（archive 格式）..."

    # 验证备份文件
    verify_backup "$backup_file" || return 1

    # 创建临时目录
    local tmp_dir=$(mktemp -d)

    # 解压 archive 文件到临时目录
    log_info "解压 archive 文件..."
    if echo "$backup_file" | grep -q "\.gz$"; then
        gunzip -c "$backup_file" > "$tmp_dir/full.archive"
    else
        cp "$backup_file" "$tmp_dir/full.archive"
    fi

    # 构建恢复命令
    local cmd=$(build_mongorestore_cmd)
    cmd="$cmd --archive=$tmp_dir/full.archive"

    # 执行恢复
    log_info "正在恢复数据..."
    $cmd 2>/dev/null

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

# 从全量备份恢复（dump 目录格式）
restore_full_dump() {
    local backup_dir="$1"

    if [ -z "$backup_dir" ]; then
        # 自动选择最新的 dump 目录
        if [ -d "$FULL_DIR/dump" ]; then
            backup_dir="$FULL_DIR/dump"
        else
            log_error "没有找到可用的全量备份"
            return 1
        fi
        log_info "使用最新的全量备份: $backup_dir"
    fi

    log_info "开始从全量备份恢复（dump 格式）..."

    if [ ! -d "$backup_dir" ]; then
        log_error "备份目录不存在: $backup_dir"
        return 1
    fi

    # 构建恢复命令
    local cmd=$(build_mongorestore_cmd)
    cmd="$cmd --drop"  # 恢复前删除已有数据
    cmd="$cmd $backup_dir"

    # 执行恢复
    log_info "正在恢复数据..."
    $cmd 2>/dev/null

    if [ $? -eq 0 ]; then
        log_success "全量备份恢复成功"
    else
        log_error "全量备份恢复失败"
        return 1
    fi

    return 0
}

# 从增量备份恢复（基于 Oplog）
restore_incremental() {
    local incremental_backup="$1"

    if [ -z "$incremental_backup" ]; then
        # 自动选择最新的增量备份
        incremental_backup=$(ls -t "$INCREMENTAL_DIR"/incremental_*.archive.gz 2>/dev/null | head -1)
        if [ -z "$incremental_backup" ]; then
            incremental_backup=$(ls -t "$INCREMENTAL_DIR"/incremental_*.archive 2>/dev/null | head -1)
        fi
        if [ -z "$incremental_backup" ]; then
            log_error "没有找到可用的增量备份"
            return 1
        fi
        log_info "使用最新的增量备份: $incremental_backup"
    fi

    log_info "开始从增量备份恢复..."

    # 验证备份文件
    verify_backup "$incremental_backup" || return 1

    # 创建临时目录
    local tmp_dir=$(mktemp -d)

    # 解压 archive 文件到临时目录
    log_info "解压增量备份..."
    if echo "$incremental_backup" | grep -q "\.gz$"; then
        gunzip -c "$incremental_backup" > "$tmp_dir/incremental.archive"
    else
        cp "$incremental_backup" "$tmp_dir/incremental.archive"
    fi

    # 构建恢复命令（使用 oplogReplay）
    local cmd=$(build_mongorestore_cmd)
    cmd="$cmd --archive=$tmp_dir/incremental.archive"
    cmd="$cmd --oplogReplay"

    # 执行恢复
    log_info "正在应用增量备份..."
    $cmd 2>/dev/null

    if [ $? -eq 0 ]; then
        log_success "增量备份恢复成功"
    else
        log_error "增量备份恢复失败"
        rm -rf "$tmp_dir"
        return 1
    fi

    # 清理临时目录
    rm -rf "$tmp_dir"

    return 0
}

# 恢复到指定时间点
restore_point_in_time() {
    local target_time="$1"

    if [ -z "$target_time" ]; then
        log_error "请指定恢复时间点（格式: YYYY-MM-DD HH:MM:SS）"
        return 1
    fi

    log_info "开始时间点恢复到: $target_time"

    # 获取最新的全量备份
    local full_backup=$(ls -t "$FULL_DIR"/full_*.archive.gz 2>/dev/null | head -1)
    if [ -z "$full_backup" ]; then
        full_backup=$(ls -t "$FULL_DIR"/full_*.archive 2>/dev/null | head -1)
    fi
    if [ -z "$full_backup" ]; then
        full_backup=$(ls -t "$FULL_DIR"/dump 2>/dev/null -d | head -1)
    fi
    if [ -z "$full_backup" ]; then
        log_error "没有找到可用的全量备份"
        return 1
    fi

    log_info "使用全量备份: $full_backup"

    # 创建临时目录
    local tmp_dir=$(mktemp -d)

    # 先恢复全量备份
    if [ -d "$full_backup" ]; then
        log_info "恢复全量备份..."
        local cmd=$(build_mongorestore_cmd)
        cmd="$cmd --drop"
        cmd="$cmd $full_backup"
        $cmd 2>/dev/null
    else
        log_info "解压全量备份..."
        if echo "$full_backup" | grep -q "\.gz$"; then
            gunzip -c "$full_backup" > "$tmp_dir/full.archive"
        else
            cp "$full_backup" "$tmp_dir/full.archive"
        fi

        log_info "恢复全量备份..."
        local cmd=$(build_mongorestore_cmd)
        cmd="$cmd --archive=$tmp_dir/full.archive"
        cmd="$cmd --drop"
        $cmd 2>/dev/null
    fi

    # 获取所有增量备份并恢复到指定时间点
    log_info "应用增量备份到指定时间点..."

    for inc_backup in $(ls -t "$INCREMENTAL_DIR"/incremental_*.archive* 2>/dev/null); do
        if echo "$inc_backup" | grep -q "\.gz$"; then
            gunzip -c "$inc_backup" > "$tmp_dir/inc.archive"
        else
            cp "$inc_backup" "$tmp_dir/inc.archive"
        fi

        local cmd=$(build_mongorestore_cmd)
        cmd="$cmd --archive=$tmp_dir/inc.archive"
        cmd="$cmd --oplogReplay"
        cmd="$cmd --oplogLimit='$target_time'"
        $cmd 2>/dev/null
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
    if echo "$backup_file" | grep -q "\.gz$"; then
        gunzip -c "$backup_file" > "$tmp_dir/restore.archive"
    else
        cp "$backup_file" "$tmp_dir/restore.archive"
    fi

    # 构建恢复命令
    local cmd=$(build_mongorestore_cmd)
    cmd="$cmd --archive=$tmp_dir/restore.archive"
    cmd="$cmd --nsInclude='$db_name.*'"

    # 执行恢复
    $cmd 2>/dev/null

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

# 恢复单个集合
restore_collection() {
    local backup_dir="$1"
    local ns="$2"

    if [ -z "$backup_dir" ] || [ -z "$ns" ]; then
        log_error "请指定备份目录和集合名（格式: database.collection）"
        return 1
    fi

    log_info "恢复集合: $ns"
    log_info "备份目录: $backup_dir"

    # 构建恢复命令
    local cmd=$(build_mongorestore_cmd)
    cmd="$cmd $backup_dir"
    cmd="$cmd --nsInclude='$ns'"

    # 执行恢复
    $cmd 2>/dev/null

    if [ $? -eq 0 ]; then
        log_success "集合 $ns 恢复成功"
    else
        log_error "集合 $ns 恢复失败"
        return 1
    fi

    return 0
}

# 显示帮助
show_help() {
    echo "MongoDB 数据库恢复脚本"
    echo ""
    echo "用法: $0 {full|dump|incremental|point|list|verify|help}"
    echo ""
    echo "命令:"
    echo "  full [备份文件]           - 从全量备份恢复（archive格式）"
    echo "  dump [备份目录]           - 从全量备份恢复（dump目录格式）"
    echo "  incremental [备份文件]    - 从增量备份恢复"
    echo "  point <时间点>            - 恢复到指定时间点"
    echo "  database <备份> <数据库>  - 恢复单个数据库"
    echo "  collection <目录> <集合>   - 恢复单个集合（格式: db.collection）"
    echo "  list                      - 列出所有可用备份"
    echo "  verify [备份文件]         - 验证备份文件"
    echo "  help                      - 显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 full                                    # 使用最新全量备份恢复"
    echo "  $0 dump /path/to/dump                     # 从dump目录恢复"
    echo "  $0 incremental                            # 使用最新增量备份恢复"
    echo "  $0 point '2024-01-15 10:30:00'            # 恢复到指定时间点"
    echo "  $0 database /path/to/backup.archive.gz mydb"
}

# 主函数
main() {
    init

    case "$1" in
        full)
            restore_full_archive "$2"
            ;;
        dump)
            restore_full_dump "$2"
            ;;
        incremental)
            restore_incremental "$2"
            ;;
        point)
            restore_point_in_time "$2"
            ;;
        database)
            restore_database "$2" "$3"
            ;;
        collection)
            restore_collection "$2" "$3"
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