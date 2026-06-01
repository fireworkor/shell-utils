#!/bin/bash
# 日志系统

LOG_FILE="/var/log/shell-utils.log"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
    echo "[INFO] $(date) - $*" >> "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
    echo "[WARN] $(date) - $*" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
    echo "[ERROR] $(date) - $*" >> "$LOG_FILE"
}

log_debug() {
    echo -e "${CYAN}[DEBUG]${NC} $*"
    echo "[DEBUG] $(date) - $*" >> "$LOG_FILE"
}

show_log() {
    local lines=${1:-50}
    tail -n "$lines" "$LOG_FILE" 2>/dev/null || echo "日志文件不存在"
}

clear_log() {
    > "$LOG_FILE"
    echo "日志已清空"
}
