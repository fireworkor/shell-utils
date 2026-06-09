#!/bin/bash
# PostgreSQL 增量备份脚本
# 基于 WAL (Write-Ahead Logging) 实现增量备份

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 配置参数
BACKUP_ROOT="/var/backups/postgresql"
INCREMENTAL_DIR="$BACKUP_ROOT/incremental"
FULL_DIR="$BACKUP_ROOT/full"
LOG_FILE="$BACKUP_ROOT/postgresql_backup.log"

PG_USER="${PG_USER:-postgres}"
PG_HOST="${PG_HOST:-localhost}"
PG_PORT="${PG_PORT:-5432}"
PG_DATABASE="${PG_DATABASE:-postgres}"

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

# 检查 WAL 配置
check_wal_config() {
    local cmd="psql -U $PG_USER -h $PG_HOST -p $PG_PORT -d $PG_DATABASE -t -c \"show wal_level;\""
    local wal_level=$(su - "$PG_USER" -c "$cmd" 2>/dev/null | tr -d ' ')
    
    if [ "$wal_level" != "replica" ] && [ "$wal_level" != "logical" ]; then
        log_error "WAL 级别配置不正确，当前为: $wal_level"
        log_error "请在 postgresql.conf 中设置 wal_level = replica"
        return 1
    fi
    
    return 0
}

# 获取当前 WAL 位置
get_wal_position() {
    local cmd="psql -U $PG_USER -h $PG_HOST -p $PG_PORT -d $PG_DATABASE -t -c \"SELECT pg_current_wal_lsn();\""
    su - "$PG_USER" -c "$cmd" 2>/dev/null | tr -d ' '
}

