#!/bin/bash
# K3s 信息脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "K3s - 轻量级 Kubernetes 发行版"
echo "================================"
echo ""
echo "端口:"
echo "  API Server: 6443"
echo "  Flannel VXLAN: 8472"
echo "  Flannel Wireguard: 51820"
echo "  Metrics Server: 10250"
echo ""
echo "配置路径:"
echo "  配置文件: /etc/rancher/k3s/k3s.yaml"
echo "  数据目录: /var/lib/rancher/k3s"
echo "  Token 文件: /var/lib/rancher/k3s/server/node-token"
echo ""
echo "常用命令:"
echo "  查看节点: k3s kubectl get nodes"
echo "  查看 Pod: k3s kubectl get pods -A"
echo "  查看服务: k3s kubectl get svc -A"
echo "  卸载: /usr/local/bin/k3s-uninstall.sh"
