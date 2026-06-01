# Docker 管理脚本

功能强大的 Docker 容器管理工具，支持安装、配置、镜像管理、容器管理、监控、日志、清理、备份恢复等操作。

## 功能特性

### 📦 安装与配置
- 自动检测操作系统并安装 Docker
- 配置 Docker 镜像加速器
- 安装 Docker Compose V2
- 一键卸载

### 🖼️ 镜像管理
- 拉取镜像
- 列出镜像（支持表格/JSON格式）
- 删除镜像
- 批量清理未使用镜像
- 备份/恢复所有镜像

### 🐳 容器管理
- 启动/停止/重启容器
- 查看容器日志
- 进入容器执行命令
- 查看容器详细信息
- 容器健康检查
- 容器资源监控

### 📊 监控与日志
- 实时容器资源监控
- 查看容器日志
- Docker 系统信息
- 磁盘使用统计

### 🧹 清理功能
- 清理已停止容器
- 清理未使用镜像
- 清理未使用卷
- 清理构建缓存
- 完整清理

### 💾 备份恢复
- 备份单个容器
- 恢复容器
- 备份所有镜像
- 恢复镜像

### ⚡ 批量操作
- 批量启动容器
- 批量停止容器
- 批量删除容器

### 🎼 Docker Compose
- 启动/停止/重启 Compose
- 查看日志
- 查看服务状态

## 使用方法

### 基础命令

```bash
# 安装 Docker
sudo ./docker-manager.sh install

# 查看 Docker 信息
sudo ./docker-manager.sh info

# 查看帮助
./docker-manager.sh help
```

### 镜像管理

```bash
# 拉取镜像
sudo ./docker-manager.sh pull nginx:latest

# 列出镜像
sudo ./docker-manager.sh images

# 删除镜像
sudo ./docker-manager.sh rmi nginx:latest

# 清理未使用镜像
sudo ./docker-manager.sh clean-images
```

### 容器管理

```bash
# 列出容器
sudo ./docker-manager.sh ps

# 列出所有容器（包括已停止）
sudo ./docker-manager.sh ps all

# 启动容器
sudo ./docker-manager.sh start myapp

# 停止容器
sudo ./docker-manager.sh stop myapp

# 重启容器
sudo ./docker-manager.sh restart myapp

# 删除容器
sudo ./docker-manager.sh rm myapp

# 强制删除容器
sudo ./docker-manager.sh rm myapp -f

# 查看容器日志
sudo ./docker-manager.sh logs myapp 200

# 实时查看日志
sudo ./docker-manager.sh logs myapp 100 -f

# 进入容器
sudo ./docker-manager.sh exec myapp bash

# 查看容器详情
sudo ./docker-manager.sh inspect myapp

# 容器健康检查
sudo ./docker-manager.sh health myapp

# 监控容器资源
sudo ./docker-manager.sh monitor myapp
```

### 批量操作

```bash
# 批量启动匹配的容器
sudo ./docker-manager.sh batch-start myapp

# 批量停止匹配的容器
sudo ./docker-manager.sh batch-stop myapp

# 批量删除匹配的容器
sudo ./docker-manager.sh batch-rm myapp
```

### Docker Compose

```bash
# 启动 Compose
sudo ./docker-manager.sh compose-up docker-compose.yml

# 停止 Compose
sudo ./docker-manager.sh compose-down docker-compose.yml

# 重启 Compose
sudo ./docker-manager.sh compose-restart docker-compose.yml

# 查看日志
sudo ./docker-manager.sh compose-logs docker-compose.yml

# 查看指定服务日志
sudo ./docker-manager.sh compose-logs docker-compose.yml web 200

# 查看服务状态
sudo ./docker-manager.sh compose-ps docker-compose.yml
```

### 清理操作

```bash
# 清理已停止容器
sudo ./docker-manager.sh clean-containers

# 清理未使用卷
sudo ./docker-manager.sh clean-volumes

# 完整清理
sudo ./docker-manager.sh clean
```

### 备份恢复

```bash
# 备份容器
sudo ./docker-manager.sh backup myapp /backups

# 恢复容器
sudo ./docker-manager.sh restore /backups/myapp_20240101_120000.tar new_container

# 备份所有镜像
sudo ./docker-manager.sh backup-images /backups

# 恢复镜像
sudo ./docker-manager.sh restore-images /backups/images_20240101_120000.tar
```

### 监控与信息

```bash
# 查看 Docker 信息
sudo ./docker-manager.sh info

# 查看系统信息
sudo ./docker-manager.sh system-info

# 查看磁盘使用
sudo ./docker-manager.sh disk-usage

# 实时监控所有容器
sudo ./docker-manager.sh stats
```

## 常用场景

### 部署 Web 应用

```bash
# 1. 拉取镜像
sudo ./docker-manager.sh pull nginx:latest

# 2. 运行容器
docker run -d --name web -p 80:80 nginx:latest

# 3. 查看状态
sudo ./docker-manager.sh ps

# 4. 查看日志
sudo ./docker-manager.sh logs web 100
```

### 部署 MySQL

```bash
# 1. 拉取镜像
sudo ./docker-manager.sh pull mysql:8.0

# 2. 运行容器
docker run -d --name mysql \
  -e MYSQL_ROOT_PASSWORD=password \
  -v mysql_data:/var/lib/mysql \
  -p 3306:3306 \
  mysql:8.0

# 3. 健康检查
sudo ./docker-manager.sh health mysql
```

### 使用 Docker Compose 部署 LNMP

```bash
# 创建 docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
  php:
    image: php:fpm
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: password
EOF

# 启动
sudo ./docker-manager.sh compose-up

# 查看状态
sudo ./docker-manager.sh compose-ps

# 查看日志
sudo ./docker-manager.sh compose-logs
```

### 定期清理维护

```bash
# 清理未使用资源
sudo ./docker-manager.sh clean

# 查看磁盘使用
sudo ./docker-manager.sh disk-usage

# 备份所有镜像
sudo ./docker-manager.sh backup-images /backups
```

## 注意事项

1. **权限要求**：大部分操作需要 root 权限
2. **数据安全**：删除容器前请确保数据已备份
3. **镜像加速**：脚本已内置多个镜像加速器
4. **磁盘空间**：定期清理未使用资源
5. **日志查看**：大量日志时使用行数限制

## 配置文件

Docker 配置文件位置：`/etc/docker/daemon.json`

```json
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
```

## 故障排查

### Docker 服务无法启动

```bash
# 查看服务状态
systemctl status docker

# 查看日志
journalctl -u docker -n 50

# 重启服务
systemctl restart docker
```

### 容器无法访问网络

```bash
# 检查 Docker 网络
docker network ls

# 检查容器网络
docker inspect myapp | grep -A 20 NetworkSettings
```

### 磁盘空间不足

```bash
# 查看磁盘使用
sudo ./docker-manager.sh disk-usage

# 清理
sudo ./docker-manager.sh clean
```

## 贡献指南

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License
