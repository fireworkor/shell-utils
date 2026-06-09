#!/bin/bash
# SQLite 数据库备份脚本
# SQLite 是文件型数据库，备份即复制文件

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 配置参数
BACKUP_ROOT="/var/backups/sqlite"
FULL_DIR="$BACKUP_ROOT/full"
LOG_FILE="$BACKUP_ROOT/sqlite_backup.log"

# SQLite 数据库文件路径（多个用空格分隔）
SQLITE_DB_PATHS="${SQLITE_DB_PATHS:-/var/lib/sqlite}"

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

# 初始化目录
init_dirs() {
    mkdir -p "$FULL_DIR"
    touch "$LOG_FILE"
}

# 查找所有 SQLite 数据库文件
find_sqlite_dbs() {
    local db_list=""
    
    for path in $SQLITE_DB_PATHS; do
        if [ -d "$path" ]; then
            # 查找 .db, .sqlite, .sqlite3 文件
            db_list="$db_list $(find "$path" -type f \( -name "*.db" -o -name "*.sqlite" -o -name "*.sqlite3" -o -name "*.db3" \) 2>/dev/null)"
        elif [ -f "$path" ]; then
            db_list="$db_list $path"
        fi
    done
    
    echo "$db_list"
}

# 全量备份
do_full_backup() {
    log_info "开始 SQLite 全量备份..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$FULL_DIR/full_$timestamp"
    local backup_count=0
    local error_count=0
    
    # 创建备份目录
    mkdir -p "$backup_dir"
    
    # 查找所有数据库文件
    local db_files=$(find_sqlite_dbs)
    
    if [ -z "$db_files" ]; then
        log_error "没有找到 SQLite 数据库文件"
        rmdir "$backup_dir"
        return 1
    fi
    
    # 备份每个数据库文件
    for db_file in $db_files; do
        if [ -f "$db_file" ]; then
            local db_name=$(basename "$db_file")
            local db_dir=$(dirname "$db_file")
            local relative_path="${db_dir#/}"
            local target_dir="$backup_dir/$relative_path"
            
            # 创建目标目录
            mkdir -p "$target_dir"
            
            # 使用 sqlite3 的 .backup 命令进行一致性备份
            if command -v sqlite3 &> /dev/null; then
                sqlite3 "$db_file" ".backup '$target_dir/$db_name'" 2>/dev/null
                if [ $? -eq 0 ]; then
                    log_info "已备份: $db_file"
                    backup_count=$((backup_count + 1))
                else
                    # 如果 sqlite3 backup 失败，尝试直接复制
                    cp "$db_file" "$target_dir/$db_name"
                    if [ $? -eq 0 ]; then
                        log_info "已备份(复制): $db_file"
                        backup_count=$((backup_count + 1))
                    else
                        log_error "备份失败: $db_file"
                        error_count=$((error_count + 1))
                    fi
                fi
            else
                # 没有 sqlite3 命令，直接复制
                cp "$db_file" "$target_dir/$db_name"
                if [ $? -eq 0 ]; then
                    log_info "已备份(复制): $db_file"
                    backup_count=$((backup_count + 1))
                else
                    log_error "备份失败: $db_file"
                    error_count=$((error_count + 1))
                fi
            fi
        fi
    done
    
    if [ $backup_count -gt 0 ]; then
        # 压缩备份目录
        tar czf "$backup_dir.tar.gz" -C "$FULL_DIR" "full_$timestamp"
        rm -rf "$backup_dir"
        
        local size=$(du -h "$backup_dir.tar.gz" | cut -f1)
        log_success "全量备份完成: $backup_dir.tar.gz (大小: $size, 数据库数: $backup_count)"
        
        # 创建备份信息文件
        cat > "${backup_dir}.tar.gz.info" <<EOF
备份时间: $(date '+%Y-%m-%d %H:%M:%S')
备份类型: 全量
主机名: $(hostname)
数据库数量: $backup_count
备份大小: $size
EOF
    else
        log_error "没有成功备份任何数据库"
        rm -rf "$backup_dir"
        return 1
    fi
}

