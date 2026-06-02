#!/bin/bash

# =========================================
# 通用工具函数库 v3.0
# 增强健壮性版本
# =========================================

# 严格模式
set -o pipefail

# 全局变量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 错误码定义
readonly E_SUCCESS=0
readonly E_INVALID_ARGS=1
readonly E_NOT_ROOT=2
readonly E_UNSUPPORTED_OS=3
readonly E_NETWORK_ERROR=4
readonly E_INSTALL_FAILED=5
readonly E_SERVICE_FAILED=6
readonly E_FILE_NOT_FOUND=7
readonly E_PERMISSION_DENIED=8
readonly E_TIMEOUT=9
readonly E_LOCK_FAILED=10

# 日志文件
LOG_FILE="${LOG_FILE:-/var/log/shell-utils.log}"
LOG_MAX_SIZE="${LOG_MAX_SIZE:-10485760}"  # 10MB

# 锁文件目录
LOCK_DIR="/var/run/shell-utils"
CURRENT_LOCK_FILE=""

# =========================================
# 初始化函数
# =========================================

init_script() {
    # 创建必要的目录
    mkdir -p "$LOCK_DIR" 2>/dev/null || true
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    
    # 设置错误陷阱
    trap 'error_handler $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR
    trap 'cleanup_handler' EXIT
    trap 'interrupt_handler' INT TERM HUP
}

# =========================================
# 错误处理函数
# =========================================

error_handler() {
    local exit_code=$1
    local line_no=$2
    local bash_lineno=$3
    local last_command=$4
    local func_trace=$5
    
    if [ $exit_code -ne 0 ]; then
        log_error "错误: 脚本在行 $line_no 失败"
        log_error "命令: $last_command"
        log_error "退出码: $exit_code"
        if [ -n "$func_trace" ]; then
            log_error "函数调用栈: $func_trace"
        fi
    fi
}

cleanup_handler() {
    local exit_code=$?
    
    # 释放锁文件
    release_lock
    
    # 清理临时文件
    cleanup_temp_files
    
    exit $exit_code
}

interrupt_handler() {
    echo -e "\n${YELLOW}收到中断信号，正在清理...${NC}"
    cleanup_handler
    exit 130
}

# =========================================
# 锁文件机制
# =========================================

acquire_lock() {
    local lock_name=${1:-"shell-utils"}
    local timeout=${2:-30}
    local lock_file="$LOCK_DIR/${lock_name}.lock"
    
    mkdir -p "$LOCK_DIR" 2>/dev/null || true
    
    local count=0
    while [ $count -lt $timeout ]; do
        if (set -C; echo $$ > "$lock_file") 2>/dev/null; then
            CURRENT_LOCK_FILE="$lock_file"
            trap 'release_lock' EXIT
            return 0
        fi
        
        # 检查锁文件是否过期（超过1小时）
        if [ -f "$lock_file" ]; then
            local lock_pid=$(cat "$lock_file" 2>/dev/null)
            local lock_age=$(( $(date +%s) - $(stat -c %Y "$lock_file" 2>/dev/null || echo 0) ))
            
            if [ $lock_age -gt 3600 ]; then
                log_warning "锁文件已过期，正在移除"
                rm -f "$lock_file"
                continue
            fi
            
            # 检查进程是否存在
            if ! kill -0 "$lock_pid" 2>/dev/null; then
                log_warning "锁文件进程不存在，正在移除"
                rm -f "$lock_file"
                continue
            fi
        fi
        
        sleep 1
        count=$((count + 1))
    done
    
    log_error "获取锁文件超时: $lock_file"
    return $E_LOCK_FAILED
}

release_lock() {
    if [ -n "$CURRENT_LOCK_FILE" ] && [ -f "$CURRENT_LOCK_FILE" ]; then
        local lock_pid=$(cat "$CURRENT_LOCK_FILE" 2>/dev/null)
        if [ "$lock_pid" = "$$" ]; then
            rm -f "$CURRENT_LOCK_FILE"
        fi
        CURRENT_LOCK_FILE=""
    fi
}

