#!/bin/bash

# =========================================
# Kubernetes 管理脚本
# 功能：集群管理、应用部署、监控、日志、安全等
# 需求：kubectl, helm (可选)
# =========================================

set -o pipefail

# 配置
readonly KUBECTL_CONTEXT="${KUBECTL_CONTEXT:-}"
readonly NAMESPACE="${NAMESPACE:-default}"
readonly KUBECONFIG="${KUBECONFIG:-~/.kube/config}"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" 
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    if ! command -v kubectl &>/dev/null; then
        log_error "kubectl 未安装"
        log_info "安装 kubectl: https://kubernetes.io/docs/tasks/tools/"
        return 1
    fi
    
    if command -v helm &>/dev/null; then
        log_success "helm 已安装"
        HELM_AVAILABLE=true
    else
        log_warn "helm 未安装，部分功能不可用"
        HELM_AVAILABLE=false
    fi
    
    return 0
}

# 显示集群信息
show_cluster_info() {
    log_info "Kubernetes 集群信息"
    echo "========================================="
    
    kubectl cluster-info 2>/dev/null || log_error "无法连接到集群"
    
    echo ""
    log_info "集群节点:"
    kubectl get nodes -o wide
    
    echo ""
    log_info "集群版本:"
    kubectl version --short 2>/dev/null || kubectl version
    
    echo ""
    log_info "API Server:"
    kubectl cluster-info | head -1
}

# 命名空间管理
namespace_list() {
    log_info "所有命名空间:"
    kubectl get namespaces
}

namespace_create() {
    local ns=$1
    if [ -z "$ns" ]; then
        log_error "请指定命名空间名称"
        return 1
    fi
    
    log_info "创建命名空间: $ns"
    kubectl create namespace "$ns"
    kubectl label namespace "$ns" name="$ns"
    log_success "命名空间 $ns 创建成功"
}

namespace_delete() {
    local ns=$1
    if [ -z "$ns" ]; then
        log_error "请指定命名空间名称"
        return 1
    fi
    
    log_warn "删除命名空间: $ns"
    read -p "确认删除? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        kubectl delete namespace "$ns"
        log_success "命名空间 $ns 删除成功"
    else
        log_info "取消删除"
    fi
}

namespace_use() {
    local ns=$1
    if [ -z "$ns" ]; then
        log_error "请指定命名空间名称"
        return 1
    fi
    
    kubectl config set-context --current --namespace="$ns"
    log_success "当前命名空间设置为: $ns"
}

# Pod 管理
pod_list() {
    local ns=${1:-$NAMESPACE}
    log_info "Pod 列表 (命名空间: $ns):"
    kubectl get pods -n "$ns" -o wide
}

pod_logs() {
    local pod=$1
    local ns=${2:-$NAMESPACE}
    local lines=${3:-100}
    
    if [ -z "$pod" ]; then
        log_error "请指定 Pod 名称"
        return 1
    fi
    
    log_info "查看 Pod 日志: $pod (命名空间: $ns)"
    kubectl logs -n "$ns" --tail="$lines" -f "$pod"
}

pod_exec() {
    local pod=$1
    local ns=${2:-$NAMESPACE}
    shift 2
    local cmd="$@"
    
    if [ -z "$pod" ]; then
        log_error "请指定 Pod 名称"
        return 1
    fi
    
    if [ -z "$cmd" ]; then
        cmd="bash"
    fi
    
    log_info "进入 Pod: $pod (命名空间: $ns)"
    kubectl exec -it -n "$ns" "$pod" -- "$cmd"
}

pod_describe() {
    local pod=$1
    local ns=${2:-$NAMESPACE}
    
    if [ -z "$pod" ]; then
        log_error "请指定 Pod 名称"
        return 1
    fi
    
    kubectl describe pod -n "$ns" "$pod"
}

