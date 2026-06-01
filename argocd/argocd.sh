#!/bin/bash
# Argo CD 安装部署脚本

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logging.sh"

# 配置参数
ARGOCD_VERSION="v2.12.0"
NAMESPACE="argocd"
RELEASE_NAME="argo-cd"

log_info "🚀 开始安装 Argo CD"

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
log_info "📦 创建 Argo CD 命名空间"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# 添加 Argo CD Helm 仓库
log_info "📦 添加 Argo CD Helm 仓库"
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# 安装 Argo CD
log_info "📦 安装 Argo CD"
helm install "$RELEASE_NAME" argo/argo-cd \
    --namespace "$NAMESPACE" \
    --version "$ARGOCD_VERSION" \
    --set server.service.type=NodePort \
    --set server.service.nodePort=30080 \
    --set controller.logFormat=json \
    --set repoServer.logFormat=json \
    --wait

# 等待安装完成
log_info "⏳ 等待 Argo CD 部署完成..."
kubectl wait --for=condition=available deployment/argo-cd-application-controller -n "$NAMESPACE" --timeout=5m
kubectl wait --for=condition=available deployment/argo-cd-repo-server -n "$NAMESPACE" --timeout=5m
kubectl wait --for=condition=available deployment/argo-cd-server -n "$NAMESPACE" --timeout=5m

# 获取初始密码
log_info "🔑 获取初始管理员密码"
ARGOCD_PASSWORD=$(kubectl -n "$NAMESPACE" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo ""
log_info "初始密码: $ARGOCD_PASSWORD"
echo ""

# 配置 Argo CD CLI
log_info "📦 安装 Argo CD CLI"
if ! command -v argocd &> /dev/null; then
    curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/"$ARGOCD_VERSION"/argocd-linux-amd64
    chmod +x /usr/local/bin/argocd
fi

# 配置端口转发（可选）
log_info "🔗 配置端口转发"
kubectl port-forward service/argo-cd-server -n "$NAMESPACE" 8080:443 &>/dev/null &
echo $! > "$SCRIPT_DIR/port-forward.pid"

log_success "✅ Argo CD 安装完成！"
echo ""
echo "📌 访问地址:"
echo "   - Web UI: http://localhost:8080 或 http://<node-ip>:30080"
echo "   - 用户名: admin"
echo "   - 密码: $ARGOCD_PASSWORD"
echo ""
echo "📖 使用命令:"
echo "   # 登录"
echo "   argocd login localhost:8080"
echo ""
echo "   # 更改密码"
echo "   argocd account update-password"
echo ""
echo "   # 创建应用"
echo "   argocd app create my-app --repo https://github.com/example/repo --path . --dest-server https://kubernetes.default.svc --dest-namespace default"