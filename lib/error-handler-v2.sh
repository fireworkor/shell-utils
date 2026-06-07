#!/bin/bash
# 增强错误处理模块
# 提供统一的错误处理、日志记录和异常捕获功能

# 错误码定义
readonly E_SUCCESS=0
readonly E_GENERAL=1
readonly E_INVALID_ARGS=2
readonly E_NOT_ROOT=3
readonly E_UNSUPPORTED_OS=4
readonly E_NETWORK_ERROR=5
readonly E_INSTALL_FAILED=6
readonly E_SERVICE_FAILED=7
readonly E_FILE_NOT_FOUND=8
readonly E_PERMISSION_DENIED=9
readonly E_TIMEOUT=10
readonly E_LOCK_FAILED=11
readonly E_CONFIG_ERROR=12
readonly E_VALIDATION_ERROR=13
readonly E_DEPENDENCY_MISSING=14
readonly E_BACKUP_FAILED=15
readonly E_RESTORE_FAILED=16

# 错误信息映射
declare -A ERROR_MESSAGES=(
    [$E_SUCCESS]="成功"
    [$E_GENERAL]="一般错误"
    [$E_INVALID_ARGS]="无效的参数"
    [$E_NOT_ROOT]="需要 root 权限"
    [$E_UNSUPPORTED_OS]="不支持的操作系统"
    [$E_NETWORK_ERROR]="网络错误"
    [$E_INSTALL_FAILED]="安装失败"
    [$E_SERVICE_FAILED]="服务操作失败"
    [$E_FILE_NOT_FOUND]="文件未找到"
    [$E_PERMISSION_DENIED]="权限不足"
    [$E_TIMEOUT]="操作超时"
    [$E_LOCK_FAILED]="获取锁失败"
    [$E_CONFIG_ERROR]="配置错误"
    [$E_VALIDATION_ERROR]="验证失败"
    [$E_DEPENDENCY_MISSING]="缺少依赖"
    [$E_BACKUP_FAILED]="备份失败"
    [$E_RESTORE_FAILED]="恢复失败"
)

# 错误统计
ERROR_COUNT=0
WARNING_COUNT=0
ERROR_LOG_FILE=""

# 设置错误日志文件
set_error_log() {
    ERROR_LOG_FILE="${1:-/var/log/shell-utils/errors.log}"
    mkdir -p "$(dirname "$ERROR_LOG_FILE")" 2>/dev/null
}

# 记录错误到文件
log_error_to_file() {
    local error_msg="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ -n "$ERROR_LOG_FILE" ]; then
        echo "[$timestamp] ERROR: $error_msg" >> "$ERROR_LOG_FILE"
    fi
}

# 记录警告到文件
log_warning_to_file() {
    local warning_msg="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ -n "$ERROR_LOG_FILE" ]; then
        echo "[$timestamp] WARNING: $warning_msg" >> "$ERROR_LOG_FILE"
    fi
}

# 获取错误信息
get_error_message() {
    local error_code=$1
    echo "${ERROR_MESSAGES[$error_code]:-未知错误}"
}

# 打印错误
print_error() {
    local error_code=$1
    local message="${2:-}"
    local details="${3:-}"
    
    ERROR_COUNT=$((ERROR_COUNT + 1))
    
    echo -e "\033[0;31m✗ 错误 [$error_code]: $(get_error_message "$error_code")\033[0m" >&2
    
    if [ -n "$message" ]; then
        echo -e "  原因: $message" >&2
    fi
    
    if [ -n "$details" ]; then
        echo -e "  详情: $details" >&2
    fi
    
    log_error_to_file "[$error_code] $(get_error_message $error_code): $message $details"
}

# 打印警告
print_warning() {
    local message="$1"
    local details="${2:-}"
    
    WARNING_COUNT=$((WARNING_COUNT + 1))
    
    echo -e "\033[1;33m⚠ 警告: $message\033[0m" >&2
    
    if [ -n "$details" ]; then
        echo -e "  详情: $details" >&2
    fi
    
    log_warning_to_file "$message: $details"
}

# 打印成功信息
print_success() {
    local message="$1"
    echo -e "\033[0;32m✓ $message\033[0m"
}

# 打印信息
print_info() {
    local message="$1"
    echo -e "\033[0;34mℹ $message\033[0m"
}

# 错误处理函数
error_handler() {
    local exit_code=$?
    local line_number=$1
    local bash_lineno=$2
    local last_command=$3
    local func_stack=$4
    
    ERROR_COUNT=$((ERROR_COUNT + 1))
    
    echo -e "\033[0;31m" >&2
    echo "========================================" >&2
    echo "✗ 脚本执行错误" >&2
    echo "========================================" >&2
    echo "行号: $line_number" >&2
    echo "命令: $last_command" >&2
    echo "退出码: $exit_code" >&2
    
    if [ -n "$func_stack" ]; then
        echo "调用栈: $func_stack" >&2
    fi
    
    echo "时间: $(date '+%Y-%m-%d %H:%M:%S')" >&2
    echo "========================================" >&2
    echo -e "\033[0m" >&2
    
    log_error_to_file "Line $line_number: '$last_command' failed with exit code $exit_code"
    
    return $exit_code
}

