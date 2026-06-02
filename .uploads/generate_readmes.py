#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
增强版 README.md 文档生成器
包含首次安装后设置、入口地址、组件、端口等完整信息
"""

import os

WORKSPACE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

DOCS = {}

DOCS["nginx"] = """# Nginx Web 服务器

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
"""

DOCS["mysql"] = """# MySQL 数据库

## 简介
MySQL 是一种关系型数据库管理系统，使用最常用的数据库管理语言 SQL（结构化查询语言）进行数据库管理。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 3306 | MySQL 服务 | 默认监听端口 |

### 主要组件

- **mysqld** - MySQL 服务器主进程
- **mysqld_safe** - 启动脚本
- **mysql** - 命令行客户端
- **mysqldump** - 备份工具
- **mysqladmin** - 管理工具
- **mysqlcheck** - 表检查和修复
- **mysql_secure_installation** - 安全配置向导

### 访问入口

- **本地连接**: `mysql -u root -p`
- **远程连接**: `mysql -h <IP> -u <user> -p`
- **Web 管理界面**: 可选 phpMyAdmin、Adminer
- **配置文件**: /etc/my.cnf

---

## 首次安装后必做设置

### 1. 运行安全配置向导
```bash
sudo mysql_secure_installation
```
建议设置：
- 设置 root 密码
- 移除匿名用户
- 禁止 root 远程登录
- 移除测试数据库
- 重新加载权限表

### 2. 创建管理员用户
```bash
mysql -u root -p
```
```sql
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'YourStrongPassword';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

### 3. 配置远程访问（可选）
```bash
sudo vim /etc/mysql/mysql.conf.d/mysqld.cnf
# 将 bind-address 改为 0.0.0.0 或注释掉
```

### 4. 配置防火墙
```bash
sudo firewall-cmd --permanent --add-port=3306/tcp
sudo firewall-cmd --reload
```

### 5. 立即备份
```bash
bash backup.sh all
```

---

## 详细使用说明

### 端口管理

```bash
bash port.sh show
bash port.sh change 3306 3307
sudo systemctl restart mysql
```

### 备份与恢复

```bash
bash backup.sh all
bash backup.sh data
mysqldump -u root -p mydb > mydb_$(date +%Y%m%d).sql
bash restore.sh /var/backups/shell-utils/mysql/backup_20250101.tar.gz
mysql -u root -p mydb < mydb_20250101.sql
```

### 服务管理

```bash
sudo systemctl start mysqld
sudo systemctl stop mysqld
sudo systemctl restart mysqld
sudo systemctl status mysqld
sudo systemctl enable mysqld
```

---

## 常见问题

### Q: 安装失败？
A: 可能需要先卸载旧版本。

### Q: 忘记 root 密码？
A: 参考官方文档重置密码流程。

### Q: 中文乱码？
A: 配置 `character-set-server=utf8mb4`

### Q: 远程连接失败？
A: 检查防火墙、bind-address、用户权限。

---

## 后续改进方向

1. 主从复制（读写分离）
2. 性能监控（Percona Monitoring）
3. 慢查询分析
4. 自动化备份
5. 高可用方案（MHA、Orchestrator）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
"""

DOCS["redis"] = """# Redis 缓存数据库

## 简介
Redis（Remote Dictionary Server）是一个开源的、基于内存的数据结构存储系统，可以用作数据库、缓存和消息中间件。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 6379 | Redis 服务 | 默认监听端口 |

### 主要组件

- **redis-server** - Redis 服务器
- **redis-cli** - 命令行客户端
- **redis-benchmark** - 性能测试工具
- **redis-sentinel** - 哨兵（高可用）
- **redis-cluster** - 集群管理

### 访问入口

- **本地连接**: `redis-cli`
- **远程连接**: `redis-cli -h <IP> -p 6379`
- **Web 管理**: RedisInsight、RedisDesktopManager

---

## 首次安装后必做设置

### 1. 设置访问密码
```bash
sudo vim /etc/redis/redis.conf
# requirepass yourStrongPassword
sudo systemctl restart redis
```

### 2. 启用持久化
默认已开启 RDB 持久化，建议同时启用 AOF：
```
appendonly yes
```

### 3. 配置最大内存
```
maxmemory 2gb
maxmemory-policy allkeys-lru
```

### 4. 限制远程访问
```bash
# 绑定特定 IP
bind 127.0.0.1 192.168.1.100
```

### 5. 配置防火墙
```bash
sudo firewall-cmd --permanent --add-port=6379/tcp
sudo firewall-cmd --reload
```

---

## 详细使用说明

### 常用命令

```bash
# 连接
redis-cli -a yourPassword

# 信息查看
INFO
INFO memory
DBSIZE