pod_delete() {
    local pod=$1
    local ns=${2:-$NAMESPACE}
    
    if [ -z "$pod" ]; then
        log_error "请指定 Pod 名称"
        return 1
    fi
    
    log_warn "删除 Pod: $pod (命名空间: $ns)"
    kubectl delete pod -n "$ns" "$pod"
    log_success "Pod 删除成功"
}

pod_restart() {
    local deployment=$1
    local ns=${2:-$NAMESPACE}
    
    if [ -z "$deployment" ]; then
        log_error "请指定 Deployment 名称"
        return 1
    fi
    
    log_info "重启 Deployment: $deployment (命名空间: $ns)"
    kubectl rollout restart deployment -n "$ns" "$deployment"
    log_success "重启成功"
}

# Deployment 管理
deployment_list() {
    local ns=${1:-$NAMESPACE}
    log_info "Deployment 列表 (命名空间: $ns):"
    kubectl get deployments -n "$ns"
}

deployment_scale() {
    local name=$1
    local replicas=$2
    local ns=${3:-$NAMESPACE}
    
    if [ -z "$name" ] || [ -z "$replicas" ]; then
        log_error "请指定 Deployment 名称和副本数"
        return 1
    fi
    
    log_info "扩缩容 Deployment: $name -> $replicas 副本"
    kubectl scale deployment -n "$ns" "$name" --replicas="$replicas"
    log_success "扩缩容成功"
}

deployment_update() {
    local name=$1
    local image=$2
    local ns=${3:-$NAMESPACE}
    
    if [ -z "$name" ] || [ -z "$image" ]; then
        log_error "请指定 Deployment 名称和镜像"
        return 1
    fi
    
    log_info "更新 Deployment: $name -> $image"
    kubectl set image deployment/"$name" "$name"="$image" -n "$ns"
    log_success "更新成功"
}

deployment_rollback() {
    local name=$1
    local ns=${2:-$NAMESPACE}
    
    if [ -z "$name" ]; then
        log_error "请指定 Deployment 名称"
        return 1
    fi
    
    log_info "回滚 Deployment: $name"
    kubectl rollout undo deployment/"$name" -n "$ns"
    log_success "回滚成功"
}

# Service 管理
service_list() {
    local ns=${1:-$NAMESPACE}
    log_info "Service 列表 (命名空间: $ns):"
    kubectl get services -n "$ns" -o wide
}

service_create() {
    local name=$1
    local port=$2
    local target=$3
    local ns=${4:-$NAMESPACE}
    
    if [ -z "$name" ] || [ -z "$port" ]; then
        log_error "请指定 Service 名称和端口"
        return 1
    fi
    
    log_info "创建 Service: $name (端口: $port)"
    kubectl expose deployment "$name" --name="$name" --port="$port" \
        --target-port="${target:-$port}" --type=ClusterIP -n "$ns"
    log_success "Service 创建成功"
}

service_delete() {
    local name=$1
    local ns=${2:-$NAMESPACE}
    
    if [ -z "$name" ]; then
        log_error "请指定 Service 名称"
        return 1
    fi
    
    kubectl delete service -n "$ns" "$name"
    log_success "Service 删除成功"
}

# Ingress 管理
ingress_list() {
    local ns=${1:-$NAMESPACE}
    log_info "Ingress 列表 (命名空间: $ns):"
    kubectl get ingress -n "$ns"
}

ingress_create() {
    local name=$1
    local host=$2
    local service=$3
    local port=$4
    local ns=${5:-$NAMESPACE}
    
    if [ -z "$name" ] || [ -z "$host" ] || [ -z "$service" ]; then
        log_error "请指定完整参数: name, host, service, port"
        return 1
    fi
    
    log_info "创建 Ingress: $name"
    
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $name
  namespace: $ns
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: $host
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: $service
            port:
              number: $port
EOF
    
    log_success "Ingress 创建成功"
}

# ConfigMap 和 Secret
configmap_list() {
    local ns=${1:-$NAMESPACE}
    kubectl get configmaps -n "$ns"
}

