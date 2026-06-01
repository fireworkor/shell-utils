#!/bin/bash
# Istio 服务网格安装部署脚本

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logging.sh"

# 配置参数
ISTIO_VERSION="1.21.0"
NAMESPACE="istio-system"

log_info "🚀 开始安装 Istio 服务网格"

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

# 下载 Istio CLI
log_info "📦 下载 Istio CLI"
curl -L https://istio.io/downloadIstio | ISTIO_VERSION="$ISTIO_VERSION" sh -

# 安装 istioctl
log_info "📦 安装 istioctl"
cp "istio-$ISTIO_VERSION/bin/istioctl" /usr/local/bin/
chmod +x /usr/local/bin/istioctl

# 验证安装
istioctl version --remote=false

# 安装 Istio（使用 default 配置文件）
log_info "📦 安装 Istio"
istioctl install --set profile=default -y

# 创建 istio-ingressgateway 服务
log_info "📦 创建 Istio Ingress Gateway"
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: istio-ingressgateway
  namespace: istio-system
spec:
  type: NodePort
  selector:
    istio: ingressgateway
  ports:
    - name: http2
      port: 80
      nodePort: 30080
    - name: https
      port: 443
      nodePort: 30443
EOF

# 等待安装完成
log_info "⏳ 等待 Istio 部署完成..."
kubectl wait --for=condition=available deployment/istio-ingressgateway -n "$NAMESPACE" --timeout=10m
kubectl wait --for=condition=available deployment/istiod -n "$NAMESPACE" --timeout=10m

# 安装 Kiali 仪表板（可选）
log_info "📦 安装 Kiali 仪表板"
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-$ISTIO_VERSION/samples/addons/kiali.yaml
kubectl wait --for=condition=available deployment/kiali -n "$NAMESPACE" --timeout=5m

# 安装 Jaeger（可选）
log_info "📦 安装 Jaeger"
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-$ISTIO_VERSION/samples/addons/jaeger.yaml
kubectl wait --for=condition=available deployment/jaeger -n "$NAMESPACE" --timeout=5m

# 安装 Prometheus（可选）
log_info "📦 安装 Prometheus"
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-$ISTIO_VERSION/samples/addons/prometheus.yaml
kubectl wait --for=condition=available deployment/prometheus -n "$NAMESPACE" --timeout=5m

# 安装 Grafana（可选）
log_info "📦 安装 Grafana"
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-$ISTIO_VERSION/samples/addons/grafana.yaml
kubectl wait --for=condition=available deployment/grafana -n "$NAMESPACE" --timeout=5m

# 配置端口转发
log_info "🔗 配置端口转发"
kubectl port-forward service/kiali -n "$NAMESPACE" 20001:20001 &>/dev/null &
echo $! > "$SCRIPT_DIR/port-forward.pid"

log_success "✅ Istio 安装完成！"
echo ""
echo "📌 访问地址:"
echo "   - Kiali: http://localhost:20001"
echo "   - Grafana: http://localhost:3000 (需要端口转发)"
echo "   - Prometheus: http://localhost:9090 (需要端口转发)"
echo "   - Ingress Gateway: http://<node-ip>:30080"
echo ""
echo "📖 使用命令:"
echo "   # 启用 Sidecar 注入"
echo "   kubectl label namespace default istio-injection=enabled"
echo ""
echo "   # 查看 Istio 状态"
echo "   istioctl status"
echo ""
echo "   # 查看服务网格拓扑"
echo "   istioctl dashboard kiali"
echo ""
echo "   # 创建 Gateway"
echo "   istioctl create gateway my-gateway --selector=istio=ingressgateway"