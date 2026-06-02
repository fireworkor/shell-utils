#!/bin/bash
# 标准化 README.md 文档生成器（最终版本）
# 为每个软件生成完整的使用说明文档

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR"/.. && pwd)"

# 为每个软件直接写 README，避免复杂替换

generate_nginx_readme() {
    cat > "$WORKSPACE_DIR/nginx/README.md" << 'EOF'
# Nginx

## 简介
高性能的 HTTP 和反向代理服务器，用于网站和应用服务

---

## 快速开始

### 1. 安装
```bash
cd nginx
sudo bash install.sh
```

### 2. 查看软件信息
```bash
cd nginx
bash info.sh
```

### 3. 检查健康状态
```bash
cd nginx
bash healthcheck.sh
```

---

## 标准脚本集

| 脚本 | 功能 | 说明 |
|------|------|------|
| **[install.sh](install.sh)** | 安装 | 安装 Nginx 软件包和依赖 |
| **[version.sh](version.sh)** | 版本管理 | 查看、切换或列出可用版本 |
| **[port.sh](port.sh)** | 端口管理 | 查看、修改或配置监听端口 |
| **[backup.sh](backup.sh)** | 备份 | 备份配置、数据或日志 |
| **[restore.sh](restore.sh)** | 恢复 | 从备份中恢复配置或数据 |
| **[healthcheck.sh](healthcheck.sh)** | 健康检查 | 检查服务状态、端口监听、进程健康 |
| **[uninstall.sh](uninstall.sh)** | 卸载 | 安全卸载 Nginx |
| **[info.sh](info.sh)** | 软件信息 | 查看完整的软件和服务信息 |
| **[config](config)** | 默认配置 | 包含软件的默认配置选项 |

---

## 详细使用说明

### 安装管理

#### 查看当前版本
```bash
bash version.sh show
```

#### 切换到其他版本
```bash
bash version.sh switch <版本号>
```

### 端口管理

#### 查看当前端口
```bash
bash port.sh show
```

#### 修改端口
```bash
# 修改端口（自动备份配置）
bash port.sh change 80 8080

# 修改后需重启服务
sudo systemctl restart nginx
```

默认端口：80,443

### 备份与恢复

#### 完整备份
```bash
bash backup.sh all
```

#### 仅备份配置
```bash
bash backup.sh config
```

#### 查看备份列表
```bash
bash backup.sh list
```

#### 恢复备份
```bash
bash restore.sh /var/backups/shell-utils/nginx/backup_20250101_120000.tar.gz
```

备份位置：`/var/backups/shell-utils/nginx/`

### 服务管理
```bash
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
sudo systemctl status nginx
sudo systemctl enable nginx
```

### 健康检查
```bash
bash healthcheck.sh
```

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 配置目录 | /etc/nginx |
| 数据目录 | /usr/share/nginx |
| 日志目录 | /var/log/nginx |

常见配置文件：
- 主配置：/etc/nginx/nginx.conf
- 网站配置：/etc/nginx/conf.d/

---

## 常见问题

### Q: 安装失败怎么办？
A: 运行 `bash install.sh` 查看详细错误，确保有 root 权限且网络正常。

### Q: 服务无法启动？
A: 运行 `bash healthcheck.sh` 和 `nginx -t` 查看错误，检查配置文件。

---

## 安全建议

1. **定期备份**：每周至少一次完整备份
2. **端口安全**：非必要不暴露到公网，使用防火墙
3. **访问控制**：启用认证和授权，使用强密码
4. **日志监控**：定期检查日志，发现异常及时处理
5. **版本更新**：及时更新到最新稳定版本
EOF
}

generate_mysql_readme() {
    cat > "$WORKSPACE_DIR/mysql/README.md" << 'EOF'
# MySQL

## 简介
关系型数据库管理系统

---

## 快速开始

### 1. 安装
```bash
cd mysql
sudo bash install.sh
```

### 2. 查看软件信息
```bash
cd mysql
bash info.sh
```

---

## 标准脚本集

| 脚本 | 功能 |
|------|------|
| **[install.sh](install.sh)** | 安装 |
| **[version.sh](version.sh)** | 版本管理 |
| **[port.sh](port.sh)** | 端口管理 |
| **[backup.sh](backup.sh)** | 备份 |
| **[restore.sh](restore.sh)** | 恢复 |
| **[healthcheck.sh](healthcheck.sh)** | 健康检查 |
| **[uninstall.sh](uninstall.sh)** | 卸载 |
| **[info.sh](info.sh)** | 软件信息 |

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 配置目录 | /etc/mysql |
| 数据目录 | /var/lib/mysql |
| 日志目录 | /var/log/mysql |

默认端口：3306

---

## 常用命令

```bash
# 连接 MySQL
mysql -u root -p

# 备份数据库
mysqldump -u root -p dbname > backup.sql

# 导入数据库
mysql -u root -p dbname < backup.sql
```
EOF
}