# 数据操作
SET key value
GET key
DEL key
EXPIRE key 60
KEYS pattern

# 性能测试
redis-benchmark -h 127.0.0.1 -p 6379 -n 10000
```

### 备份与恢复

```bash
# 自动备份（配置 save 规则）
# 手动备份
redis-cli BGSAVE

# 使用脚本
bash backup.sh all

# 恢复
sudo cp /var/backups/shell-utils/redis/data/redis_20250101.rdb /var/lib/redis/dump.rdb
sudo chown redis:redis /var/lib/redis/dump.rdb
sudo systemctl start redis
```

### 服务管理
```bash
sudo systemctl start redis
sudo systemctl stop redis
sudo systemctl restart redis
sudo systemctl enable redis
```

---

## 常见问题

### Q: 启动失败？
A: 查看 `/var/log/redis/redis.log`

### Q: 内存占用过高？
A: 配置 maxmemory 和淘汰策略

### Q: 性能调优？
A: 调整 tcp-keepalive、timeout 参数

---

## 后续改进方向

1. Redis Sentinel（高可用）
2. Redis Cluster（集群分片）
3. 监控告警（Redis Exporter + Grafana）
4. 慢查询日志
5. 大 Key 治理

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
"""

DOCS["php"] = """# PHP 编程语言

## 简介
PHP（PHP: Hypertext Preprocessor）即"超文本预处理器"，是在服务器端执行的脚本语言，尤其适用于 Web 开发并能嵌入 HTML 中。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 9000 | PHP-FPM | FastCGI 进程管理器 |

### 主要组件

- **php** - PHP CLI
- **php-fpm** - FastCGI 进程管理器
- **php-cgi** - CGI 接口
- **phpize** - 扩展编译工具
- **php-config** - 配置查询工具
- **pecl** - 扩展包管理器
- **composer** - 依赖管理工具

### 访问入口

- **命令行**: `php -v`
- **Web 访问**: 通过 Nginx/Apache + PHP-FPM
- **测试页面**: 创建 phpinfo 验证

---

## 首次安装后必做设置

### 1. 验证安装
```bash
php -v
php -m
```

### 2. 配置 PHP-FPM
```bash
sudo vim /etc/php/8.0/fpm/pool.d/www.conf
# 修改监听
listen = /run/php/php8.0-fpm.sock
```

### 3. 安装常用扩展
```bash
sudo apt install php-curl php-gd php-mbstring php-xml php-zip php-mysql
```

### 4. 安装 Composer
```bash
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
```

### 5. 配置 Nginx 集成
参见 nginx/README.md 的 PHP-FPM 配置示例。

---

## 详细使用说明

### 版本管理
```bash
bash version.sh show
bash version.sh switch 7.4
```

### 端口管理
```bash
bash port.sh show
bash port.sh change 9000 9001
```

### 备份与恢复
```bash
bash backup.sh all
bash restore.sh /var/backups/shell-utils/php/backup_20250101.tar.gz
```

### 服务管理
```bash
sudo systemctl start php8.0-fpm
sudo systemctl enable php8.0-fpm
```

---

## 常见问题

### Q: PHP-FPM 无法启动？
A: 查看 `/var/log/php-fpm/` 日志

### Q: 502 Bad Gateway？
A: 检查 Nginx 配置和 PHP-FPM 监听

### Q: 扩展缺失？
A: `apt search php-` 查找

---

## 后续改进方向

1. OPcache 优化
2. Xdebug 集成
3. PHPUnit 测试
4. 性能监控（Tideways、Blackfire）
5. 安全加固

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
"""

DOCS["python"] = """# Python 编程语言

## 简介
Python 是一个高层次的结合了解释性、编译性、互动性和面向对象的脚本语言，具有简洁的语法和强大的标准库。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 8000 | 开发服务器 | `python -m http.server` |

### 主要组件

- **python3** - Python 3 解释器
- **pip3** - 包管理工具
- **venv** - 虚拟环境模块
- **idle** - 集成开发环境
- **pytest** - 测试框架（需安装）

### 访问入口

- **命令行**: `python3 --version`
- **REPL**: `python3`
- **脚本执行**: `python3 script.py`

---

## 首次安装后必做设置

### 1. 验证安装
```bash
python3 --version
pip3 --version
```

### 2. 配置 pip 源（国内推荐）
```bash
mkdir -p ~/.pip
cat > ~/.pip/pip.conf << 'EOF'
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF
```

### 3. 创建虚拟环境
```bash
python3 -m venv myproject_env
source myproject_env/bin/activate
pip install requests flask
deactivate
```

### 4. 升级 pip
```bash
pip3 install --upgrade pip
```

### 5. 安装常用工具
```bash
pip3 install requests flask django fastapi uvicorn pytest
```

---

## 详细使用说明

### pip 使用

```bash
pip3 install package_name
pip3 install package_name==1.0.0
pip3 freeze > requirements.txt
pip3 install -r requirements.txt
pip3 install --upgrade package_name
pip3 uninstall package_name
```

### 虚拟环境
```bash
python3 -m venv myenv
source myenv/bin/activate
deactivate
```

### 常用 Web 框架
```bash
# Flask
pip3 install flask
python3 -m flask run --host=0.0.0.0 --port=5000

