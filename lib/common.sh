#!/bin/bash

# =========================================
# 通用工具函数库
# =========================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 检测操作系统
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

# 获取包管理器
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

# 检查 root 权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}错误：请使用 root 用户运行此脚本${NC}"
        echo "使用方法: sudo $0"
        exit 1
    fi
}

# 检查操作系统
check_os() {
    detect_os
    if [ "$OS" = "unknown" ]; then
        echo -e "${RED}错误：不支持的操作系统${NC}"
        exit 1
    fi
    echo -e "${GREEN}检测到操作系统：${OS} ${VER}${NC}"
}

# 安装基础依赖
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

# 配置防火墙
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

# 启动服务
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

# 打印成功消息
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# 打印错误消息
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# 打印信息消息
print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# 打印警告消息
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}