generate_redis_readme() {
    cat > "$WORKSPACE_DIR/redis/README.md" << 'EOF'
# Redis

## 简介
高性能键值对缓存和数据库

---

## 快速开始

### 1. 安装
```bash
cd redis
sudo bash install.sh
```

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 配置目录 | /etc/redis |
| 数据目录 | /var/lib/redis |
| 日志目录 | /var/log/redis |

默认端口：6379

---

## 常用命令

```bash
# 连接 Redis
redis-cli

# 查看状态
redis-cli info

# 保存数据
redis-cli BGSAVE
```
EOF
}

generate_php_readme() {
    cat > "$WORKSPACE_DIR/php/README.md" << 'EOF'
# PHP

## 简介
流行的服务端脚本语言，用于动态网页

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 配置目录 | /etc/php |
| 数据目录 | /var/www/html |
| 日志目录 | /var/log/php |

默认端口：9000
EOF
}

generate_python_readme() {
    cat > "$WORKSPACE_DIR/python/README.md" << 'EOF'
# Python

## 简介
通用编程语言，广泛用于 Web 开发、数据分析

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 配置目录 | /etc/python3 |
| 数据目录 | /usr/local/bin |
| 日志目录 | /var/log/python |

默认端口：8000
EOF
}

generate_nodejs_readme() {
    cat > "$WORKSPACE_DIR/nodejs/README.md" << 'EOF'
# Node.js

## 简介
基于 Chrome V8 引擎的 JavaScript 运行环境

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 配置目录 | /etc/nodejs |
| 数据目录 | /usr/local/bin |
| 日志目录 | /var/log/nodejs |

默认端口：3000,8080
EOF
}

generate_docker_readme() {
    cat > "$WORKSPACE_DIR/docker/README.md" << 'EOF'
# Docker

## 简介
开源容器化平台

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 配置目录 | /etc/docker |
| 数据目录 | /var/lib/docker |
| 日志目录 | /var/log/docker |

默认端口：2375

---

## 常用命令

```bash
# 查看镜像
docker images

# 查看容器
docker ps -a

# 运行容器
docker run hello-world
```
EOF
}

generate_mariadb_readme() {
    cat > "$WORKSPACE_DIR/mariadb/README.md" << 'EOF'
# MariaDB

## 简介
MySQL 的开源分支，高性能数据库

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 配置目录 | /etc/mariadb |
| 数据目录 | /var/lib/mariadb |
| 日志目录 | /var/log/mariadb |

默认端口：3306
EOF
}

generate_apache_readme() {
    cat > "$WORKSPACE_DIR/apache/README.md" << 'EOF'
# Apache

## 简介
开源 HTTP 服务器，广泛用于网站托管

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 配置目录 | /etc/httpd |
| 数据目录 | /var/www/html |
| 日志目录 | /var/log/httpd |

默认端口：80,443
EOF
}

generate_postgresql_readme() {
    cat > "$WORKSPACE_DIR/postgresql/README.md" << 'EOF'
# PostgreSQL

## 简介
高级开源关系型数据库

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 配置目录 | /etc/postgresql |
| 数据目录 | /var/lib/postgresql |
| 日志目录 | /var/log/postgresql |

默认端口：5432
EOF
}

generate_mongodb_readme() {
    cat > "$WORKSPACE_DIR/mongodb/README.md" << 'EOF'
# MongoDB

## 简介
NoSQL 文档数据库

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 配置目录 | /etc/mongodb |
| 数据目录 | /var/lib/mongodb |
| 日志目录 | /var/log/mongodb |

默认端口：27017
EOF
}

generate_java_readme() {
    cat > "$WORKSPACE_DIR/java/README.md" << 'EOF'
# Java

## 简介
流行的企业级编程语言

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 配置目录 | /etc/java |
| 数据目录 | /usr/local/java |
| 日志目录 | /var/log/java |

默认端口：8080,9000
EOF
}

