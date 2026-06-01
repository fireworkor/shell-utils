#!/bin/bash

# =========================================
# 统一错误处理系统
# 需要：lib/logging.sh
# =========================================

# 错误码定义
readonly ERR_SUCCESS=0
readonly ERR_GENERAL=1
readonly ERR_PARAMS=2
readonly ERR_PERMISSION=3
readonly ERR_NETWORK=4
readonly ERR_DEPENDENCY=5
readonly ERR_TIMEOUT=6
readonly ERR_FILE_NOT_FOUND=7
readonly ERR_CONFIG=8

# 错误信息映射
declare -A ERROR_MESSAGES=(
    [$ERR_SUCCESS]="成功"
    [$ERR_GENERAL]="一般错误"
    [$ERR_PARAMS]="参数错误"
    [$ERR_PERMISSION]="权限不足"
    [$ERR_NETWORK]="网络错误"
    [$ERR_DEPENDENCY]="依赖错误"
    [$ERR_TIMEOUT]="超时错误"
    [$ERR_FILE_NOT_FOUND]="文件未找到"
    [$ERR_CONFIG]="配置错误"
)

# 全局变量
ERROR_COUNT=0
WARN_COUNT=0
SCRIPT_START_TIME=$(date +%s)

# 设置错误处理
setup_error_handling() {
    set -o pipefail 2>/dev/null || true
    shopt -s inherit_errexit 2>/dev/null || true
}

# 获取错误信息
get_error_message() {
    local code=$1
    echo "${ERROR_MESSAGES[$code]:-未知错误}"
}

# 错误处理器
error_handler() {
    local exit_code=$?
    local line_number=${BASH_LINENO[0]}
    local command="${BASH_COMMAND}"
    local funcstack="${FUNCNAME[*]:1:3}"

    ERROR_COUNT=$((ERROR_COUNT + 1))

    if [ -n "${FUNCNAME[1]}" ]; then
        log_error "[${FUNCNAME[1]}] 行 ${BASH_LINENO[0]}: 命令失败: $command (退出码: $exit_code)"
    else
        log_error "[主脚本] 行 ${BASH_LINENO[0]}: 命令失败: $command (退出码: $exit_code)"
    fi

    if [ "${DEBUG:-0}" = "1" ]; then
        log_debug "调用栈: ${funcstack}"
        log_debug "工作目录: $(pwd)"
    fi
}

# 退出处理器
cleanup_handler() {
    local exit_code=$?
    local duration=$(($(date +%s) - SCRIPT_START_TIME))

    if [ $# -gt 0 ]; then
        exit_code=$1
    fi

    if [ $ERROR_COUNT -gt 0 ]; then
        log_warn "脚本执行完成（耗时: ${duration}s），发生 $ERROR_COUNT 个错误"
    else
        log_info "脚本执行完成（耗时: ${duration}s）"
    fi

    return $exit_code
}

# 启用错误处理
enable_error_handling() {
    trap error_handler ERR
    trap cleanup_handler EXIT
}

# 禁用错误处理（用于已知可能失败的命令）
disable_error_handling() {
    trap - ERR
}

# 恢复错误处理
restore_error_handling() {
    trap error_handler ERR
}

# 执行命令并记录错误
run_command() {
    local description="$1"
    shift
    local cmd="$@"

    log_info "执行: $description"
    log_debug "命令: $cmd"

    if [ "${DRY_RUN:-0}" = "1" ]; then
        log_warn "[DRY-RUN] 跳过执行: $cmd"
        return 0
    fi

    disable_error_handling
    "$@" 2>&1 | tee -a "${LOG_FILE:-/tmp/script.log}"
    local exit_code=${PIPESTATUS[0]}
    restore_error_handling

    if [ $exit_code -ne 0 ]; then
        ERROR_COUNT=$((ERROR_COUNT + 1))
        log_error "命令执行失败: $description (退出码: $exit_code)"
        return $exit_code
    fi

    log_info "命令执行成功: $description"
    return 0
}

# 安全执行命令（不中断脚本）
safe_run() {
    local description="$1"
    shift
    local cmd="$@"

    log_debug "安全执行: $description"

    disable_error_handling
    "$@" > /dev/null 2>&1
    local exit_code=$?
    restore_error_handling

    if [ $exit_code -eq 0 ]; then
        log_debug "执行成功: $description"
        return 0
    else
        log_warn "执行失败（已忽略）: $description (退出码: $exit_code)"
        return $exit_code
    fi
}

# 检查命令是否成功
check_success() {
    local exit_code=$?
    local message="${1:-操作}"

    if [ $exit_code -eq 0 ]; then
        return 0
    else
        ERROR_COUNT=$((ERROR_COUNT + 1))
        log_error "$message 失败 (退出码: $exit_code)"
        return $exit_code
    fi
}

# 警告处理器
warning_handler() {
    WARN_COUNT=$((WARN_COUNT + 1))
    log_warn "$@"
}

# 获取统计信息
get_error_stats() {
    echo "错误数: $ERROR_COUNT, 警告数: $WARN_COUNT"
}

# 重置计数器
reset_error_count() {
    ERROR_COUNT=0
    WARN_COUNT=0
    SCRIPT_START_TIME=$(date +%s)
}

# 严格模式
enable_strict_mode() {
    set -euo pipefail
    enable_error_handling
}

# 验证必需参数
require_params() {
    local missing_params=()
    for param in "$@"; do
        if [ -z "${!param}" ]; then
            missing_params+=("$param")
        fi
    done

    if [ ${#missing_params[@]} -gt 0 ]; then
        log_error "缺少必需参数: ${missing_params[*]}"
        return $ERR_PARAMS
    fi

    return 0
}

# 验证文件存在
require_file() {
    local file=$1
    local description="${2:-文件}"

    if [ ! -f "$file" ]; then
        log_error "$description 不存在: $file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        return $ERR_FILE_NOT_FOUND
    fi

    return 0
}

# 验证目录存在
require_dir() {
    local dir=$1
    local description="${2:-目录}"

    if [ ! -d "$dir" ]; then
        log_error "$description 不存在: $dir"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        return $ERR_FILE_NOT_FOUND
    fi

    return 0
}

# 超时执行
timeout_run() {
    local timeout=$1
    shift
    local cmd="$@"

    log_debug "执行命令（超时: ${timeout}s）: $cmd"

    timeout "$timeout" bash -c "$cmd"
    local exit_code=$?

    if [ $exit_code -eq 124 ]; then
        log_error "命令执行超时（${timeout}s）"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        return $ERR_TIMEOUT
    fi

    return $exit_code
}

# 重试执行
retry_run() {
    local max_attempts=$1
    local delay=${2:-5}
    shift 2
    local cmd="$@"

    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        log_info "执行命令（第 $attempt/$max_attempts 次）: $cmd"

        if [ "${DRY_RUN:-0}" = "1" ]; then
            log_warn "[DRY-RUN] 跳过执行"
            return 0
        fi

        disable_error_handling
        eval "$cmd"
        local exit_code=$?
        restore_error_handling

        if [ $exit_code -eq 0 ]; then
            log_info "命令执行成功"
            return 0
        fi

        if [ $attempt -lt $max_attempts ]; then
            log_warn "命令执行失败，${delay}s 后重试..."
            sleep "$delay"
        fi

        attempt=$((attempt + 1))
    done

    log_error "命令执行失败（已重试 $max_attempts 次）"
    ERROR_COUNT=$((ERROR_COUNT + 1))
    return $ERR_GENERAL
}

# 初始化
setup_error_handling