configmap_create() {
    local name=$1
    local key=$2
    local value=$3
    local ns=${4:-$NAMESPACE}
    
    if [ -z "$name" ] || [ -z "$key" ] || [ -z "$value" ]; then
        log_error "请指定完整参数: name, key, value"
        return 1
    fi
    
    kubectl create configmap -n "$ns" "$name" --from-literal="$key=$value"
    log_success "ConfigMap 创建成功"
}

secret_create() {
    local name=$1
    local key=$2
    local value=$3
    local ns=${4:-$NAMESPACE}
    
    if [ -z "$name" ] || [ -z "$key" ] || [ -z "$value" ]; then
        log_error "请指定完整参数: name, key, value"
        return 1
    fi
    
    kubectl create secret generic -n "$ns" "$name" --from-literal="$key=$value"
    log_success "Secret 创建成功"
}

# 资源使用情况
resource_usage() {
    log_info "节点资源使用情况:"
    kubectl top nodes
    
    echo ""
    log_info "Pod 资源使用情况:"
    kubectl top pods -A | head -20
}

# 健康检查
health_check() {
    log_info "集群健康检查"
    echo "========================================="
    
    log_info "检查 API Server..."
    kubectl get --raw /healthz
    
    echo ""
    log_info "检查 CoreDNS..."
    kubectl get pods -n kube-system -l k8s-app=kube-dns
    
    echo ""
    log_info "检查 etcd..."
    kubectl get pods -n kube-system -l component=etcd
    
    echo ""
    log_info "检查 kube-proxy..."
    kubectl get pods -n kube-system -l k8s-app=kube-proxy
}

# 故障排查
debug_pod() {
    local pod=$1
    local ns=${2:-$NAMESPACE}
    
    if [ -z "$pod" ]; then
        log_error "请指定 Pod 名称"
        return 1
    fi
    
    log_info "故障排查: $pod"
    echo "========================================="
    
    echo "Pod 状态:"
    kubectl get pod -n "$ns" "$pod" -o wide
    
    echo ""
    echo "Pod 描述:"
    kubectl describe pod -n "$ns" "$pod"
    
    echo ""
    echo "Pod 日志 (最近 50 行):"
    kubectl logs -n "$ns" --tail=50 "$pod" || true
    
    echo ""
    echo "上一个容器的日志:"
    kubectl logs -n "$ns" --tail=50 "$pod" -p || true
}

# 导出配置
export_config() {
    local resource=$1
    local name=$2
    local ns=${3:-$NAMESPACE}
    local output=${4:-./${name}.yaml}
    
    if [ -z "$resource" ] || [ -z "$name" ]; then
        log_error "请指定资源类型和名称"
        return 1
    fi
    
    log_info "导出配置: $resource/$name"
    kubectl get "$resource" -n "$ns" "$name" -o yaml > "$output"
    log_success "配置已导出到: $output"
}

# 应用部署（使用 YAML）
apply_manifest() {
    local file=$1
    
    if [ -z "$file" ]; then
        log_error "请指定 YAML 文件"
        return 1
    fi
    
    if [ ! -f "$file" ]; then
        log_error "文件不存在: $file"
        return 1
    fi
    
    log_info "应用配置: $file"
    kubectl apply -f "$file"
    log_success "配置应用成功"
}

# Helm 操作
helm_install() {
    if [ "$HELM_AVAILABLE" != "true" ]; then
        log_error "Helm 未安装"
        return 1
    fi
    
    local name=$1
    local chart=$2
    local ns=${3:-default}
    shift 3
    local extra_args="$@"
    
    if [ -z "$name" ] || [ -z "$chart" ]; then
        log_error "请指定 Release 名称和 Chart"
        return 1
    fi
    
    log_info "安装 Helm Chart: $name ($chart)"
    helm install "$name" "$chart" -n "$ns" $extra_args
    log_success "安装成功"
}

