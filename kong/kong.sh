#!/bin/bash
# Kong API Gateway 安装部署脚本

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logging.sh"

# 配置参数
KONG_VERSION="3.6"
NAMESPACE="kong"
RELEASE_NAME="kong"

log_info "🚀 开始安装 Kong API Gateway"

# 检查 Kubernetes 集群
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl 未安装，请先安装 Kubernetes"
    exit 1
fi

# 检查集群连接
if ! kubectl cluster-info &> /dev/null; then
    log_error "无法连接到 Kubernetes 集群"
    exit 1
fi

# 创建命名空间
log_info "📦 创建 Kong 命名空间"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# 添加 Kong Helm 仓库
log_info "📦 添加 Kong Helm 仓库"
helm repo add kong https://charts.konghq.com
helm repo update

# 安装 Kong（使用简单配置）
log_info "📦 安装 Kong"
helm install "$RELEASE_NAME" kong/kong \
    --namespace "$NAMESPACE" \
    --set proxy.type=NodePort \
    --set proxy.http.nodePort=30080 \
    --set proxy.tls.nodePort=30443 \
    --set admin.type=NodePort \
    --set admin.http.nodePort=30081 \
    --set ingressController.enabled=true \
    --wait

# 等待安装完成
log_info "⏳ 等待 Kong 部署完成..."
kubectl wait --for=condition=available deployment/kong -n "$NAMESPACE" --timeout=10m

# 配置端口转发
log_info "🔗 配置端口转发"
kubectl port-forward service/kong-admin -n "$NAMESPACE" 8001:8001 &>/dev/null &
echo $! > "$SCRIPT_DIR/port-forward.pid"

log_success "✅ Kong API Gateway 安装完成！"
echo ""
echo "📌 访问地址:"
echo "   - Admin API: http://localhost:8001 或 http://<node-ip>:30081"
echo "   - Proxy: http://<node-ip>:30080"
echo "   - Proxy (HTTPS): https://<node-ip>:30443"
echo ""
echo "📖 使用示例:"
echo "   # 查看 Kong 状态"
echo "   curl http://localhost:8001/status"
echo ""
echo "   # 创建 Service"
echo "   curl -X POST http://localhost:8001/services \\"
echo "     --data 'name=my-service' \\"
echo "     --data 'url=http://httpbin.org'"
echo ""
echo "   # 创建 Route"
echo "   curl -X POST http://localhost:8001/services/my-service/routes \\"
echo "     --data 'name=my-route' \\"
echo "     --data 'paths[]=/my-path'"
echo ""
echo "   # 测试 API"
echo "   curl http://localhost:8000/my-path"
echo ""
echo "   # 安装插件"
echo "   curl -X POST http://localhost:8001/plugins \\"
echo "     --data 'name=rate-limiting' \\"
echo "     --data 'config.minute=100' \\"
echo "     --data 'config.hour=1000'"