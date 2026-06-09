#!/bin/bash
# Redis 增量备份脚本
# 基于 RDB 快照实现增量备份

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 配置参数
BACKUP_ROOT="/var/backups/redis"
INCREMENTAL_DIR="$BACKUP_ROOT/incremental"
FULL_DIR="$BACKUP_ROOT/full"
LOG_FILE="$BACKUP_ROOT/redis_backup.log"

REDIS_HOST="${REDIS_HOST:-localhost}"
REDIS_PORT="${REDIS_PORT:-6379}"
REDIS_PASSWORD="${REDIS_PASSWORD:-}"

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

# 执行 Redis 命令
redis_cmd() {
    local cmd="$1"
    if [ -n "$REDIS_PASSWORD" ]; then
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" --no-auth-warning "$cmd" 2>/dev/null
    else
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" "$cmd" 2>/dev/null
    fi
}

# 增量备份（基于 RDB 快照）
do_incremental_backup() {
    log_info "开始 Redis 增量备份..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$INCREMENTAL_DIR/redis_incremental_$timestamp.rdb"
    
    # 获取上次备份时间
    local last_time_file="$INCREMENTAL_DIR/last_backup_time.txt"
    local last_time=""
    
    if [ -f "$last_time_file" ]; then
        read last_time < "$last_time_file"
        log_info "上次备份时间: $last_time"
    fi
    
    # 执行 BGSAVE
    redis_cmd "BGSAVE"
    
    # 等待 BGSAVE 完成
    local attempts=0
    local max_attempts=30
    
    while [ $attempts -lt $max_attempts ]; do
        local bg_save_in_progress=$(redis_cmd "INFO Persistence" | grep -o "rdb_bgsave_in_progress:[01]" | cut -d: -f2)
        if [ "$bg_save_in_progress" = "0" ]; then
            break
        fi
        sleep 2
        attempts=$((attempts + 1))
    done
    
    # 获取 RDB 文件路径
    local rdb_path=$(redis_cmd "CONFIG GET dir" | tail -1)
    local rdb_filename=$(redis_cmd "CONFIG GET dbfilename" | tail -1)
    local src_rdb="$rdb_path/$rdb_filename"
    
    # 复制 RDB 文件
    if [ -f "$src_rdb" ]; then
        cp "$src_rdb" "$backup_file"
        gzip "$backup_file"
        
        # 更新上次备份时间
        date '+%Y-%m-%d %H:%M:%S' > "$last_time_file"
        
        local size=$(du -h "${backup_file}.gz" | cut -f1)
        log_success "增量备份完成: ${backup_file}.gz (大小: $size)"
    else
        log_error "RDB 文件不存在: $src_rdb"
        return 1
    fi
}

# 全量备份
do_full_backup() {
    log_info "开始 Redis 全量备份..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$FULL_DIR/redis_full_$timestamp.rdb"
    
    # 执行 BGSAVE
    redis_cmd "BGSAVE"
    
    # 等待 BGSAVE 完成
    local attempts=0
    local max_attempts=30
    
    while [ $attempts -lt $max_attempts ]; do
        local bg_save_in_progress=$(redis_cmd "INFO Persistence" | grep -o "rdb_bgsave_in_progress:[01]" | cut -d: -f2)
        if [ "$bg_save_in_progress" = "0" ]; then
            break
        fi
        sleep 2
        attempts=$((attempts + 1))
    done
    
    # 获取 RDB 文件路径
    local rdb_path=$(redis_cmd "CONFIG GET dir" | tail -1)
    local rdb_filename=$(redis_cmd "CONFIG GET dbfilename" | tail -1)
    local src_rdb="$rdb_path/$rdb_filename"
    
    # 复制 RDB 文件
    if [ -f "$src_rdb" ]; then
        cp "$src_rdb" "$backup_file"
        gzip "$backup_file"
        
        local size=$(du -h "${backup_file}.gz" | cut -f1)
        log_success "全量备份完成: ${backup_file}.gz (大小: $size)"
        
        # 创建备份信息文件
        cat > "${backup_file}.gz.info" <<EOF
备份时间: $(date '+%Y-%m-%d %H:%M:%S')
备份类型: 全量
主机名: $(hostname)
Redis版本: $(redis_cmd "INFO Server" | grep -o "redis_version:[0-9.]*" | cut -d: -f2)
备份大小: $size
EOF
    else
        log_error "RDB 文件不存在: $src_rdb"
        return 1
    fi
}

# 清理旧备份
cleanup_old_backups() {
    log_info "清理 ${INCREMENTAL_RETENTION} 天前的增量备份..."
    find "$INCREMENTAL_DIR" -name "redis_incremental_*.rdb.gz" -mtime +$INCREMENTAL_RETENTION -delete 2>/dev/null
    
    log_info "清理 ${FULL_RETENTION} 天前的全量备份..."
    find "$FULL_DIR" -name "redis_full_*.rdb.gz" -mtime +$FULL_RETENTION -delete 2>/dev/null
    find "$FULL_DIR" -name "redis_full_*.rdb.gz.info" -mtime +$FULL_RETENTION -delete 2>/dev/null
    
    log_success "旧备份清理完成"
}

# 显示备份列表
list_backups() {
    echo "=== Redis 全量备份 ==="
    ls -lt "$FULL_DIR"/redis_full_*.rdb.gz 2>/dev/null | head -10 || echo "  暂无全量备份"
    
    echo ""
    echo "=== Redis 增量备份 ==="
    ls -lt "$INCREMENTAL_DIR"/redis_incremental_*.rdb.gz 2>/dev/null | head -10 || echo "  暂无增量备份"
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