# FastAPI
pip3 install fastapi uvicorn
uvicorn main:app --host=0.0.0.0 --port=8000
```

---

## 常见问题

### Q: pip 安装慢？
A: 更换国内源

### Q: 虚拟环境激活失败？
A: 检查 source 路径

### Q: 模块找不到？
A: 确认虚拟环境已激活

---

## 后续改进方向

1. 包管理工具（Poetry、PDM）
2. 类型检查（mypy）
3. 代码格式化（black、isort）
4. 性能分析（cProfile、py-spy）
5. 文档生成（Sphinx）
6. 依赖安全（safety、pip-audit）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
"""

DOCS["nodejs"] = """# Node.js 运行环境

## 简介
Node.js 是一个基于 Chrome V8 引擎的 JavaScript 运行时，可以在服务器端运行 JavaScript。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 3000 | Express 默认 | Node.js 应用常用 |
| 8080 | 备用 | 通用端口 |

### 主要组件

- **node** - Node.js 运行时
- **npm** - 包管理器
- **npx** - 包执行器
- **yarn** - 替代包管理器
- **pm2** - 进程管理器
- **nodemon** - 开发热重载

### 访问入口

- **命令行**: `node -v`
- **REPL**: `node`
- **运行脚本**: `node app.js`

---

## 首次安装后必做设置

### 1. 验证安装
```bash
node -v
npm -v
```

### 2. 配置 npm 源
```bash
npm config set registry https://registry.npmmirror.com
```

### 3. 安装常用工具
```bash
npm install -g yarn
npm install -g pm2
npm install -g nodemon
```

### 4. 创建第一个项目
```bash
mkdir myapp && cd myapp
npm init -y
npm install express
```

编辑 `app.js`（添加 Express 监听代码）:
```bash
node app.js
# 访问 http://localhost:3000
```

### 5. 使用 PM2 部署
```bash
pm2 start app.js --name myapp
pm2 startup
pm2 save
```

---

## 详细使用说明

### npm 常用命令
```bash
npm init
npm install <package>
npm install <package> --save-dev
npm install -g <package>
npm uninstall <package>
npm update
npm run <script>
```

### 进程管理（PM2）
```bash
pm2 start app.js
pm2 start app.js --name myapp
pm2 start app.js -i 4    # 4 个实例
pm2 list
pm2 show myapp
pm2 logs
pm2 restart myapp
pm2 stop myapp
pm2 delete myapp
pm2 startup
pm2 save
```

---

## 常见问题

### Q: npm 安装慢？
A: 配置国内镜像源

### Q: 端口被占用？
A: `lsof -i :3000`

### Q: 内存泄漏？
A: 使用 --inspect 调试

---

## 后续改进方向

1. TypeScript 集成
2. Docker 化
3. Nginx 反向代理
4. 日志管理（Winston、Pino）
5. 性能监控（PM2 Plus）
6. CI/CD 自动化部署

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
"""

DOCS["docker"] = """# Docker 容器化平台

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
docker run -d -p 9000:9000 --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest
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
"""

DOCS["mariadb"] = """# MariaDB 数据库

## 简介
MariaDB 是 MySQL 的一个分支，由 MySQL 创始人主导开发，目标是完全兼容 MySQL。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 3306 | MariaDB 服务 | 与 MySQL 相同 |

### 主要组件

- **mariadbd** - MariaDB 服务器
- **mariadb** - 命令行客户端
- **mariadb-dump** - 备份工具
- **mariadb-admin** - 管理工具
- **mariadb-secure-installation** - 安全配置

### 访问入口

- **本地连接**: `mariadb -u root -p`
- **远程连接**: `mariadb -h <IP> -u <user> -p`
- **Web 管理**: phpMyAdmin、Adminer

---

## 首次安装后必做设置

### 1. 安全初始化
```bash
sudo mariadb-secure-installation
```

### 2. 设置 root 密码
```bash
sudo mariadb
```
```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'YourStrongPassword';
FLUSH PRIVILEGES;
```

### 3. 创建管理员用户
```sql
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'YourPassword';
GRANT ALL ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;
```

### 4. 配置防火墙
```bash
sudo firewall-cmd --permanent --add-port=3306/tcp
sudo firewall-cmd --reload
```

### 5. 立即备份
```bash
bash backup.sh all
```

---

## 详细使用说明

### 服务管理
```bash
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo systemctl status mariadb
```

### 备份与恢复
```bash
bash backup.sh all
bash backup.sh data
mariadb-dump -u root -p --all-databases > backup.sql
mariadb -u root -p < backup.sql
```

### 端口管理
```bash
bash port.sh show
bash port.sh change 3306 3307
```

---

## 常见问题

### Q: 与 MySQL 的区别？
A: 完全兼容 MySQL，但增加了新特性、性能优化。

### Q: 如何从 MySQL 迁移？
A: mysqldump 备份，mariadb 导入即可。

---

## 后续改进方向

1. Galera Cluster（多主集群）
2. ColumnStore（列式存储）
3. 性能监控
4. 自动化备份
5. 慢查询分析

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
"""

DOCS["apache"] = """# Apache HTTP 服务器

## 简介
Apache HTTP Server 是 Apache 软件基金会的一个开放源码的网页服务器，是最流行的 Web 服务器软件之一。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 80 | HTTP | 提供 HTTP 访问 |
| 443 | HTTPS | 提供 HTTPS 访问 |

### 主要组件

- **httpd** - Apache 主进程
- **apache2** - Debian/Ubuntu 命名
- **apachectl** - 控制脚本
- **htpasswd** - 密码文件管理
- **ab** - 压力测试工具
- **rotatelogs** - 日志轮转

### 访问入口

- **HTTP**: `http://<服务器IP>/`
- **HTTPS**: `https://<服务器IP>/`
- **测试页**: "It works!"

