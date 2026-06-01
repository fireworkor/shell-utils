# Kubernetes Prometheus + Grafana 监控配置

## 架构

```
┌─────────────┐
│   Grafana   │◄── Dashboard 可视化
└──────┬──────┘
       │ 3000
┌──────▼──────┐
│ Prometheus  │◄── 指标收集
└──────┬──────┘
       │ 9090
┌──────▼──────┐
│ Kube-state  │◄── Kubernetes 对象状态
└─────────────┘
       │
┌──────▼──────┐
│ Node Exp.   │◄── 节点指标
└─────────────┘
       │
┌──────▼──────┐
│   Kubelet   │◄── Pod 指标
└─────────────┘
```

## 部署方法

### 方法 1：使用 Helm (推荐)

```bash
# 添加 Helm 仓库
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 安装 kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.retention=30d \
  --set grafana.adminPassword='admin123'
```

### 方法 2：手动部署 YAML

```bash
kubectl apply -f prometheus-operator.yaml
kubectl apply -f prometheus.yaml
kubectl apply -f grafana.yaml
kubectl apply -f node-exporter.yaml
kubectl apply -f kube-state-metrics.yaml
```

## 访问

- **Grafana**: http://localhost:3000 (用户名: admin, 密码: admin123)
- **Prometheus**: http://localhost:9090

## 常用查询

### 节点资源使用
```promql
# CPU 使用率
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# 内存使用率
100 - ((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100)

# 磁盘使用率
100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)
```

### Pod 资源使用
```promql
# Pod CPU 使用
sum by (pod, namespace) (rate(container_cpu_usage_seconds_total[5m]))

# Pod 内存使用
sum by (pod, namespace) (container_memory_working_set_bytes)

# Pod 网络流量
rate(container_network_receive_bytes_total[5m])
```

### Kubernetes 状态
```promql
# Pod 运行数量
count by (namespace) (kube_pod_info)

# Deployment 可用副本
kube_deployment_status_replicas_available

# Service 端点数量
count by (namespace) (kube_endpoint_info)
```