# 增量备份（基于 WAL 归档）
do_incremental_backup() {
    log_info "开始 PostgreSQL 增量备份..."
    
    # 检查 WAL 配置
    check_wal_config || return 1
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$INCREMENTAL_DIR/incremental_$timestamp.tar.gz"
    
    # 获取上次备份位置
    local last_pos_file="$INCREMENTAL_DIR/last_position.txt"
    local from_lsn=""
    
    if [ -f "$last_pos_file" ]; then
        read from_lsn < "$last_pos_file"
        log_info "从上次位置继续备份: $from_lsn"
    fi
    
    # 获取当前 WAL 位置
    local current_lsn=$(get_wal_position)
    
    if [ -z "$current_lsn" ]; then
        log_error "无法获取当前 WAL 位置"
        return 1
    fi
    
    # 获取 WAL 目录
    local wal_dir=$(su - "$PG_USER" -c "psql -U $PG_USER -h $PG_HOST -p $PG_PORT -d $PG_DATABASE -t -c \"show wal_directory;\"" 2>/dev/null | tr -d ' ')
    
    if [ ! -d "$wal_dir" ]; then
        log_error "WAL 目录不存在: $wal_dir"
        return 1
    fi
    
    # 创建临时目录用于存储增量备份
    local tmp_dir=$(mktemp -d)
    
    # 复制未备份的 WAL 文件
    local copied=0
    for wal_file in $(ls "$wal_dir"/*.wal 2>/dev/null); do
        local wal_name=$(basename "$wal_file")
        local wal_lsn=$(echo "$wal_name" | cut -d. -f1)
        
        if [ -n "$from_lsn" ]; then
            if ! compare_lsn "$wal_lsn" "$from_lsn"; then
                continue
            fi
        fi
        
        cp "$wal_file" "$tmp_dir/" && copied=$((copied + 1))
    done
    
    if [ $copied -gt 0 ]; then
        # 创建备份信息文件
        cat > "$tmp_dir/backup.info" <<EOF
备份时间: $(date '+%Y-%m-%d %H:%M:%S')
备份类型: 增量
起始LSN: ${from_lsn:-0/0}
结束LSN: $current_lsn
主机名: $(hostname)
WAL文件数: $copied
EOF
        
        # 打包备份
        tar czf "$backup_file" -C "$tmp_dir" .
        rm -rf "$tmp_dir"
        
        # 更新上次备份位置
        echo "$current_lsn" > "$last_pos_file"
        
        local size=$(du -h "$backup_file" | cut -f1)
        log_success "增量备份完成: $backup_file (大小: $size, WAL文件数: $copied)"
    else
        log_info "没有新的 WAL 文件需要备份"
        rm -rf "$tmp_dir"
    fi
}

# 比较两个 LSN 大小
compare_lsn() {
    local lsn1=$1
    local lsn2=$2
    
    local part1_1=$(echo "$lsn1" | cut -d/ -f1)
    local part1_2=$(echo "$lsn1" | cut -d/ -f2)
    local part2_1=$(echo "$lsn2" | cut -d/ -f1)
    local part2_2=$(echo "$lsn2" | cut -d/ -f2)
    
    if [ "$part1_1" -gt "$part2_1" ] || ([ "$part1_1" -eq "$part2_1" ] && [ "$part1_2" -ge "$part2_2" ]); then
        return 0
    else
        return 1
    fi
}

# 全量备份
do_full_backup() {
    log_info "开始 PostgreSQL 全量备份..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$FULL_DIR/full_$timestamp.tar.gz"
    
    # 使用 pg_basebackup 进行全量备份
    su - "$PG_USER" -c "pg_basebackup -h $PG_HOST -p $PG_PORT -D $FULL_DIR/base_$timestamp -Ft -z -Xs -P" 2>/dev/null
    
    if [ $? -eq 0 ] && [ -d "$FULL_DIR/base_$timestamp" ]; then
        # 打包备份
        tar czf "$backup_file" -C "$FULL_DIR" "base_$timestamp"
        rm -rf "$FULL_DIR/base_$timestamp"
        
        local size=$(du -h "$backup_file" | cut -f1)
        log_success "全量备份完成: $backup_file (大小: $size)"
        
        # 创建备份信息文件
        cat > "${backup_file}.info" <<EOF
备份时间: $(date '+%Y-%m-%d %H:%M:%S')
备份类型: 全量
主机名: $(hostname)
PostgreSQL版本: $(su - "$PG_USER" -c "psql -U $PG_USER -h $PG_HOST -p $PG_PORT -d $PG_DATABASE -t -c \"SELECT version();\"" 2>/dev/null | head -1)
备份大小: $size
EOF
    else
        log_error "全量备份失败"
        rm -rf "$FULL_DIR/base_$timestamp"
        return 1
    fi
}

# 清理旧备份
cleanup_old_backups() {
    log_info "清理 ${INCREMENTAL_RETENTION} 天前的增量备份..."
    find "$INCREMENTAL_DIR" -name "incremental_*.tar.gz" -mtime +$INCREMENTAL_RETENTION -delete 2>/dev/null
    find "$INCREMENTAL_DIR" -name "incremental_*.tar.gz.info" -mtime +$INCREMENTAL_RETENTION -delete 2>/dev/null
    
    log_info "清理 ${FULL_RETENTION} 天前的全量备份..."
    find "$FULL_DIR" -name "full_*.tar.gz" -mtime +$FULL_RETENTION -delete 2>/dev/null
    find "$FULL_DIR" -name "full_*.tar.gz.info" -mtime +$FULL_RETENTION -delete 2>/dev/null
    
    log_success "旧备份清理完成"
}

# 显示备份列表
list_backups() {
    echo "=== PostgreSQL 全量备份 ==="
    ls -lt "$FULL_DIR"/full_*.tar.gz 2>/dev/null | head -10 || echo "  暂无全量备份"
    
    echo ""
    echo "=== PostgreSQL 增量备份 ==="
    ls -lt "$INCREMENTAL_DIR"/incremental_* 2>/dev/null | head -10 || echo "  暂无增量备份"
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