---

## 首次安装后必做设置

### 1. 验证安装
```bash
httpd -v
apachectl configtest
```

### 2. 配置防火墙
```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### 3. 设置主机名
```bash
sudo vim /etc/httpd/conf/httpd.conf
# ServerName www.example.com:80
```

### 4. 创建虚拟主机
参见 Apache 虚拟主机配置示例。

### 5. 设置权限
```bash
sudo chown -R apache:apache /var/www/example.com
```

---

## 详细使用说明

### 服务管理
```bash
sudo systemctl start httpd    # CentOS
sudo systemctl start apache2  # Ubuntu
sudo systemctl enable httpd
```

### 常用模块
```bash
sudo a2enmod ssl rewrite headers
sudo a2dismod autoindex
```

### 备份与恢复
```bash
bash backup.sh all
bash restore.sh /var/backups/shell-utils/apache/backup_20250101.tar.gz
```

---

## 常见问题

### Q: 403 Forbidden？
A: 检查目录权限和 Require 指令

### Q: 加载 PHP？
A: 安装 libapache2-mod-php

### Q: 性能调优？
A: 调整 MaxRequestWorkers

---

## 后续改进方向

1. HTTPS 配置（Let's Encrypt）
2. mod_rewrite（URL 重写）
3. 访问控制（IP 白名单）
4. 日志分析（AWStats）
5. WAF 集成（ModSecurity）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
"""

DOCS["postgresql"] = """# PostgreSQL 数据库

## 简介
PostgreSQL 是一个功能强大的开源对象关系型数据库系统，使用并扩展了 SQL 语言。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 5432 | PostgreSQL | 默认监听端口 |

### 主要组件

- **postgres** - 服务器主进程
- **psql** - 命令行客户端
- **pg_dump** - 备份工具
- **pg_restore** - 恢复工具
- **pg_ctl** - 服务控制
- **createdb/dropdb** - 数据库管理

### 访问入口

- **本地连接**: `psql -U postgres`
- **远程连接**: `psql -h <IP> -U <user> -d <db>`
- **Web 管理**: pgAdmin、Adminer

---

## 首次安装后必做设置

### 1. 切换到 postgres 用户
```bash
sudo -u postgres psql
```

### 2. 设置密码
```sql
\\password postgres
```

### 3. 创建数据库和用户
```sql
CREATE USER myuser WITH PASSWORD 'mypassword';
CREATE DATABASE mydb OWNER myuser;
GRANT ALL PRIVILEGES ON DATABASE mydb TO myuser;
```

### 4. 配置远程访问
```bash
sudo vim /etc/postgresql/14/main/postgresql.conf
# listen_addresses = '*'
sudo vim /etc/postgresql/14/main/pg_hba.conf
# host    all    all    0.0.0.0/0    md5
```

### 5. 重启服务
```bash
sudo systemctl restart postgresql
```

### 6. 配置防火墙
```bash
sudo firewall-cmd --permanent --add-port=5432/tcp
sudo firewall-cmd --reload
```

---

## 详细使用说明

### 常用命令
```bash
psql -U postgres
\\l
\\c mydb
\\dt
\\d tablename
\\i /path/to/file.sql
```

### 备份与恢复
```bash
bash backup.sh all
pg_dump -U postgres mydb > mydb.sql
pg_dumpall -U postgres > all.sql
psql -U postgres -d mydb < mydb.sql
```

### 服务管理
```bash
sudo systemctl start postgresql
sudo systemctl stop postgresql
sudo systemctl restart postgresql
sudo systemctl status postgresql
```

---

## 常见问题

### Q: 远程连接失败？
A: 检查 pg_hba.conf、listen_addresses

### Q: 性能问题？
A: 调整 postgresql.conf 参数

### Q: 主从复制？
A: 配置流复制

---

## 后续改进方向

1. 流复制（主从热备）
2. PostgreSQL Cluster（Patroni）
3. 逻辑复制
4. 分区表
5. pgBouncer（连接池）
6. 监控（pg_stat_statements）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
"""

DOCS["mongodb"] = """# MongoDB NoSQL 数据库

## 简介
MongoDB 是一个基于分布式文件存储的数据库，由 C++ 语言编写，旨在为 WEB 应用提供可扩展的高性能数据存储解决方案。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 27017 | MongoDB | 默认服务端口 |

### 主要组件

- **mongod** - 数据库主进程
- **mongos** - 分片路由器
- **mongosh** - 命令行客户端
- **mongodump** - 备份工具
- **mongorestore** - 恢复工具

### 访问入口

- **本地连接**: `mongosh`
- **远程连接**: `mongosh mongodb://<IP>:27017`
- **Web 管理**: MongoDB Compass、Studio 3T

