# Shell 工具集合

一个模块化的 Shell 脚本工具集，支持 **CentOS 7, CentOS 8, Ubuntu 18/20/22**，每个软件独立成模块，支持单独或批量执行。

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

## 📁 目录结构

```
shell-utils/
├── main.sh                 # ⭐ 总控脚本
├── lib/
│   └── common.sh           # 通用函数库
├── nginx/
│   └── nginx.sh            # Nginx
├── apache/
│   └── apache.sh           # Apache
├── mariadb/
│   └── mariadb.sh          # MariaDB
├── mysql/
│   └── mysql.sh            # MySQL
├── postgresql/
│   └── postgresql.sh       # PostgreSQL
├── php/
│   └── php.sh              # PHP（支持多版本）
├── python/
│   └── python.sh           # Python（支持多版本）
├── nodejs/
│   └── nodejs.sh           # Node.js（支持多版本）
├── java/
│   └── java.sh             # Java（支持多版本）
├── docker/
│   └── docker.sh           # Docker
├── redis/
│   └── redis.sh            # Redis
├── monitor/
│   └── monitor.sh          # Prometheus 监控
├── ssl/
│   └── ssl.sh              # Let's Encrypt SSL
├── backup/
│   └── backup.sh          # 数据库备份
├── cleanup/
│   └── cleanup.sh          # 系统清理
├── tune-kernel/
│   └── tune-kernel.sh      # 内核调优
└── dev-tools/
    └── dev-tools.sh        # 开发工具
```

## 📋 使用示例

### 使用总控脚本

```bash
# 查看帮助
sudo ./main.sh help

# 列出所有脚本
sudo ./main.sh list

# 安装单个软件
sudo ./main.sh nginx
sudo ./main.sh mariadb
sudo ./main.sh php 8.0
sudo ./main.sh python 3.11

# 一键部署
sudo ./main.sh lnmp
sudo ./main.sh lamp

# 运维工具
sudo ./main.sh monitor
sudo ./main.sh ssl example.com
sudo ./main.sh backup
sudo ./main.sh cleanup
sudo ./main.sh tune-kernel
```

### 单独使用某个脚本

```bash
# 直接运行
sudo ./nginx/nginx.sh
sudo ./php/php.sh 8.0
sudo ./python/python.sh 3.11
sudo ./nodejs/nodejs.sh 20

# 查看版本支持
./nginx/nginx.sh --help
./php/php.sh --help
```

## 🌐 支持的操作系统

| 操作系统 | 版本 | 包管理器 |
|---------|------|---------|
| CentOS | 7, 8 | yum/dnf |
| Ubuntu | 18.04, 20.04, 22.04 | apt |

脚本会自动检测操作系统并使用正确的命令！

## 📦 软件版本

### Web 服务器
- **Nginx**: 最新稳定版
- **Apache**: 最新稳定版

### 数据库
- **MariaDB**: 10.5
- **MySQL**: 8.0
- **PostgreSQL**: 15

### 编程语言
| 软件 | 支持版本 | 默认版本 |
|------|---------|---------|
| PHP | 7.4, 8.0, 8.1 | 7.4 |
| Python | 3.8, 3.9, 3.10, 3.11 | 3.11 |
| Node.js | 16, 18, 20 | 20 |
| Java | 8, 11, 17, 21 | 11 |

### 容器和缓存
- **Docker**: 最新版（含 Docker Compose）
- **Redis**: 最新版

### 运维工具
- **Prometheus**: 2.45.0
- **Node Exporter**: 1.6.1

## 🔧 常用命令

### 安装 LNMP 栈
```bash
sudo ./main.sh lnmp
```

### 安装 LAMP 栈
```bash
sudo ./main.sh lamp
```

### 安装开发环境
```bash
sudo ./main.sh python 3.11
sudo ./main.sh nodejs 20
sudo ./main.sh java 17
```

### 安装运维工具
```bash
sudo ./main.sh monitor      # 安装监控
sudo ./main.sh ssl example.com  # 申请 SSL
sudo ./main.sh backup       # 备份数据库
sudo ./main.sh cleanup      # 清理系统
sudo ./main.sh tune-kernel  # 内核调优
```

## 📖 开发自己的模块

创建新的模块非常简单：

1. 创建目录：`mkdir -p mymodule`
2. 创建脚本：`mymodule/mymodule.sh`
3. 添加描述：

```bash
#!/bin/bash
# 描述：我的自定义模块

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

install_my_module() {
    check_root
    # 你的安装逻辑
    print_success "安装完成"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_my_module "$@"
fi
```

4. 添加执行权限：`chmod +x mymodule/mymodule.sh`
5. 使用总控脚本调用：`sudo ./main.sh mymodule`

## 🔒 安全性

- ✅ 自动检测 root 权限
- ✅ 自动配置防火墙
- ✅ 安全初始化数据库
- ✅ 使用官方仓库

## 📚 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 🔗 GitHub

**https://github.com/fireworkor/shell-utils**
