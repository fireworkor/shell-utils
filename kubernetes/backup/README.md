# Kubernetes 备份和恢复配置

## 概述

使用 Velero 进行 Kubernetes 集群备份和恢复

## 部署步骤

### 1. 安装 Velero CLI
```bash
# macOS
brew install velero

# Linux
wget https://github.com/vmware-tanzu/velero/releases/download/v1.12.0/velero-v1.12.0-linux-amd64.tar.gz
tar -xvf velero-v1.12.0-linux-amd64.tar.gz
sudo mv velero /usr/local/bin/
```

### 2. 部署 MinIO (本地存储)
```bash
kubectl apply -f minio.yaml
```

### 3. 部署 Velero
```bash
# 创建凭证文件
cat > credentials-velero <<EOF
[default]
aws_access_key_id = minioadmin
aws_secret_access_key = minioadmin
EOF

# 部署 Velero
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.8.0 \
  --bucket velero \
  --secret-file ./credentials-velero \
  --backup-location-config region=minio,s3ForcePathStyle="true",publicUrl=http://minio:9000 \
  --snapshot-location-config region=minio \
  --namespace velero
```

### 4. 验证安装
```bash
kubectl get pods -n velero
```

## 使用方法

### 创建备份
```bash
# 备份整个命名空间
velero backup create my-backup --include-namespaces default

# 备份所有命名空间
velero backup create full-backup

# 按标签备份
velero backup create labeled-backup --selector app=myapp

# 排除特定资源
velero backup create my-backup \
  --include-namespaces myapp \
  --exclude-resources secrets,configmaps
```

### 调度备份
```bash
# 每天凌晨 2 点备份
velero schedule create daily-backup \
  --schedule="0 2 * * *" \
  --include-namespaces default

# 每 6 小时备份
velero schedule create six-hourly-backup \
  --schedule="@every 6h" \
  --include-namespaces production

# 保留 30 天
velero schedule create monthly-backup \
  --schedule="@daily" \
  --ttl 720h
```

### 查看备份
```bash
# 列出所有备份
velero backup get

# 查看备份详情
velero backup describe my-backup

# 查看备份日志
velero backup logs my-backup
```

### 恢复
```bash
# 从备份恢复
velero restore create --from-backup my-backup

# 恢复并排除特定资源
velero restore create --from-backup my-backup \
  --exclude-resources pods,deployments

# 查看恢复状态
velero restore get

# 查看恢复详情
velero restore describe <restore-name>
```

### 快照操作
```bash
# 创建快照备份
velero backup create snapshot-backup \
  --include-namespaces production \
  --snapshot-volumes

# 查看快照
velero snapshot-location get
```

## MinIO 控制台

访问 http://localhost:30090 查看备份存储
- 用户名: minioadmin
- 密码: minioadmin