helm_upgrade() {
    if [ "$HELM_AVAILABLE" != "true" ]; then
        log_error "Helm 未安装"
        return 1
    fi
    
    local name=$1
    local chart=$2
    shift 2
    local extra_args="$@"
    
    if [ -z "$name" ] || [ -z "$chart" ]; then
        log_error "请指定 Release 名称和 Chart"
        return 1
    fi
    
    log_info "升级 Helm Release: $name ($chart)"
    helm upgrade "$name" "$chart" $extra_args
    log_success "升级成功"
}

helm_list() {
    if [ "$HELM_AVAILABLE" != "true" ]; then
        log_error "Helm 未安装"
        return 1
    fi
    
    local ns=${1:-default}
    helm list -n "$ns"
}

helm_uninstall() {
    if [ "$HELM_AVAILABLE" != "true" ]; then
        log_error "Helm 未安装"
        return 1
    fi
    
    local name=$1
    local ns=${2:-default}
    
    if [ -z "$name" ]; then
        log_error "请指定 Release 名称"
        return 1
    fi
    
    log_warn "卸载 Helm Release: $name"
    helm uninstall "$name" -n "$ns"
    log_success "卸载成功"
}

# 完整集群备份
backup_cluster() {
    local backup_dir=${1:-./k8s-backup-$(date +%Y%m%d)}
    
    log_info "创建集群备份: $backup_dir"
    mkdir -p "$backup_dir"
    
    # 备份所有命名空间
    kubectl get namespaces -o json | jq '.items[]' > "$backup_dir/namespaces.json"
    
    # 备份所有配置
    for ns in $(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}'); do
        log_info "备份命名空间: $ns"
        mkdir -p "$backup_dir/$ns"
        kubectl get all -n "$ns" -o yaml > "$backup_dir/$ns/resources.yaml"
        kubectl get configmaps -n "$ns" -o yaml >> "$backup_dir/$ns/resources.yaml"
        kubectl get secrets -n "$ns" -o yaml >> "$backup_dir/$ns/resources.yaml"
        kubectl get persistentvolumeclaims -n "$ns" -o yaml >> "$backup_dir/$ns/resources.yaml"
    done
    
    log_success "备份完成: $backup_dir"
}

# 完整集群清理
cleanup_cluster() {
    log_warn "即将清理所有资源（除 kube-system）..."
    
    echo "========================================="
    echo "将清理以下命名空间中的所有资源:"
    kubectl get namespaces | grep -v kube-system | awk '{print $1}' | tail -n +2
    echo "========================================="
    
    read -p "确认清理? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        log_info "取消清理"
        return 0
    fi
    
    for ns in $(kubectl get namespaces | grep -v kube-system | awk '{print $1}' | tail -n +2); do
        log_info "清理命名空间: $ns"
        kubectl delete namespace "$ns"
    done
    
    log_success "清理完成"
}

# 端口转发
port_forward() {
    local resource=$1
    local name=$2
    local port=$3
    local target_port=${4:-$port}
    local ns=${5:-$NAMESPACE}
    
    if [ -z "$resource" ] || [ -z "$name" ] || [ -z "$port" ]; then
        log_error "请指定资源类型、名称和端口"
        return 1
    fi
    
    log_info "端口转发: localhost:$port -> $resource/$name:$target_port"
    kubectl port-forward -n "$ns" "$resource/$name" "$port:$target_port"
}

