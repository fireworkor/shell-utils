#!/bin/bash
# Jaeger 分布式追踪系统安装部署脚本

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logging.sh"

# 配置参数
JAEGER_VERSION="1.55.0"
NAMESPACE="observability"
RELEASE_NAME="jaeger"

log_info "🚀 开始安装 Jaeger 分布式追踪系统"

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
log_info "📦 创建 observability 命名空间"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# 添加 Jaeger Helm 仓库
log_info "📦 添加 Jaeger Helm 仓库"
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update

# 安装 Jaeger（使用 all-in-one 模式，适合测试和开发）
log_info "📦 安装 Jaeger (all-in-one 模式)"
helm install "$RELEASE_NAME" jaegertracing/jaeger \
    --namespace "$NAMESPACE" \
    --version "$JAEGER_VERSION" \
    --set service.type=NodePort \
    --set service.nodePort=30686 \
    --set query.service.type=NodePort \
    --set query.service.nodePort=30687 \
    --set collector.service.type=NodePort \
    --set collector.service.nodePort=30688 \
    --wait

# 等待安装完成
log_info "⏳ 等待 Jaeger 部署完成..."
kubectl wait --for=condition=available deployment/jaeger -n "$NAMESPACE" --timeout=5m

# 配置端口转发
log_info "🔗 配置端口转发"
kubectl port-forward service/jaeger-query -n "$NAMESPACE" 16686:16686 &>/dev/null &
echo $! > "$SCRIPT_DIR/port-forward.pid"

log_success "✅ Jaeger 安装完成！"
echo ""
echo "📌 访问地址:"
echo "   - Web UI: http://localhost:16686 或 http://<node-ip>:30687"
echo "   - Collector: http://<node-ip>:30688"
echo ""
echo "📖 使用示例:"
echo "   # 配置应用接入 Jaeger"
echo "   export JAEGER_AGENT_HOST=<jaeger-host>"
echo "   export JAEGER_AGENT_PORT=6831"
echo ""
echo "   # 使用 OpenTelemetry SDK"
echo "   # Node.js:"
echo "   const tracer = new JaegerTracer({ serviceName: 'my-service' });"
echo ""
echo "   # Python:"
echo "   from jaeger_client import Config"
echo "   config = Config(config={'sampler': {'type': 'const', 'param': 1}})"
echo "   tracer = config.initialize_tracer()"