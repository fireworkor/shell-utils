# Shell 工具集合 v2.0

一个功能强大的模块化 Shell 脚本工具集，支持 **CentOS 7, CentOS 8, Ubuntu 18/20/22**，提供安装、卸载、升级、备份等完整的运维功能。

## 🚀 快速开始

### 方式一：使用总控脚本（推荐）

```bash
# 下载并运行
curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/main.sh | bash -s -- <命令>

# 本地使用
chmod +x main.sh
sudo ./main.sh nginx
```

### 方式二：单独运行某个脚本

```bash
# Nginx
sudo ./nginx/nginx.sh

# PHP 8.0
sudo ./php/php.sh 8.0

# Python 3.11
sudo ./python/python.sh 3.11
```

## ✨ 新功能 (v2.0)

- 🔧 **配置文件管理** - 统一的版本配置
- 📊 **安装状态检查** - 一键查看已安装软件
- 📝 **安装日志系统** - 完整的操作日志
- 🔄 **卸载功能** - 干净的卸载支持
- ⬆️ **升级功能** - 软件版本升级
- 💾 **自动备份** - 配置和重要文件备份
- ✅ **安全检查** - 安装前环境验证
- 🎯 **版本检测** - 自动识别已安装版本

## 📁 目录结构

```
shell-utils/
├── main.sh                 # ⭐ 总控脚本 v2.0
├── lib/
│   ├── common.sh          # 通用函数库（增强版）
│   ├── logging.sh         # 日志系统
│   └── config.sh          # 配置管理
├── config/
│   └── versions.conf      # 软件版本配置
├── uninstall/
│   └── uninstall.sh       # 卸载功能
├── examples/
│   └── lnmp-setup.sh     # 示例脚本
├── test.sh                # 测试脚本
├── nginx/                 # Nginx
├── apache/                # Apache
├── php/                   # PHP（支持多版本）
├── python/                # Python（支持多版本）
├── nodejs/               # Node.js（支持多版本）
├── java/                 # Java（支持多版本）
├── go/                   # Go（支持多版本）
├── rust/                 # Rust
├── ruby/                 # Ruby（支持多版本）
├── perl/                 # Perl（支持多版本）
├── mysql/                # MySQL
├── mariadb/              # MariaDB
├── postgresql/           # PostgreSQL
├── mongodb/              # MongoDB
├── sqlite/               # SQLite
├── elasticsearch/        # Elasticsearch
├── clickhouse/           # ClickHouse
├── docker/               # Docker
├── redis/                # Redis
├── memcached/            # Memcached
├── minio/                # MinIO
├── rabbitmq/             # RabbitMQ
├── kafka/                # Kafka
├── zookeeper/            # Zookeeper
├── monitor/              # Prometheus 监控
├── ssl/                  # Let's Encrypt SSL
├── backup/               # 数据库备份
├── cleanup/              # 系统清理
├── tune-kernel/          # 内核调优
└── dev-tools/            # 开发工具
```

## 📋 使用示例

### 基础命令

```bash
# 查看帮助
sudo ./main.sh help

# 列出所有脚本
sudo ./main.sh list

# 查看系统信息
sudo ./main.sh system-info

# 查看软件安装状态
sudo ./main.sh status

# 查看安装日志
sudo ./main.sh log 50
```

### 安装命令

```bash
# 安装单个软件
sudo ./main.sh install nginx
sudo ./main.sh install mariadb
sudo ./main.sh install php 8.0
sudo ./main.sh install python 3.11
sudo ./main.sh install go 1.22
sudo ./main.sh install mongodb

# 直接安装（简写）
sudo ./main.sh nginx
sudo ./main.sh php 8.0
sudo ./main.sh python 3.11
```

### 卸载命令

```bash
# 卸载软件（带确认）
sudo ./main.sh uninstall nginx
sudo ./main.sh uninstall mysql
sudo ./main.sh uninstall docker

# 简写
sudo ./main.sh remove nginx
sudo ./main.sh rm mysql
```

### 升级命令

```bash
# 升级软件
sudo ./main.sh upgrade nginx
sudo ./main.sh upgrade php
sudo ./main.sh upgrade mysql
```

### 一键部署

```bash
# LNMP 栈
sudo ./main.sh lnmp

# LAMP 栈
sudo ./main.sh lamp

# 开发工具
sudo ./main.sh dev-tools
```

### 配置管理

