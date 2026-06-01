# Kubernetes 安全扫描配置

## 概述

本目录包含 Kubernetes 安全扫描工具的配置：
- **Trivy**: 容器镜像漏洞扫描
- **Falco**: 运行时安全监控
- **Kyverno**: Kubernetes 策略引擎

## 快速部署

### Trivy 部署
```bash
kubectl create namespace security
kubectl apply -f trivy.yaml
```

### Falco 部署
```bash
kubectl apply -f falco.yaml
```

### Kyverno 部署
```bash
kubectl apply -f kyverno.yaml
```

## 使用方法

### Trivy 扫描

```bash
# 扫描镜像
kubectl trivy image nginx:latest

# 扫描 K8s 资源
kubectl trivy k8s deployment/myapp

# 扫描整个集群
kubectl trivy k8s cluster
```

### Falco 告警

```bash
# 查看 Falco 日志
kubectl logs -n security -l app=falco

# 查看告警
kubectl get events -n security --watch
```

### Kyverno 策略

```bash
# 查看策略
kubectl get clusterpolicies

# 查看策略违规
kubectl get polr -A
```
