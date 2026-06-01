# Kubernetes EFK (Elasticsearch + Fluent Bit + Kibana) 日志收集

## 架构

```
┌────────────────────────────────────────────────────────────┐
│                        Kibana                               │
│                   (可视化界面 :5601)                        │
└────────────────────────────┬───────────────────────────────┘
                             │
┌────────────────────────────▼───────────────────────────────┐
│                      Elasticsearch                         │
│                    (搜索引擎 :9200)                        │
└────────────────────────────┬───────────────────────────────┘
                             │
┌────────────────────────────▼───────────────────────────────┐
│                       Fluent Bit                           │
│                   (日志收集器 DaemonSet)                    │
└────────────────────────────┬───────────────────────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
    ┌─────────┐        ┌─────────┐        ┌─────────┐
    │  Node 1 │        │  Node 2 │        │  Node 3 │
    └─────────┘        └─────────┘        └─────────┘
```

## 部署方法

```bash
# 创建命名空间
kubectl create namespace logging

# 部署 Elasticsearch
kubectl apply -f elasticsearch.yaml

# 部署 Fluent Bit
kubectl apply -f fluent-bit.yaml

# 部署 Kibana
kubectl apply -f kibana.yaml

# 检查状态
kubectl get pods -n logging
```

## 访问

- **Kibana**: http://localhost:30001 (需要等待 Elasticsearch 启动完成)

## 常用查询

### 查询所有日志
```
* 
```

### 查询特定命名空间的日志
```
kubernetes.namespace_name: default
```

### 查询特定 Pod 的日志
```
kubernetes.pod_name: myapp-*
```

### 查询错误日志
```
level: error OR kubernetes.labels.app: myapp AND log: *error*
```

### 查询最近 1 小时的日志
```
@timestamp: [now-1h TO now]
```
