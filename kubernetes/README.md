# Kubernetes 部署和管理工具集

本目录包含完整的 Kubernetes 集群部署、管理、监控、日志、安全和备份解决方案。

## 目录结构

```
kubernetes/
├── k8s-manage.sh          # Kubernetes 管理脚本
├── cluster/               # 集群配置
├── monitoring/            # 监控配置 (Prometheus + Grafana)
├── logging/               # 日志收集 (EFK Stack)
├── security/              # 安全扫描 (Trivy + Falco + Kyverno)
├── backup/                # 备份恢复 (Velero + MinIO)
├── apps/                  # 常见应用部署示例
└── tools/                 # 辅助工具
```

## 功能特性

### 🎯 核心管理
- ✅ 集群信息查看
- ✅ 命名空间管理
- ✅ Pod/Deployment/Service 管理
- ✅ Ingress 管理
- ✅ ConfigMap/Secret 管理
- ✅ Helm 集成
- ✅ 故障排查工具
- ✅ 集群备份和恢复

### 📊 监控和日志
- ✅ Prometheus 指标收集
- ✅ Grafana 可视化仪表板
- ✅ 节点和 Pod 资源监控
- ✅ Elasticsearch 日志存储
- ✅ Fluent Bit 日志收集
- ✅ Kibana 日志分析

### 🔒 安全
- ✅ Trivy 镜像漏洞扫描
- ✅ Falco 运行时安全监控
- ✅ Kyverno 策略引擎
- ✅ 安全策略管理

### 💾 备份恢复
- ✅ Velero 集群备份
- ✅ MinIO 存储后端
- ✅ 定时备份
- ✅ 增量备份
- ✅ 灾难恢复

## 快速开始

### 1. 安装 kubectl
```bash
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### 2. 配置集群访问
```bash
# 复制配置文件
mkdir -p ~/.kube
cp /path/to/kubeconfig ~/.kube/config

# 测试连接
kubectl cluster-info
```

### 3. 使用管理脚本
```bash
# 添加执行权限
chmod +x k8s-manage.sh

# 查看帮助
./k8s-manage.sh help

# 查看集群信息
./k8s-manage.sh info

# 列出所有 Pod
./k8s-manage.sh pods
```

## 部署监控栈

### Prometheus + Grafana
```bash
kubectl apply -f monitoring/

# 访问地址
# Prometheus: http://localhost:30090
# Grafana: http://localhost:30300 (admin/admin123)
```

## 部署日志栈

### EFK (Elasticsearch + Fluent Bit + Kibana)
```bash
kubectl apply -f logging/

# 访问地址
# Kibana: http://localhost:30001
```

## 部署安全工具

### Trivy + Falco + Kyverno
```bash
kubectl apply -f security/

# 扫描镜像
kubectl trivy image nginx:latest

# 查看安全告警
kubectl logs -n falco -l app=falco
```

## 部署备份工具

### Velero + MinIO
```bash
# 部署 MinIO
kubectl apply -f backup/minio.yaml

# 安装 Velero CLI 后
velero install --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.8.0 \
  --bucket velero \
  --secret-file ./credentials-velero \
  --backup-location-config region=minio,s3ForcePathStyle="true",publicUrl=http://minio:9000

# 创建备份
velero backup create my-backup --include-namespaces default
```

## 部署应用示例

### Nginx
```bash
kubectl apply -f apps/nginx.yaml

# 访问地址
# http://localhost:30080
```

### MySQL
```bash
kubectl apply -f apps/mysql.yaml

# 连接信息
# Host: mysql.app.svc.cluster.local
# Port: 3306
```

### WordPress
```bash
kubectl apply -f apps/wordpress.yaml

# 访问地址
# http://localhost:30081
```

### Jenkins
```bash
kubectl apply -f apps/jenkins.yaml

