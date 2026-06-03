#!/bin/bash
# Nginx 插件安装脚本
# 使用插件系统安装 Nginx

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_NAME="nginx"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 插件安装入口
plugin_install_main() {
    local version="${1:-}"
    local nginx_version="${version:-latest}"

    log_info "开始安装 Nginx${version:+ ($version)}..."

    # 获取系统信息
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        log_error "无法确定操作系统类型"
        return 1
    fi

    log_info "检测到操作系统: $OS $VER"

    # 检查是否已安装
    if command -v nginx &>/dev/null; then
        local current_version=$(nginx -v 2>&1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
        log_warning "Nginx 已安装 (版本: $current_version)"
        log_info "跳过安装步骤"
        return 0
    fi

    # 安装依赖
    log_info "安装依赖包..."
    case $OS in
        centos)
            yum install -y yum-utils
            ;;
        ubuntu)
            apt-get update
            apt-get install -y curl gnupg2 ca-certificates lsb-release
            ;;
        *)
            log_error "不支持的操作系统: $OS"
            return 1
            ;;
    esac

    # 添加 Nginx 官方仓库
    log_info "添加 Nginx 官方仓库..."
    case $OS in
        centos)
            cat > /etc/yum.repos.d/nginx.repo <<EOF
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF
            ;;
        ubuntu)
            curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add - > /dev/null
            echo "deb http://nginx.org/packages/ubuntu/ $(lsb_release -cs) nginx" > /etc/apt/sources.list.d/nginx.list
            ;;
    esac

    # 安装 Nginx
    log_info "安装 Nginx${nginx_version:+ ($nginx_version)}..."
    case $OS in
        centos)
            yum install -y nginx
            ;;
        ubuntu)
            apt-get update
            apt-get install -y nginx
            ;;
    esac

    # 验证安装
    if command -v nginx &>/dev/null; then
        local installed_version=$(nginx -v 2>&1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
        log_success "Nginx 安装成功 (版本: $installed_version)"
    else
        log_error "Nginx 安装失败"
        return 1
    fi

    # 启动 Nginx
    log_info "启动 Nginx 服务..."
    case $OS in
        centos)
            systemctl enable nginx
            systemctl start nginx
            ;;
        ubuntu)
            systemctl enable nginx
            systemctl start nginx
            ;;
    esac

    # 检查服务状态
    if systemctl is-active nginx &>/dev/null; then
        log_success "Nginx 服务已启动"
    else
        log_warning "Nginx 服务可能未正常启动，请检查配置"
    fi

    log_success "Nginx 插件安装完成!"
    return 0
}

# 直接运行或被调用
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    plugin_install_main "$@"
else
    # 被主脚本调用
    plugin_install_main "$@"
fi