generate_go_readme() {
    cat > "$WORKSPACE_DIR/go/README.md" << 'EOF'
# Go

## 简介
Go 编程语言，专注于并发和性能

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 配置目录 | /etc/go |
| 数据目录 | /usr/local/go |
| 日志目录 | /var/log/go |

默认端口：8080
EOF
}

generate_memcached_readme() {
    cat > "$WORKSPACE_DIR/memcached/README.md" << 'EOF'
# Memcached

## 简介
高性能分布式内存对象缓存系统

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 配置目录 | /etc/memcached |
| 数据目录 | /var/lib/memcached |
| 日志目录 | /var/log/memcached |

默认端口：11211
EOF
}

generate_rabbitmq_readme() {
    cat > "$WORKSPACE_DIR/rabbitmq/README.md" << 'EOF'
# RabbitMQ

## 简介
消息队列代理，用于消息传递

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 配置目录 | /etc/rabbitmq |
| 数据目录 | /var/lib/rabbitmq |
| 日志目录 | /var/log/rabbitmq |

默认端口：5672,15672
EOF
}

generate_kafka_readme() {
    cat > "$WORKSPACE_DIR/kafka/README.md" << 'EOF'
# Kafka

## 简介
分布式流式处理平台

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 配置目录 | /etc/kafka |
| 数据目录 | /var/lib/kafka |
| 日志目录 | /var/log/kafka |

默认端口：9092
EOF
}

generate_zookeeper_readme() {
    cat > "$WORKSPACE_DIR/zookeeper/README.md" << 'EOF'
# ZooKeeper

## 简介
分布式协调服务

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 配置目录 | /etc/zookeeper |
| 数据目录 | /var/lib/zookeeper |
| 日志目录 | /var/log/zookeeper |

默认端口：2181
EOF
}

generate_elasticsearch_readme() {
    cat > "$WORKSPACE_DIR/elasticsearch/README.md" << 'EOF'
# Elasticsearch

## 简介
分布式搜索和分析引擎

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 配置目录 | /etc/elasticsearch |
| 数据目录 | /var/lib/elasticsearch |
| 日志目录 | /var/log/elasticsearch |

默认端口：9200
EOF
}

# 主函数
main() {
    echo "========================================"
    echo "  生成标准化软件文档"
    echo "========================================"
    echo ""

    generate_nginx_readme
    echo "  ✓ 已生成 nginx/README.md"
    
    generate_mysql_readme
    echo "  ✓ 已生成 mysql/README.md"
    
    generate_redis_readme
    echo "  ✓ 已生成 redis/README.md"
    
    generate_php_readme
    echo "  ✓ 已生成 php/README.md"
    
    generate_python_readme
    echo "  ✓ 已生成 python/README.md"
    
    generate_nodejs_readme
    echo "  ✓ 已生成 nodejs/README.md"
    
    generate_docker_readme
    echo "  ✓ 已生成 docker/README.md"
    
    generate_mariadb_readme
    echo "  ✓ 已生成 mariadb/README.md"
    
    generate_apache_readme
    echo "  ✓ 已生成 apache/README.md"
    
    generate_postgresql_readme
    echo "  ✓ 已生成 postgresql/README.md"
    
    generate_mongodb_readme
    echo "  ✓ 已生成 mongodb/README.md"
    
    generate_java_readme
    echo "  ✓ 已生成 java/README.md"
    
    generate_go_readme
    echo "  ✓ 已生成 go/README.md"
    
    generate_memcached_readme
    echo "  ✓ 已生成 memcached/README.md"
    
    generate_rabbitmq_readme
    echo "  ✓ 已生成 rabbitmq/README.md"
    
    generate_kafka_readme
    echo "  ✓ 已生成 kafka/README.md"
    
    generate_zookeeper_readme
    echo "  ✓ 已生成 zookeeper/README.md"
    
    generate_elasticsearch_readme
    echo "  ✓ 已生成 elasticsearch/README.md"

    echo ""
    echo "========================================"
    echo "  文档生成完成"
    echo "========================================"
    echo ""
    echo "每个软件目录现在都包含完整的 README.md"
    echo "包括快速开始、使用说明、常见问题等"
    echo ""
}

main "$@"
