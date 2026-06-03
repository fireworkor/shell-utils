#!/bin/bash
# Redis 插件卸载脚本
# 使用插件系统卸载 Redis

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_NAME="redis"

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
    log_warning "即将卸载 Redis"
    log_warning "此操作将："
    log_warning "  1. 停止 Redis 服务"
    log_warning "  2. 禁用 Redis 服务自动启动"
    log_warning "  3. 删除 Redis 程序文件"
    log_warning "  4. 删除 Redis 数据 (可选)"
    log_warning "  5. 删除 Redis 配置文件 (可选)"
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
    local remove_data="${1:-false}"
    local remove_config="${2:-false}"

    log_info "开始卸载 Redis 插件..."

    # 检查是否已安装
    if ! command -v redis-server &>/dev/null; then
        log_warning "Redis 未安装"
        return 0
    fi

    # 确认卸载
    confirm_uninstall || return 0

    # 停止服务
    log_info "停止 Redis 服务..."
    systemctl stop redis 2>/dev/null || true
    if systemctl is-active redis &>/dev/null; then
        redis-cli shutdown 2>/dev/null || true
    fi

    # 禁用服务
    log_info "禁用 Redis 服务..."
    systemctl disable redis 2>/dev/null || true

    # 删除 systemd 服务文件
    log_info "删除 Redis 服务文件..."
    rm -f /usr/lib/systemd/system/redis.service
    rm -f /usr/lib/systemd/system/redis-sentinel.service
    systemctl daemon-reload

    # 卸载程序
    log_info "卸载 Redis 程序..."
    rm -f /usr/local/bin/redis-server
    rm -f /usr/local/bin/redis-cli
    rm -f /usr/local/bin/redis-benchmark
    rm -f /usr/local/bin/redis-check-rdb
    rm -f /usr/local/bin/redis-check-aof
    rm -f /usr/local/bin/redis-sentinel

    # 删除数据
    if [ "$remove_data" = "true" ]; then
        log_info "删除 Redis 数据..."
        rm -rf /var/lib/redis
        log_success "数据已删除"
    else
        log_info "保留数据文件 (使用 --remove-data 可删除)"
    fi

    # 删除配置文件
    if [ "$remove_config" = "true" ]; then
        log_info "删除 Redis 配置文件..."
        rm -rf /etc/redis
        log_success "配置文件已删除"
    else
        log_info "保留配置文件 (使用 --remove-config 可删除)"
    fi

    # 删除日志
    log_info "删除 Redis 日志..."
    rm -rf /var/log/redis

    # 删除用户
    log_info "删除 Redis 用户..."
    userdel redis 2>/dev/null || true

    # 验证卸载
    if command -v redis-server &>/dev/null; then
        log_error "Redis 卸载失败"
        return 1
    else
        log_success "Redis 卸载成功"
    fi

    log_success "Redis 插件卸载完成!"
    return 0
}

# 直接运行或被调用
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    plugin_uninstall_main "$@"
else
    plugin_uninstall_main "$@"
fi
