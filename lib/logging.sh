#!/bin/bash

# =========================================
# 日志系统
# =========================================

LOG_DIR="/var/log/shell-utils"
LOG_FILE="$LOG_DIR/install.log"
MAX_LOG_SIZE=10485760  # 10MB

mkdir -p "$LOG_DIR"

init_log() {
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
    fi
    
    # 获取文件大小，兼容 BSD/macOS 和 Linux
    local size=""
    if [ "$(uname)" = "Darwin" ]; then
        size=$(stat -f%z "$LOG_FILE" 2>/dev/null || echo 0)
    else
        size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
    fi
    
    if [ -n "$size" ] && [ "$size" -gt "$MAX_LOG_SIZE" ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        touch "$LOG_FILE"
    fi
}

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

log_info() {
    log "INFO" "$@"
}

log_warn() {
    log "WARN" "$@"
}

log_error() {
    log "ERROR" "$@"
}

log_debug() {
    if [ "${DEBUG:-0}" = "1" ]; then
        log "DEBUG" "$@"
    fi
}

log_cmd() {
    local cmd="$@"
    log "CMD" "Executing: $cmd"
    eval "$cmd" 2>&1 | while read line; do
        log "CMD" "$line"
    done
}

show_log() {
    local lines=${1:-50}
    if [ -f "$LOG_FILE" ]; then
        echo -e "${YELLOW}最近日志：${NC}"
        tail -n "$lines" "$LOG_FILE"
    else
        echo -e "${RED}日志文件不存在${NC}"
    fi
}

clear_log() {
    > "$LOG_FILE"
    print_success "日志已清空"
}

init_log
