# Shell 工具函数集合

一个包含常用 Shell 脚本工具的项目，提供了 CentOS 8 软件部署、监控、SSL 证书管理、自动备份和系统清理等完整的运维工具集。

## 🚀 一键远程安装（推荐）

您可以通过 `curl` 远程直接运行脚本，无需下载！

### 基本语法

```bash
# 查看帮助
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | bash

# 安装软件（需要 root 权限）
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | sudo bash -s -- <命令>

# 普通命令（不需要 root）
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | bash -s -- <命令>
```

## 📋 所有可用命令

### 基础工具命令（不需要 root）

| 命令 | 说明 |
|------|------|
| `system_info` | 显示系统信息（主机名、系统版本、内核、内存、磁盘等） |
| `check_disk` | 检查磁盘使用情况 |
| `check_network` | 检查网络连接 |
| `backup <文件>` | 备份指定文件 |

### CentOS 8 软件部署命令（需要 root）

| 命令 | 说明 | 示例 |
|------|------|------|
| `nginx` | 安装 Nginx | `nginx` |
| `apache` | 安装 Apache | `apache` |
| `mysql` | 安装 MySQL 8.0 | `mysql` |
| `mariadb` | 安装 MariaDB 10.5 | `mariadb` |
| `postgresql` | 安装 PostgreSQL 15 | `postgresql` |
| `php [版本]` | 安装 PHP | `php 8.0` |
| `python [版本]` | 安装 Python | `python 3.11` |
| `nodejs [版本]` | 安装 Node.js | `nodejs 20` |
| `java [版本]` | 安装 OpenJDK | `java 17` |
| `docker` | 安装 Docker | `docker` |
| `redis` | 安装 Redis | `redis` |

### 监控管理命令（需要 root）

| 命令 | 说明 | 示例 |
|------|------|------|
| `monitor_install` | 安装监控系统 (Prometheus + Node Exporter) | `monitor_install` |
| `monitor_start` | 启动监控服务 | `monitor_start` |
| `monitor_stop` | 停止监控服务 | `monitor_stop` |
| `monitor_status` | 查看监控状态 | `monitor_status` |
| `sysmon` | 实时系统监控（终端界面） | `sysmon` |

### SSL 证书命令（需要 root）

| 命令 | 说明 | 示例 |
|------|------|------|
| `ssl_cert <域名>` | 为域名申请 Let's Encrypt 证书 | `ssl_cert example.com` |
| `ssl_renew` | 续期所有证书 | `ssl_renew` |
| `ssl_list` | 列出所有证书 | `ssl_list` |
| `ssl_delete <域名>` | 删除指定证书 | `ssl_delete example.com` |

### 备份管理命令（需要 root）

| 命令 | 说明 | 示例 |
|------|------|------|
| `backup_files` | 备份重要配置文件 | `backup_files` |
| `backup_db` | 备份所有数据库 | `backup_db` |
| `backup_all` | 完整备份（文件+数据库） | `backup_all` |
| `backup_auto` | 配置自动备份（每天凌晨执行） | `backup_auto` |
| `restore_db <文件>` | 恢复数据库 | `restore_db /var/backups/xxx.sql.gz` |

### 系统清理命令（需要 root）

| 命令 | 说明 | 示例 |
|------|------|------|
| `cleanup_check` | 检查可清理空间 | `cleanup_check` |
| `cleanup_kernel` | 清理旧内核 | `cleanup_kernel` |
| `cleanup_log` | 清理日志文件 | `cleanup_log` |
| `cleanup_cache` | 清理缓存 | `cleanup_cache` |
| `cleanup_all` | 完整系统清理 | `cleanup_all` |

### 性能优化命令（需要 root）

| 命令 | 说明 | 适用场景 |
|------|------|----------|
| `tune_kernel` | 自动调优内核参数 | 根据内存大小自动优化内核配置 |

### 一键部署方案（需要 root）

| 命令 | 说明 |
|------|------|
| `lnmp` | 一键安装 LNMP 栈（Nginx + MariaDB + PHP） |
| `lamp` | 一键安装 LAMP 栈（Apache + MariaDB + PHP） |
| `dev_tools` | 安装开发工具（gcc, git, make 等） |
| `common_tools` | 安装常用工具（htop, nmap, tcpdump 等） |
| `firewall` | 配置防火墙（开放常用端口） |
| `all` | 安装所有基础服务 |
| `ops_all` | 安装所有运维工具（监控+备份+SSL） |

## 🎯 快速使用示例

### 1. 安装监控系统

```bash
# 安装 Prometheus + Node Exporter
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | sudo bash -s -- monitor_install

# 查看监控状态
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | sudo bash -s -- monitor_status

# 实时系统监控
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | sudo bash -s -- sysmon
```

### 2. 申请 SSL 证书

```bash
# 为域名申请 SSL 证书
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | sudo bash -s -- ssl_cert example.com

# 查看所有证书
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | sudo bash -s -- ssl_list

# 续期所有证书
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | sudo bash -s -- ssl_renew
```