# =========================================
# 日志函数
# =========================================

_log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_line="[$timestamp] [$level] $message"
    
    # 输出到文件
    if [ -w "$(dirname "$LOG_FILE")" ] || [ -w "$LOG_FILE" ]; then
        echo "$log_line" >> "$LOG_FILE"
        
        # 日志轮转
        if [ -f "$LOG_FILE" ] && [ $(stat -c %s "$LOG_FILE" 2>/dev/null || echo 0) -gt $LOG_MAX_SIZE ]; then
            mv "$LOG_FILE" "${LOG_FILE}.old"
            gzip "${LOG_FILE}.old" 2>/dev/null &
        fi
    fi
}

log_info() {
    _log "INFO" "$@"
}

log_error() {
    _log "ERROR" "$@"
}

log_warning() {
    _log "WARN" "$@"
}

log_debug() {
    if [ "${DEBUG:-}" = "true" ]; then
        _log "DEBUG" "$@"
    fi
}

show_log() {
    local lines=${1:-50}
    if [ -f "$LOG_FILE" ]; then
        tail -n "$lines" "$LOG_FILE"
    else
        echo "日志文件不存在: $LOG_FILE"
    fi
}

# =========================================
# 临时文件管理
# =========================================

TEMP_FILES=()

create_temp_file() {
    local prefix=${1:-"shell-utils"}
    local temp_file=$(mktemp "/tmp/${prefix}.XXXXXX")
    TEMP_FILES+=("$temp_file")
    echo "$temp_file"
}

cleanup_temp_files() {
    for file in "${TEMP_FILES[@]}"; do
        [ -f "$file" ] && rm -f "$file"
    done
    TEMP_FILES=()
}

# =========================================
# 重试机制
# =========================================

retry_command() {
    local max_attempts=${1:-3}
    local delay=${2:-2}
    shift 2
    local cmd="$@"
    
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        log_debug "执行命令 (尝试 $attempt/$max_attempts): $cmd"
        
        if eval "$cmd"; then
            return 0
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            log_warning "命令执行失败，${delay}秒后重试..."
            sleep $delay
        fi
        
        attempt=$((attempt + 1))
    done
    
    log_error "命令执行失败，已重试 $max_attempts 次: $cmd"
    return 1
}

# =========================================
# 超时控制
# =========================================

run_with_timeout() {
    local timeout=$1
    shift
    local cmd="$@"
    
    if command -v timeout &>/dev/null; then
        timeout "$timeout" $cmd
        local status=$?
        if [ $status -eq 124 ]; then
            log_error "命令执行超时 (${timeout}秒): $cmd"
            return $E_TIMEOUT
        fi
        return $status
    else
        # 如果没有 timeout 命令，直接执行
        $cmd
    fi
}

# =========================================
# 系统检测函数
# =========================================

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        export OS=$ID
        export VER=$VERSION_ID
    elif [ -f /etc/centos-release ]; then
        export OS="centos"
        export VER=$(cat /etc/centos-release | grep -oE '[0-9]+' | head -1)
    else
        export OS="unknown"
        export VER=""
    fi
}

get_pkg_manager() {
    case $OS in
        centos)
            if [ "$VER" = "8" ]; then
                echo "dnf"
            else
                echo "yum"
            fi
            ;;
        ubuntu|debian)
            echo "apt"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}错误：请使用 root 用户运行此脚本${NC}"
        echo "使用方法: sudo $0"
        exit 1
    fi
}

check_os() {
    detect_os
    if [ "$OS" = "unknown" ]; then
        echo -e "${RED}错误：不支持的操作系统${NC}"
        exit 1
    fi
    echo -e "${GREEN}检测到操作系统：${OS} ${VER}${NC}"
}