# 显示帮助
show_help() {
    cat <<EOF
${GREEN}Kubernetes 管理脚本${NC}

${YELLOW}使用方法:${NC} $0 <命令> [参数]

${BLUE}集群信息:${NC}
  info                    显示集群信息
  health                  健康检查
  resources               资源使用情况

${BLUE}命名空间管理:${NC}
  ns-list                 列出命名空间
  ns-create <名称>         创建命名空间
  ns-delete <名称>         删除命名空间
  ns-use <名称>           设置当前命名空间

${BLUE}Pod 管理:${NC}
  pods [命名空间]          列出 Pod
  logs <Pod> [ns] [行数]  查看日志
  exec <Pod> [ns] [命令]   进入 Pod
  describe <Pod> [ns]      查看 Pod 详情
  delete <Pod> [ns]       删除 Pod
  restart <Deployment> [ns] 重启 Deployment

${BLUE}Deployment 管理:${NC}
  deploys [命名空间]        列出 Deployment
  scale <名称> <副本数> [ns] 扩缩容
  update <名称> <镜像> [ns]  更新镜像
  rollback <名称> [ns]     回滚

${BLUE}Service 管理:${NC}
  services [命名空间]       列出 Service
  svc-create <名称> <端口> [目标端口] [ns]  创建 Service
  svc-delete <名称> [ns]    删除 Service

${BLUE}Ingress 管理:${NC}
  ingresses [命名空间]       列出 Ingress
  ingress-create <名称> <域名> <服务> <端口> [ns]  创建 Ingress

${BLUE}配置管理:${NC}
  cm-list [ns]             列出 ConfigMap
  cm-create <名称> <键> <值> [ns]  创建 ConfigMap
  secret-create <名称> <键> <值> [ns]  创建 Secret
  export <类型> <名称> [ns] [文件]  导出配置

${BLUE}部署操作:${NC}
  apply <YAML文件>          应用 YAML 配置
  helm-install <名称> <Chart> [ns] [参数]  安装 Helm
  helm-upgrade <名称> <Chart> [参数]       升级 Helm
  helm-list [ns]            列出 Helm Release
  helm-uninstall <名称> [ns]  卸载 Helm

${BLUE}故障排查:${NC}
  debug <Pod> [ns]          故障排查
  pf <类型> <名称> <端口> [目标端口] [ns]  端口转发

${BLUE}备份恢复:${NC}
  backup [目录]              备份集群配置
  cleanup                   清理所有资源

${BLUE}示例:${NC}
  $0 info
  $0 pods
  $0 logs myapp default 100
  $0 exec myapp default bash
  $0 deploys
  $0 scale myapp 3
  $0 update myapp nginx:latest
  $0 apply nginx.yaml
  $0 helm-install mynginx bitnami/nginx
  $0 backup
  $0 pf deployment myapp 8080 80

EOF
}

# 主函数
main() {
    local command=${1:-help}
    shift || true
    
    check_dependencies || exit 1
    
    case "$command" in
        info)
            show_cluster_info
            ;;
        health)
            health_check
            ;;
        resources)
            resource_usage
            ;;
        ns-list)
            namespace_list
            ;;
        ns-create)
            namespace_create "$@"
            ;;
        ns-delete)
            namespace_delete "$@"
            ;;
        ns-use)
            namespace_use "$@"
            ;;
        pods)
            pod_list "$@"
            ;;
        logs)
            pod_logs "$@"
            ;;
        exec)
            pod_exec "$@"
            ;;
        describe)
            pod_describe "$@"
            ;;
        delete)
            pod_delete "$@"
            ;;
        restart)
            pod_restart "$@"
            ;;
        deploys)
            deployment_list "$@"
            ;;
        scale)
            deployment_scale "$@"
            ;;
        update)
            deployment_update "$@"
            ;;
        rollback)
            deployment_rollback "$@"
            ;;
        services)
            service_list "$@"
            ;;
        svc-create)
            service_create "$@"
            ;;
        svc-delete)
            service_delete "$@"
            ;;
        ingresses)
            ingress_list "$@"
            ;;
        ingress-create)
            ingress_create "$@"
            ;;
        cm-list)
            configmap_list "$@"
            ;;
        cm-create)
            configmap_create "$@"
            ;;
        secret-create)
            secret_create "$@"
            ;;
        export)
            export_config "$@"
            ;;
        apply)
            apply_manifest "$@"
            ;;
        helm-install)
            helm_install "$@"
            ;;
        helm-upgrade)
            helm_upgrade "$@"
            ;;
        helm-list)
            helm_list "$@"
            ;;
        helm-uninstall)
            helm_uninstall "$@"
            ;;
        debug)
            debug_pod "$@"
            ;;
        backup)
            backup_cluster "$@"
            ;;
        cleanup)
            cleanup_cluster
            ;;
        pf)
            port_forward "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