# 访问地址
# http://localhost:30082
```

## 管理脚本命令

### 集群信息
```bash
./k8s-manage.sh info                 # 集群信息
./k8s-manage.sh health               # 健康检查
./k8s-manage.sh resources            # 资源使用
```

### 命名空间
```bash
./k8s-manage.sh ns-list             # 列出命名空间
./k8s-manage.sh ns-create myns       # 创建命名空间
./k8s-manage.sh ns-delete myns       # 删除命名空间
./k8s-manage.sh ns-use myns          # 设置当前命名空间
```

### Pod 管理
```bash
./k8s-manage.sh pods                 # 列出 Pod
./k8s-manage.sh logs myapp           # 查看日志
./k8s-manage.sh exec myapp bash     # 进入容器
./k8s-manage.sh debug myapp          # 故障排查
./k8s-manage.sh delete myapp         # 删除 Pod
./k8s-manage.sh restart myapp        # 重启 Deployment
```

### Deployment 管理
```bash
./k8s-manage.sh deploys              # 列出 Deployment
./k8s-manage.sh scale myapp 3        # 扩缩容
./k8s-manage.sh update myapp nginx:latest  # 更新镜像
./k8s-manage.sh rollback myapp       # 回滚
```

### Service 管理
```bash
./k8s-manage.sh services             # 列出 Service
./k8s-manage.sh svc-create myapp 8080  # 创建 Service
./k8s-manage.sh svc-delete myapp     # 删除 Service
```

### Ingress 管理
```bash
./k8s-manage.sh ingresses            # 列出 Ingress
./k8s-manage.sh ingress-create myapp example.com myservice 80  # 创建 Ingress
```

### 配置管理
```bash
./k8s-manage.sh cm-list              # 列出 ConfigMap
./k8s-manage.sh cm-create myconfig key value  # 创建 ConfigMap
./k8s-manage.sh secret-create mysecret key value  # 创建 Secret
./k8s-manage.sh export deployment myapp  # 导出配置
```

### Helm 操作
```bash
./k8s-manage.sh helm-list            # 列出 Helm Release
./k8s-manage.sh helm-install mynginx bitnami/nginx  # 安装 Chart
./k8s-manage.sh helm-upgrade mynginx bitnami/nginx  # 升级
./k8s-manage.sh helm-uninstall mynginx  # 卸载
```

### 备份恢复
```bash
./k8s-manage.sh backup              # 备份集群配置
./k8s-manage.sh cleanup             # 清理所有资源
```

## 常用 Kubernetes 查询

### 节点信息
```bash
kubectl get nodes -o wide
kubectl describe node <node-name>
kubectl top node
```

### Pod 信息
```bash
kubectl get pods -A -o wide
kubectl top pods -A
kubectl logs <pod-name> -f
kubectl exec -it <pod-name> -- /bin/bash
```

### 服务信息
```bash
kubectl get svc -A
kubectl get ingress -A
kubectl get endpoints -A
```

### 资源配额
```bash
kubectl get resourcequotas -A
kubectl get limitranges -A
kubectl describe resourcequotas -n <namespace>
```

### 事件
```bash
kubectl get events -A
kubectl get events --sort-by='.lastTimestamp'
kubectl get events --field-selector involvedObject.name=<pod-name>
```

## 故障排查

### Pod 无法启动
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous
```

### Service 无法访问
```bash
kubectl get endpoints <service-name>
kubectl describe service <service-name>
kubectl get pods -l app=<app-name> -o wide
```

### 网络问题
```bash
kubectl run test --rm -it --image=busybox -- wget -qO- <service>:<port>
kubectl run dnsutils --rm -it --image=tutum/dnsutils -- nslookup <service>
```

## 最佳实践

### 1. 资源限制
```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### 2. 健康检查
```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5

livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 10
```

### 3. 标签和选择器
```yaml
metadata:
  labels:
    app: myapp
    tier: frontend
    environment: production
```

### 4. 持久化存储
```yaml
volumes:
  - name: data
    persistentVolumeClaim:
      claimName: my-pvc
```

## 性能优化

### 1. 合理设置副本数
```yaml
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

### 2. 使用反亲和性
```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app: myapp
          topologyKey: kubernetes.io/hostname
```

### 3. 优先级和抢占
```yaml
priorityClassName: high-priority
```

## 安全加固

### 1. 使用非 root 用户
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 2000
```

### 2. 限制 capabilities
```yaml
securityContext:
  capabilities:
    drop:
      - ALL
```

### 3. NetworkPolicy
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: myapp-network-policy
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
    - Ingress
    - Egress
```

## 贡献指南

欢迎提交新的配置示例！请确保：
1. 使用稳定版本的镜像
2. 配置资源限制
3. 添加健康检查
4. 使用持久化存储
5. 添加详细注释

## 许可证

MIT License
