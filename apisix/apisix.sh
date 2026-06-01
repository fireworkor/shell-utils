#!/bin/bash
# Apache APISIX API 网关安装部署脚本

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logging.sh"

# 配置参数
APISIX_VERSION="3.0.0"
NAMESPACE="apisix"
RELEASE_NAME="apisix"

log_info "🚀 开始安装 Apache APISIX API 网关"

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
log_info "📦 创建 APISIX 命名空间"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# 添加 Apache APISIX Helm 仓库
log_info "📦 添加 Apache APISIX Helm 仓库"
helm repo add apisix https://charts.apiseven.com
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# 安装 etcd（APISIX 需要）
log_info "📦 安装 etcd"
helm install etcd bitnami/etcd \
    --namespace "$NAMESPACE" \
    --set auth.rbac.create=true \
    --set auth.rbac.password=etcd_password \
    --set persistence.enabled=false \
    --wait

# 安装 Apache APISIX
log_info "📦 安装 Apache APISIX"
helm install "$RELEASE_NAME" apisix/apisix \
    --namespace "$NAMESPACE" \
    --version "$APISIX_VERSION" \
    --set gateway.type=NodePort \
    --set gateway.http.nodePort=30080 \
    --set gateway.tls.nodePort=30443 \
    --set admin.enabled=true \
    --set admin.service.type=NodePort \
    --set admin.http.nodePort=30081 \
    --set etcd.host[0]=http://etcd.$NAMESPACE.svc.cluster.local:2379 \
    --set dashboard.enabled=true \
    --set dashboard.service.type=NodePort \
    --set dashboard.service.nodePort=30082 \
    --wait

# 安装 Ingress Controller（可选）
log_info "📦 安装 APISIX Ingress Controller"
kubectl apply -f - <<EOF
apiVersion: apisix.apache.org/v2
kind: ApisixRoute
metadata:
  name: demo-route
  namespace: default
spec:
  http:
    - name: demo
      match:
        hosts:
          - demo.local
        paths:
          - /*
      backends:
        - serviceName: httpbin
          servicePort: 80
EOF

# 等待安装完成
log_info "⏳ 等待 APISIX 部署完成..."
kubectl wait --for=condition=available deployment/apisix -n "$NAMESPACE" --timeout=10m

# 配置端口转发
log_info "🔗 配置端口转发"
kubectl port-forward service/apisix-admin -n "$NAMESPACE" 9180:9180 &>/dev/null &
kubectl port-forward service/apisix-dashboard -n "$NAMESPACE" 18080:80 &>/dev/null &
echo $! > "$SCRIPT_DIR/port-forward.pid"

log_success "✅ Apache APISIX 安装完成！"
echo ""
echo "📌 访问地址:"
echo "   - APISIX Gateway: http://<node-ip>:30080"
echo "   - APISIX Admin API: http://localhost:9180 或 http://<node-ip>:30081"
echo "   - Dashboard: http://localhost:18080 或 http://<node-ip>:30082"
echo ""
echo "📖 使用示例:"
echo "   # 查看 APISIX 路由"
echo "   curl http://localhost:9180/apisix/admin/routes"
echo ""
echo "   # 创建上游服务"
echo "   curl -X POST http://localhost:9180/apisix/admin/upstreams \\"
echo "     -H 'X-API-Key: edd1c9f34a5a76eda1a7a9b4f88f4dac' \\"
echo "     -d '{"
echo "       \"nodes\": [{\"host\": \"httpbin.org\", \"port\": 80, \"weight\": 1}],"
echo "       \"type\": \"roundrobin\""
echo "     }'"
echo ""
echo "   # 创建路由"
echo "   curl -X POST http://localhost:9180/apisix/admin/routes \\"
echo "     -H 'X-API-Key: edd1c9f34a5a76eda1a7a9b4f88f4dac' \\"
echo "     -d '{"
echo "       \"uri\": \"/test\","
echo "       \"upstream_id\": \"<upstream_id>\""
echo "     }'"
echo ""
echo "   # 测试路由"
echo "   curl http://localhost:30080/test"
echo ""
echo "📝 默认 Admin API Key:"
echo "   edd1c9f34a5a76eda1a7a9b4f88f4dac"