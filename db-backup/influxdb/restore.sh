#!/bin/bash
# InfluxDB 数据库恢复脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 配置参数
BACKUP_ROOT="/var/backups/influxdb"
FULL_DIR="$BACKUP_ROOT/full"
INCREMENTAL_DIR="$BACKUP_ROOT/incremental"
LOG_FILE="$BACKUP_ROOT/influxdb_restore.log"

INFLUX_HOST="${INFLUX_HOST:-localhost}"
INFLUX_PORT="${INFLUX_PORT:-8086}"
INFLUX_TOKEN="${INFLUX_TOKEN:-}"
INFLUX_ORG="${INFLUX_ORG:-}"

INFLUX_VERSION="${INFLUX_VERSION:-2}"

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
    mkdir -p "$INCREMENTAL_DIR"
    touch "$LOG_FILE"
}

# 列出备份
list_backups() {
    echo "=== InfluxDB 全量备份列表 ==="
    ls -lt "$FULL_DIR"/full_*.tar.gz 2>/dev/null | head -20 || echo "  暂无全量备份"
    
    echo ""
    echo "=== InfluxDB 增量备份列表 ==="
    ls -lt "$INCREMENTAL_DIR"/incremental_*.tar.gz 2>/dev/null | head -20 || echo "  暂无增量备份"
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

# InfluxDB v2 恢复
restore_v2() {
    local backup_file="$1"
    local bucket="$2"
    
    if [ -z "$backup_file" ]; then
        backup_file=$(ls -t "$FULL_DIR"/full_*.tar.gz 2>/dev/null | head -1)
        if [ -z "$backup_file" ]; then
            log_error "没有找到可用的备份"
            return 1
        fi
        log_info "使用最新的备份: $backup_file"
    fi
    
    log_info "开始 InfluxDB v2 恢复..."
    
    # 验证备份文件
    verify_backup "$backup_file" || return 1
    
    # 创建临时目录
    local tmp_dir=$(mktemp -d)
    
    # 解压备份
    log_info "解压备份文件..."
    tar xzf "$backup_file" -C "$tmp_dir"
    
    # 查找备份目录
    local backup_dir=$(ls "$tmp_dir" | head -1)
    
    # 构建恢复命令
    local cmd="influx restore $tmp_dir/$backup_dir"
    
    if [ -n "$INFLUX_HOST" ]; then
        cmd="$cmd --host http://$INFLUX_HOST:$INFLUX_PORT"
    fi
    
    if [ -n "$INFLUX_TOKEN" ]; then
        cmd="$cmd --token $INFLUX_TOKEN"
    fi
    
    if [ -n "$bucket" ]; then
        cmd="$cmd --bucket $bucket"
    fi
    
    # 执行恢复
    log_info "正在恢复数据..."
    $cmd 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "数据恢复成功"
    else
        log_error "数据恢复失败"
        rm -rf "$tmp_dir"
        return 1
    fi
    
    rm -rf "$tmp_dir"
    return 0
}

# InfluxDB v1 恢复
restore_v1() {
    local backup_file="$1"
    local database="$2"
    
    if [ -z "$backup_file" ]; then
        backup_file=$(ls -t "$FULL_DIR"/full_*.tar.gz 2>/dev/null | head -1)
        if [ -z "$backup_file" ]; then
            log_error "没有找到可用的备份"
            return 1
        fi
    fi
    
    log_info "开始 InfluxDB v1 恢复..."
    
    # 验证备份文件
    verify_backup "$backup_file" || return 1
    
    # 创建临时目录
    local tmp_dir=$(mktemp -d)
    
    # 解压备份
    tar xzf "$backup_file" -C "$tmp_dir"
    
    local backup_dir=$(ls "$tmp_dir" | head -1)
    
    # 停止 InfluxDB
    log_info "停止 InfluxDB 服务..."
    systemctl stop influxdb 2>/dev/null || service influxdb stop 2>/dev/null
    
    # 使用 influxd restore
    local cmd="influxd restore -portable"
    
    if [ -n "$database" ]; then
        cmd="$cmd -db $database"
    fi
    
    cmd="$cmd $tmp_dir/$backup_dir"
    
    log_info "正在恢复数据..."
    $cmd 2>/dev/null
    
    # 启动 InfluxDB
    log_info "启动 InfluxDB 服务..."
    systemctl start influxdb 2>/dev/null || service influxdb start 2>/dev/null
    
    rm -rf "$tmp_dir"
    log_success "数据恢复完成"
}

# 恢复
do_restore() {
    if [ "$INFLUX_VERSION" = "1" ]; then
        restore_v1 "$2" "$3"
    else
        restore_v2 "$2" "$3"
    fi
}

# 恢复指定 bucket/database
restore_bucket() {
    local backup_file="$1"
    local bucket="$2"
    
    if [ -z "$backup_file" ] || [ -z "$bucket" ]; then
        log_error "请指定备份文件和 bucket/database 名称"
        return 1
    fi
    
    log_info "恢复 bucket/database: $bucket"
    
    if [ "$INFLUX_VERSION" = "1" ]; then
        restore_v1 "$backup_file" "$bucket"
    else
        restore_v2 "$backup_file" "$bucket"
    fi
}

# 显示帮助
show_help() {
    echo "InfluxDB 数据库恢复脚本"
    echo ""
    echo "用法: $0 {restore|bucket|list|verify|help}"
    echo ""
    echo "命令:"
    echo "  restore [备份文件]           - 从备份恢复"
    echo "  bucket <备份> <bucket>       - 恢复指定 bucket/database"
    echo "  list                         - 列出所有备份"
    echo "  verify [备份文件]            - 验证备份文件"
    echo "  help                         - 显示帮助"
    echo ""
    echo "环境变量:"
    echo "  INFLUX_VERSION - InfluxDB版本 (1 或 2，默认: 2)"
    echo "  INFLUX_HOST    - InfluxDB主机"
    echo "  INFLUX_PORT    - InfluxDB端口"
    echo "  INFLUX_TOKEN   - 认证Token (v2)"
    echo "  INFLUX_ORG     - 组织名称 (v2)"
}

# 主函数
main() {
    init
    
    case "$1" in
        restore)
            do_restore "$@"
            ;;
        bucket)
            restore_bucket "$2" "$3"
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