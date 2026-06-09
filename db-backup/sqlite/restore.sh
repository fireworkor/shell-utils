#!/bin/bash
# SQLite 数据库恢复脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 配置参数
BACKUP_ROOT="/var/backups/sqlite"
FULL_DIR="$BACKUP_ROOT/full"
LOG_FILE="$BACKUP_ROOT/sqlite_restore.log"

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
    mkdir -p "$FULL_DIR"
    touch "$LOG_FILE"
}

# 列出备份
list_backups() {
    echo "=== SQLite 备份列表 ==="
    echo ""
    
    if [ -d "$FULL_DIR" ]; then
        local backups=$(ls -lt "$FULL_DIR"/*.tar.gz 2>/dev/null)
        if [ -z "$backups" ]; then
            echo "  暂无备份"
        else
            echo "$backups" | head -20
        fi
    else
        echo "  备份目录不存在"
    fi
}

# 验证备份文件
verify_backup() {
    local backup_file="$1"
    
    log_info "验证备份文件: $backup_file"
    
    if [ ! -f "$backup_file" ]; then
        log_error "备份文件不存在: $backup_file"
        return 1
    fi
    
    tar tzf "$backup_file" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log_success "备份文件验证通过: $backup_file"
        return 0
    else
        log_error "备份文件损坏: $backup_file"
        return 1
    fi
}

# 从备份恢复
restore_backup() {
    local backup_file="$1"
    local target_dir="$2"
    
    if [ -z "$backup_file" ]; then
        # 自动选择最新的备份
        backup_file=$(ls -t "$FULL_DIR"/full_*.tar.gz 2>/dev/null | head -1)
        if [ -z "$backup_file" ]; then
            backup_file=$(ls -t "$FULL_DIR"/incremental_*.tar.gz 2>/dev/null | head -1)
        fi
        if [ -z "$backup_file" ]; then
            log_error "没有找到可用的备份"
            return 1
        fi
        log_info "使用最新的备份: $backup_file"
    fi
    
    if [ -z "$target_dir" ]; then
        target_dir="/var/lib/sqlite"
    fi
    
    log_info "开始恢复 SQLite 数据库..."
    log_info "备份文件: $backup_file"
    log_info "目标目录: $target_dir"
    
    # 验证备份文件
    verify_backup "$backup_file" || return 1
    
    # 创建临时目录
    local tmp_dir=$(mktemp -d)
    
    # 解压备份
    log_info "解压备份文件..."
    tar xzf "$backup_file" -C "$tmp_dir"
    
    # 查找解压后的目录
    local backup_content=$(ls "$tmp_dir" | head -1)
    local source_dir="$tmp_dir/$backup_content"
    
    # 备份当前数据
    if [ -d "$target_dir" ] && [ "$(ls -A $target_dir 2>/dev/null)" ]; then
        local backup_old="$target_dir.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "备份当前数据到: $backup_old"
        cp -r "$target_dir" "$backup_old"
    fi
    
    # 创建目标目录
    mkdir -p "$target_dir"
    
    # 复制数据库文件
    log_info "恢复数据库文件..."
    cp -r "$source_dir"/* "$target_dir"/ 2>/dev/null
    
    # 设置权限
    chmod -R 644 "$target_dir"/*.db 2>/dev/null
    chmod -R 755 "$target_dir" 2>/dev/null
    
    # 清理临时目录
    rm -rf "$tmp_dir"
    
    log_success "SQLite 数据库恢复完成"
    return 0
}

# 恢复单个数据库
restore_database() {
    local backup_file="$1"
    local db_name="$2"
    local target_path="$3"
    
    if [ -z "$backup_file" ] || [ -z "$db_name" ] || [ -z "$target_path" ]; then
        log_error "请指定备份文件、数据库名和目标路径"
        return 1
    fi
    
    log_info "恢复单个数据库: $db_name"
    
    # 创建临时目录
    local tmp_dir=$(mktemp -d)
    
    # 解压备份
    tar xzf "$backup_file" -C "$tmp_dir"
    
    # 查找数据库文件
    local db_file=$(find "$tmp_dir" -name "$db_name" 2>/dev/null | head -1)
    
    if [ -z "$db_file" ]; then
        log_error "在备份中未找到数据库: $db_name"
        rm -rf "$tmp_dir"
        return 1
    fi
    
    # 备份当前文件
    if [ -f "$target_path" ]; then
        cp "$target_path" "${target_path}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # 复制数据库文件
    cp "$db_file" "$target_path"
    
    # 清理临时目录
    rm -rf "$tmp_dir"
    
    log_success "数据库 $db_name 恢复完成"
    return 0
}

# 显示帮助
show_help() {
    echo "SQLite 数据库恢复脚本"
    echo ""
    echo "用法: $0 {restore|database|list|verify|help}"
    echo ""
    echo "命令:"
    echo "  restore [备份文件] [目标目录]  - 从备份恢复"
    echo "  database <备份> <库名> <目标>  - 恢复单个数据库"
    echo "  list                          - 列出所有备份"
    echo "  verify [备份文件]             - 验证备份文件"
    echo "  help                          - 显示帮助"
    echo ""
    echo "示例:"
    echo "  $0 restore                                    # 使用最新备份恢复"
    echo "  $0 restore /path/to/backup.tar.gz /var/lib/sqlite"
    echo "  $0 database backup.tar.gz mydb.db /var/lib/sqlite/mydb.db"
}

# 主函数
main() {
    init
    
    case "$1" in
        restore)
            restore_backup "$2" "$3"
            ;;
        database)
            restore_database "$2" "$3" "$4"
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