install_dependencies() {
    local pkg_manager=$(get_pkg_manager)
    echo -e "${BLUE}安装基础依赖...${NC}"
    
    case $pkg_manager in
        dnf|yum)
            yum install -y epel-release ca-certificates gnupg wget curl
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y ca-certificates gnupg wget curl
            ;;
    esac
    
    echo -e "${GREEN}✓ 基础依赖安装完成${NC}"
}

configure_firewall() {
    local port=$1
    local service=${2:-$port/tcp}
    
    echo -e "${BLUE}配置防火墙：开放端口 $service${NC}"
    
    case $OS in
        centos)
            if systemctl is-active firewalld &>/dev/null; then
                firewall-cmd --permanent --add-port=$service > /dev/null 2>&1 || true
                firewall-cmd --reload > /dev/null 2>&1 || true
            fi
            ;;
        ubuntu|debian)
            if command -v ufw &>/dev/null; then
                ufw allow $service > /dev/null 2>&1 || true
            fi
            ;;
    esac
    
    echo -e "${GREEN}✓ 防火墙配置完成${NC}"
}

start_service() {
    local service=$1
    local enable=${2:-true}
    
    echo -e "${BLUE}启动服务：$service${NC}"
    systemctl start $service
    if [ "$enable" = "true" ]; then
        systemctl enable $service
    fi
    
    if systemctl is-active $service &>/dev/null; then
        echo -e "${GREEN}✓ 服务 $service 已启动${NC}"
    else
        echo -e "${RED}✗ 服务 $service 启动失败${NC}"
    fi
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_header() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}\n"
}

print_step() {
    local current=$1
    local total=$2
    local message=$3
    echo -e "${YELLOW}[$current/$total]${NC} $message"
}

# =========================================
# 安全性检查函数
# =========================================

check_prerequisites() {
    print_info "检查系统环境..."
    
    # 网络检查 - 更稳健的方法
    local has_network=false
    if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        has_network=true
    elif ping -c 1 -W 2 1.1.1.1 &>/dev/null; then
        has_network=true
    elif curl -s --connect-timeout 2 https://www.baidu.com &>/dev/null; then
        has_network=true
    fi
    
    if [ "$has_network" = false ]; then
        print_warning "网络连接不可用，部分功能可能受影响"
    fi
    
    # 磁盘空间检查 - 兼容性更好
    local available=$(df -BM / | tail -1 | awk '{print $4}' | sed 's/M//')
    if [ -z "$available" ] || [ "$available" -lt 2048 ]; then
        print_warning "磁盘空间不足 2GB，建议清理磁盘"
    fi
    
    # 内存检查 - 兼容性更好
    local total_mem=""
    if [ -f /proc/meminfo ]; then
        total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}' | awk '{printf "%.0f", $1/1024}')
    else
        total_mem=$(free -m 2>/dev/null | awk 'NR==2 {print $2}' || echo 1024)
    fi
    
    if [ -z "$total_mem" ] || [ "$total_mem" -lt 1024 ]; then
        print_warning "内存不足 1GB，部分软件可能运行不稳定"
    fi
    
    print_success "系统环境检查完成"
}

# =========================================
# 备份函数
# =========================================

backup_file() {
    local file=$1
    local backup_dir=${2:-"/var/backups/shell-utils"}
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    mkdir -p "$backup_dir"
    local filename=$(basename "$file")
    local backup_file="${backup_dir}/${filename}.backup.$(date +%Y%m%d%H%M%S)"
    
    cp "$file" "$backup_file"
    print_info "已备份 $file -> $backup_file"
    echo "$backup_file"
}

