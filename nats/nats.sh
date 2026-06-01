#!/bin/bash
# NATS 消息系统安装部署脚本

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logging.sh"

# 配置参数
NATS_VERSION="0.22.0"
NAMESPACE="nats"
RELEASE_NAME="nats"

log_info "🚀 开始安装 NATS 消息系统"

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
log_info "📦 创建 NATS 命名空间"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# 添加 NATS Helm 仓库
log_info "📦 添加 NATS Helm 仓库"
helm repo add nats https://nats-io.github.io/k8s/helm/charts
helm repo update

# 安装 NATS（集群模式）
log_info "📦 安装 NATS"
helm install "$RELEASE_NAME" nats/nats \
    --namespace "$NAMESPACE" \
    --version "$NATS_VERSION" \
    --set replicaCount=3 \
    --set service.type=NodePort \
    --set service.nats.port=30422 \
    --set service.cluster.port=30491 \
    --set service.metrics.port=30492 \
    --set auth.enabled=false \
    --set metrics.enabled=true \
    --set metrics.serviceMonitor.enabled=true \
    --wait

# 安装 NATS JetStream（可选，用于持久化消息）
log_info "📦 安装 NATS JetStream"
helm upgrade "$RELEASE_NAME" nats/nats \
    --namespace "$NAMESPACE" \
    --set jetstream.enabled=true \
    --set jetstream.persistentVolumeClaim.enabled=true \
    --set jetstream.persistentVolumeClaim.size=10Gi \
    --wait

# 安装 NATS Box（用于测试和管理）
log_info "📦 安装 NATS Box"
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: nats-box
  namespace: $NAMESPACE
spec:
  containers:
  - name: nats-box
    image: synadia/nats-box:latest
    env:
    - name: NATS_URL
      value: nats://nats:4222
    command: ["sleep", "infinity"]
EOF

# 等待安装完成
log_info "⏳ 等待 NATS 部署完成..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=nats -n "$NAMESPACE" --timeout=10m

# 配置端口转发
log_info "🔗 配置端口转发"
kubectl port-forward service/nats -n "$NAMESPACE" 4222:4222 &>/dev/null &
echo $! > "$SCRIPT_DIR/port-forward.pid"

log_success "✅ NATS 安装完成！"
echo ""
echo "📌 访问地址:"
echo "   - NATS Server: nats://localhost:4222"
echo "   - Monitoring: http://localhost:8222"
echo ""
echo "📖 使用示例:"
echo "   # 进入 NATS Box"
echo "   kubectl exec -it nats-box -n $NAMESPACE -- /bin/sh"
echo ""
echo "   # 发布消息"
echo "   nats pub subject.name 'Hello NATS!'"
echo ""
echo "   # 订阅消息"
echo "   nats sub subject.name"
echo ""
echo "   # 请求-响应模式"
echo "   nats req service.request 'Hello' --reply='World'"
echo ""
echo "   # JetStream 流管理"
echo "   nats stream add"
echo ""
echo "   # 创建消费者"
echo "   nats consumer add"
echo ""
echo "📝 客户端连接示例:"
echo ""
echo "   # Go"
echo "   import github.com/nats-io/nats.go"
echo "   nc, _ := nats.Connect('nats://localhost:4222')"
echo "   nc.Publish('subject', []byte('Hello'))"
echo ""
echo "   # Node.js"
echo "   const nats = require('nats')"
echo "   const nc = await nats.connect('nats://localhost:4222')"
echo "   nc.publish('subject', 'Hello')"
echo ""
echo "📊 Monitoring: http://localhost:8222/streaming"