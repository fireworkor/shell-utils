#!/bin/bash

# =========================================
# 通用工具函数库 v2.0
# =========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

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
    
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        print_warning "网络连接不可用，部分功能可能受影响"
    fi
    
    local available=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
    if [ "$available" -lt 2 ]; then
        print_warning "磁盘空间不足 2GB，建议清理磁盘"
    fi
    
    local total_mem=$(free -m | awk 'NR==2 {print $2}')
    if [ "$total_mem" -lt 1024 ]; then
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
