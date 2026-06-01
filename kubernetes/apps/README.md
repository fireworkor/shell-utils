# 常见应用部署示例

## 目录内容

本目录包含常用的 Kubernetes 应用部署配置：

### 数据库应用
- `mysql.yaml` - MySQL 单实例部署
- `mysql-cluster.yaml` - MySQL 主从复制
- `postgres.yaml` - PostgreSQL 部署
- `mongodb.yaml` - MongoDB 部署
- `redis.yaml` - Redis 部署

### Web 应用
- `nginx.yaml` - Nginx 部署
- `apache.yaml` - Apache 部署
- `tomcat.yaml` - Tomcat 部署

### CMS 和博客
- `wordpress.yaml` - WordPress 部署
- `ghost.yaml` - Ghost 博客

### 开发工具
- `jenkins.yaml` - Jenkins CI/CD
- `gitlab.yaml` - GitLab 代码仓库

### 消息队列
- `rabbitmq.yaml` - RabbitMQ 部署
- `kafka.yaml` - Kafka 部署

## 快速部署

```bash
# 部署 MySQL
kubectl apply -f mysql.yaml

# 部署 Nginx
kubectl apply -f nginx.yaml

# 部署 WordPress
kubectl apply -f wordpress.yaml
```

## 常见操作

### 查看部署状态
```bash
kubectl get pods -n app
kubectl get svc -n app
kubectl get pvc -n app
```

### 扩缩容
```bash
kubectl scale deployment mysql --replicas=3 -n app
```

### 更新镜像
```bash
kubectl set image deployment/nginx nginx=nginx:1.25 -n app
```

### 清理
```bash
kubectl delete -f nginx.yaml
```
