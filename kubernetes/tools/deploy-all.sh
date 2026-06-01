#!/bin/bash

# =========================================
# 一键部署完整 Kubernetes 环境
# =========================================

set -o pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NAMESPACE="${1:-all}"

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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Kubernetes 一键部署${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查 kubectl
if ! command -v kubectl &>/dev/null; then
    log_error "kubectl 未安装"
    exit 1
fi

# 检查集群连接
if ! kubectl cluster-info &>/dev/null; then
    log_error "无法连接到 Kubernetes 集群"
    exit 1
fi

log_success "Kubernetes 集群连接正常"
echo ""

# 部署函数
deploy_monitoring() {
    log_info "部署监控栈 (Prometheus + Grafana)..."
    kubectl apply -f monitoring/
    log_success "监控栈部署完成"
}

deploy_logging() {
    log_info "部署日志栈 (EFK)..."
    kubectl apply -f logging/
    log_success "日志栈部署完成"
}

deploy_security() {
    log_info "部署安全工具..."
    kubectl apply -f security/
    log_success "安全工具部署完成"
}

deploy_apps() {
    log_info "部署示例应用..."
    kubectl apply -f apps/
    log_success "示例应用部署完成"
}

# 主流程
case "$NAMESPACE" in
    all)
        log_info "部署所有组件..."
        echo ""
        
        log_info "1/4 部署监控栈"
        deploy_monitoring
        
        echo ""
        log_info "2/4 部署日志栈"
        deploy_logging
        
        echo ""
        log_info "3/4 部署安全工具"
        deploy_security
        
        echo ""
        log_info "4/4 部署示例应用"
        deploy_apps
        
        echo ""
        log_success "全部部署完成！"
        echo ""
        echo -e "${YELLOW}访问地址:${NC}"
        echo "  Prometheus: http://localhost:30090"
        echo "  Grafana:    http://localhost:30300 (admin/admin123)"
        echo "  Kibana:     http://localhost:30001"
        echo "  Nginx:      http://localhost:30080"
        echo "  WordPress:  http://localhost:30081"
        echo "  Jenkins:   http://localhost:30082"
        ;;
    
    monitoring)
        deploy_monitoring
        ;;
    
    logging)
        deploy_logging
        ;;
    
    security)
        deploy_security
        ;;
    
    apps)
        deploy_apps
        ;;
    
    *)
        log_error "未知参数: $NAMESPACE"
        echo "可用参数: all, monitoring, logging, security, apps"
        exit 1
        ;;
esac

echo ""
log_info "检查部署状态..."
sleep 2
kubectl get pods -A --field-selector=status.phase!=Running 2>/dev/null | grep -v "NAMESPACE" || log_success "所有 Pod 运行正常"