---

## 首次安装后必做设置

### 1. 验证安装
```bash
mongod --version
sudo systemctl status mongod
```

### 2. 启用认证
```yaml
# /etc/mongod.conf
security:
  authorization: enabled
```

### 3. 创建管理员用户
```bash
mongosh
```
```javascript
use admin
db.createUser({
  user: "admin",
  pwd: "YourStrongPassword",
  roles: [{ role: "userAdminAnyDatabase", db: "admin" }]
})
```

### 4. 配置远程访问
```yaml
net:
  port: 27017
  bindIp: 0.0.0.0
```

### 5. 重启服务
```bash
sudo systemctl restart mongod
```

### 6. 配置防火墙
```bash
sudo firewall-cmd --permanent --add-port=27017/tcp
sudo firewall-cmd --reload
```

---

## 详细使用说明

### 基本命令
```javascript
use mydb
db.users.insertOne({ name: "Alice", age: 30 })
db.users.find()
db.users.find({ age: { $gt: 25 } })
db.users.updateOne({ name: "Alice" }, { $set: { age: 31 } })
db.users.deleteOne({ name: "Alice" })
db.users.createIndex({ name: 1 })
```

### 备份与恢复
```bash
bash backup.sh all
mongodump --db mydb --out /backup/
mongorestore --db mydb /backup/mydb/
```

### 服务管理
```bash
sudo systemctl start mongod
sudo systemctl stop mongod
sudo systemctl restart mongod
sudo systemctl enable mongod
```

---

## 常见问题

### Q: 连接被拒绝？
A: 检查 bindIp、防火墙、是否启用认证

### Q: 性能问题？
A: 创建合适的索引

### Q: 数据量过大？
A: 启用分片集群

---

## 后续改进方向

1. 副本集（高可用）
2. 分片集群（水平扩展）
3. 监控（MongoDB Atlas）
4. 备份策略
5. 安全加固（TLS/SSL）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
"""

DOCS["java"] = """# Java 开发环境

## 简介
Java 是一门面向对象编程语言，不仅吸收了 C++ 语言的各种优点，还摒弃了 C++ 里难以理解的多继承、指针等概念。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 8080 | Tomcat | Java Web 应用 |
| 9000 | JMX | Java 管理扩展 |

### 主要组件

- **java** - Java 运行时
- **javac** - Java 编译器
- **jar** - JAR 打包工具
- **javadoc** - 文档生成
- **jstack** - 线程分析
- **jmap** - 内存分析
- **jconsole** - 图形化监控

### 访问入口

- **命令行**: `java -version`
- **编译**: `javac Hello.java`
- **运行**: `java Hello`

---

## 首次安装后必做设置

### 1. 验证安装
```bash
java -version
javac -version
echo $JAVA_HOME
```

### 2. 设置 JAVA_HOME
```bash
readlink -f $(which java) | sed 's:/bin/java::'
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrc
source ~/.bashrc
```

### 3. 安装 Maven
```bash
sudo apt install maven    # Ubuntu
sudo yum install maven    # CentOS
mvn -version
```

### 4. 第一个程序
```bash
cat > Hello.java << 'EOF'
public class Hello {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}
EOF
javac Hello.java
java Hello
```

