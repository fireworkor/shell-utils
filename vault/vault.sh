#!/bin/bash
# HashiCorp Vault 安装部署脚本

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logging.sh"

# 配置参数
VAULT_VERSION="1.16.2"
NAMESPACE="vault"
RELEASE_NAME="vault"

log_info "🚀 开始安装 HashiCorp Vault"

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
log_info "📦 创建 Vault 命名空间"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# 添加 HashiCorp Helm 仓库
log_info "📦 添加 HashiCorp Helm 仓库"
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# 安装 Vault（开发模式）
log_info "📦 安装 Vault (开发模式)"
helm install "$RELEASE_NAME" hashicorp/vault \
    --namespace "$NAMESPACE" \
    --version "$VAULT_VERSION" \
    --set "server.dev.enabled=true" \
    --set "server.service.type=NodePort" \
    --set "server.service.nodePort=30820" \
    --wait

# 等待安装完成
log_info "⏳ 等待 Vault 部署完成..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n "$NAMESPACE" --timeout=5m

# 配置端口转发
log_info "🔗 配置端口转发"
kubectl port-forward service/vault -n "$NAMESPACE" 8200:8200 &>/dev/null &
echo $! > "$SCRIPT_DIR/port-forward.pid"

# 获取初始化状态
log_info "🔑 获取 Vault 初始化状态"
UNSEAL_KEY=$(kubectl exec -n "$NAMESPACE" vault-0 -- vault status 2>/dev/null | grep "Sealed" || echo "未初始化")

log_success "✅ Vault 安装完成！"
echo ""
echo "📌 访问地址:"
echo "   - Web UI: http://localhost:8200"
echo "   - API: http://localhost:8200"
echo ""
echo "📖 使用示例:"
echo "   # 配置环境变量"
echo "   export VAULT_ADDR='http://localhost:8200'"
echo ""
echo "   # 写入密钥"
echo "   vault kv put secret/myapp username=admin password=secret123"
echo ""
echo "   # 读取密钥"
echo "   vault kv get secret/myapp"
echo ""
echo "   # 启用数据库密钥引擎"
echo "   vault secrets enable database"
echo ""
echo "   # 创建策略"
echo "   vault policy write myapp-policy myapp-policy.hcl"
echo ""
echo "   # 创建 Token"
echo "   vault token create -policy=myapp-policy"
echo ""
echo "📝 注意事项:"
echo "   - 开发模式已启用，不需要 unseal"
echo "   - 生产环境请使用高可用模式并配置存储后端"
echo "   - 建议启用 TLS 和 Kubernetes 认证"