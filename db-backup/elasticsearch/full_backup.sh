#!/bin/bash
# Elasticsearch 数据库备份脚本
# 使用 Elasticsearch 快照 API 进行备份

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 配置参数
BACKUP_ROOT="/var/backups/elasticsearch"
LOG_FILE="$BACKUP_ROOT/elasticsearch_backup.log"

ES_HOST="${ES_HOST:-localhost}"
ES_PORT="${ES_PORT:-9200}"
ES_USER="${ES_USER:-}"
ES_PASSWORD="${ES_PASSWORD:-}"

# 快照仓库名称
REPO_NAME="${REPO_NAME:-backup_repo}"

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
init() {
    mkdir -p "$BACKUP_ROOT"
    touch "$LOG_FILE"
}

# 执行 curl 命令
es_curl() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    
    local cmd="curl -s -X $method"
    
    if [ -n "$ES_USER" ] && [ -n "$ES_PASSWORD" ]; then
        cmd="$cmd -u $ES_USER:$ES_PASSWORD"
    fi
    
    if [ -n "$data" ]; then
        cmd="$cmd -H 'Content-Type: application/json' -d '$data'"
    fi
    
    cmd="$cmd http://$ES_HOST:$ES_PORT$endpoint"
    
    eval "$cmd"
}

# 检查 Elasticsearch 连接
check_connection() {
    local result=$(es_curl "GET" "/_cluster/health" "")
    
    if echo "$result" | grep -q "cluster_name"; then
        return 0
    else
        log_error "无法连接到 Elasticsearch: $ES_HOST:$ES_PORT"
        return 1
    fi
}

# 注册快照仓库
register_repository() {
    log_info "注册快照仓库: $REPO_NAME"
    
    # 创建备份目录
    mkdir -p "$BACKUP_ROOT/$REPO_NAME"
    
    # 注册仓库
    local data="{
        \"type\": \"fs\",
        \"settings\": {
            \"location\": \"$BACKUP_ROOT/$REPO_NAME\",
            \"compress\": true
        }
    }"
    
    local result=$(es_curl "PUT" "/_snapshot/$REPO_NAME" "$data")
    
    if echo "$result" | grep -q '"acknowledged":true'; then
        log_success "快照仓库注册成功"
        return 0
    else
        log_error "快照仓库注册失败: $result"
        return 1
    fi
}

# 全量备份（创建快照）
do_full_backup() {
    log_info "开始 Elasticsearch 全量备份..."
    
    check_connection || return 1
    
    # 确保仓库已注册
    register_repository
    
    local snapshot_name="snapshot_$(date +%Y%m%d_%H%M%S)"
    
    log_info "创建快照: $snapshot_name"
    
    # 创建快照（等待完成）
    local data="{
        \"indices\": \"*\",
        \"ignore_unavailable\": true,
        \"include_global_state\": true
    }"
    
    local result=$(es_curl "PUT" "/_snapshot/$REPO_NAME/$snapshot_name?wait_for_completion=true" "$data")
    
    if echo "$result" | grep -q '"state":"SUCCESS"'; then
        local size=$(echo "$result" | grep -o '"size_in_bytes":[0-9]*' | cut -d: -f2)
        local human_size=$(numfmt --to=iec $size 2>/dev/null || echo "$size bytes")
        
        log_success "全量备份完成: $snapshot_name (大小: $human_size)"
        
        # 创建备份信息文件
        echo "备份时间: $(date '+%Y-%m-%d %H:%M:%S')
快照名称: $snapshot_name
备份大小: $human_size" > "$BACKUP_ROOT/${snapshot_name}.info"
    else
        log_error "全量备份失败: $result"
        return 1
    fi
}

# 增量备份（快照本身是增量的）
do_incremental_backup() {
    log_info "开始 Elasticsearch 增量备份..."
    
    check_connection || return 1
    
    # 确保仓库已注册
    register_repository
    
    local snapshot_name="incremental_$(date +%Y%m%d_%H%M%S)"
    
    log_info "创建增量快照: $snapshot_name"
    
    # Elasticsearch 快照默认是增量的
    local data="{
        \"indices\": \"*\",
        \"ignore_unavailable\": true,
        \"include_global_state\": false,
        \"partial\": true
    }"
    
    local result=$(es_curl "PUT" "/_snapshot/$REPO_NAME/$snapshot_name?wait_for_completion=true" "$data")
    
    if echo "$result" | grep -q '"state":"SUCCESS"'; then
        log_success "增量备份完成: $snapshot_name"
    else
        log_error "增量备份失败: $result"
        return 1
    fi
}

# 清理旧快照
cleanup_old_snapshots() {
    log_info "清理 ${RETENTION_DAYS} 天前的快照..."
    
    # 获取所有快照
    local result=$(es_curl "GET" "/_snapshot/$REPO_NAME/_all" "")
    
    # 解析快照列表并删除旧的
    echo "$result" | grep -o '"snapshot":"[^"]*"' | cut -d'"' -f4 | while read snapshot; do
        local start_time=$(es_curl "GET" "/_snapshot/$REPO_NAME/$snapshot" "" | grep -o '"start_time":"[^"]*"' | cut -d'"' -f4)
        
        if [ -n "$start_time" ]; then
            local snapshot_date=$(date -d "$start_time" +%s 2>/dev/null)
            local cutoff_date=$(date -d "-$RETENTION_DAYS days" +%s)
            
            if [ "$snapshot_date" -lt "$cutoff_date" ]; then
                log_info "删除旧快照: $snapshot"
                es_curl "DELETE" "/_snapshot/$REPO_NAME/$snapshot" ""
            fi
        fi
    done
    
    log_success "旧快照清理完成"
}

# 显示快照列表
list_backups() {
    echo "=== Elasticsearch 快照列表 ==="
    echo ""
    
    check_connection || return 1
    
    local result=$(es_curl "GET" "/_snapshot/$REPO_NAME/_all" "")
    
    if echo "$result" | grep -q "snapshots"; then
        echo "$result" | python3 -m json.tool 2>/dev/null || echo "$result"
    else
        echo "  暂无快照"
    fi
}

# 显示仓库信息
show_repo_info() {
    echo "=== Elasticsearch 快照仓库信息 ==="
    echo ""
    
    check_connection || return 1
    
    local result=$(es_curl "GET" "/_snapshot/$REPO_NAME" "")
    echo "$result" | python3 -m json.tool 2>/dev/null || echo "$result"
}

# 主函数
main() {
    init
    
    case "$1" in
        full)
            do_full_backup
            ;;
        incremental)
            do_incremental_backup
            ;;
        cleanup)
            cleanup_old_snapshots
            ;;
        all)
            do_full_backup
            cleanup_old_snapshots
            ;;
        list)
            list_backups
            ;;
        repo)
            show_repo_info
            ;;
        *)
            echo "用法: $0 {full|incremental|cleanup|all|list|repo}"
            echo "  full        - 执行全量备份"
            echo "  incremental - 执行增量备份"
            echo "  cleanup     - 清理旧快照"
            echo "  all         - 执行备份并清理"
            echo "  list        - 列出快照"
            echo "  repo        - 显示仓库信息"
            ;;
    esac
}

main "$@"