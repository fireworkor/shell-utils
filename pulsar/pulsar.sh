#!/bin/bash
# Apache Pulsar 云原生消息队列安装部署脚本

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logging.sh"

# 配置参数
PULSAR_VERSION="3.0.0"
NAMESPACE="pulsar"
RELEASE_NAME="pulsar"

log_info "🚀 开始安装 Apache Pulsar 云原生消息队列"

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
log_info "📦 创建 Pulsar 命名空间"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# 添加 Apache Pulsar Helm 仓库
log_info "📦 添加 Apache Pulsar Helm 仓库"
helm repo add apache-pulsar https://puls.apache.org/charts
helm repo update

# 安装 Pulsar（最小化模式）
log_info "📦 安装 Pulsar (最小化模式)"
helm install "$RELEASE_NAME" apache-pulsar/pulsar \
    --namespace "$NAMESPACE" \
    --version "$PULSAR_VERSION" \
    --set components=true \
    --set deployPods=false \
    --set persistence.enabled=false \
    --set service.type=NodePort \
    --set gateway.service.type=NodePort \
    --set gateway.service.nodePort=30665 \
    --set proxy.service.type=NodePort \
    --set proxy.service.nodePort=30666 \
    --set bookkeeper.replicaCount=1 \
    --set zookeeper.replicaCount=1 \
    --wait

# 等待 Pod 启动
log_info "⏳ 等待 Pulsar 组件启动..."
sleep 30

# 检查状态
kubectl get pods -n "$NAMESPACE"

# 配置端口转发
log_info "🔗 配置端口转发"
kubectl port-forward service/pulsar-proxy -n "$NAMESPACE" 6650:6650 &>/dev/null &
kubectl port-forward service/pulsar-gateway -n "$NAMESPACE" 8080:8080 &>/dev/null &
echo $! > "$SCRIPT_DIR/port-forward.pid"

# 获取初始密码
log_info "🔑 获取管理员密码"
ADMIN_PASSWORD=$(kubectl get secret -n "$NAMESPACE" pulsar-admin -o jsonpath="{.data.token}" 2>/dev/null | base64 -d || echo "apachepulsar")

log_success "✅ Apache Pulsar 安装完成！"
echo ""
echo "📌 访问地址:"
echo "   - Pulsar Gateway: http://localhost:8080 或 http://<node-ip>:30665"
echo "   - Pulsar Proxy: pulsar://localhost:6650 或 pulsar://<node-ip>:30666"
echo "   - Dashboard: http://localhost:3000 (需要端口转发)"
echo ""
echo "📖 使用示例:"
echo "   # 安装 Pulsar 管理工具"
echo "   curl -fsSL https://archive.apache.org/dist/pulsar/pulsar-$PULSAR_VERSION/connector-cli-tools/pulsar-admin.tar.gz | tar -xz -C /tmp"
echo "   export PATH=\$PATH:/tmp/pulsar/bin"
echo ""
echo "   # 创建租户"
echo "   pulsar-admin tenants create my-tenant \\"
echo "     --allowed-clusters standalone \\"
echo "     --admin-roles my-admin-role"
echo ""
echo "   # 创建命名空间"
echo "   pulsar-admin namespaces create my-tenant/my-namespace"
echo ""
echo "   # 创建主题"
echo "   pulsar-admin topics create persistent://my-tenant/my-namespace/my-topic"
echo ""
echo "   # 生产消息"
echo "   pulsar-client produce persistent://my-tenant/my-namespace/my-topic \\"
echo "     --messages 'Hello Pulsar!'"
echo ""
echo "   # 消费消息"
echo "   pulsar-client consume persistent://my-tenant/my-namespace/my-topic \\"
echo "     -s 'my-subscriber' -t latest"
echo ""
echo "📝 Java 客户端示例:"
echo "   <dependency>"
echo "     <groupId>org.apache.pulsar</groupId>"
echo "     <artifactId>pulsar-client</artifactId>"
echo "     <version>$PULSAR_VERSION</version>"
echo "   </dependency>"
echo ""
echo "   Producer producer = client.newProducer()"
echo "       .topic(\"persistent://my-tenant/my-namespace/my-topic\")"
echo "       .create();"
echo "   producer.send(\"Hello Pulsar!\".getBytes());"
echo ""
echo "   Consumer consumer = client.newConsumer()"
echo "       .topic(\"persistent://my-tenant/my-namespace/my-topic\")"
echo "       .subscriptionName(\"my-subscriber\")"
echo "       .subscribe();"
echo "   Message msg = consumer.receive();"
echo ""
echo "📊 功能特性:"
echo "   ✓ 多租户"
echo "   ✓ 持久化消息"
echo "   ✓ 跨地域复制"
echo "   ✓ 函数计算"
echo "   ✓ 连接器框架"
echo "   ✓ Schema Registry"