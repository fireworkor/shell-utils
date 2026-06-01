#!/bin/bash

# =========================================
# 标准化日志系统 v2.0
# 特性：
#   - 标准化的日志格式
#   - 日志级别控制
#   - 彩色输出
#   - 日志轮转
#   - 多输出目标
# =========================================

# 日志配置
LOG_DIR="${LOG_DIR:-/var/log/shell-utils}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/app.log}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"
LOG_MAX_SIZE="${LOG_MAX_SIZE:-10485760}"  # 10MB
LOG_BACKUP_COUNT="${LOG_BACKUP_COUNT:-5}"
LOG_FORMAT="${LOG_FORMAT:-standard}"  # standard | json | simple
LOG_TO_CONSOLE="${LOG_TO_CONSOLE:-true}"
LOG_TO_FILE="${LOG_TO_FILE:-true}"

# 日志级别优先级
declare -A LOG_LEVELS=(
    [DEBUG]=0
    [INFO]=1
    [WARN]=2
    [ERROR]=3
    [FATAL]=4
)

# 颜色定义
readonly COLOR_RESET='\033[0m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_DIM='\033[2m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_MAGENTA='\033[0;35m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_WHITE='\033[0;37m'

# 颜色映射（用于彩色输出）
declare -A LEVEL_COLORS=(
    [DEBUG]="$COLOR_CYAN"
    [INFO]="$COLOR_GREEN"
    [WARN]="$COLOR_YELLOW"
    [ERROR]="$COLOR_RED"
    [FATAL]="$COLOR_BOLD$COLOR_RED"
)

# 模块名称（可在引入后设置）
LOG_MODULE="${LOG_MODULE:-main}"

# 初始化日志目录
init_log_dir() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || {
            LOG_DIR="/tmp/shell-utils"
            mkdir -p "$LOG_DIR"
        }
    fi
}

# 日志轮转
rotate_log() {
    if [ -f "$LOG_FILE" ]; then
        local size=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null)

        if [ "$size" -gt "$LOG_MAX_SIZE" ]; then
            log_debug "开始日志轮转"

            # 删除最旧的备份
            if [ -f "${LOG_FILE}.${LOG_BACKUP_COUNT}" ]; then
                rm -f "${LOG_FILE}.${LOG_BACKUP_COUNT}"
            fi

            # 移动现有备份
            for i in $(seq $((LOG_BACKUP_COUNT - 1)) -1 1); do
                if [ -f "${LOG_FILE}.${i}" ]; then
                    mv "${LOG_FILE}.${i}" "${LOG_FILE}.$((i + 1))"
                fi
            done

            # 移动当前日志
            mv "$LOG_FILE" "${LOG_FILE}.1"

            log_debug "日志轮转完成"
        fi
    fi
}

# 获取日志前缀
get_log_prefix() {
    local level=$1
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$LOG_FORMAT" in
        json)
            echo "{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"module\":\"$LOG_MODULE\",\"pid\":$$}"
            ;;
        simple)
            echo "[$level]"
            ;;
        *)
            echo "[$timestamp] [$level] [$LOG_MODULE]"
            ;;
    esac
}

# 格式化日志消息
format_log() {
    local level=$1
    shift
    local message="$*"
    local prefix=$(get_log_prefix "$level")

    case "$LOG_FORMAT" in
        json)
            echo "{\"message\":\"$message\"}"
            ;;
        *)
            echo "$prefix $message"
            ;;
    esac
}

# 写入日志文件
write_log() {
    local level=$1
    shift
    local message="$*"

    if [ "$LOG_TO_FILE" = "true" ]; then
        rotate_log
        echo "$message" >> "$LOG_FILE"
    fi
}

# 输出到控制台
write_console() {
    local level=$1
    shift
    local message="$*"

    if [ "$LOG_TO_CONSOLE" = "true" ]; then
        local color="${LEVEL_COLORS[$level]:-}"
        local reset="${COLOR_RESET}"

        # JSON 格式不输出颜色
        if [ "$LOG_FORMAT" = "json" ]; then
            echo "$message"
        else
            echo -e "${color}${message}${reset}"
        fi
    fi
}

# 内部日志函数
_log() {
    local level=$1
    shift
    local message="$*"

    # 检查日志级别
    local current_level_priority=${LOG_LEVELS[$LOG_LEVEL]}
    local msg_level_priority=${LOG_LEVELS[$level]}

    if [ "$msg_level_priority" -lt "$current_level_priority" ]; then
        return
    fi

    local formatted_message=$(format_log "$level" "$message")

    write_log "$level" "$formatted_message"
    write_console "$level" "$formatted_message"
}

# 公共日志函数
log_debug() {
    _log DEBUG "$@"
}

log_info() {
    _log INFO "$@"
}

log_warn() {
    _log WARN "$@"
}

log_error() {
    _log ERROR "$@"
}

log_fatal() {
    _log FATAL "$@"
}

