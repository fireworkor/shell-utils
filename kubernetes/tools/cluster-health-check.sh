#!/bin/bash

# =========================================
# Kubernetes 集群健康检查脚本
# =========================================

set -o pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Kubernetes 集群健康检查${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查函数
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}!${NC} $1"
}

# 1. API Server 检查
echo -e "${BLUE}[1] API Server 检查${NC}"
if kubectl get --raw /healthz &>/dev/null; then
    check_pass "API Server 运行正常"
else
    check_fail "API Server 不可用"
fi
echo ""

# 2. 节点状态检查
echo -e "${BLUE}[2] 节点状态${NC}"
total_nodes=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
ready_nodes=$(kubectl get nodes --no-headers 2>/dev/null | grep -c "Ready" || echo 0)

if [ $total_nodes -eq 0 ]; then
    check_fail "没有找到节点"
else
    echo "总节点数: $total_nodes"
    echo "就绪节点: $ready_nodes"
    
    if [ $ready_nodes -eq $total_nodes ]; then
        check_pass "所有节点状态正常"
    else
        check_warn "$((total_nodes - ready_nodes)) 个节点不健康"
    fi
fi

kubectl get nodes -o wide 2>/dev/null || true
echo ""

# 3. 系统组件检查
echo -e "${BLUE}[3] 系统组件${NC}"
components=("kube-apiserver" "kube-controller-manager" "kube-scheduler" "etcd" "kube-proxy" "coredns")

for component in "${components[@]}"; do
    count=$(kubectl get pods -n kube-system -l k8s-app="$component" --no-headers 2>/dev/null | wc -l)
    if [ $count -gt 0 ]; then
        running=$(kubectl get pods -n kube-system -l k8s-app="$component" --no-headers 2>/dev/null | grep -c "Running" || echo 0)
        if [ $running -eq $count ]; then
            check_pass "$component ($running/$count)"
        else
            check_warn "$component ($running/$count)"
        fi
    fi
done
echo ""

# 4. 资源使用检查
echo -e "${BLUE}[4] 资源使用${NC}"

# CPU 和内存使用
echo "节点资源使用:"
kubectl top nodes 2>/dev/null || check_warn "metrics-server 未安装"

echo ""
echo "Pod 资源使用 (Top 10):"
kubectl top pods -A --no-headers 2>/dev/null | head -10 || check_warn "metrics-server 未安装"
echo ""

# 5. 存储检查
echo -e "${BLUE}[5] 存储检查${NC}"
total_pvc=$(kubectl get pvc --all-namespaces --no-headers 2>/dev/null | wc -l)
bound_pvc=$(kubectl get pvc --all-namespaces --no-headers 2>/dev/null | grep -c "Bound" || echo 0)

echo "PVC 状态: $bound_pvc/$total_pvc 已绑定"
if [ $total_pvc -gt 0 ]; then
    if [ $bound_pvc -eq $total_pvc ]; then
        check_pass "所有 PVC 已绑定"
    else
        check_warn "$((total_pvc - bound_pvc)) 个 PVC 未绑定"
    fi
fi
echo ""

# 6. 命名空间检查
echo -e "${BLUE}[6] 命名空间${NC}"
kubectl get namespaces --no-headers 2>/dev/null | grep -v "kube-system" | awk '{print $1, $3}'
echo ""

# 7. Deployment 状态
echo -e "${BLUE}[7] Deployment 状态${NC}"
total_deploy=$(kubectl get deployments --all-namespaces --no-headers 2>/dev/null | wc -l)
available_deploy=$(kubectl get deployments --all-namespaces --no-headers 2>/dev/null | grep -c "1/1\|2/2\|3/3" || echo 0)

echo "Deployment: $available_deploy/$total_deploy 可用"
if [ $total_deploy -gt 0 ]; then
    kubectl get deployments --all-namespaces 2>/dev/null | grep -v "NAMESPACE" || true
fi
echo ""

# 8. Service 状态
echo -e "${BLUE}[8] Service 状态${NC}"
kubectl get services --all-namespaces 2>/dev/null | head -20 || true
echo ""

# 9. 事件检查
echo -e "${BLUE}[9] 最近事件 (Warning)${NC}"
kubectl get events -A --sort-by='.lastTimestamp' 2>/dev/null | grep "Warning" | tail -10 || check_pass "没有 Warning 事件"
echo ""

# 10. 网络检查
echo -e "${BLUE}[10] 网络连接检查${NC}"
if kubectl run test-pod --image=busybox --rm -it --restart=Never -- sh -c "wget -qO- kubernetes.default.svc.cluster.local:80 --timeout=3" &>/dev/null; then
    check_pass "Pod 到 Service 网络正常"
else
    check_warn "Pod 到 Service 网络可能有问题"
fi

if kubectl get ns ingress-nginx 2>/dev/null; then
    ingress_pods=$(kubectl get pods -n ingress-nginx --no-headers 2>/dev/null | grep -c "Running" || echo 0)
    echo "Ingress Controller: $ingress_pods 个运行中"
fi
echo ""

# 11. DNS 检查
echo -e "${BLUE}[11] DNS 检查${NC}"
kubectl run dns-test --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default &>/dev/null && \
    check_pass "DNS 解析正常" || check_warn "DNS 解析可能有问题"
echo ""

# 总结
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  检查完成${NC}"
echo -e "${BLUE}========================================${NC}"

# 输出建议
echo ""
echo -e "${YELLOW}建议:${NC}"
echo "1. 定期检查节点资源使用情况"
echo "2. 确保所有 Deployment 的副本数足够"
echo "3. 监控 PVC 的绑定状态"
echo "4. 定期查看 Warning 事件"
echo "5. 配置适当的资源限制和健康检查"
echo ""
