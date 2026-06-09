#!/bin/bash
# Redis 数据库恢复脚本
# 支持从全量备份和增量备份恢复

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 配置参数
BACKUP_ROOT="/var/backups/redis"
INCREMENTAL_DIR="$BACKUP_ROOT/incremental"
FULL_DIR="$BACKUP_ROOT/full"
LOG_FILE="$BACKUP_ROOT/redis_restore.log"

REDIS_HOST="${REDIS_HOST:-localhost}"
REDIS_PORT="${REDIS_PORT:-6379}"
REDIS_PASSWORD="${REDIS_PASSWORD:-}"

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
    echo "=== Redis 全量备份列表 ==="
    echo ""

    if [ -d "$FULL_DIR" ]; then
        local backups=$(ls -lt "$FULL_DIR"/redis_full_*.rdb* 2>/dev/null)
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
    echo "=== Redis 增量备份列表 ==="
    echo ""

    if [ -d "$INCREMENTAL_DIR" ]; then
        local backups=$(ls -lt "$INCREMENTAL_DIR"/redis_incremental_*.rdb* 2>/dev/null)
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
    if echo "$backup_file" | grep -q "\.gz$"; then
        gunzip -t "$backup_file" 2>/dev/null
        if [ $? -ne 0 ]; then
            log_error "备份文件损坏: $backup_file"
            return 1
        fi

        # 进一步检查 RDB 文件结构
        local tmp_file=$(mktemp)
        gunzip -c "$backup_file" > "$tmp_file"
        if ! grep -q "REDIS" "$tmp_file" 2>/dev/null && ! head -c 5 "$tmp_file" | grep -q "REDIS"; then
            log_error "RDB 文件格式无效: $backup_file"
            rm -f "$tmp_file"
            return 1
        fi
        rm -f "$tmp_file"
    else
        # 检查原始 RDB 文件
        if ! head -c 5 "$backup_file" | grep -q "REDIS"; then
            log_error "RDB 文件格式无效: $backup_file"
            return 1
        fi
    fi

    log_success "备份文件验证通过: $backup_file"
    return 0
}

# 获取 Redis 配置
get_redis_config() {
    redis_cmd "CONFIG GET $1" | tail -1
}

# 执行 Redis 命令
redis_cmd() {
    local cmd="$1"
    if [ -n "$REDIS_PASSWORD" ]; then
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" --no-auth-warning "$cmd" 2>/dev/null
    else
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" "$cmd" 2>/dev/null
    fi
}

# 停止 Redis
stop_redis() {
    log_info "停止 Redis 服务..."

    # 尝试多种方式停止 Redis
    if command -v redis-cli &> /dev/null; then
        redis_cmd "SHUTDOWN NOSAVE" 2>/dev/null
    fi

    # 如果上面的命令失败，尝试其他方式
    if pgrep -x redis-server > /dev/null; then
        if [ -f /etc/init.d/redis ]; then
            service redis stop 2>/dev/null
        elif [ -f /etc/systemd/system/redis.service ]; then
            systemctl stop redis 2>/dev/null
        fi
    fi

    sleep 1
}

# 启动 Redis
start_redis() {
    log_info "启动 Redis 服务..."

    if command -v redis-server &> /dev/null; then
        if [ -f /etc/systemd/system/redis.service ]; then
            systemctl start redis 2>/dev/null || redis-server --daemonize yes 2>/dev/null
        elif [ -f /etc/init.d/redis ]; then
            service redis start 2>/dev/null || redis-server --daemonize yes 2>/dev/null
        else
            redis-server --daemonize yes 2>/dev/null
        fi
    fi

    sleep 1
}