backup_service_configs() {
    local service=$1
    local backup_dir="/var/backups/shell-utils/${service}"
    
    mkdir -p "$backup_dir"
    
    case $service in
        nginx)
            [ -f /etc/nginx/nginx.conf ] && cp /etc/nginx/nginx.conf "$backup_dir/"
            ;;
        apache)
            [ -f /etc/httpd/conf/httpd.conf ] && cp /etc/httpd/conf/httpd.conf "$backup_dir/"
            [ -f /etc/apache2/apache2.conf ] && cp /etc/apache2/apache2.conf "$backup_dir/"
            ;;
        mysql|mariadb)
            [ -f /etc/my.cnf ] && cp /etc/my.cnf "$backup_dir/"
            [ -f /etc/mysql/my.cnf ] && cp /etc/mysql/my.cnf "$backup_dir/"
            ;;
    esac
    
    print_info "$service 配置已备份到 $backup_dir"
}

# =========================================
# 验证函数
# =========================================

validate_version() {
    local version=$1
    local pattern=$2
    
    if [ -z "$version" ]; then
        return 1
    fi
    
    if [ -n "$pattern" ]; then
        if [[ $version =~ $pattern ]]; then
            return 0
        else
            print_error "无效的版本号格式: $version"
            return 1
        fi
    fi
    
    return 0
}

validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_domain() {
    local domain=$1
    if [[ $domain =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# =========================================
# 下载函数
# =========================================

download_with_retry() {
    local url=$1
    local output=$2
    local max_attempts=${3:-3}
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        print_info "下载尝试 $attempt/$max_attempts: $url"
        
        if wget -q --show-progress -O "$output" "$url" 2>&1; then
            print_success "下载完成"
            return 0
        fi
        
        attempt=$((attempt + 1))
        if [ $attempt -le $max_attempts ]; then
            print_warning "下载失败，3秒后重试..."
            sleep 3
        fi
    done
    
    print_error "下载失败: $url"
    return 1
}

download_simple() {
    local url=$1
    local output=$2
    
    if wget -q -O "$output" "$url"; then
        return 0
    else
        print_error "下载失败: $url"
        return 1
    fi
}

# =========================================
# 版本检测函数
# =========================================

get_installed_version() {
    local software=$1
    
    case $software in
        nginx)
            nginx -v 2>&1 | grep -oE '[0-9]+\.[0-9]+'
            ;;
        apache|httpd)
            httpd -v 2>&1 | grep -oE 'Apache/[0-9]+\.[0-9]+' | cut -d'/' -f2
            ;;
        php)
            php -v 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+'
            ;;
        python)
            python3 --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' || python --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+'
            ;;
        nodejs|node)
            node -v 2>/dev/null | sed 's/v//'
            ;;
        mysql)
            mysql --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+'
            ;;
        mariadb)
            mariadb --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+'
            ;;
        postgresql|postgres)
            psql --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+'
            ;;
        redis-server|redis)
            redis-server --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+'
            ;;
        java)
            java -version 2>&1 | head -1 | grep -oE '[0-9]+(\.[0-9]+)+'
            ;;
        go)
            go version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+'
            ;;
        docker)
            docker --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+'
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

