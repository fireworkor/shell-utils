#!/bin/bash

# Shell 工具函数集合
# 提供常用的实用函数

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 2. 文件操作函数
create_backup() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup
        backup="${file}.$(date '+%Y%m%d_%H%M%S').bak"
        cp "$file" "$backup"
        log_success "已创建备份: $backup"
        echo "$backup"
    else
        log_error "文件不存在: $file"
        return 1
    fi
}

# 3. 系统信息函数
show_system_info() {
    log_info "系统信息:"
    echo "  主机名: $(hostname)"
    echo "  操作系统: $(uname -s)"
    echo "  内核版本: $(uname -r)"
    echo "  架构: $(uname -m)"
    echo "  当前用户: $(whoami)"
    echo "  当前目录: $(pwd)"
}

# 4. 网络函数
check_internet() {
    if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
        log_success "网络连接正常"
        return 0
    else
        log_error "网络连接失败"
        return 1
    fi
}

# 5. 进度条函数
show_progress() {
    local current="$1"
    local total="$2"
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))
    
    printf "\r["
    printf "%${completed}s" | tr ' ' '='
    printf "%${remaining}s" | tr ' ' ' '
    printf "] %d%%" "$percentage"
    
    if [ "$current" -eq "$total" ]; then
        echo
    fi
}

# 6. 目录统计函数
count_files() {
    local dir="${1:-.}"
    if [ -d "$dir" ]; then
        local file_count dir_count
        file_count=$(find "$dir" -type f | wc -l)
        dir_count=$(find "$dir" -type d | wc -l)
        log_info "目录统计 ($dir):"
        echo "  文件数: $file_count"
        echo "  目录数: $dir_count"
    else
        log_error "目录不存在: $dir"
        return 1
    fi
}

# 7. 字符串处理函数
to_uppercase() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

to_lowercase() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

trim() {
    local var="$1"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

# 8. 时间函数
wait_seconds() {
    local seconds="$1"
    log_info "等待 ${seconds} 秒..."
    for ((i=1; i<=seconds; i++)); do
        show_progress "$i" "$seconds"
        sleep 1
    done
}

# 9. 检查命令是否存在
command_exists() {
    if command -v "$1" >/dev/null 2>&1; then
        log_success "命令 '$1' 已安装"
        return 0
    else
        log_error "命令 '$1' 未安装"
        return 1
    fi
}

# 10. 压缩和解压函数
compress_dir() {
    local dir="$1"
    local output="${2:-${dir}.tar.gz}"
    if [ -d "$dir" ]; then
        tar -czf "$output" "$dir"
        log_success "已压缩目录 $dir 到 $output"
    else
        log_error "目录不存在: $dir"
        return 1
    fi
}

extract_file() {
    local file="$1"
    if [ -f "$file" ]; then
        case "$file" in
            *.tar.gz|*.tgz)
                tar -xzf "$file"
                ;;
            *.zip)
                unzip "$file"
                ;;
            *.tar.bz2)
                tar -xjf "$file"
                ;;
            *)
                log_error "不支持的文件格式: $file"
                return 1
                ;;
        esac
        log_success "已解压文件: $file"
    else
        log_error "文件不存在: $file"
        return 1
    fi
}

# 11. 磁盘使用检查
check_disk_usage() {
    local threshold="${1:-90}"
    log_info "检查磁盘使用情况 (阈值: ${threshold}%):"
    df -h | awk -v threshold="$threshold" 'NR==1; /^\/dev\// {print $0}' | while read -r line; do
        if echo "$line" | grep -q -E '([0-9]+)%'; then
            local usage
            usage=$(echo "$line" | grep -oE '[0-9]+%' | tr -d '%')
            if [ "$usage" -ge "$threshold" ]; then
                log_warning "$line"
            else
                echo "  $line"
            fi
        fi
    done
}

# 12. 查找大文件
find_large_files() {
    local dir="${1:-.}"
    local size="${2:-100M}"
    log_info "在 $dir 中查找大于 $size 的文件:"
    find "$dir" -type f -size "+$size" -exec ls -lh {} \; 2>/dev/null
}

# 使用说明
usage() {
    echo "Shell 工具函数集合"
    echo
    echo "用法: source $0 或 . $0"
    echo
    echo "可用函数:"
    echo "  log_info, log_success, log_warning, log_error - 日志函数"
    echo "  create_backup <file> - 创建文件备份"
    echo "  show_system_info - 显示系统信息"
    echo "  check_internet - 检查网络连接"
    echo "  show_progress <current> <total> - 显示进度条"
    echo "  count_files [dir] - 统计目录文件数"
    echo "  to_uppercase <string>, to_lowercase <string> - 字符串转换"
    echo "  trim <string> - 去除字符串首尾空格"
    echo "  wait_seconds <seconds> - 等待指定秒数"
    echo "  command_exists <command> - 检查命令是否存在"
    echo "  compress_dir <dir> [output] - 压缩目录"
    echo "  extract_file <file> - 解压文件"
    echo "  check_disk_usage [threshold] - 检查磁盘使用"
    echo "  find_large_files [dir] [size] - 查找大文件"
}

# 如果直接执行脚本，显示使用说明
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    usage
fi