# 错误恢复建议
get_recovery_suggestion() {
    local error_code=$1
    
    case $error_code in
        $E_NOT_ROOT)
            echo "请使用 sudo 或以 root 用户身份运行此脚本"
            ;;
        $E_NETWORK_ERROR)
            echo "请检查网络连接和 DNS 配置"
            ;;
        $E_INSTALL_FAILED)
            echo "请检查安装日志和依赖关系"
            ;;
        $E_SERVICE_FAILED)
            echo "请检查服务状态和日志"
            ;;
        $E_FILE_NOT_FOUND)
            echo "请检查文件路径是否正确"
            ;;
        $E_PERMISSION_DENIED)
            echo "请检查文件权限或使用 sudo"
            ;;
        $E_TIMEOUT)
            echo "请增加超时时间或检查系统负载"
            ;;
        $E_LOCK_FAILED)
            echo "请检查是否有其他进程正在运行"
            ;;
        $E_CONFIG_ERROR)
            echo "请检查配置文件格式和内容"
            ;;
        $E_DEPENDENCY_MISSING)
            echo "请安装缺失的依赖包"
            ;;
        *)
            echo "请查看详细错误日志获取更多信息"
            ;;
    esac
}

# 带建议的错误输出
print_error_with_suggestion() {
    local error_code=$1
    local message="${2:-}"
    local details="${3:-}"
    
    print_error "$error_code" "$message" "$details"
    echo ""
    echo -e "\033[1;36m建议:\033[0m $(get_recovery_suggestion "$error_code")"
}

# 验证函数参数
validate_arg() {
    local arg_name="$1"
    local arg_value="$2"
    local required="${3:-true}"
    
    if [ "$required" == "true" ] && [ -z "$arg_value" ]; then
        print_error_with_suggestion $E_INVALID_ARGS "参数 '$arg_name' 不能为空"
        return 1
    fi
    
    return 0
}

# 验证文件存在
validate_file() {
    local file_path="$1"
    local description="${2:-文件}"
    
    if [ ! -f "$file_path" ]; then
        print_error_with_suggestion $E_FILE_NOT_FOUND "$description 不存在" "路径: $file_path"
        return 1
    fi
    
    if [ ! -r "$file_path" ]; then
        print_error_with_suggestion $E_PERMISSION_DENIED "$description 不可读" "路径: $file_path"
        return 1
    fi
    
    return 0
}

# 验证目录存在
validate_directory() {
    local dir_path="$1"
    local description="${2:-目录}"
    local create_if_missing="${3:-false}"
    
    if [ ! -d "$dir_path" ]; then
        if [ "$create_if_missing" == "true" ]; then
            if mkdir -p "$dir_path" 2>/dev/null; then
                print_info "已创建目录: $dir_path"
                return 0
            else
                print_error_with_suggestion $E_PERMISSION_DENIED "无法创建目录" "路径: $dir_path"
                return 1
            fi
        else
            print_error_with_suggestion $E_FILE_NOT_FOUND "$description 不存在" "路径: $dir_path"
            return 1
        fi
    fi
    
    return 0
}

# 验证命令存在
validate_command() {
    local cmd="$1"
    local package="${2:-$cmd}"
    
    if ! command -v "$cmd" &>/dev/null; then
        print_error_with_suggestion $E_DEPENDENCY_MISSING "命令 '$cmd' 未找到" "请安装: $package"
        return 1
    fi
    
    return 0
}

# 验证 root 权限
validate_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error_with_suggestion $E_NOT_ROOT "需要 root 权限运行此脚本"
        return 1
    fi
    
    return 0
}

# 错误统计摘要
error_summary() {
    echo ""
    echo "========================================"
    echo "  错误统计摘要"
    echo "========================================"
    echo "错误数量: $ERROR_COUNT"
    echo "警告数量: $WARNING_COUNT"
    echo "========================================"
    
    if [ -n "$ERROR_LOG_FILE" ] && [ -f "$ERROR_LOG_FILE" ]; then
        echo ""
        echo "错误日志: $ERROR_LOG_FILE"
    fi
}

# 重置错误计数
reset_error_count() {
    ERROR_COUNT=0
    WARNING_COUNT=0
}

# 设置错误捕获
enable_error_trapping() {
    set -E
    trap 'error_handler $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR
}

# 禁用错误捕获
disable_error_trapping() {
    trap - ERR
}

# 清理函数
cleanup_on_exit() {
    local exit_code=$?
    
    if [ $exit_code -ne 0 ] && [ $ERROR_COUNT -gt 0 ]; then
        error_summary
    fi
    
    return $exit_code
}

# 设置退出清理
setup_exit_cleanup() {
    trap 'cleanup_on_exit' EXIT
}
