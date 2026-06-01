# Shell 工具函数集合

一个包含常用 Shell 脚本工具函数的项目，提供了日志、文件操作、系统信息、网络检查、CentOS 8 软件部署等功能。

## 功能介绍

### 1. 日志函数
- `log_info` - 输出信息日志（蓝色）
- `log_success` - 输出成功日志（绿色）
- `log_warning` - 输出警告日志（黄色）
- `log_error` - 输出错误日志（红色）

### 2. 文件操作函数
- `create_backup <file>` - 创建文件备份（带时间戳）

### 3. 系统信息函数
- `show_system_info` - 显示系统信息

### 4. 网络函数
- `check_internet` - 检查网络连接

### 5. 进度条函数
- `show_progress <current> <total>` - 显示进度条

### 6. 目录统计函数
- `count_files [dir]` - 统计目录中的文件和目录数量

### 7. 字符串处理函数
- `to_uppercase <string>` - 字符串转大写
- `to_lowercase <string>` - 字符串转小写
- `trim <string>` - 去除字符串首尾空格

### 8. 时间函数
- `wait_seconds <seconds>` - 等待指定秒数，带进度条

### 9. 命令检查函数
- `command_exists <command>` - 检查命令是否已安装

### 10. 压缩解压函数
- `compress_dir <dir> [output]` - 压缩目录为 tar.gz
- `extract_file <file>` - 解压文件（支持 tar.gz, zip, tar.bz2）

### 11. 磁盘使用检查
- `check_disk_usage [threshold]` - 检查磁盘使用情况

### 12. 大文件查找
- `find_large_files [dir] [size]` - 查找指定大小以上的文件

## 使用方法

### 引入脚本
```bash
source utils.sh
# 或
. utils.sh
```

### 运行示例
```bash
./example.sh
```

## 文件说明
- `utils.sh` - 工具函数集合
- `example.sh` - 使用示例
- `deploy-centos8.sh` - CentOS 8 软件部署工具集
- `deploy-to-github.sh` - 一键部署到 GitHub 脚本
- `README.md` - 项目说明文档

## CentOS 8 软件部署

### 功能概览

提供针对 CentOS 8 的软件一键部署功能，包括：

#### Web 服务器
- **Nginx** - 高性能 Web 服务器和反向代理服务器
- **Apache** - 流行的 Apache HTTP Server

#### 数据库
- **MySQL 8.0** - 流行的关系型数据库
- **PostgreSQL 15** - 高级开源关系型数据库
- **Redis** - 内存数据结构存储
- **Memcached** - 高性能分布式内存缓存

#### 编程语言环境
- **PHP** - 支持多个版本（7.4, 8.0, 8.1 等）
- **Python** - 支持多个版本（3.8, 3.9, 3.10, 3.11 等）
- **Node.js** - JavaScript 运行时环境
- **Java** - OpenJDK 多个版本支持
- **Maven** - Java 项目管理工具

#### 容器和 DevOps
- **Docker** - 容器化平台（包含 Docker Compose）
- **GitLab** - 完整的 Git 仓库管理
- **Prometheus** - 监控系统

#### 一键部署方案
- **LNMP 栈** - Nginx + MySQL + PHP
- **LAMP 栈** - Apache + MySQL + PHP

### 使用方法

```bash
# 必须使用 root 权限
sudo ./deploy-centos8.sh <命令>

# 查看帮助
sudo ./deploy-centos8.sh help

# 单个软件安装
sudo ./deploy-centos8.sh install_nginx
sudo ./deploy-centos8.sh install_docker
sudo ./deploy-centos8.sh install_mysql

# 一键安装完整栈
sudo ./deploy-centos8.sh install_lnmp
sudo ./deploy-centos8.sh install_lamp

# 指定软件版本
sudo ./deploy-centos8.sh install_php 8.0
sudo ./deploy-centos8.sh install_nodejs 18
sudo ./deploy-centos8.sh install_python 3.11
```

### 常用命令示例

```bash
# 1. 更新系统并安装开发工具
sudo ./deploy-centos8.sh update_system
sudo ./deploy-centos8.sh install_dev_tools

# 2. 安装 LNMP 网站环境
sudo ./deploy-centos8.sh install_lnmp

# 3. 安装 Docker 容器环境
sudo ./deploy-centos8.sh install_docker

# 4. 安装 Python 开发环境
sudo ./deploy-centos8.sh install_python 3.11

# 5. 配置防火墙
sudo ./deploy-centos8.sh configure_firewall

# 6. 安装常用工具
sudo ./deploy-centos8.sh install_common_tools
```

### 主要函数列表

| 函数名 | 功能 | 说明 |
|--------|------|------|
| `update_system` | 系统更新 | 更新 CentOS 8 所有软件包 |
| `install_dev_tools` | 开发工具 | 安装 gcc, git, make 等开发工具 |
| `install_nginx` | Nginx | 安装最新稳定版 Nginx |
| `install_apache` | Apache | 安装 Apache HTTP Server |
| `install_mysql` | MySQL | 安装 MySQL 8.0 |
| `install_postgresql` | PostgreSQL | 安装 PostgreSQL 15 |
| `install_php` | PHP | 安装 PHP 及常用扩展 |
| `install_python` | Python | 从源码编译安装 Python |
| `install_nodejs` | Node.js | 安装 Node.js 运行时 |
| `install_docker` | Docker | 安装 Docker 及 Docker Compose |
| `install_lnmp` | LNMP 栈 | 一键安装 Nginx+MySQL+PHP |
| `install_lamp` | LAMP 栈 | 一键安装 Apache+MySQL+PHP |
| `configure_firewall` | 防火墙 | 配置 firewalld 开放常用端口 |

## 部署到 GitHub

### 一键部署（推荐）

使用提供的部署脚本可以快速将项目推送到 GitHub：

```bash
./deploy-to-github.sh
```

脚本会自动：
- 检查并安装 GitHub CLI（如需要）
- 引导您完成 GitHub 登录
- 创建仓库并推送代码

### 手动部署

如果您想手动部署，执行以下步骤：

1. 在 GitHub 上创建新仓库（不初始化 README、.gitignore 或 LICENSE）
2. 在本地仓库目录执行：

```bash
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git branch -M main
git push -u origin main
```

## 许可证
MIT