# 增量备份（基于文件修改时间）
do_incremental_backup() {
    log_info "开始 SQLite 增量备份..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$FULL_DIR/incremental_$timestamp"
    local backup_count=0
    
    # 创建备份目录
    mkdir -p "$backup_dir"
    
    # 获取上次备份时间
    local last_backup_file="$FULL_DIR/last_backup_time.txt"
    local last_backup_time=0
    
    if [ -f "$last_backup_file" ]; then
        last_backup_time=$(cat "$last_backup_file")
    fi
    
    # 查找所有数据库文件
    local db_files=$(find_sqlite_dbs)
    
    for db_file in $db_files; do
        if [ -f "$db_file" ]; then
            local file_mtime=$(stat -c %Y "$db_file" 2>/dev/null)
            
            # 如果文件修改时间晚于上次备份时间
            if [ "$file_mtime" -gt "$last_backup_time" ]; then
                local db_name=$(basename "$db_file")
                local db_dir=$(dirname "$db_file")
                local relative_path="${db_dir#/}"
                local target_dir="$backup_dir/$relative_path"
                
                mkdir -p "$target_dir"
                
                if command -v sqlite3 &> /dev/null; then
                    sqlite3 "$db_file" ".backup '$target_dir/$db_name'" 2>/dev/null || cp "$db_file" "$target_dir/$db_name"
                else
                    cp "$db_file" "$target_dir/$db_name"
                fi
                
                log_info "已备份(增量): $db_file"
                backup_count=$((backup_count + 1))
            fi
        fi
    done
    
    if [ $backup_count -gt 0 ]; then
        tar czf "$backup_dir.tar.gz" -C "$FULL_DIR" "incremental_$timestamp"
        rm -rf "$backup_dir"
        
        local size=$(du -h "$backup_dir.tar.gz" | cut -f1)
        log_success "增量备份完成: $backup_dir.tar.gz (大小: $size, 数据库数: $backup_count)"
    else
        log_info "没有需要备份的变更文件"
        rm -rf "$backup_dir"
    fi
    
    # 更新上次备份时间
    date +%s > "$last_backup_file"
}

# 清理旧备份
cleanup_old_backups() {
    log_info "清理 ${RETENTION_DAYS} 天前的备份..."
    
    # 保留最新的一个备份
    local latest_backup=$(ls -t "$FULL_DIR"/full_*.tar.gz 2>/dev/null | head -1)
    
    find "$FULL_DIR" -name "full_*.tar.gz" -mtime +$RETENTION_DAYS | while read backup; do
        if [ "$backup" != "$latest_backup" ]; then
            rm -f "$backup" "${backup}.info"
            log_info "已删除: $backup"
        fi
    done
    
    find "$FULL_DIR" -name "incremental_*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null
    
    log_success "旧备份清理完成"
}

# 显示备份列表
list_backups() {
    echo "=== SQLite 全量备份列表 ==="
    echo ""
    
    if [ -d "$FULL_DIR" ]; then
        local backups=$(ls -lt "$FULL_DIR"/full_*.tar.gz 2>/dev/null)
        if [ -z "$backups" ]; then
            echo "  暂无全量备份"
        else
            echo "$backups" | head -20
        fi
        
        echo ""
        echo "=== SQLite 增量备份列表 ==="
        local inc_backups=$(ls -lt "$FULL_DIR"/incremental_*.tar.gz 2>/dev/null)
        if [ -z "$inc_backups" ]; then
            echo "  暂无增量备份"
        else
            echo "$inc_backups" | head -20
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
            echo "用法: $0 {backup|incremental|cleanup|all|list}"
            echo "  backup      - 执行全量备份"
            echo "  incremental - 执行增量备份"
            echo "  cleanup     - 清理旧备份"
            echo "  all         - 执行备份并清理"
            echo "  list        - 列出备份"
            ;;
    esac
}

main "$@"