# 从全量备份恢复
restore_full() {
    local backup_file="$1"

    if [ -z "$backup_file" ]; then
        # 自动选择最新的全量备份
        backup_file=$(ls -t "$FULL_DIR"/redis_full_*.rdb.gz 2>/dev/null | head -1)
        if [ -z "$backup_file" ]; then
            backup_file=$(ls -t "$FULL_DIR"/redis_full_*.rdb 2>/dev/null | head -1)
        fi
        if [ -z "$backup_file" ]; then
            log_error "没有找到可用的全量备份"
            return 1
        fi
        log_info "使用最新的全量备份: $backup_file"
    fi

    log_info "开始从全量备份恢复..."

    # 验证备份文件
    verify_backup "$backup_file" || return 1

    # 获取 Redis 数据目录
    local redis_dir=$(get_redis_config "dir")
    if [ -z "$redis_dir" ]; then
        redis_dir="/var/lib/redis"
    fi

    local redis_dbfile=$(get_redis_config "dbfilename")
    if [ -z "$redis_dbfile" ]; then
        redis_dbfile="dump.rdb"
    fi

    local target_rdb="$redis_dir/$redis_dbfile"
    log_info "Redis 数据目录: $redis_dir"
    log_info "目标 RDB 文件: $target_rdb"

    # 备份当前的 RDB 文件
    if [ -f "$target_rdb" ]; then
        local backup_old="$target_rdb.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "备份当前 RDB 文件到: $backup_old"
        cp "$target_rdb" "$backup_old"
    fi

    # 停止 Redis
    stop_redis

    # 解压并复制 RDB 文件
    log_info "复制 RDB 文件..."
    if echo "$backup_file" | grep -q "\.gz$"; then
        gunzip -c "$backup_file" > "$target_rdb"
    else
        cp "$backup_file" "$target_rdb"
    fi

    # 设置正确的权限
    chown redis:redis "$target_rdb" 2>/dev/null
    chmod 644 "$target_rdb"

    # 启动 Redis
    start_redis

    # 验证 Redis 是否正常运行
    if redis_cmd "PING" 2>/dev/null | grep -q "PONG"; then
        log_success "Redis 全量备份恢复成功"
    else
        log_error "Redis 启动失败，请检查配置"
        return 1
    fi

    return 0
}

# 从增量备份恢复
restore_incremental() {
    local incremental_backup="$1"

    if [ -z "$incremental_backup" ]; then
        # 自动选择最新的增量备份
        incremental_backup=$(ls -t "$INCREMENTAL_DIR"/redis_incremental_*.rdb.gz 2>/dev/null | head -1)
        if [ -z "$incremental_backup" ]; then
            incremental_backup=$(ls -t "$INCREMENTAL_DIR"/redis_incremental_*.rdb 2>/dev/null | head -1)
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

    # 获取 Redis 数据目录
    local redis_dir=$(get_redis_config "dir")
    if [ -z "$redis_dir" ]; then
        redis_dir="/var/lib/redis"
    fi

    local redis_dbfile=$(get_redis_config "dbfilename")
    if [ -z "$redis_dbfile" ]; then
        redis_dbfile="dump.rdb"
    fi

    local target_rdb="$redis_dir/$redis_dbfile"

    # 备份当前的 RDB 文件
    if [ -f "$target_rdb" ]; then
        local backup_old="$target_rdb.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "备份当前 RDB 文件到: $backup_old"
        cp "$target_rdb" "$backup_old"
    fi

    # 停止 Redis
    stop_redis

    # 解压并复制 RDB 文件
    log_info "复制增量 RDB 文件..."
    if echo "$incremental_backup" | grep -q "\.gz$"; then
        gunzip -c "$incremental_backup" > "$target_rdb"
    else
        cp "$incremental_backup" "$target_rdb"
    fi

    # 设置正确的权限
    chown redis:redis "$target_rdb" 2>/dev/null
    chmod 644 "$target_rdb"

    # 启动 Redis
    start_redis

    # 验证 Redis 是否正常运行
    if redis_cmd "PING" 2>/dev/null | grep -q "PONG"; then
        log_success "Redis 增量备份恢复成功"
    else
        log_error "Redis 启动失败，请检查配置"
        return 1
    fi

    return 0
}

# 从指定时间点恢复
restore_point_in_time() {
    local target_backup="$1"

    if [ -z "$target_backup" ]; then
        log_error "请指定要恢复到的时间点对应的备份文件"
        return 1
    fi

    log_info "开始恢复到指定时间点..."

    # 获取 Redis 数据目录
    local redis_dir=$(get_redis_config "dir")
    if [ -z "$redis_dir" ]; then
        redis_dir="/var/lib/redis"
    fi

    local redis_dbfile=$(get_redis_config "dbfilename")
    if [ -z "$redis_dbfile" ]; then
        redis_dbfile="dump.rdb"
    fi

    local target_rdb="$redis_dir/$redis_dbfile"

    # 备份当前的 RDB 文件
    if [ -f "$target_rdb" ]; then
        local backup_old="$target_rdb.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "备份当前 RDB 文件到: $backup_old"
        cp "$target_rdb" "$backup_old"
    fi

    # 停止 Redis
    stop_redis

    # 解压并复制 RDB 文件
    log_info "复制 RDB 文件..."
    if echo "$target_backup" | grep -q "\.gz$"; then
        gunzip -c "$target_backup" > "$target_rdb"
    else
        cp "$target_backup" "$target_rdb"
    fi

    # 设置正确的权限
    chown redis:redis "$target_rdb" 2>/dev/null
    chmod 644 "$target_rdb"

    # 启动 Redis
    start_redis

    # 验证 Redis 是否正常运行
    if redis_cmd "PING" 2>/dev/null | grep -q "PONG"; then
        log_success "Redis 时间点恢复成功"
    else
        log_error "Redis 启动失败，请检查配置"
        return 1
    fi

    return 0
}

