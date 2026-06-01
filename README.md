# Shell 工具函数集合

一个包含常用 Shell 脚本工具的项目，支持 **CentOS 7、CentOS 8、Ubuntu 18/20/22**，提供软件部署、监控、SSL 证书管理、自动备份和系统清理等完整的运维工具集。

## 🚀 一键远程安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | bash -s -- <命令>
```

## 🌐 跨平台支持

| 操作系统 | 版本 | 包管理器 |
|---------|------|---------|
| CentOS | 7, 8 | yum/dnf |
| Ubuntu | 18.04, 20.04, 22.04 | apt |

脚本会自动检测您的操作系统并使用正确的包管理器！

## 📋 快速使用

### 基础命令

```bash
# 查看帮助
curl ... | bash

# 更新系统
curl ... | sudo bash -s -- update

# 查看系统信息
curl ... | bash -s -- system_info
```

### Web 服务器

```bash
# 安装 Nginx
curl ... | sudo bash -s -- nginx

# 安装 Apache
curl ... | sudo bash -s -- apache

# 一键 LNMP
curl ... | sudo bash -s -- lnmp

# 一键 LAMP
curl ... | sudo bash -s -- lamp
```

### 数据库

```bash
# 安装 MariaDB
curl ... | sudo bash -s -- mariadb

# 安装 MySQL
curl ... | sudo bash -s -- mysql

# 安装 PostgreSQL
curl ... | sudo bash -s -- postgresql
```

### 编程语言

```bash
# PHP 8.0
curl ... | sudo bash -s -- php 8.0

# Python 3.11
curl ... | sudo bash -s -- python 3.11

# Node.js 20
curl ... | sudo bash -s -- nodejs 20

# OpenJDK 17
curl ... | sudo bash -s -- java 17
```

### 容器和缓存

```bash
# Docker
curl ... | sudo bash -s -- docker

# Redis
curl ... | sudo bash -s -- redis
```

### 运维工具

```bash
# 安装监控系统
curl ... | sudo bash -s -- monitor

# 内核调优
curl ... | sudo bash -s -- tune_kernel

# SSL 证书
curl ... | sudo bash -s -- ssl example.com

# 数据库备份
curl ... | sudo bash -s -- backup