---

## 详细使用说明

### 编译运行
```bash
javac MyApp.java
javac -d build/ src/com/example/*.java
java -cp . MyApp
java -cp .:lib/* MyApp
```

### JAR 打包
```bash
jar cf myapp.jar -C build/ .
java -jar myapp.jar
jar tf myapp.jar
```

### Maven 使用
```bash
mvn archetype:generate -DgroupId=com.example -DartifactId=myapp
mvn compile
mvn package
mvn clean
mvn test
```

### 性能调优
```bash
java -Xms512m -Xmx2g -jar myapp.jar
java -Xlog:gc* -jar myapp.jar
```

---

## 常见问题

### Q: JAVA_HOME 未设置？
A: 参考首次安装后必做设置的步骤 2

### Q: 类找不到？
A: 检查 -classpath 参数

### Q: OutOfMemoryError？
A: 调整 -Xmx 参数

---

## 后续改进方向

1. 构建工具（Gradle）
2. 微服务（Spring Boot）
3. 容器化（Docker + K8s）
4. 监控（Micrometer + Prometheus）
5. 性能分析（JProfiler）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
"""

DOCS["go"] = """# Go 编程语言

## 简介
Go（又称 Golang）是 Google 开发的一种静态强类型、编译型语言，有自动垃圾回收、并发机制简单等特性。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 8080 | Web 应用 | 通用 HTTP |

### 主要组件

- **go** - Go 编译器
- **gofmt** - 代码格式化
- **go mod** - 依赖管理
- **go test** - 单元测试
- **go build** - 编译
- **go run** - 运行

### 访问入口

- **命令行**: `go version`

---

## 首次安装后必做设置

### 1. 验证安装
```bash
go version
```

### 2. 配置 Go Modules
```bash
echo 'export GOPATH=$HOME/go' >> ~/.bashrc
echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
echo 'export GOPROXY=https://goproxy.cn,direct' >> ~/.bashrc
source ~/.bashrc
```

### 3. 第一个项目
```bash
mkdir hello && cd hello
go mod init hello
# 创建 main.go
go run main.go
go build -o hello
./hello
```

---

## 详细使用说明

### 模块管理
```bash
go mod init myproject
go get github.com/gin-gonic/gin
go mod tidy
go mod download
```

### 构建运行
```bash
go run main.go
go build
go build -o myapp
go build -ldflags="-s -w" -o myapp
GOOS=linux GOARCH=amd64 go build -o myapp-linux
```

### 常用框架
```bash
go get -u github.com/gin-gonic/gin
# 编写 main.go 启动 Gin
```

---

## 常见问题

### Q: go get 失败？
A: 配置 GOPROXY 代理

### Q: 编译慢？
A: `go env -w GOCACHE=~/.cache/go-build`

### Q: 减小二进制？
A: `-ldflags="-s -w"` 和 UPX 压缩

---

## 后续改进方向

1. Web 框架（Gin、Echo、Fiber）
2. ORM（GORM、Ent）
3. 微服务（gRPC、go-kit）
4. 容器化（Docker + K8s）
5. 监控（Prometheus 客户端）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
"""

DOCS["memcached"] = """# Memcached 缓存系统

## 简介
Memcached 是一个高性能的分布式内存对象缓存系统，用于动态 Web 应用以减轻数据库负载。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 11211 | Memcached | 默认服务端口 |

### 主要组件

- **memcached** - 主进程
- **memcached-tool** - 统计工具
- **libmemcached** - C 客户端库

### 访问入口

- **命令行**: `memcached -h`
- **telnet**: `telnet 127.0.0.1 11211`
- **stats**: `echo "stats" | nc 127.0.0.1 11211`

---

## 首次安装后必做设置

### 1. 启动参数优化
```
# /etc/memcached.conf
-m 1024    # 最大内存
-c 1024    # 最大连接
-p 11211
-l 127.0.0.1
-d
```

### 2. 启动服务
```bash
sudo systemctl start memcached
sudo systemctl enable memcached
```

### 3. 测试
```bash
echo "stats" | nc 127.0.0.1 11211
```

---

## 常用命令

```bash
set key 0 60 5
hello
get key
delete key
stats
stats items
stats slabs
```

---

## 后续改进方向

1. 集群部署
2. 持久化（Couchbase）
3. 监控（Memcached Exporter）
4. 安全（SASL 认证）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
"""

DOCS["rabbitmq"] = """# RabbitMQ 消息队列

## 简介
RabbitMQ 是一个开源的消息代理和队列服务器，用来通过普通协议在完全不同的应用之间共享数据。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 5672 | AMQP | 消息协议 |
| 15672 | Web UI | 管理界面 |

### 主要组件

