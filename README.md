# Shell 工具函数集合

一个包含常用 Shell 脚本工具函数的项目，提供了日志、文件操作、系统信息、网络检查、CentOS 8 软件部署等功能。

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

### 快速使用示例

```bash
# 1. 查看系统信息
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | bash -s -- system_info

# 2. 一键安装 LNMP 网站环境
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | sudo bash -s -- lnmp

# 3. 安装 Docker
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | sudo bash -s -- docker

# 4. 安装 Nginx
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | sudo bash -s -- nginx

# 5. 安装 PHP 8.0
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | sudo bash -s -- php 8.0

# 6. 安装 Python 3.11
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | sudo bash -s -- python 3.11

# 7. 检查磁盘使用
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | bash -s -- check_disk

# 8. 检查网络连接
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | bash -s -- check_network
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
| `postgresql` | 安装 PostgreSQL 15 | `postgresql` |
| `php [版本]` | 安装 PHP | `php 8.0` |
| `python [版本]` | 安装 Python | `python 3.11` |
| `nodejs [版本]` | 安装 Node.js | `nodejs 20` |
| `java [版本]` | 安装 OpenJDK | `java 17` |
| `docker` | 安装 Docker | `docker` |
| `redis` | 安装 Redis | `redis` |

### 一键部署方案（需要 root）

| 命令 | 说明 |
|------|------|
| `lnmp` | 一键安装 LNMP 栈（Nginx + MySQL + PHP） |
| `lamp` | 一键安装 LAMP 栈（Apache + MySQL + PHP） |
| `dev_tools` | 安装开发工具（gcc, git, make 等） |
| `common_tools` | 安装常用工具（htop, nmap, tcpdump 等） |
| `firewall` | 配置防火墙（开放常用端口） |
| `all` | 安装所有基础服务 |

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
sudo ./deploy-centos8.sh install_docker

# 指定版本
sudo ./deploy-centos8.sh install_php 8.0
sudo ./deploy-centos8.sh install_nodejs 18
```

## 文件说明

- `install.sh` - ⭐ 一键远程安装脚本（推荐）
- `utils.sh` - 工具函数集合
- `example.sh` - 工具函数使用示例
- `deploy-centos8.sh` - CentOS 8 完整部署脚本
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
