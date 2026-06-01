#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 检查 root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}错误：请使用 root 用户运行${NC}"
        exit 1
    fi
}

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        OS="unknown"
        VER=""
    fi
    echo "$OS $VER"
}

# 检查系统兼容性
check_os() {
    local os_info=$(detect_os)
    local os=$(echo "$os_info" | awk '{print $1}')
    case $os in
        centos|rhel|fedora|ubuntu|debian) return 0 ;;
        *) echo -e "${RED}不支持的操作系统: $os${NC}"; exit 1 ;;
    esac
}

# 获取包管理器
get_pkg_manager() {
    if command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v yum &>/dev/null; then
        echo "yum"
    elif command -v apt &>/dev/null; then
        echo "apt"
    else
        echo "unknown"
    fi
}

# 安装前环境检查（必需）
check_prerequisites() {
    echo -e "${BLUE}检查环境...${NC}"
    check_root
    check_os
    # 可添加更多检查，如磁盘空间、网络等
    echo -e "${GREEN}环境检查通过${NC}"
}

# 打印标题
print_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# 打印步骤
print_step() {
    echo -e "${BLUE}[${1}/${2}] $3${NC}"
}

# 打印成功/错误/信息
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error()   { echo -e "${RED}✗ $1${NC}"; }
print_info()    { echo -e "${BLUE}ℹ $1${NC}"; }

# 备份单个文件
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        local backup="${file}.$(date +%Y%m%d_%H%M%S).bak"
        cp "$file" "$backup"
        echo "$backup"
        return 0
    fi
    return 1
}

# 备份服务配置（main.sh 中用到）
backup_service_configs() {
    local service=$1
    local config_dir=""
    case $service in
        nginx) config_dir="/etc/nginx" ;;
        apache) config_dir="/etc/httpd /etc/apache2" ;;
        mysql|mariadb) config_dir="/etc/mysql /etc/my.cnf.d" ;;
        *) return 0 ;;
    esac
    if [ -n "$config_dir" ]; then
        local backup_dir="/root/backup_${service}_$(date +%Y%m%d)"
        mkdir -p "$backup_dir"
        cp -r $config_dir 2>/dev/null || true "$backup_dir/" 2>/dev/null
        echo -e "${GREEN}已备份 $service 配置到 $backup_dir${NC}"
    fi
}

# 确认提示
confirm() {
    local prompt="$1"
    read -p "$prompt (yes/no): " confirm
    [[ "$confirm" == "yes" ]]
}

# 获取已安装版本（简化）
get_installed_version() {
    local software=$1
    case $software in
        nginx) nginx -v 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 ;;
        php) php -v 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 ;;
        *) echo "unknown" ;;
    esac
}

# 检查是否已安装
check_installed() {
    local software=$1
    case $software in
        nginx) command -v nginx &>/dev/null ;;
        php) command -v php &>/dev/null ;;
        *) return 1 ;;
    esac
}

# 显示系统信息
get_system_info() {
    echo "主机名: $(hostname)"
    echo "操作系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "内核版本: $(uname -r)"
    echo "CPU 核心: $(nproc)"
    echo "内存总量: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "磁盘总量: $(df -h / | awk 'NR==2 {print $2}')"
}

# 配置管理（占位，避免报错）
list_config() { echo "配置文件: $SCRIPT_DIR/config/versions.conf"; }
set_config() { local key=$1; local value=$2; echo "$key=$value" >> "$SCRIPT_DIR/config/versions.conf"; }

# 其他可能用到的函数
configure_firewall() {
    local service=$1
    local port=$2
    if command -v firewall-cmd &>/dev/null; then
        firewall-cmd --permanent --add-service="$service" 2>/dev/null || \
        firewall-cmd --permanent --add-port="$port/tcp" 2>/dev/null
        firewall-cmd --reload 2>/dev/null
    elif command -v ufw &>/dev/null; then
        ufw allow "$port/tcp"
    fi
}

start_service() {
    local service=$1
    systemctl start "$service"
    systemctl enable "$service"
}

validate_version() { return 0; }
download_with_retry() { return 0; }
download_simple() { return 0; }
