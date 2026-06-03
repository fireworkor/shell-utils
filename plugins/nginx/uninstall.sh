#!/bin/bash
# Nginx 插件卸载脚本
# 使用插件系统卸载 Nginx

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

# 确认卸载
confirm_uninstall() {
    echo ""
    log_warning "即将卸载 Nginx"
    log_warning "此操作将："
    log_warning "  1. 停止 Nginx 服务"
    log_warning "  2. 禁用 Nginx 服务自动启动"
    log_warning "  3. 删除 Nginx 程序文件"
    log_warning "  4. 删除 Nginx 配置文件 (可选)"
    echo ""

    read -p "是否继续卸载? (y/N): " confirm
    case $confirm in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            log_info "取消卸载"
            return 1
            ;;
    esac
}

# 插件卸载入口
plugin_uninstall_main() {
    local remove_config="${1:-false}"

    log_info "开始卸载 Nginx 插件..."

    # 获取系统信息
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        log_error "无法确定操作系统类型"
        return 1
    fi

    # 确认卸载
    confirm_uninstall || return 0

    # 检查是否已安装
    if ! command -v nginx &>/dev/null; then
        log_warning "Nginx 未安装"
        return 0
    fi

    # 停止服务
    log_info "停止 Nginx 服务..."
    if systemctl is-active nginx &>/dev/null; then
        systemctl stop nginx
        log_success "Nginx 服务已停止"
    fi

    # 禁用服务
    log_info "禁用 Nginx 服务..."
    systemctl disable nginx 2>/dev/null || true

    # 卸载程序
    log_info "卸载 Nginx 程序..."
    case $OS in
        centos)
            yum remove -y nginx nginx-all-modules nginx-filesystem nginx-mod-http*.x86_64 2>/dev/null || true
            yum clean all
            ;;
        ubuntu)
            apt-get purge -y nginx nginx-* 2>/dev/null || true
            apt-get autoremove -y
            ;;
    esac

    # 删除配置文件
    if [ "$remove_config" = "true" ]; then
        log_info "删除 Nginx 配置文件..."
        rm -rf /etc/nginx
        log_success "配置文件已删除"
    else
        log_info "保留配置文件 (使用 --remove-config 可删除)"
    fi

    # 删除日志文件
    log_info "删除 Nginx 日志..."
    rm -rf /var/log/nginx

    # 验证卸载
    if command -v nginx &>/dev/null; then
        log_error "Nginx 卸载失败"
        return 1
    else
        log_success "Nginx 卸载成功"
    fi

    log_success "Nginx 插件卸载完成!"
    return 0
}

# 直接运行或被调用
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    plugin_uninstall_main "$@"
else
    plugin_uninstall_main "$@"
fi