# 日志命令执行
log_cmd() {
    local description="$1"
    shift
    local cmd="$@"

    log_info "执行命令: $description"
    log_debug "命令内容: $cmd"

    if [ "${DRY_RUN:-0}" = "1" ]; then
        log_warn "[DRY-RUN] 跳过执行: $cmd"
        return 0
    fi

    local output
    local exit_code

    output=$(eval "$cmd" 2>&1)
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        log_debug "命令执行成功"
        [ -n "$output" ] && log_debug "输出: $output"
        return 0
    else
        log_error "命令执行失败（退出码: $exit_code）: $description"
        [ -n "$output" ] && log_error "错误输出: $output"
        return $exit_code
    fi
}

# 带确认的日志命令
log_cmd_confirm() {
    local description="$1"
    shift
    local cmd="$@"

    log_warn "即将执行: $description"
    log_warn "命令: $cmd"

    read -p "确认执行? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        log_info "操作已取消"
        return 1
    fi

    log_cmd "$description" "$cmd"
    return $?
}

# 分隔线
log_separator() {
    local char="${1:--}"
    local length="${2:-50}"
    local message="${3:-}"

    if [ -n "$message" ]; then
        log_info "$message"
    fi

    printf -v line '%*s' "$length"
    echo "${line// /$char}"
}

# 进度显示
log_progress() {
    local current=$1
    local total=$2
    local message="${3:-}"
    local width=40

    local percent=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))

    local bar=$(printf '%*s' "$completed" | tr ' ' '=')
    local spaces=$(printf '%*s' "$remaining" | tr ' ' '-')

    echo -ne "\r${COLOR_CYAN}[${bar}${spaces}]${COLOR_RESET} ${percent}% ${message}"
    
    if [ $current -eq $total ]; then
        echo
    fi
}

# 表格日志
log_table() {
    local -a headers=("$@")
    local header_line=""

    for header in "${headers[@]}"; do
        printf "| %-20s" "$header"
    done
    echo "|"

    for header in "${headers[@]}"; do
        printf "|%s" "--------------------"
    done
    echo "|"
}

# 键值对日志
log_kv() {
    local key=$1
    local value=$2
    local indent="${3:-0}"

    printf "%${indent}s${COLOR_BOLD}%-20s${COLOR_RESET}: %s\n" "" "$key" "$value"
}

# JSON 格式键值对
log_json() {
    local key=$1
    local value=$2

    echo "{\"key\":\"$key\",\"value\":\"$value\"}"
}

# 显示日志文件
show_log() {
    local lines=${1:-50}
    local filter="${2:-}"

    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${COLOR_RED}日志文件不存在: $LOG_FILE${COLOR_RESET}"
        return 1
    fi

    if [ -n "$filter" ]; then
        echo -e "${COLOR_YELLOW}过滤条件: $filter${COLOR_RESET}"
        grep -i "$filter" "$LOG_FILE" | tail -n "$lines"
    else
        tail -n "$lines" "$LOG_FILE"
    fi
}

# 清理日志
clear_log() {
    > "$LOG_FILE"
    log_info "日志已清空"
}

# 获取日志统计
log_stats() {
    if [ ! -f "$LOG_FILE" ]; then
        echo "日志文件不存在"
        return
    fi

    local total=$(wc -l < "$LOG_FILE")
    local errors=$(grep -c "ERROR" "$LOG_FILE" 2>/dev/null || echo 0)
    local warnings=$(grep -c "WARN" "$LOG_FILE" 2>/dev/null || echo 0)
    local size=$(du -h "$LOG_FILE" | cut -f1)

    echo "日志统计:"
    log_kv "文件路径" "$LOG_FILE"
    log_kv "日志大小" "$size"
    log_kv "总行数" "$total"
    log_kv "错误数" "$errors"
    log_kv "警告数" "$warnings"
}

# 设置日志级别
set_log_level() {
    local level=$1

    if [ -z "${LOG_LEVELS[$level]}" ]; then
        log_error "无效的日志级别: $level"
        log_error "可用级别: ${!LOG_LEVELS[*]}"
        return 1
    fi

    LOG_LEVEL="$level"
    log_info "日志级别已设置为: $level"
}

# 启用/禁用控制台输出
toggle_console() {
    if [ "$LOG_TO_CONSOLE" = "true" ]; then
        LOG_TO_CONSOLE="false"
        log_info "控制台输出已禁用"
    else
        LOG_TO_CONSOLE="true"
        log_info "控制台输出已启用"
    fi
}

# 启用/禁用文件输出
toggle_file() {
    if [ "$LOG_TO_FILE" = "true" ]; then
        LOG_TO_FILE="false"
        log_info "文件输出已禁用"
    else
        LOG_TO_FILE="true"
        LOG_TO_FILE="true"
        log_info "文件输出已启用"
    fi
}

# 导出日志配置
export_log_config() {
    cat <<EOF
LOG_DIR=$LOG_DIR
LOG_FILE=$LOG_FILE
LOG_LEVEL=$LOG_LEVEL
LOG_FORMAT=$LOG_FORMAT
LOG_TO_CONSOLE=$LOG_TO_CONSOLE
LOG_TO_FILE=$LOG_TO_FILE
EOF
}

# 初始化
init_log_dir
