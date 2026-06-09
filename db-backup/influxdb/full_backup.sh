#!/bin/bash
# InfluxDB 数据库备份脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 配置参数
BACKUP_ROOT="/var/backups/influxdb"
FULL_DIR="$BACKUP_ROOT/full"
INCREMENTAL_DIR="$BACKUP_ROOT/incremental"
LOG_FILE="$BACKUP_ROOT/influxdb_backup.log"

INFLUX_HOST="${INFLUX_HOST:-localhost}"
INFLUX_PORT="${INFLUX_PORT:-8088}"
INFLUX_TOKEN="${INFLUX_TOKEN:-}"
INFLUX_ORG="${INFLUX_ORG:-}"

# InfluxDB 版本 (v1 或 v2)
INFLUX_VERSION="${INFLUX_VERSION:-2}"

# 保留天数
RETENTION_DAYS=30

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
init_dirs() {
    mkdir -p "$FULL_DIR"
    mkdir -p "$INCREMENTAL_DIR"
    touch "$LOG_FILE"
}

# InfluxDB v2 全量备份
do_full_backup_v2() {
    log_info "开始 InfluxDB v2 全量备份..."
    
    if ! command -v influx &> /dev/null; then
        log_error "influx 命令不可用"
        return 1
    fi
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$FULL_DIR/full_$timestamp"
    
    mkdir -p "$backup_dir"
    
    # 构建备份命令
    local cmd="influx backup $backup_dir"
    
    if [ -n "$INFLUX_HOST" ]; then
        cmd="$cmd --host http://$INFLUX_HOST:$INFLUX_PORT"
    fi
    
    if [ -n "$INFLUX_TOKEN" ]; then
        cmd="$cmd --token $INFLUX_TOKEN"
    fi
    
    if [ -n "$INFLUX_ORG" ]; then
        cmd="$cmd --org $INFLUX_ORG"
    fi
    
    # 执行备份
    $cmd 2>/dev/null
    
    if [ $? -eq 0 ] && [ "$(ls -A $backup_dir 2>/dev/null)" ]; then
        # 压缩备份
        tar czf "$backup_dir.tar.gz" -C "$FULL_DIR" "full_$timestamp"
        rm -rf "$backup_dir"
        
        local size=$(du -h "$backup_dir.tar.gz" | cut -f1)
        log_success "全量备份完成: $backup_dir.tar.gz (大小: $size)"
        
        # 创建备份信息
        cat > "${backup_dir}.tar.gz.info" <<EOF
备份时间: $(date '+%Y-%m-%d %H:%M:%S')
备份类型: 全量
主机名: $(hostname)
InfluxDB版本: $(influx version 2>/dev/null | head -1)
备份大小: $size
EOF
    else
        log_error "全量备份失败"
        rm -rf "$backup_dir"
        return 1
    fi
}

# InfluxDB v1 全量备份
do_full_backup_v1() {
    log_info "开始 InfluxDB v1 全量备份..."
    
    if ! command -v influxd &> /dev/null; then
        log_error "influxd 命令不可用"
        return 1
    fi
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$FULL_DIR/full_$timestamp"
    
    mkdir -p "$backup_dir"
    
    # 使用 influxd backup
    influxd backup -portable "$backup_dir" 2>/dev/null
    
    if [ $? -eq 0 ] && [ "$(ls -A $backup_dir 2>/dev/null)" ]; then
        tar czf "$backup_dir.tar.gz" -C "$FULL_DIR" "full_$timestamp"
        rm -rf "$backup_dir"
        
        local size=$(du -h "$backup_dir.tar.gz" | cut -f1)
        log_success "全量备份完成: $backup_dir.tar.gz (大小: $size)"
    else
        log_error "全量备份失败"
        rm -rf "$backup_dir"
        return 1
    fi
}

# 全量备份
do_full_backup() {
    if [ "$INFLUX_VERSION" = "1" ]; then
        do_full_backup_v1
    else
        do_full_backup_v2
    fi
}