```bash
# 查看当前配置
sudo ./main.sh config show

# 修改配置
sudo ./main.sh config set PHP_VERSION 8.1
sudo ./main.sh config set NGINX_VERSION 1.24
```

### 运维工具

```bash
# 监控系统
sudo ./main.sh monitor

# 申请 SSL 证书
sudo ./main.sh ssl example.com

# 数据库备份
sudo ./main.sh backup

# 系统清理
sudo ./main.sh cleanup

# 内核调优
sudo ./main.sh tune-kernel
```

## 🌐 支持的操作系统

| 操作系统 | 版本 | 包管理器 |
|---------|------|---------|
| CentOS | 7, 8 | yum/dnf |
| Ubuntu | 18.04, 20.04, 22.04 | apt |

脚本会自动检测操作系统并使用正确的命令！

## 📦 支持的软件

### Web 服务器
- **Nginx**: 最新稳定版
- **Apache**: 最新稳定版

### 数据库
- **MySQL**: 8.0
- **MariaDB**: 10.5
- **PostgreSQL**: 15
- **MongoDB**: 6.0
- **SQLite**: 最新版
- **Elasticsearch**: 8.x
- **ClickHouse**: 最新版

### 编程语言
| 软件 | 支持版本 | 默认版本 |
|------|---------|---------|
| PHP | 7.4, 8.0, 8.1 | 8.0 |
| Python | 3.8 - 3.12 | 3.11 |
| Node.js | 16, 18, 20 | 20 |
| Java | 8, 11, 17, 21 | 11 |
| Go | 1.20, 1.21, 1.22 | 1.22 |
| Rust | 最新版 | - |
| Ruby | 3.0, 3.1, 3.2 | 3.2 |
| Perl | 5.34, 5.36 | 5.36 |

### 容器和缓存
- **Docker**: 最新版（含 Docker Compose）
- **Redis**: 最新版
- **Memcached**: 最新版
- **MinIO**: 最新版
- **RabbitMQ**: 3.12
- **Kafka**: 3.6
- **Zookeeper**: 3.9

### 运维工具
- **Prometheus**: 2.45.0
- **Node Exporter**: 1.6.1
- **Certbot**: SSL 证书

## 🔧 新增函数库

### common.sh 增强功能

```bash
# 安全检查
check_prerequisites           # 安装前环境检查

# 备份功能
backup_file                   # 备份单个文件
backup_service_configs         # 备份服务配置

# 验证函数
validate_version              # 版本号验证
validate_ip                   # IP 地址验证
validate_domain               # 域名验证

# 下载函数
download_with_retry           # 带重试的下载
download_simple               # 简单下载

# 版本检测
get_installed_version         # 获取已安装版本
check_installed               # 检查是否已安装

# 用户交互
confirm                       # 确认提示
select_option                 # 选项菜单

# 系统信息
get_system_info               # 获取系统信息
```

### logging.sh 日志系统

```bash
log_info                      # 信息日志
log_warn                      # 警告日志
log_error                     # 错误日志
log_debug                     # 调试日志
show_log                      # 查看日志
clear_log                     # 清空日志
```

### config.sh 配置管理

```bash
load_config                   # 加载配置
get_config                    # 获取配置项
set_config                    # 设置配置项
list_config                   # 列出配置
```

## 🧪 测试

```bash
# 运行测试套件
chmod +x test.sh
./test.sh

# 测试结果
✓ 脚本语法检查
✓ 函数库加载测试
✓ 配置文件测试
✓ 模块完整性测试
```

## 🔒 安全性

- ✅ 自动检测 root 权限
- ✅ 自动配置防火墙
- ✅ 安全初始化数据库
- ✅ 使用官方仓库
- ✅ 安装前安全检查
- ✅ 自动备份配置文件
- ✅ 操作日志记录

## 📖 开发自己的模块

创建新的模块非常简单：

```bash
#!/bin/bash
# 描述：我的自定义模块

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logging.sh"

install_my_module() {
    check_root
    check_os
    check_prerequisites
    
    log_info "开始安装..."
    
    print_step 1 2 "下载软件"
    # 下载逻辑
    
    print_step 2 2 "安装配置"
    # 安装逻辑
    
    backup_service_configs "mysoftware"
    
    print_success "安装完成"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_my_module "$@"
fi
```

## 📚 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 🔗 GitHub

**https://github.com/fireworkor/shell-utils**
