#!/bin/bash
# HashiCorp Consul 服务发现与配置安装部署脚本

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logging.sh"

# 配置参数
CONSUL_VERSION="1.17.0"
NAMESPACE="consul"
RELEASE_NAME="consul"

log_info "🚀 开始安装 HashiCorp Consul"

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
log_info "📦 创建 Consul 命名空间"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# 添加 HashiCorp Helm 仓库
log_info "📦 添加 HashiCorp Helm 仓库"
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# 安装 Consul（开发模式，适合测试）
log_info "📦 安装 Consul (开发模式)"
helm install "$RELEASE_NAME" hashicorp/consul \
    --namespace "$NAMESPACE" \
    --version "$CONSUL_VERSION" \
    --set global.name=consul \
    --set server.replicas=1 \
    --set client.enabled=true \
    --set client.grpc=true \
    --set ui.enabled=true \
    --set ui.service.type=NodePort \
    --set ui.service.nodePort=30085 \
    --set connectInject.enabled=true \
    --set meshGateway.enabled=false \
    --set controller.enabled=true \
    --wait

# 等待安装完成
log_info "⏳ 等待 Consul 部署完成..."
kubectl wait --for=condition=available statefulset/consul-server -n "$NAMESPACE" --timeout=10m

# 配置端口转发
log_info "🔗 配置端口转发"
kubectl port-forward service/consul-ui -n "$NAMESPACE" 8500:8500 &>/dev/null &
echo $! > "$SCRIPT_DIR/port-forward.pid"

log_success "✅ Consul 安装完成！"
echo ""
echo "📌 访问地址:"
echo "   - Web UI: http://localhost:8500 或 http://<node-ip>:30085"
echo "   - API: http://localhost:8500/v1/"
echo ""
echo "📖 使用示例:"
echo "   # 查看服务列表"
echo "   curl http://localhost:8500/v1/catalog/services"
echo ""
echo "   # 注册服务"
echo "   curl -X PUT -d '{\"ID\":\"my-service\",\"Name\":\"my-service\",\"Address\":\"127.0.0.1\",\"Port\":8080}' http://localhost:8500/v1/agent/service/register"
echo ""
echo "   # 发现服务"
echo "   curl http://localhost:8500/v1/catalog/service/my-service"
echo ""
echo "   # 健康检查"
echo "   curl http://localhost:8500/v1/health/service/my-service"
echo ""
echo "   # KV 存储"
echo "   curl -X PUT -d 'my-value' http://localhost:8500/v1/kv/my-key"
echo "   curl http://localhost:8500/v1/kv/my-key"
echo ""
echo "   # 使用 DNS 解析"
echo "   dig my-service.service.consul @localhost -p 8600"