# 使用 RDB 文件恢复（本地文件）
restore_from_file() {
    local rdb_file="$1"

    if [ -z "$rdb_file" ]; then
        log_error "请指定 RDB 文件路径"
        return 1
    fi

    if [ ! -f "$rdb_file" ]; then
        log_error "RDB 文件不存在: $rdb_file"
        return 1
    fi

    log_info "从本地 RDB 文件恢复: $rdb_file"

    # 获取 Redis 数据目录
    local redis_dir=$(get_redis_config "dir")
    if [ -z "$redis_dir" ]; then
        redis_dir="/var/lib/redis"
    fi

    local redis_dbfile=$(get_redis_config "dbfilename")
    if [ -z "$redis_dbfile" ]; then
        redis_dbfile="dump.rdb"
    fi

    local target_rdb="$redis_dir/$redis_dbfile"

    # 备份当前的 RDB 文件
    if [ -f "$target_rdb" ]; then
        local backup_old="$target_rdb.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "备份当前 RDB 文件到: $backup_old"
        cp "$target_rdb" "$backup_old"
    fi

    # 停止 Redis
    stop_redis

    # 复制 RDB 文件
    log_info "复制 RDB 文件..."
    if echo "$rdb_file" | grep -q "\.gz$"; then
        gunzip -c "$rdb_file" > "$target_rdb"
    else
        cp "$rdb_file" "$target_rdb"
    fi

    # 设置正确的权限
    chown redis:redis "$target_rdb" 2>/dev/null
    chmod 644 "$target_rdb"

    # 启动 Redis
    start_redis

    # 验证 Redis 是否正常运行
    if redis_cmd "PING" 2>/dev/null | grep -q "PONG"; then
        log_success "Redis 恢复成功"
    else
        log_error "Redis 启动失败，请检查配置"
        return 1
    fi

    return 0
}

# 显示 Redis 信息
show_info() {
    echo "=== Redis 信息 ==="
    echo ""

    if redis_cmd "PING" 2>/dev/null | grep -q "PONG"; then
        echo "Redis 状态: 运行中"
        echo ""
        echo "服务器信息:"
        redis_cmd "INFO Server" | grep -E "(redis_version|os|arch_bits|uptime_in_days)" | while read line; do
            echo "  $line"
        done
        echo ""
        echo "内存信息:"
        redis_cmd "INFO Memory" | grep -E "(used_memory_human|maxmemory_human|used_memory_peak_human)" | while read line; do
            echo "  $line"
        done
        echo ""
        echo "持久化信息:"
        redis_cmd "INFO Persistence" | grep -E "(rdb_last_save_time|rdb_last_bgsave_time|aof_enabled)" | while read line; do
            echo "  $line"
        done
        echo ""
        echo "数据库统计:"
        redis_cmd "INFO Keyspace" 2>/dev/null || echo "  无数据库统计"
    else
        echo "Redis 状态: 未运行"
        echo "请先启动 Redis 服务"
    fi
}

# 显示帮助
show_help() {
    echo "Redis 数据库恢复脚本"
    echo ""
    echo "用法: $0 {full|incremental|point|file|list|verify|info|help}"
    echo ""
    echo "命令:"
    echo "  full [备份文件]           - 从全量备份恢复（不指定则使用最新的）"
    echo "  incremental [备份文件]    - 从增量备份恢复（不指定则使用最新的）"
    echo "  point [备份文件]          - 恢复到指定时间点"
    echo "  file <RDB文件>             - 从本地 RDB 文件恢复"
    echo "  list                      - 列出所有可用备份"
    echo "  verify [备份文件]         - 验证备份文件"
    echo "  info                      - 显示 Redis 当前信息"
    echo "  help                      - 显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 full                                    # 使用最新全量备份恢复"
    echo "  $0 full /var/backups/redis/full/xxx.rdb.gz # 使用指定备份恢复"
    echo "  $0 incremental                             # 使用最新增量备份恢复"
    echo "  $0 file /tmp/dump.rdb                     # 从本地文件恢复"
    echo "  $0 verify                                  # 验证最新备份"
    echo "  $0 info                                    # 查看 Redis 信息"
}

# 主函数
main() {
    init

    case "$1" in
        full)
            restore_full "$2"
            ;;
        incremental)
            restore_incremental "$2"
            ;;
        point)
            restore_point_in_time "$2"
            ;;
        file)
            restore_from_file "$2"
            ;;
        list)
            list_backups
            ;;
        verify)
            verify_backup "$2"
            ;;
        info)
            show_info
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