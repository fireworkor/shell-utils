#!/bin/bash
# Kubernetes 安装脚本
# 容器编排平台

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="kubernetes"
SOFTWARE_NAME="kubernetes"
DISPLAY_NAME="Kubernetes"

# 颜色定义
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
    log_info "检查 Kubernetes 安装前置条件..."
    
    if ! command -v curl &>/dev/null; then
        log_error "curl 未安装，请先安装 curl"
        return 1
    fi
    
    if ! command -v tar &>/dev/null; then
        log_error "tar 未安装，请先安装 tar"
        return 1
    fi
    
    return 0
}

install_kubectl() {
    log_info "安装 kubectl..."
    
    local os_type=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch_type=$(uname -m)
    
    if [ "$arch_type" = "x86_64" ]; then
        arch_type="amd64"
    elif [ "$arch_type" = "aarch64" ] || [ "$arch_type" = "arm64" ]; then
        arch_type="arm64"
    else
        log_error "不支持的架构: $arch_type"
        return 1
    fi
    
    local kubectl_version="$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"
    local download_url="https://storage.googleapis.com/kubernetes-release/release/${kubectl_version}/bin/${os_type}/${arch_type}/kubectl"
    
    log_info "下载 kubectl ${kubectl_version}..."
    if ! curl -LO "$download_url"; then
        log_error "kubectl 下载失败"
        return 1
    fi
    
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    
    if command -v kubectl &>/dev/null; then
        log_success "kubectl 安装成功"
        kubectl version --client
    else
        log_error "kubectl 安装失败"
        return 1
    fi
    
    return 0
}

install() {
    log_info "正在安装 ${DISPLAY_NAME}..."
    
    if ! check_prerequisites; then
        return 1
    fi
    
    install_kubectl || return 1
    
    log_info "安装 kubeadm, kubelet, kube-proxy..."
    
    if command -v apt &>/dev/null; then
        log_info "检测到 Debian/Ubuntu 系统"
        
        if ! sudo apt update; then
            log_error "更新软件源失败"
            return 1
        fi
        
        if ! sudo apt install -y apt-transport-https ca-certificates curl; then
            log_error "安装依赖失败"
            return 1
        fi
        
        if ! curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg; then
            log_error "下载 GPG 密钥失败"
            return 1
        fi
        
        echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
        
        if ! sudo apt update; then
            log_error "更新 Kubernetes 源失败"
            return 1
        fi
        
        if ! sudo apt install -y kubelet kubeadm kubectl; then
            log_error "安装 Kubernetes 组件失败"
            return 1
        fi
        
        sudo apt-mark hold kubelet kubeadm kubectl
        
    elif command -v yum &>/dev/null || command -v dnf &>/dev/null; then
        log_info "检测到 CentOS/RHEL 系统"
        
        local pkg_mgr="yum"
        if command -v dnf &>/dev/null; then
            pkg_mgr="dnf"
        fi
        
        if ! sudo "$pkg_mgr" install -y yum-utils; then
            log_error "安装 yum-utils 失败"
            return 1
        fi
        
        if ! sudo "$pkg_mgr" install -y https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64.rpm; then
            log_error "添加 Kubernetes 源失败"
            return 1
        fi
        
        if ! sudo "$pkg_mgr" install -y kubelet kubeadm kubectl; then
            log_error "安装 Kubernetes 组件失败"
            return 1
        fi
        
        sudo systemctl enable --now kubelet
        
    else
        log_warn "无法识别操作系统"
        log_info "请手动安装 Kubernetes"
        log_info "参考文档: https://kubernetes.io/docs/setup/"
        return 0
    fi
    
    log_success "${DISPLAY_NAME} 安装完成"
    log_info "下一步：使用 'kubeadm init' 初始化集群"
    log_info "参考: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/"
    
    return 0
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install "$@"
fi