- **rabbitmq-server** - 主服务
- **rabbitmqctl** - 命令行管理
- **rabbitmq-plugins** - 插件管理
- **rabbitmqadmin** - HTTP API 工具

### 访问入口

- **AMQP**: `amqp://<IP>:5672`
- **Web UI**: `http://<IP>:15672`
- **默认账号**: guest / guest（仅 localhost）

---

## 首次安装后必做设置

### 1. 启用管理界面
```bash
sudo rabbitmq-plugins enable rabbitmq_management
```

### 2. 创建管理员用户
```bash
sudo rabbitmqctl add_user admin YourStrongPassword
sudo rabbitmqctl set_user_tags admin administrator
sudo rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
```

### 3. 允许远程访问
```bash
# /etc/rabbitmq/rabbitmq.conf
loopback_users.guest = false
```

### 4. 配置防火墙
```bash
sudo firewall-cmd --permanent --add-port=5672/tcp
sudo firewall-cmd --permanent --add-port=15672/tcp
sudo firewall-cmd --reload
```

### 5. 重启服务
```bash
sudo systemctl restart rabbitmq-server
```

访问 Web UI: `http://<IP>:15672`

---

## 详细使用说明

### 服务管理
```bash
sudo systemctl start rabbitmq-server
sudo systemctl stop rabbitmq-server
sudo systemctl restart rabbitmq-server
sudo systemctl enable rabbitmq-server
```

### 常用命令
```bash
sudo rabbitmqctl status
sudo rabbitmqctl list_users
sudo rabbitmqctl list_queues
sudo rabbitmqctl list_exchanges
sudo rabbitmqctl list_connections
```

### 备份与恢复
```bash
sudo rabbitmqctl export_definitions /tmp/definitions.json
sudo rabbitmqctl import_definitions /tmp/definitions.json
sudo cp -r /var/lib/rabbitmq/mnesia /backup/
```

---

## 常见问题

### Q: 无法远程登录？
A: 设置 loopback_users.guest = false

### Q: 内存告警？
A: 配置 vm_memory_high_watermark

---

## 后续改进方向

1. 集群部署（3 节点）
2. 镜像队列（高可用）
3. Federation（跨地域）
4. Shovel（消息迁移）
5. 监控（Prometheus + Grafana）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
"""

DOCS["kafka"] = """# Kafka 消息系统

## 简介
Apache Kafka 是一个分布式流处理平台，最初由 LinkedIn 开发。Kafka 是一种高吞吐量的分布式发布订阅消息系统。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 9092 | Kafka Broker | 主服务端口 |
| 2181 | ZooKeeper | 依赖组件 |

### 主要组件

- **kafka-server-start.sh** - 启动 Broker
- **kafka-topics.sh** - Topic 管理
- **kafka-console-producer.sh** - 生产消息
- **kafka-console-consumer.sh** - 消费消息

---

## 首次安装后必做设置

### 1. 配置 server.properties
```bash
sudo vim /opt/kafka/config/server.properties
broker.id=0
listeners=PLAINTEXT://:9092
advertised.listeners=PLAINTEXT://<IP>:9092
log.dirs=/var/lib/kafka/data
```

### 2. 启动服务
```bash
sudo systemctl start kafka
sudo systemctl enable kafka
```

### 3. 创建 Topic
```bash
/opt/kafka/bin/kafka-topics.sh --create \
    --bootstrap-server localhost:9092 \
    --topic mytopic \
    --partitions 3 \
    --replication-factor 1
```

### 4. 测试
```bash
# 生产
/opt/kafka/bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic mytopic
# 消费
/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic mytopic --from-beginning
```

---

## 详细使用说明

### Topic 管理
```bash
/opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092
/opt/kafka/bin/kafka-topics.sh --describe --bootstrap-server localhost:9092
/opt/kafka/bin/kafka-topics.sh --delete --bootstrap-server localhost:9092 --topic mytopic
```

### 消费者组
```bash
/opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list
/opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group mygroup
```

---

## 后续改进方向

1. 集群部署（多 Broker）
2. KRaft 模式（替代 ZooKeeper）
3. 监控（JMX Exporter + Prometheus）
4. 安全（SASL/SSL）
5. 流处理（Kafka Streams）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
"""

DOCS["zookeeper"] = """# ZooKeeper 协调服务

## 简介
Apache ZooKeeper 是一个为分布式应用提供一致性服务的开源组件。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 2181 | 客户端连接 | 默认服务端口 |
| 2888 | Follower 连接 | 集群内部 |
| 3888 | 选举 | 集群选举 |

### 主要组件

- **zkServer.sh** - 启动脚本
- **zkCli.sh** - 命令行客户端
- **zkCleanup.sh** - 清理工具

---

