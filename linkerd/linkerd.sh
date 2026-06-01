#!/bin/bash
# Linkerd 服务网格安装部署脚本

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logging.sh"

# 配置参数
LINKERD_VERSION="2.14.10"

log_info "🚀 开始安装 Linkerd 服务网格"

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

# 下载 Linkerd CLI
log_info "📦 下载 Linkerd CLI"
curl -L https://github.com/linkerd/linkerd2/releases/download/stable-"$LINKERD_VERSION"/linkerd2-cli-stable-"$LINKERD_VERSION"-linux-amd64 -o /usr/local/bin/linkerd
chmod +x /usr/local/bin/linkerd

# 验证安装
linkerd version --client

# 安装 Linkerd（Helm 方式）
log_info "📦 添加 Linkerd Helm 仓库"
helm repo add linkerd https://helm.linkerd.io/stable
helm repo update

# 安装 Linkerd CRDs
log_info "📦 安装 Linkerd CRDs"
linkerd crds install | kubectl apply -f -

# 安装 Linkerd 控制平面
log_info "📦 安装 Linkerd 控制平面"
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -

# 等待安装完成
log_info "⏳ 等待 Linkerd 部署完成..."
kubectl wait --for=condition=available deployment/linkerd-identity -n linkerd --timeout=10m
kubectl wait --for=condition=available deployment/linkerd-proxy-injector -n linkerd --timeout=10m

# 安装 Linkerd Viz 扩展（可选，用于仪表板和监控）
log_info "📦 安装 Linkerd Viz 扩展"
linkerd viz install | kubectl apply -f -

# 等待 Viz 部署
kubectl wait --for=condition=available deployment/grafana -n linkerd-viz --timeout=5m
kubectl wait --for=condition=available deployment/prometheus -n linkerd-viz --timeout=5m

# 配置端口转发
log_info "🔗 配置端口转发"
kubectl port-forward -n linkerd-viz service/web 8084:8084 &>/dev/null &
echo $! > "$SCRIPT_DIR/port-forward.pid"

log_success "✅ Linkerd 安装完成！"
echo ""
echo "📌 访问地址:"
echo "   - Dashboard: http://localhost:8084"
echo "   - Grafana: http://localhost:8084/grafana"
echo ""
echo "📖 使用命令:"
echo "   # 检查 Linkerd 状态"
echo "   linkerd check"
echo ""
echo "   # 查看 Dashboard"
echo "   linkerd viz dashboard"
echo ""
echo "   # 启用命名空间自动注入"
echo "   kubectl label namespace default linkerd.io/inject=enabled"
echo ""
echo "   # 部署示例应用"
echo "   curl -sL https://run.linkerd.io/emojivoto.yml | kubectl apply -f -"
echo ""
echo "   # 查看服务拓扑"
echo "   linkerd viz top deploy"
echo ""
echo "   # 查看服务健康"
echo "   linkerd viz stat svc"
echo ""
echo "   # 卸载"
echo "   linkerd viz uninstall | kubectl delete -f -"
echo "   linkerd uninstall | kubectl delete -f -"