### 3. 备份管理

```bash
# 备份所有数据库
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | sudo bash -s -- backup_db

# 完整备份（文件+数据库）
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | sudo bash -s -- backup_all

# 配置自动备份（每天凌晨 2:00 执行）
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | sudo bash -s -- backup_auto
```

### 4. 系统清理

```bash
# 检查可清理空间
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | sudo bash -s -- cleanup_check

# 完整系统清理
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | sudo bash -s -- cleanup_all
```

### 5. 一键 LNMP + 运维工具

```bash
# 安装 LNMP + 所有运维工具
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | sudo bash -s -- ops_all
```

## 🔧 功能详解

### 监控系统 (Prometheus)

安装后提供：
- **Prometheus**: http://your_server_ip:9090
- **Node Exporter**: http://your_server_ip:9100

监控指标：
- CPU、内存、磁盘使用率
- 网络流量和连接数
- 系统负载和运行时间
- 进程监控

### SSL 证书 (Let's Encrypt)

功能：
- 自动申请免费 SSL 证书
- 自动配置 Nginx/Apache
- 自动续期
- 支持多域名

### 自动备份

备份内容：
- MySQL/MariaDB 所有数据库
- PostgreSQL 所有数据库
- 重要配置文件（/etc/nginx, /etc/httpd 等）

备份位置：`/var/backups/`

自动清理：保留 30 天

### 系统清理

清理内容：
- 旧内核
- 日志文件
- DNF/Yum 缓存
- pip/npm 缓存
- 临时文件

## 📊 MariaDB vs MySQL

项目中同时提供了 MariaDB 和 MySQL 的安装选项：

| 特性 | MariaDB | MySQL |
|------|---------|-------|
| 版本 | 10.5 | 8.0 |
| 兼容性 | MySQL 兼容 | Oracle MySQL |
| 默认配置 | 更优 | 标准 |
| 推荐场景 | 生产环境 | 特定需求 |

### 推荐使用 MariaDB

- ✅ 完全开源
- ✅ 更活跃的社区
- ✅ 默认配置更优
- ✅ 更好的性能
- ✅ 完全兼容 MySQL

## 内核调优详解

### tune_kernel 命令

自动根据服务器内存大小应用最优的内核参数配置。

### 内存配置方案

| 内存范围 | 配置方案 | 说明 |
|---------|---------|------|
| < 1GB | tiny | 极小内存配置 |
| 1-2GB | small | 小型服务器配置 |
| 2-4GB | medium | 中型服务器配置 |
| 4-8GB | large | 大型服务器配置 |
| 8-16GB | xlarge | 超大型服务器配置 |
| 16-32GB | 2xlarge | 双倍超大型配置 |
| 32-64GB | 4xlarge | 四倍超大型配置 |
| > 64GB | 8xlarge | 八倍超大型配置 |

### 优化的内核参数

- **网络参数**: TCP 缓冲区、连接数、超时时间等
- **文件系统参数**: 文件描述符限制、swappiness 等
- **内存参数**: 共享内存、内存映射数等
- **系统限制**: nofile、nproc 等

## 使用方法

### 本地使用

```bash
# 克隆仓库
git clone https://github.com/fireworkor/shell-utils.git
cd shell-utils

# 一键安装脚本（支持传参）
./install.sh <命令>

# 或者引入工具函数
source utils.sh
./example.sh
```

### 高级部署脚本

对于更复杂的部署需求，可以使用 `deploy-centos8.sh`：

```bash
# 查看帮助
sudo ./deploy-centos8.sh help

# 单个软件安装
sudo ./deploy-centos8.sh install_nginx
sudo ./deploy-centos8.sh install_mariadb

# 内核调优（完整版）
sudo ./tune-kernel.sh
```

### 运维工具脚本

完整的运维工具集合：

```bash
# 查看帮助
sudo ./ops-tools.sh help

# 安装监控系统
sudo ./ops-tools.sh monitor_install

# SSL 证书管理
sudo ./ops-tools.sh ssl_cert example.com

# 备份管理
sudo ./ops-tools.sh backup_all

# 系统清理
sudo ./ops-tools.sh cleanup_all
```

## 文件说明

- `install.sh` - ⭐ 一键远程安装脚本（推荐）
- `utils.sh` - 工具函数集合
- `example.sh` - 工具函数使用示例
- `deploy-centos8.sh` - CentOS 8 完整部署脚本
- `tune-kernel.sh` - 内核调优脚本（完整版）
- `ops-tools.sh` - 运维工具箱（监控+SSL+备份+清理）
- `deploy-to-github.sh` - 一键部署到 GitHub 脚本
- `README.md` - 项目说明文档

## 部署到 GitHub

如需将此项目部署到您自己的 GitHub 仓库：

```bash
./deploy-to-github.sh
```

或使用自动化脚本：

```bash
export GH_TOKEN="your_github_token"
export GH_USERNAME="your_username"
./deploy-automated.sh
```

## 许可证

MIT