## 首次安装后必做设置

### 1. 配置 zoo.cfg
```properties
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/var/lib/zookeeper
clientPort=2181
maxClientCnxns=60
```

### 2. 创建 myid
```bash
echo "1" | sudo tee /var/lib/zookeeper/myid
```

### 3. 启动
```bash
sudo systemctl start zookeeper
sudo systemctl enable zookeeper
```

### 4. 测试
```bash
echo "ruok" | nc 127.0.0.1 2181
# imok
```

---

## 常用命令

```bash
zkCli.sh -server 127.0.0.1:2181
ls /
create /mynode "data"
get /mynode
set /mynode "new data"
delete /mynode
```

---

## 后续改进方向

1. 集群部署（3/5 节点）
2. 监控（Four Letter Words + Prometheus）
3. 配置管理（Exhibitor）
4. 高可用（Observer 节点）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
"""

DOCS["elasticsearch"] = """# Elasticsearch 搜索引擎

## 简介
Elasticsearch 是一个分布式、RESTful 风格的搜索和数据分析引擎。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 9200 | HTTP API | RESTful 接口 |
| 9300 | 节点通信 | 集群内部 |

### 主要组件

- **elasticsearch** - 主服务
- **kibana** - 可视化
- **logstash** - 日志处理
- **beats** - 轻量数据收集

### 访问入口

- **HTTP API**: `http://<IP>:9200`
- **Web UI**: Kibana
- **健康检查**: `curl http://<IP>:9200/_cluster/health`

---

## 首次安装后必做设置

### 1. 配置 elasticsearch.yml
```yaml
cluster.name: my-cluster
node.name: node-1
network.host: 0.0.0.0
http.port: 9200
discovery.seed_hosts: ["127.0.0.1"]
cluster.initial_master_nodes: ["node-1"]
```

### 2. 配置 JVM
```
-Xms2g
-Xmx2g
```

### 3. 启动
```bash
sudo systemctl start elasticsearch
sudo systemctl enable elasticsearch
```

### 4. 验证
```bash
curl http://127.0.0.1:9200
```

### 5. 防火墙
```bash
sudo firewall-cmd --permanent --add-port=9200/tcp
sudo firewall-cmd --permanent --add-port=9300/tcp
sudo firewall-cmd --reload
```

---

## 详细使用说明

### 基本操作
```bash
# 创建索引
curl -X PUT http://127.0.0.1:9200/myindex

# 添加文档
curl -X POST http://127.0.0.1:9200/myindex/_doc/1 -H "Content-Type: application/json" -d '{"title": "Hello"}'

# 搜索
curl -X GET http://127.0.0.1:9200/myindex/_search

# 集群健康
curl http://127.0.0.1:9200/_cluster/health?pretty
```

### 备份恢复
```bash
curl -X PUT "http://127.0.0.1:9200/_snapshot/my_backup" -H "Content-Type: application/json" -d '{"type": "fs", "settings": {"location": "/backup/es"}}'
curl -X PUT "http://127.0.0.1:9200/_snapshot/my_backup/snapshot_1?wait_for_completion=true"
curl -X POST "http://127.0.0.1:9200/_snapshot/my_backup/snapshot_1/_restore"
```

---

## 常见问题

### Q: 启动失败？
A: 查看 /var/log/elasticsearch/

### Q: 内存不足？
A: 调整 -Xmx（不超过物理内存 50%）

---

## 后续改进方向

1. 集群部署（3 节点以上）
2. Kibana 集成
3. X-Pack 安全
4. ILM 策略
5. 监控（Metricbeat + Kibana）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
"""


def main():
    print("=" * 50)
    print("  生成增强版软件文档")
    print("=" * 50)
    print()

    count = 0
    for software, content in DOCS.items():
        target_dir = os.path.join(WORKSPACE_DIR, software)
        readme_path = os.path.join(target_dir, "README.md")

        if not os.path.isdir(target_dir):
            continue

        try:
            with open(readme_path, "w", encoding="utf-8") as f:
                f.write(content)
            lines = content.count("\n")
            print(f"  ✓ {software}/README.md ({lines} 行)")
            count += 1
        except Exception as e:
            print(f"  ✗ {software}/README.md 错误: {e}")

    print()
    print("=" * 50)
    print(f"  文档生成完成，共 {count} 个文件")
    print("=" * 50)
    print()
    print("文档特性：")
    print("  1. 首次安装后必做设置（5 步）")
    print("  2. 端口与组件清单")
    print("  3. 访问入口说明")
    print("  4. 详细使用说明")
    print("  5. 高级配置示例")
    print("  6. 常见问题 FAQ")
    print("  7. 安全建议")
    print("  8. 后续改进方向")
    print()


if __name__ == "__main__":
    main()
