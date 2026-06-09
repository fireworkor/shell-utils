#!/bin/bash
# MongoDB 增量备份脚本
# 基于 Oplog 实现增量备份

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 配置参数
BACKUP_ROOT="/var/backups/mongodb"
INCREMENTAL_DIR="$BACKUP_ROOT/incremental"
FULL_DIR="$BACKUP_ROOT/full"
LOG_FILE="$BACKUP_ROOT/mongodb_backup.log"

MONGO_HOST="${MONGO_HOST:-localhost}"
MONGO_PORT="${MONGO_PORT:-27017}"
MONGO_USER="${MONGO_USER:-}"
MONGO_PASSWORD="${MONGO_PASSWORD:-}"

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

# 检查是否启用了 Oplog
check_oplog() {
    local cmd="mongosh --host $MONGO_HOST --port $MONGO_PORT --eval \"rs.status()\" --quiet 2>/dev/null"
    if [ -n "$MONGO_USER" ] && [ -n "$MONGO_PASSWORD" ]; then
        cmd="mongosh --host $MONGO_HOST --port $MONGO_PORT -u $MONGO_USER -p $MONGO_PASSWORD --eval \"rs.status()\" --quiet 2>/dev/null"
    fi
    
    local result=$($cmd)
    if echo "$result" | grep -q "replicaSet"; then
        return 0
    else
        log_error "MongoDB 未配置为副本集，无法进行增量备份"
        log_error "请配置副本集以启用 Oplog"
        return 1
    fi
}

# 获取当前 Oplog 时间戳
get_oplog_timestamp() {
    local cmd="mongosh --host $MONGO_HOST --port $MONGO_PORT --eval \"db.getMongo().getDB('local').oplog.rs.find().sort({\\$natural:-1}).limit(1).next()\" --quiet 2>/dev/null"
    if [ -n "$MONGO_USER" ] && [ -n "$MONGO_PASSWORD" ]; then
        cmd="mongosh --host $MONGO_HOST --port $MONGO_PORT -u $MONGO_USER -p $MONGO_PASSWORD --eval \"db.getMongo().getDB('local').oplog.rs.find().sort({\\$natural:-1}).limit(1).next()\" --quiet 2>/dev/null"
    fi
    
    $cmd | grep -o '"ts"[^}]*' | head -1
}

# 增量备份（基于 Oplog 时间范围）
do_incremental_backup() {
    log_info "开始 MongoDB 增量备份..."
    
    # 检查 Oplog
    check_oplog || return 1
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$INCREMENTAL_DIR/incremental_$timestamp.archive.gz"
    
    # 获取上次备份位置
    local last_pos_file="$INCREMENTAL_DIR/last_timestamp.txt"
    local from_timestamp=""
    
    if [ -f "$last_pos_file" ]; then
        read from_timestamp < "$last_pos_file"
        log_info "从上次时间戳继续备份: $from_timestamp"
    fi
    
    # 获取当前时间戳
    local current_timestamp=$(date +%s)
    
    # 使用 mongodump 导出增量数据
    local cmd="mongodump --host $MONGO_HOST --port $MONGO_PORT --gzip --archive=$backup_file"
    if [ -n "$MONGO_USER" ] && [ -n "$MONGO_PASSWORD" ]; then
        cmd="$cmd -u $MONGO_USER -p $MONGO_PASSWORD"
    fi
    
    # 如果有上次备份时间，只备份增量数据
    if [ -n "$from_timestamp" ]; then
        cmd="$cmd --query '{\"_id\":{\"\\$gt\":{\"\\$timestamp\":{\"t\":$from_timestamp,\"i\":0}}}}'"
    fi
    
    $cmd 2>/dev/null
    
    if [ $? -eq 0 ] && [ -s "$backup_file" ]; then
        # 更新上次备份时间戳
        echo "$current_timestamp" > "$last_pos_file"
        
        local size=$(du -h "$backup_file" | cut -f1)
        log_success "增量备份完成: $backup_file (大小: $size)"
        
        # 创建备份信息文件
        cat > "${backup_file}.info" <<EOF
备份时间: $(date '+%Y-%m-%d %H:%M:%S')
备份类型: 增量
起始时间戳: $from_timestamp
结束时间戳: $current_timestamp
主机名: $(hostname)
备份大小: $size
EOF
    else
        log_error "增量备份失败"
        rm -f "$backup_file"
        return 1
    fi
}

# 全量备份
do_full_backup() {
    log_info "开始 MongoDB 全量备份..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$FULL_DIR/full_$timestamp.archive.gz"
    
    local cmd="mongodump --host $MONGO_HOST --port $MONGO_PORT --archive=$FULL_DIR/full_$timestamp.archive --gzip"
    if [ -n "$MONGO_USER" ] && [ -n "$MONGO_PASSWORD" ]; then
        cmd="$cmd -u $MONGO_USER -p $MONGO_PASSWORD"
    fi
    
    $cmd 2>/dev/null
    
    if [ $? -eq 0 ] && [ -s "$FULL_DIR/full_$timestamp.archive" ]; then
        local size=$(du -h "$FULL_DIR/full_$timestamp.archive" | cut -f1)
        log_success "全量备份完成: $FULL_DIR/full_$timestamp.archive (大小: $size)"
        
        # 创建备份信息文件
        cat > "${FULL_DIR}/full_$timestamp.archive.info" <<EOF
备份时间: $(date '+%Y-%m-%d %H:%M:%S')
备份类型: 全量
主机名: $(hostname)
MongoDB版本: $(mongosh --version 2>/dev/null | grep -o 'version.*' | head -1)
备份大小: $size
EOF
    else
        log_error "全量备份失败"
        rm -f "$FULL_DIR/full_$timestamp.archive"
        return 1
    fi
}

# 清理旧备份
cleanup_old_backups() {
    log_info "清理 ${INCREMENTAL_RETENTION} 天前的增量备份..."
    find "$INCREMENTAL_DIR" -name "incremental_*.archive.gz" -mtime +$INCREMENTAL_RETENTION -delete 2>/dev/null
    find "$INCREMENTAL_DIR" -name "incremental_*.archive.gz.info" -mtime +$INCREMENTAL_RETENTION -delete 2>/dev/null
    
    log_info "清理 ${FULL_RETENTION} 天前的全量备份..."
    find "$FULL_DIR" -name "full_*.archive" -mtime +$FULL_RETENTION -delete 2>/dev/null
    find "$FULL_DIR" -name "full_*.archive.info" -mtime +$FULL_RETENTION -delete 2>/dev/null
    
    log_success "旧备份清理完成"
}

# 显示备份列表
list_backups() {
    echo "=== MongoDB 全量备份 ==="
    ls -lt "$FULL_DIR"/full_*.archive 2>/dev/null | head -10 || echo "  暂无全量备份"
    
    echo ""
    echo "=== MongoDB 增量备份 ==="
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