# 系统清理
curl ... | sudo bash -s -- cleanup
```

## 📋 所有命令列表

### 基础命令

| 命令 | 说明 |
|------|------|
| `update` | 更新系统 |
| `system_info` | 显示系统信息 |
| `help` | 显示帮助 |

### Web 服务器

| 命令 | 说明 | CentOS | Ubuntu |
|------|------|--------|--------|
| `nginx` | Nginx | ✅ | ✅ |
| `apache` | Apache | httpd | apache2 |
| `lnmp` | LNMP 栈 | ✅ | ✅ |
| `lamp` | LAMP 栈 | ✅ | ✅ |

### 数据库

| 命令 | 说明 |
|------|------|
| `mariadb` | MariaDB 10.5 |
| `mysql` | MySQL 8.0 |
| `postgresql` | PostgreSQL 15 |

### 编程语言

| 命令 | 说明 | 支持版本 |
|------|------|---------|
| `php [版本]` | PHP | 7.4, 8.0, 8.1 |
| `python [版本]` | Python | 3.8, 3.9, 3.10, 3.11 |
| `nodejs [版本]` | Node.js | 16, 18, 20 |
| `java [版本]` | OpenJDK | 8, 11, 17, 21 |

### 容器和缓存

| 命令 | 说明 |
|------|------|
| `docker` | Docker 容器平台 |
| `redis` | Redis 缓存 |

### 运维工具

| 命令 | 说明 |
|------|------|
| `monitor` | 安装 Prometheus 监控系统 |
| `tune_kernel` | 自动内核调优（根据内存） |
| `ssl <域名>` | 申请 Let's Encrypt SSL 证书 |
| `backup` | 备份数据库 |
| `cleanup` | 系统清理 |

### 一键部署

| 命令 | 说明 |
|------|------|
| `dev_tools` | 安装开发工具 |
| `firewall` | 配置防火墙 |

## 🔧 功能详解

### 自动系统检测

脚本会自动检测您的操作系统：

```bash
$ curl ... | bash
检测到系统：centos 8
包管理器：dnf
```

### 包管理器适配

| 功能 | CentOS 7 | CentOS 8 | Ubuntu |
|------|---------|---------|--------|
| 系统更新 | yum | dnf | apt |
| 防火墙 | firewalld | firewalld | ufw |
| Nginx 仓库 | Nginx Official | Nginx Official | 系统自带 |
| PHP 版本 | Remi | Remi | PPA (ondrej) |
| Python | 源码编译 | 源码编译 | PPA |
| Docker | Docker CE | Docker CE | Docker CE |

### 防火墙配置

自动开放常用端口：

| 端口 | 服务 | 说明 |
|------|------|------|
| 22 | SSH | SSH 连接 |
| 80 | HTTP | Web 服务 |
| 443 | HTTPS | SSL 连接 |
| 3306 | MySQL | 数据库 |
| 5432 | PostgreSQL | 数据库 |
| 6379 | Redis | 缓存 |
| 8080 | 自定义 | 应用端口 |
| 9090 | Prometheus | 监控 |
| 9100 | Node Exporter | 监控 |

### 监控系统

安装后提供：
- **Prometheus**: http://your_server_ip:9090
- **Node Exporter**: http://your_server_ip:9100

### SSL 证书

- 自动申请 Let's Encrypt 免费证书
- 自动续期
- 支持 Nginx 和 Apache

## 📦 项目文件

| 文件 | 说明 |
|------|------|
| `install.sh` | ⭐ 主脚本（跨平台） |
| `utils.sh` | 工具函数集合 |
| `example.sh` | 使用示例 |
| `deploy-centos8.sh` | CentOS 8 完整脚本 |
| `tune-kernel.sh` | 内核调优（完整版） |
| `ops-tools.sh` | 运维工具箱 |
| `README.md` | 项目文档 |

## 💡 使用技巧

### 1. 查看帮助
```bash
curl ... | bash
```

### 2. 查看系统信息
```bash
curl ... | bash -s -- system_info
```

### 3. 一键安装 LNMP + 运维工具
```bash
curl ... | sudo bash -s -- lnmp
curl ... | sudo bash -s -- monitor
curl ... | sudo bash -s -- tune_kernel
```

### 4. 指定软件版本
```bash
# 安装 PHP 8.0
curl ... | sudo bash -s -- php 8.0

# 安装 Python 3.11
curl ... | sudo bash -s -- python 3.11
```

### 5. 本地使用
```bash
# 下载脚本
wget https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh

# 添加执行权限
chmod +x install.sh

# 运行
sudo ./install.sh <命令>
```

## 🔒 安全性

- ✅ 自动检测 root 权限
- ✅ 使用官方仓库
- ✅ 自动配置防火墙
- ✅ 安全初始化数据库

## 📊 MariaDB vs MySQL

| 特性 | MariaDB | MySQL |
|------|---------|-------|
| 版本 | 10.5 | 8.0 |
| 开源 | 完全开源 | 部分开源 |
| 性能 | 更优 | 标准 |
| 推荐 | ✅ 生产环境首选 | 特定需求 |

## 🎯 常见使用场景

### 场景 1：搭建 Web 服务器
```bash
curl ... | sudo bash -s -- lnmp
curl ... | sudo bash -s -- ssl example.com
```

### 场景 2：搭建开发环境
```bash
curl ... | sudo bash -s -- dev_tools
curl ... | sudo bash -s -- python 3.11
curl ... | sudo bash -s -- nodejs 20
```

### 场景 3：搭建数据库服务器
```bash
curl ... | sudo bash -s -- mariadb
curl ... | sudo bash -s -- tune_kernel
curl ... | sudo bash -s -- backup
```

### 场景 4：搭建监控系统
```bash
curl ... | sudo bash -s -- monitor
curl ... | sudo bash -s -- tune_kernel
```

## 📚 许可

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 🔗 GitHub

**https://github.com/fireworkor/shell-utils**
