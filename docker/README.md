# Docker 容器引擎

## 简介
Docker 是一个开源的容器化平台，用于开发、部署和运行应用程序。

## 端口信息
- Docker: 2375 (未加密) / 2376 (TLS加密)
- Docker Registry: 5000

## 使用命令

```bash
# 安装 Docker
bash docker.sh

# 启动服务
systemctl start docker
systemctl enable docker

# 查看版本
docker --version
docker-compose --version

# 验证安装
docker run hello-world
```

## 常用 Docker 命令

```bash
# 镜像操作
docker pull nginx:latest
docker images
docker rmi nginx:latest
docker build -t myapp .

# 容器操作
docker run -d --name nginx nginx:latest
docker ps -a
docker start nginx
docker stop nginx
docker restart nginx
docker rm nginx
docker logs -f nginx

# 进入容器
docker exec -it nginx bash

# 查看资源使用
docker stats
docker system df
```

## 默认配置
- 配置文件: `/etc/docker/daemon.json`
- 数据目录: `/var/lib/docker/`
- 日志配置: `/etc/docker/daemon.json`

## 健康检查

```bash
# 检查 Docker 服务
systemctl status docker

# 检查 Docker 版本
docker version

# 检查 Docker 信息
docker info

# 检查容器运行状态
docker ps

# 检查 Docker 存储驱动
docker info | grep "Storage Driver"
```

## 备份

```bash
# 备份 Docker 配置
cp -r /etc/docker /backup/docker_config_$(date +%Y%m%d)

# 备份所有镜像
docker save -o /backup/images_$(date +%Y%m%d).tar $(docker images -q)

# 备份容器（需要先 commit 为镜像）
docker commit nginx nginx_backup
docker save nginx_backup | gzip > /backup/nginx_backup.tar.gz
```

## 恢复

```bash
# 恢复 Docker 配置
cp -r /backup/docker_config_20240101/* /etc/docker/

# 恢复镜像
docker load -i /backup/images_20240101.tar

# 恢复容器镜像
gunzip < /backup/nginx_backup.tar.gz | docker load
```

## Docker Compose

```bash
# 启动服务
docker-compose up -d

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 重新构建
docker-compose up -d --build
```

## Web UI
推荐使用 Portainer 或 DockStation。
