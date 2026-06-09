#!/bin/bash
# MySQL 全量备份脚本
# 每30天执行一次全量备份

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 配置参数
BACKUP_ROOT="/var/backups/mysql"
FULL_DIR="$BACKUP_ROOT/full"
LOG_FILE="$BACKUP_ROOT/mysql_full_backup.log"

MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-}"
MYSQL_HOST="${MYSQL_HOST:-localhost}"
MYSQL_PORT="${MYSQL_PORT:-3306}"

# 保留30天
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

# 初始化目录
init_dirs() {
    mkdir -p "$FULL_DIR"
    touch "$LOG_FILE"
}

# 全量备份
do_full_backup() {
    log_info "开始 MySQL 全量备份..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$FULL_DIR/full_$timestamp.sql.gz"
    
    # 获取数据库列表
    local cmd="mysql -u$MYSQL_USER"
    [ -n "$MYSQL_PASSWORD" ] && cmd="$cmd -p$MYSQL_PASSWORD"
    [ "$MYSQL_HOST" != "localhost" ] && cmd="$cmd -h$MYSQL_HOST -P$MYSQL_PORT"
    
    # 使用 mysqldump 进行全量备份
    $cmd --all-databases \
        --single-transaction \
        --master-data=2 \
        --flush-logs \
        --triggers \
        --routines \
        --events \
        2>/dev/null | gzip > "$backup_file"
    
    if [ $? -eq 0 ] && [ -s "$backup_file" ]; then
        local size=$(du -h "$backup_file" | cut -f1)
        log_success "全量备份完成: $backup_file (大小: $size)"
        
        # 创建备份信息文件
        cat > "${backup_file}.info" <<EOF
备份时间: $(date '+%Y-%m-%d %H:%M:%S')
备份类型: 全量
主机名: $(hostname)
MySQL版本: $($cmd -V 2>/dev/null | awk '{print $5}')
备份大小: $size
EOF
    else
        log_error "全量备份失败"
        rm -f "$backup_file"
        return 1
    fi
}

# 验证备份
verify_backup() {
    local backup_file="$1"
    
    log_info "验证备份文件..."
    
    if [ -f "$backup_file" ]; then
        # 检查gzip文件完整性
        gunzip -t "$backup_file" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_success "备份文件验证通过"
            return 0
        else
            log_error "备份文件损坏"
            return 1
        fi
    else
        log_error "备份文件不存在"
        return 1
    fi
}

# 清理旧备份（保留30天）
cleanup_old_backups() {
    log_info "清理 ${RETENTION_DAYS} 天前的全量备份..."
    
    # 保留最近的全量备份作为基准
    local latest_backup=$(ls -t "$FULL_DIR"/full_*.sql.gz 2>/dev/null | head -1)
    
    # 删除30天前的备份，但保留最新的一个
    find "$FULL_DIR" -name "full_*.sql.gz" -mtime +$RETENTION_DAYS | while read backup; do
        if [ "$backup" != "$latest_backup" ]; then
            rm -f "$backup" "${backup}.info"
            log_info "已删除: $backup"
        fi
    done
    
    log_success "旧备份清理完成"
}

# 显示备份列表
list_backups() {
    echo "=== MySQL 全量备份列表 ==="
    echo ""
    
    if [ -d "$FULL_DIR" ]; then
        local backups=$(ls -lt "$FULL_DIR"/full_*.sql.gz 2>/dev/null)
        if [ -z "$backups" ]; then
            echo "  暂无全量备份"
        else
            echo "$backups" | while read backup; do
                local size=$(du -h "$backup" | cut -f1)
                local time=$(stat -c %y "$backup" 2>/dev/null | cut -d. -f1)
                echo "  $backup"
                echo "    大小: $size, 创建时间: $time"
                if [ -f "${backup}.info" ]; then
                    echo "    $(grep '备份大小' "${backup}.info")"
                fi
                echo ""
            done
        fi
    else
        echo "  备份目录不存在"
    fi
}

# 主函数
main() {
    init_dirs
    
    case "$1" in
        backup)
            do_full_backup
            ;;
        verify)
            local latest=$(ls -t "$FULL_DIR"/full_*.sql.gz 2>/dev/null | head -1)
            if [ -n "$latest" ]; then
                verify_backup "$latest"
            else
                log_error "没有找到备份文件"
            fi
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
            echo "用法: $0 {backup|verify|cleanup|all|list}"
            echo "  backup   - 执行全量备份"
            echo "  verify   - 验证最新备份"
            echo "  cleanup  - 清理30天前的旧备份"
            echo "  all      - 执行备份并清理"
            echo "  list     - 列出所有全量备份"
            ;;
    esac
}

main "$@"