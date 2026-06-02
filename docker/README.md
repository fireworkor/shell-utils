# Docker 容器化平台

## 简介
Docker 是一个开源的应用容器引擎，让开发者可以打包他们的应用以及依赖包到一个可移植的镜像中。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 2375 | Docker API（非加密） | 不推荐生产 |
| 2376 | Docker API（TLS） | 生产推荐 |
| 9000 | Portainer（可选） | Web 管理界面 |

### 主要组件

- **dockerd** - Docker 守护进程
- **docker** - 命令行客户端
- **containerd** - 容器运行时
- **runc** - 容器运行时
- **docker-compose** - 多容器编排

### 访问入口

- **命令行**: `docker version`
- **API**: `http://<IP>:2375` 或 `https://<IP>:2376`
- **Web 管理**: Portainer（推荐）
- **镜像仓库**: Docker Hub、私有仓库

---

## 首次安装后必做设置

### 1. 验证安装
```bash
docker --version
docker compose version
```

### 2. 添加用户到 docker 组（免 sudo）
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### 3. 配置镜像加速器
```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json << 'EOF'
{
    "registry-mirrors": [
        "https://mirror.ccs.tencentyun.com",
        "https://hub-mirror.c.163.com"
    ]
}
EOF
sudo systemctl restart docker
```

### 4. 配置防火墙
```bash
sudo firewall-cmd --permanent --add-port=2375/tcp
sudo firewall-cmd --reload
```

### 5. 部署 Portainer
```bash
docker volume create portainer_data
docker run -d -p 9000:9000 --name portainer     --restart=always     -v /var/run/docker.sock:/var/run/docker.sock     -v portainer_data:/data     portainer/portainer-ce:latest
```
访问: `http://<IP>:9000`

### 6. 测试
```bash
docker run hello-world
docker run -d -p 80:80 nginx
```

---

## 详细使用说明

### 镜像管理
```bash
docker search nginx
docker pull nginx:latest
docker images
docker rmi <image_id>
docker image prune -a
```

### 容器管理
```bash
docker run -d --name web -p 80:80 nginx
docker run -it ubuntu bash
docker ps
docker ps -a
docker start web
docker stop web
docker restart web
docker exec -it web bash
docker logs web
docker logs -f web
docker rm web
```

### Docker Compose
参见 `docker-compose.yml` 示例配置章节。

---

## 常见问题

### Q: 镜像拉取慢？
A: 配置镜像加速器

### Q: 容器无法访问外网？
A: 检查 DNS、iptables

### Q: 磁盘空间不足？
A: `docker system prune -a`

---

## 后续改进方向

1. Docker Swarm（集群）
2. Kubernetes（生产级编排）
3. CI/CD 集成
4. 镜像安全扫描（Trivy、Clair）
5. 监控告警（cAdvisor + Prometheus）
6. 私有仓库（Harbor）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
