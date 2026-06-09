#!/bin/bash
# Elasticsearch 数据库恢复脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 配置参数
BACKUP_ROOT="/var/backups/elasticsearch"
LOG_FILE="$BACKUP_ROOT/elasticsearch_restore.log"

ES_HOST="${ES_HOST:-localhost}"
ES_PORT="${ES_PORT:-9200}"
ES_USER="${ES_USER:-}"
ES_PASSWORD="${ES_PASSWORD:-}"

REPO_NAME="${REPO_NAME:-backup_repo}"

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

# 检查连接
check_connection() {
    local result=$(es_curl "GET" "/_cluster/health" "")
    
    if echo "$result" | grep -q "cluster_name"; then
        return 0
    else
        log_error "无法连接到 Elasticsearch"
        return 1
    fi
}

# 注册仓库
register_repository() {
    mkdir -p "$BACKUP_ROOT/$REPO_NAME"
    
    local data="{
        \"type\": \"fs\",
        \"settings\": {
            \"location\": \"$BACKUP_ROOT/$REPO_NAME\",
            \"compress\": true
        }
    }"
    
    es_curl "PUT" "/_snapshot/$REPO_NAME" "$data" > /dev/null
}

# 列出快照
list_snapshots() {
    echo "=== Elasticsearch 快照列表 ==="
    echo ""
    
    check_connection || return 1
    register_repository
    
    local result=$(es_curl "GET" "/_snapshot/$REPO_NAME/_all" "")
    
    if echo "$result" | grep -q '"snapshot"'; then
        echo "$result" | python3 -m json.tool 2>/dev/null || echo "$result"
    else
        echo "  暂无快照"
    fi
}

# 验证快照
verify_snapshot() {
    local snapshot_name="$1"
    
    if [ -z "$snapshot_name" ]; then
        log_error "请指定快照名称"
        return 1
    fi
    
    log_info "验证快照: $snapshot_name"
    
    check_connection || return 1
    register_repository
    
    local result=$(es_curl "POST" "/_snapshot/$REPO_NAME/$snapshot_name/_verify" "")
    
    if echo "$result" | grep -q '"state":"SUCCESS"'; then
        log_success "快照验证通过: $snapshot_name"
        return 0
    else
        log_error "快照验证失败: $result"
        return 1
    fi
}

# 恢复快照
restore_snapshot() {
    local snapshot_name="$1"
    local indices="$2"
    
    if [ -z "$snapshot_name" ]; then
        # 获取最新的快照
        local result=$(es_curl "GET" "/_snapshot/$REPO_NAME/_all" "")
        snapshot_name=$(echo "$result" | grep -o '"snapshot":"[^"]*"' | tail -1 | cut -d'"' -f4)
        
        if [ -z "$snapshot_name" ]; then
            log_error "没有找到可用的快照"
            return 1
        fi
        log_info "使用最新的快照: $snapshot_name"
    fi
    
    log_info "开始恢复快照: $snapshot_name"
    
    check_connection || return 1
    register_repository
    
    # 关闭索引（如果恢复所有索引）
    if [ -z "$indices" ]; then
        log_info "关闭所有索引..."
        es_curl "POST" "/_all/_close" "" > /dev/null
    fi
    
    # 构建恢复请求
    local data="{
        \"indices\": \"${indices:-*}\",
        \"ignore_unavailable\": true,
        \"include_global_state\": true,
        \"include_aliases\": true
    }"
    
    # 执行恢复
    log_info "正在恢复数据..."
    local result=$(es_curl "POST" "/_snapshot/$REPO_NAME/$snapshot_name/_restore?wait_for_completion=true" "$data")
    
    if echo "$result" | grep -q '"state":"SUCCESS"'; then
        log_success "快照恢复成功: $snapshot_name"
        
        # 打开索引
        if [ -z "$indices" ]; then
            log_info "打开所有索引..."
            es_curl "POST" "/_all/_open" "" > /dev/null
        fi
    else
        log_error "快照恢复失败: $result"
        return 1
    fi
}

# 恢复指定索引
restore_indices() {
    local snapshot_name="$1"
    local indices="$2"
    
    if [ -z "$snapshot_name" ] || [ -z "$indices" ]; then
        log_error "请指定快照名称和索引名称"
        return 1
    fi
    
    log_info "恢复索引: $indices (快照: $snapshot_name)"
    
    check_connection || return 1
    register_repository
    
    # 关闭索引
    es_curl "POST" "/$indices/_close" "" > /dev/null
    
    # 恢复
    local data="{
        \"indices\": \"$indices\",
        \"ignore_unavailable\": true
    }"
    
    local result=$(es_curl "POST" "/_snapshot/$REPO_NAME/$snapshot_name/_restore?wait_for_completion=true" "$data")
    
    if echo "$result" | grep -q '"state":"SUCCESS"'; then
        log_success "索引恢复成功: $indices"
        
        # 打开索引
        es_curl "POST" "/$indices/_open" "" > /dev/null
    else
        log_error "索引恢复失败: $result"
        return 1
    fi
}

# 显示快照详情
show_snapshot_info() {
    local snapshot_name="$1"
    
    if [ -z "$snapshot_name" ]; then
        log_error "请指定快照名称"
        return 1
    fi
    
    check_connection || return 1
    register_repository
    
    echo "=== 快照详情: $snapshot_name ==="
    echo ""
    
    local result=$(es_curl "GET" "/_snapshot/$REPO_NAME/$snapshot_name" "")
    echo "$result" | python3 -m json.tool 2>/dev/null || echo "$result"
}

# 显示帮助
show_help() {
    echo "Elasticsearch 数据库恢复脚本"
    echo ""
    echo "用法: $0 {restore|indices|list|verify|info|help}"
    echo ""
    echo "命令:"
    echo "  restore [快照名]           - 从快照恢复所有索引"
    echo "  indices <快照> <索引>      - 恢复指定索引"
    echo "  list                       - 列出所有快照"
    echo "  verify <快照名>            - 验证快照"
    echo "  info <快照名>              - 显示快照详情"
    echo "  help                       - 显示帮助"
    echo ""
    echo "示例:"
    echo "  $0 restore snapshot_20240115_120000"
    echo "  $0 indices snapshot_20240115_120000 myindex"
}

# 主函数
main() {
    init
    
    case "$1" in
        restore)
            restore_snapshot "$2"
            ;;
        indices)
            restore_indices "$2" "$3"
            ;;
        list)
            list_snapshots
            ;;
        verify)
            verify_snapshot "$2"
            ;;
        info)
            show_snapshot_info "$2"
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