check_installed() {
    local software=$1
    
    if command -v $software &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# =========================================
# 用户交互函数
# =========================================

confirm() {
    local prompt=$1
    local default=${2:-"n"}
    
    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    read -p "$prompt" response
    response=${response:-$default}
    
    if [[ $response =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

select_option() {
    local prompt=$1
    shift
    local options=("$@")
    local num=${#options[@]}
    
    echo "$prompt"
    for i in "${!options[@]}"; do
        echo "$((i+1))) ${options[$i]}"
    done
    
    read -p "请选择 (1-$num): " choice
    if [[ $choice =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$num" ]; then
        echo "${options[$((choice-1))]}"
        return 0
    else
        return 1
    fi
}

# =========================================
# 系统信息函数
# =========================================

get_system_info() {
    detect_os
    
    echo "操作系统: $OS $VER"
    echo "内核版本: $(uname -r)"
    echo "架构: $(uname -m)"
    echo "主机名: $(hostname)"
    echo "运行时间: $(uptime -p 2>/dev/null || uptime)"
    echo ""
    echo "CPU: $(nproc) 核心"
    echo "内存: $(free -h | awk 'NR==2 {print $2}')"
    echo "磁盘: $(df -h / | tail -1 | awk '{print $2}')"
}

# =========================================
# 清理函数
# =========================================

cleanup_tmp() {
    local pattern=$1
    rm -rf /tmp/$pattern* 2>/dev/null || true
}

cleanup_old_kernels() {
    if [ "$OS" = "centos" ]; then
        package-cleanup -y --oldkernels --count=1 2>/dev/null || true
    elif [ "$OS" = "ubuntu" ]; then
        apt autoremove -y 2>/dev/null || true
    fi
}

# =========================================
# 参数验证函数
# =========================================

validate_required_args() {
    local args=("$@")
    local missing=()
    
    for arg in "${args[@]}"; do
        if [ -z "${!arg}" ]; then
            missing+=("$arg")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_error "缺少必要参数: ${missing[*]}"
        return 1
    fi
    
    return 0
}

validate_file_exists() {
    local file=$1
    local description=${2:-"文件"}
    
    if [ ! -f "$file" ]; then
        print_error "$description 不存在: $file"
        return $E_FILE_NOT_FOUND
    fi
    
    return 0
}

validate_dir_exists() {
    local dir=$1
    local description=${2:-"目录"}
    
    if [ ! -d "$dir" ]; then
        print_error "$description 不存在: $dir"
        return $E_FILE_NOT_FOUND
    fi
    
    return 0
}

validate_file_writable() {
    local file=$1
    
    if [ -f "$file" ] && [ ! -w "$file" ]; then
        print_error "文件不可写: $file"
        return $E_PERMISSION_DENIED
    fi
    
    local dir=$(dirname "$file")
    if [ ! -w "$dir" ]; then
        print_error "目录不可写: $dir"
        return $E_PERMISSION_DENIED
    fi
    
    return 0
}

# =========================================
# 网络检查函数
# =========================================

check_network() {
    local timeout=${1:-5}
    local hosts=("8.8.8.8" "1.1.1.1" "114.114.114.114")
    
    for host in "${hosts[@]}"; do
        if ping -c 1 -W $timeout $host &>/dev/null; then
            return 0
        fi
    done
    
    print_warning "网络连接不可用"
    return $E_NETWORK_ERROR
}

check_url_accessible() {
    local url=$1
    local timeout=${2:-10}
    
    if command -v curl &>/dev/null; then
        if curl -sSf --connect-timeout $timeout "$url" &>/dev/null; then
            return 0
        fi
    elif command -v wget &>/dev/null; then
        if wget -q --timeout=$timeout --spider "$url" 2>/dev/null; then
            return 0
        fi
    fi
    
    return $E_NETWORK_ERROR
}

# =========================================
# 进程管理函数
# =========================================

is_process_running() {
    local pid=$1
    
    if kill -0 "$pid" 2>/dev/null; then
        return 0
    fi
    
    return 1
}

wait_for_process() {
    local pid=$1
    local timeout=${2:-60}
    local count=0
    
    while [ $count -lt $timeout ]; do
        if ! is_process_running "$pid"; then
            return 0
        fi
        
        sleep 1
        count=$((count + 1))
    done
    
    print_warning "等待进程超时: PID $pid"
    return $E_TIMEOUT
}

kill_process_tree() {
    local pid=$1
    local signal=${2:-TERM}
    
    # 递归杀死子进程
    local children=$(pgrep -P "$pid" 2>/dev/null)
    for child in $children; do
        kill_process_tree "$child" "$signal"
    done
    
    kill -$signal "$pid" 2>/dev/null
}

# =========================================
# 安全执行函数
# =========================================

safe_execute() {
    local description=$1
    shift
    local cmd="$@"
    
    print_info "$description..."
    
    if $cmd; then
        print_success "$description 成功"
        return 0
    else
        print_error "$description 失败"
        return 1
    fi
}

execute_with_rollback() {
    local description=$1
    local execute_cmd=$2
    local rollback_cmd=$3
    
    print_info "$description..."
    
    if eval "$execute_cmd"; then
        print_success "$description 成功"
        return 0
    else
        print_warning "$description 失败，执行回滚..."
        if [ -n "$rollback_cmd" ]; then
            eval "$rollback_cmd"
        fi
        return 1
    fi
}

# =========================================
# 资源检查函数
# =========================================

check_disk_space() {
    local path=${1:-"/"}
    local required_mb=${2:-1024}
    
    local available=$(df -BM "$path" | tail -1 | awk '{print $4}' | sed 's/M//')
    
    if [ "$available" -lt "$required_mb" ]; then
        print_warning "磁盘空间不足: 需要 ${required_mb}MB，可用 ${available}MB"
        return 1
    fi
    
    return 0
}

check_memory() {
    local required_mb=${1:-512}
    
    local available=$(free -m | awk 'NR==2 {print $7}')
    
    if [ "$available" -lt "$required_mb" ]; then
        print_warning "内存不足: 需要 ${required_mb}MB，可用 ${available}MB"
        return 1
    fi
    
    return 0
}

check_cpu_load() {
    local max_load=${1:-$(nproc)}
    
    local current_load=$(awk '{print $1}' /proc/loadavg | cut -d. -f1)
    
    if [ "$current_load" -gt "$max_load" ]; then
        print_warning "CPU 负载过高: 当前 $current_load，阈值 $max_load"
        return 1
    fi
    
    return 0
}

# =========================================
# 配置文件安全操作
# =========================================

safe_append_to_file() {
    local content=$1
    local file=$2
    local marker=${3:-"# shell-utils added"}
    
    # 检查是否已存在
    if grep -qF "$marker" "$file" 2>/dev/null; then
        print_info "配置已存在，跳过"
        return 0
    fi
    
    # 备份原文件
    backup_file "$file"
    
    # 追加内容
    echo "" >> "$file"
    echo "$marker" >> "$file"
    echo "$content" >> "$file"
    
    print_success "配置已添加到 $file"
}

safe_remove_from_file() {
    local marker=$1
    local file=$2
    
    if [ ! -f "$file" ]; then
        return 0
    fi
    
    # 备份原文件
    backup_file "$file"
    
    # 删除标记之间的内容
    sed -i "/$marker/,/$marker/d" "$file" 2>/dev/null || true
    
    print_success "配置已从 $file 移除"
}

# =========================================
# 健壮的包安装函数
# =========================================

robust_install() {
    local packages=("$@")
    local pkg_manager=$(get_pkg_manager)
    local max_retries=3
    
    check_network || return $E_NETWORK_ERROR
    
    for attempt in $(seq 1 $max_retries); do
        case $pkg_manager in
            dnf|yum)
                if $pkg_manager install -y "${packages[@]}"; then
                    return 0
                fi
                ;;
            apt)
                export DEBIAN_FRONTEND=noninteractive
                apt update
                if apt install -y "${packages[@]}"; then
                    return 0
                fi
                ;;
        esac
        
        if [ $attempt -lt $max_retries ]; then
            print_warning "安装失败，重试 $attempt/$max_retries..."
            sleep 5
        fi
    done
    
    print_error "安装失败: ${packages[*]}"
    return $E_INSTALL_FAILED
}

# =========================================
# 初始化脚本模板
# =========================================

# 使用方法: 在脚本开头调用此函数
# init_script_env "script-name"
init_script_env() {
    local script_name=${1:-"shell-utils"}
    
    # 初始化脚本
    init_script
    
    # 获取锁
    acquire_lock "$script_name" || exit $E_LOCK_FAILED
    
    # 检测系统
    detect_os
    
    # 记录开始
    log_info "脚本开始执行: $script_name (PID: $$)"
}
