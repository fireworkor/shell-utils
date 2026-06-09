#!/bin/bash
# K3s 安装脚本
# 轻量级 Kubernetes 发行版

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"
VERSION="${1:-}"
INSTALL_TYPE="${2:-server}"  # server 或 agent

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

if [ -f "$SCRIPT_DIR/config" ]; then
    source "$SCRIPT_DIR/config"
fi

SERVICE_NAME="k3s"
SOFTWARE_NAME="k3s"
DISPLAY_NAME="K3s"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

check_prerequisites() {
    log_info "检查 K3s 安装前置条件..."
    
    # 检查是否已安装
    if command -v k3s &>/dev/null; then
        log_warn "K3s 已安装"
        k3s --version
        return 0
    fi
    
    # 检查操作系统
    if [ ! -f /etc/os-release ]; then
        log_error "无法检测操作系统"
        return 1
    fi
    
    # 检查架构
    local arch=$(uname -m)
    case $arch in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l|armhf)
            ARCH="armhf"
            ;;
        *)
            log_error "不支持的架构: $arch"
            return 1
            ;;
    esac
    
    log_info "检测到架构: $ARCH"
    
    # 检查必要命令
    for cmd in curl tar; do
        if ! command -v $cmd &>/dev/null; then
            log_error "$cmd 未安装"
            return 1
        fi
    done
    
    return 0
}

install_server() {
    log_info "安装 K3s Server 节点..."
    
    local install_script="https://get.k3s.io"
    local extra_args=""
    
    # 版本指定
    if [ -n "$VERSION" ]; then
        extra_args="$extra_args INSTALL_K3S_VERSION=$VERSION"
    fi
    
    # 配置参数
    if [ -f "$SCRIPT_DIR/config" ]; then
        # 读取配置
        if grep -q "K3S_TOKEN" "$SCRIPT_DIR/config" 2>/dev/null; then
            source "$SCRIPT_DIR/config"
        fi
    fi
    
    # 执行安装
    log_info "下载并安装 K3s..."
    if curl -sfL $install_script | sh -s - server \
        --write-kubeconfig-mode 644 \
        ${K3S_EXTRA_ARGS:-}; then
        log_success "K3s Server 安装成功"
        
        # 显示节点信息
        log_info "等待 K3s 启动..."
        sleep 10
        
        log_info "节点状态:"
        k3s kubectl get nodes
        
        log_info "Token (用于添加 Agent 节点):"
        cat /var/lib/rancher/k3s/server/node-token 2>/dev/null || log_warn "无法读取 token"
        
        return 0
    else
        log_error "K3s Server 安装失败"
        return 1
    fi
}

install_agent() {
    log_info "安装 K3s Agent 节点..."
    
    # 检查必要参数
    if [ -z "$K3S_URL" ]; then
        log_error "未设置 K3S_URL (Server 地址)"
        log_info "使用方法: K3S_URL=https://server:6443 K3S_TOKEN=xxx $0 agent"
        return 1
    fi
    
    if [ -z "$K3S_TOKEN" ]; then
        log_error "未设置 K3S_TOKEN"
        log_info "Token 可从 Server 节点的 /var/lib/rancher/k3s/server/node-token 获取"
        return 1
    fi
    
    local install_script="https://get.k3s.io"
    
    # 版本指定
    if [ -n "$VERSION" ]; then
        export INSTALL_K3S_VERSION=$VERSION
    fi
    
    # 执行安装
    log_info "下载并安装 K3s Agent..."
    if curl -sfL $install_script | K3S_URL=$K3S_URL K3S_TOKEN=$K3S_TOKEN sh -s - agent; then
        log_success "K3s Agent 安装成功"
        return 0
    else
        log_error "K3s Agent 安装失败"
        return 1
    fi
}

uninstall() {
    log_warn "卸载 K3s..."
    
    if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
        /usr/local/bin/k3s-uninstall.sh
        log_success "K3s 卸载成功"
    else
        log_error "未找到卸载脚本"
        return 1
    fi
}

show_status() {
    log_info "K3s 状态:"
    
    if ! command -v k3s &>/dev/null; then
        log_warn "K3s 未安装"
        return 0
    fi
    
    echo ""
    echo "版本:"
    k3s --version
    
    echo ""
    echo "服务状态:"
    systemctl status k3s --no-pager 2>/dev/null || service k3s status 2>/dev/null || log_warn "无法获取服务状态"
    
    echo ""
    echo "节点状态:"
    k3s kubectl get nodes 2>/dev/null || log_warn "无法获取节点状态"
    
    echo ""
    echo "Pod 状态:"
    k3s kubectl get pods -A 2>/dev/null || log_warn "无法获取 Pod 状态"
}

show_help() {
    echo "K3s - 轻量级 Kubernetes 发行版"
    echo ""
    echo "使用方法: $0 [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  server    安装 Server 节点 (默认)"
    echo "  agent     安装 Agent 节点 (需要 K3S_URL 和 K3S_TOKEN)"
    echo "  uninstall 卸载 K3s"
    echo "  status    显示 K3s 状态"
    echo "  help      显示帮助信息"
    echo ""
    echo "环境变量:"
    echo "  K3S_URL       Server 地址 (Agent 模式必需)"
    echo "  K3S_TOKEN     集群 Token (Agent 模式必需)"
    echo ""
    echo "示例:"
    echo "  # 安装 Server 节点"
    echo "  $0 server"
    echo ""
    echo "  # 安装指定版本"
    echo "  $0 server v1.28.0"
    echo ""
    echo "  # 安装 Agent 节点"
    echo "  K3S_URL=https://192.168.1.100:6443 K3S_TOKEN=xxx $0 agent"
    echo ""
    echo "  # 卸载"
    echo "  $0 uninstall"
}

install() {
    case "$INSTALL_TYPE" in
        server)
            check_prerequisites && install_server
            ;;
        agent)
            check_prerequisites && install_agent
            ;;
        uninstall)
            uninstall
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $INSTALL_TYPE"
            show_help
            return 1
            ;;
    esac
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install "$@"
fi
