#!/bin/bash
# Redis 插件安装脚本
# 使用插件系统安装 Redis

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

# 插件安装入口
plugin_install_main() {
    local version="${1:-}"
    local redis_version="${version:-latest}"

    log_info "开始安装 Redis${version:+ ($version)}..."

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
    if command -v redis-server &>/dev/null; then
        local current_version=$(redis-server --version | grep -oP '\d+\.\d+' | head -1 || echo "unknown")
        log_warning "Redis 已安装 (版本: $current_version)"
        log_info "跳过安装步骤"
        return 0
    fi

    # 安装依赖
    log_info "安装依赖包..."
    case $OS in
        centos)
            yum install -y gcc make wget
            ;;
        ubuntu)
            apt-get update
            apt-get install -y gcc make wget
            ;;
        *)
            log_error "不支持的操作系统: $OS"
            return 1
            ;;
    esac

    # 编译安装 Redis
    log_info "下载并编译安装 Redis..."

    local REDIS_URL="http://download.redis.io/releases/redis-7.2.4.tar.gz"
    local TEMP_DIR="/tmp/redis-install"

    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"

    if command -v wget &>/dev/null; then
        wget -q "$REDIS_URL" -O redis.tar.gz || {
            log_error "下载 Redis 失败"
            return 1
        }
    else
        curl -sL "$REDIS_URL" -o redis.tar.gz || {
            log_error "下载 Redis 失败"
            return 1
        }
    fi

    tar xzf redis.tar.gz
    cd redis-*

    make -j$(nproc) || {
        log_error "编译 Redis 失败"
        return 1
    }

    make install || {
        log_error "安装 Redis 失败"
        return 1
    }

    # 创建用户和目录
    log_info "创建 Redis 用户和目录..."
    id redis &>/dev/null || useradd -r -s /sbin/nologin redis
    mkdir -p /var/lib/redis /var/log/redis /etc/redis
    chown redis:redis /var/lib/redis /var/log/redis
    chmod 750 /var/lib/redis /var/log/redis

    # 配置 Redis
    log_info "配置 Redis..."
    cat > /etc/redis/redis.conf <<EOF
bind 127.0.0.1
protected-mode yes
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300
daemonize no
supervised systemd
pidfile /var/run/redis/redis.pid
loglevel notice
logfile /var/log/redis/redis.log
databases 16
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /var/lib/redis
replica-read-only yes
maxmemory 256mb
maxmemory-policy allkeys-lru
appendonly no
EOF

    chown redis:redis /etc/redis/redis.conf
    chmod 640 /etc/redis/redis.conf

    # 创建 systemd 服务文件
    log_info "创建 Redis 服务..."
    cat > /usr/lib/systemd/system/redis.service <<EOF
[Unit]
Description=Redis In-Memory Data Store
Documentation=https://redis.io/documentation
After=network.target

[Service]
Type=notify
User=redis
Group=redis
ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
ExecStop=/usr/local/bin/redis-cli shutdown
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # 清理临时文件
    cd /
    rm -rf "$TEMP_DIR"

    # 启动服务
    log_info "启动 Redis 服务..."
    systemctl daemon-reload
    systemctl enable redis
    systemctl start redis

    # 验证安装
    if command -v redis-server &>/dev/null; then
        local installed_version=$(redis-server --version | grep -oP '\d+\.\d+' | head -1 || echo "unknown")
        log_success "Redis 安装成功 (版本: $installed_version)"
    else
        log_error "Redis 安装失败"
        return 1
    fi

    # 检查服务状态
    if systemctl is-active redis &>/dev/null; then
        log_success "Redis 服务已启动"
    else
        log_warning "Redis 服务可能未正常启动，请检查配置"
    fi

    log_success "Redis 插件安装完成!"
    return 0
}

# 直接运行或被调用
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    plugin_install_main "$@"
else
    plugin_install_main "$@"
fi