# 增量备份（InfluxDB v2）
do_incremental_backup_v2() {
    log_info "开始 InfluxDB v2 增量备份..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$INCREMENTAL_DIR/incremental_$timestamp"
    
    mkdir -p "$backup_dir"
    
    local cmd="influx backup $backup_dir"
    
    if [ -n "$INFLUX_HOST" ]; then
        cmd="$cmd --host http://$INFLUX_HOST:$INFLUX_PORT"
    fi
    
    if [ -n "$INFLUX_TOKEN" ]; then
        cmd="$cmd --token $INFLUX_TOKEN"
    fi
    
    # 增量备份（只备份新数据）
    local last_backup_file="$INCREMENTAL_DIR/last_backup_time.txt"
    if [ -f "$last_backup_file" ]; then
        local last_time=$(cat "$last_backup_file")
        cmd="$cmd --start $last_time"
    fi
    
    $cmd 2>/dev/null
    
    if [ $? -eq 0 ] && [ "$(ls -A $backup_dir 2>/dev/null)" ]; then
        tar czf "$backup_dir.tar.gz" -C "$INCREMENTAL_DIR" "incremental_$timestamp"
        rm -rf "$backup_dir"
        
        # 更新最后备份时间
        date -u +"%Y-%m-%dT%H:%M:%SZ" > "$last_backup_file"
        
        local size=$(du -h "$backup_dir.tar.gz" | cut -f1)
        log_success "增量备份完成: $backup_dir.tar.gz (大小: $size)"
    else
        log_error "增量备份失败"
        rm -rf "$backup_dir"
        return 1
    fi
}

# 增量备份
do_incremental_backup() {
    if [ "$INFLUX_VERSION" = "1" ]; then
        log_info "InfluxDB v1 不支持增量备份，执行全量备份"
        do_full_backup_v1
    else
        do_incremental_backup_v2
    fi
}

# 清理旧备份
cleanup_old_backups() {
    log_info "清理 ${RETENTION_DAYS} 天前的备份..."
    
    # 保留最新的一个全量备份
    local latest_backup=$(ls -t "$FULL_DIR"/full_*.tar.gz 2>/dev/null | head -1)
    
    find "$FULL_DIR" -name "full_*.tar.gz" -mtime +$RETENTION_DAYS | while read backup; do
        if [ "$backup" != "$latest_backup" ]; then
            rm -f "$backup" "${backup}.info"
            log_info "已删除: $backup"
        fi
    done
    
    find "$INCREMENTAL_DIR" -name "incremental_*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null
    
    log_success "旧备份清理完成"
}

# 显示备份列表
list_backups() {
    echo "=== InfluxDB 全量备份列表 ==="
    ls -lt "$FULL_DIR"/full_*.tar.gz 2>/dev/null | head -10 || echo "  暂无全量备份"
    
    echo ""
    echo "=== InfluxDB 增量备份列表 ==="
    ls -lt "$INCREMENTAL_DIR"/incremental_*.tar.gz 2>/dev/null | head -10 || echo "  暂无增量备份"
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
        cleanup)
            cleanup_old_backups
            ;;
        all)
            do_full_backup
            cleanup_old_backups
            ;;
        list)
            list_backups
            ;;
        *)
            echo "用法: $0 {full|incremental|cleanup|all|list}"
            echo "  full        - 执行全量备份"
            echo "  incremental - 执行增量备份"
            echo "  cleanup     - 清理旧备份"
            echo "  all         - 执行备份并清理"
            echo "  list        - 列出备份"
            echo ""
            echo "环境变量:"
            echo "  INFLUX_VERSION - InfluxDB版本 (1 或 2，默认: 2)"
            echo "  INFLUX_HOST    - InfluxDB主机"
            echo "  INFLUX_PORT    - InfluxDB端口"
            echo "  INFLUX_TOKEN   - 认证Token (v2)"
            echo "  INFLUX_ORG     - 组织名称 (v2)"
            ;;
    esac
}

main "$@"