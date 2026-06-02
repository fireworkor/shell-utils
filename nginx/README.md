# Nginx Web 服务器

## 简介
Nginx (engine x) 是一个高性能的 HTTP 和反向代理服务器，特点是占有内存少，并发能力强，事实上 Nginx 的并发能力确实在同类型的网页服务器中表现较好。

---

## 快速开始

### 1. 安装
```bash
cd nginx
sudo bash install.sh
```

### 2. 查看软件信息
```bash
bash info.sh
```

### 3. 检查健康状态
```bash
bash healthcheck.sh
```

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 80 | HTTP | 提供 HTTP 访问 |
| 443 | HTTPS | 提供 HTTPS 访问（需要 SSL 证书） |

### 主要组件

- **nginx** - 主程序
- **nginx.service** - 系统服务（systemd）
- **nginx.conf** - 主配置文件
- **conf.d/** - 网站配置目录
- **mime.types** - MIME 类型映射
- **fastcgi_params** - FastCGI 参数
- **uwsgi_params** - uWSGI 参数

### 访问入口

- **HTTP**: `http://<服务器IP>/`
- **HTTPS**: `https://<服务器IP>/`（配置 SSL 后）
- **管理界面**: 无图形界面，使用配置文件管理
- **健康检查端点**: 配置 `location /health` 块可实现

---

## 首次安装后必做设置

### 1. 检查安装
```bash
nginx -v    # 查看版本
nginx -t    # 测试配置
systemctl status nginx
```

### 2. 配置防火墙
```bash
# CentOS/RHEL
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# Ubuntu
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### 3. 设置开机自启
```bash
sudo systemctl enable nginx
```

### 4. 修改默认端口（可选）
```bash
bash port.sh change 80 8080
sudo systemctl restart nginx
```

### 5. 部署第一个网站
```bash
sudo mkdir -p /var/www/mysite
sudo cp configs/static-site.conf /etc/nginx/conf.d/
sudo nginx -t
sudo systemctl reload nginx
```

---

## 详细使用说明

### 安装管理

```bash
bash version.sh show
bash version.sh switch <版本号>
bash version.sh list
```

### 端口管理

```bash
bash port.sh show
bash port.sh change 80 8080
bash port.sh set 80,443,8080
bash port.sh add 9090
bash port.sh remove 8080
sudo systemctl restart nginx
```

### 备份与恢复

```bash
bash backup.sh all
bash backup.sh config
bash backup.sh log
bash backup.sh list
bash restore.sh /var/backups/shell-utils/nginx/backup_20250101.tar.gz
```

### 服务管理
```bash
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
sudo systemctl reload nginx
sudo systemctl status nginx
sudo systemctl enable nginx
```

### 健康检查
```bash
bash healthcheck.sh
```

### 高级配置示例

#### 反向代理
```nginx
server {
    listen 80;
    server_name api.example.com;
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

#### 负载均衡
```nginx
upstream backend {
    server 192.168.1.10:8080;
    server 192.168.1.11:8080;
}
server {
    listen 80;
    location / {
        proxy_pass http://backend;
    }
}
```

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 配置目录 | /etc/nginx |
| 数据目录 | /usr/share/nginx |
| 日志目录 | /var/log/nginx |
| 临时文件 | /var/lib/nginx |

---

## 常见问题

### Q: 安装失败怎么办？
A: 运行 `bash install.sh` 查看详细错误信息。

### Q: 服务无法启动？
A: 运行 `nginx -t` 检查配置，查看 `/var/log/nginx/error.log`。

### Q: 端口被占用？
A: `bash port.sh change 80 8080` 修改端口。

### Q: 如何完全卸载？
A: `bash uninstall.sh --purge-data` 完全移除。

---

## 安全建议

1. 定期备份：每周至少一次
2. 端口安全：使用防火墙控制访问
3. HTTPS：使用 Let's Encrypt
4. 限流配置：使用 limit_req 防 CC
5. 隐藏版本号：server_tokens off
6. 日志监控：定期检查日志

---

## 后续改进方向

1. 自动化证书管理（Let's Encrypt）
2. 性能监控面板（Prometheus + Grafana）
3. 配置模板库（更多应用场景）
4. 日志分析（GoAccess、AWStats）
5. WAF 集成（ModSecurity）
6. 高可用方案（Keepalived + 双机热备）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
