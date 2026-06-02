#!/bin/bash
# 标准化 README.md 文档生成器（简化版，避免变量扩展问题）
# 为每个软件生成完整的使用说明文档

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR"/.. && pwd)"

# 软件详细信息库
declare -A SOFTWARE_INFO=(
    ["nginx"]="Nginx|高性能的 HTTP 和反向代理服务器，用于网站和应用服务|80,443|/etc/nginx|/usr/share/nginx|/var/log/nginx"
    ["apache"]="Apache|开源 HTTP 服务器，广泛用于网站托管|80,443|/etc/httpd|/var/www/html|/var/log/httpd"
    ["mysql"]="MySQL|关系型数据库管理系统|3306|/etc/mysql|/var/lib/mysql|/var/log/mysql"
    ["mariadb"]="MariaDB|MySQL 的开源分支，高性能数据库|3306|/etc/mariadb|/var/lib/mariadb|/var/log/mariadb"
    ["postgresql"]="PostgreSQL|高级开源关系型数据库|5432|/etc/postgresql|/var/lib/postgresql|/var/log/postgresql"
    ["mongodb"]="MongoDB|NoSQL 文档数据库|27017|/etc/mongodb|/var/lib/mongodb|/var/log/mongodb"
    ["redis"]="Redis|高性能键值对缓存和数据库|6379|/etc/redis|/var/lib/redis|/var/log/redis"
    ["php"]="PHP|流行的服务端脚本语言，用于动态网页|9000|/etc/php|/var/www/html|/var/log/php"
    ["python"]="Python|通用编程语言，广泛用于 Web 开发、数据分析|8000|/etc/python3|/usr/local/bin|/var/log/python"
    ["nodejs"]="Node.js|基于 Chrome V8 引擎的 JavaScript 运行环境|3000,8080|/etc/nodejs|/usr/local/bin|/var/log/nodejs"
    ["docker"]="Docker|开源容器化平台|2375|/etc/docker|/var/lib/docker|/var/log/docker"
    ["java"]="Java|流行的企业级编程语言|8080,9000|/etc/java|/usr/local/java|/var/log/java"
    ["go"]="Go|Go 编程语言，专注于并发和性能|8080|/etc/go|/usr/local/go|/var/log/go"
    ["tomcat"]="Tomcat|Java Servlet 容器，用于运行 Java Web 应用|8080|/etc/tomcat|/var/lib/tomcat|/var/log/tomcat"
    ["memcached"]="Memcached|高性能分布式内存对象缓存系统|11211|/etc/memcached|/var/lib/memcached|/var/log/memcached"
    ["rabbitmq"]="RabbitMQ|消息队列代理，用于消息传递|5672,15672|/etc/rabbitmq|/var/lib/rabbitmq|/var/log/rabbitmq"
    ["kafka"]="Kafka|分布式流式处理平台|9092|/etc/kafka|/var/lib/kafka|/var/log/kafka"
    ["zookeeper"]="ZooKeeper|分布式协调服务|2181|/etc/zookeeper|/var/lib/zookeeper|/var/log/zookeeper"
    ["elasticsearch"]="Elasticsearch|分布式搜索和分析引擎|9200|/etc/elasticsearch|/var/lib/elasticsearch|/var/log/elasticsearch"
)

generate_readme() {
    local software="$1"
    local info="${SOFTWARE_INFO[$software]}"
    
    IFS='|' read -r display_name description ports config_dir data_dir log_dir <<< "$info"
    
    local target_dir="$WORKSPACE_DIR/$software"
    
    if [ ! -d "$target_dir" ]; then
        return
    fi
    
    echo "正在生成 $software 的 README.md..."
    
    # 使用 cat <<'READMEMD' 来避免变量扩展问题
    cat << 'READMEMD' > "$target_dir/README.md"
# {display_name}

## 简介
{description}

---

## 快速开始

### 1. 安装
```bash
cd {target_dir}
sudo bash install.sh
```

### 2. 查看软件信息
```bash
cd {software}
bash info.sh
```

### 3. 检查健康状态
```bash
cd {software}
bash healthcheck.sh
```

---

## 标准脚本集

本目录包含完整的管理脚本，提供统一的使用接口：

| 脚本 | 功能 | 说明 |
|------|------|------|
| **[install.sh](install.sh)** | 安装 | 安装 {display_name} 软件包和依赖 |
| **[version.sh](version.sh)** | 版本管理 | 查看、切换或列出可用版本 |
| **[port.sh](port.sh)** | 端口管理 | 查看、修改或配置监听端口 |
| **[backup.sh](backup.sh)** | 备份 | 备份配置、数据或日志 |
| **[restore.sh](restore.sh)** | 恢复 | 从备份中恢复配置或数据 |
| **[healthcheck.sh](healthcheck.sh)** | 健康检查 | 检查服务状态、端口监听、进程健康 |
| **[uninstall.sh](uninstall.sh)** | 卸载 | 安全卸载 {display_name} |
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
bash port.sh change <旧端口> <新端口>

# 或者直接设置新端口
bash port.sh set <端口1,端口2,...>

# 修改后需重启服务
sudo systemctl restart {software}
```

默认端口：{ports}

### 备份与恢复

#### 完整备份（推荐）
```bash
bash backup.sh all
```

#### 仅备份配置
```bash
bash backup.sh config
```

#### 仅备份数据
```bash
bash backup.sh data
```

#### 查看备份列表
```bash
bash backup.sh list
```

#### 恢复备份
```bash
# 列出可用备份
bash restore.sh list

# 从备份恢复
bash restore.sh /var/backups/shell-utils/{software}/backup_20250101_120000.tar.gz
```

备份文件位置：`/var/backups/shell-utils/{software}/`

### 服务管理（系统服务方式）
```bash
# 启动服务
sudo systemctl start {software}

# 停止服务
sudo systemctl stop {software}

# 重启服务
sudo systemctl restart {software}

# 查看状态
sudo systemctl status {software}

# 设置开机自启动
sudo systemctl enable {software}

# 取消开机自启动
sudo systemctl disable {software}
```

### 健康检查
```bash
# 运行完整健康检查
bash healthcheck.sh
```

检查项目包括：
- 服务运行状态
- 端口监听状态
- 进程健康情况
- 配置文件完整性
- 磁盘空间使用

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 配置目录 | {config_dir} |
| 数据目录 | {data_dir} |
| 日志目录 | {log_dir} |

常见配置文件：
- 主配置：{config_dir}/{software}.conf
- 扩展配置：{config_dir}/conf.d/

---

## 常见问题

### Q: 安装失败怎么办？
A: 运行 `bash install.sh` 查看详细错误信息，确保您有 root 权限，并且网络连接正常。

### Q: 如何确认 {display_name} 已正确安装？
A: 运行 `bash info.sh` 查看安装状态，或使用系统命令 `which {software}` 验证。

### Q: 服务无法启动？
A: 
1. 运行健康检查：`bash healthcheck.sh`
2. 查看日志：`journalctl -xe -u {software}`
3. 测试配置：{software} -t

### Q: 端口被占用？
A: 
1. 查看占用：`sudo ss -tulpn | grep <端口>`
2. 修改端口：`bash port.sh change <旧端口> <新端口>`
3. 或停止占用端口的进程

### Q: 如何完全卸载？
A: 
```bash
# 保留数据卸载
bash uninstall.sh --keep-data

# 或完全移除（包括数据）
bash uninstall.sh --purge-data
```

---

## 安全建议

1. **定期备份**：每周至少运行一次完整备份
2. **端口安全**：非必要时不要暴露服务到公网，使用防火墙
3. **访问控制**：启用认证和授权，使用强密码
4. **日志监控**：定期检查日志，发现异常及时处理
5. **版本更新**：及时更新到最新稳定版本

---

## 更多资源

- 官方文档：搜索 "{display_name} 官方文档"
- 在线教程：社区教程和常见问题解答
- 技术支持：查看项目的 Issue 或社区论坛

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
READMEMD

    # 现在进行字符串替换
    sed -i "s/{display_name}/$display_name/g" "$target_dir/README.md"
    sed -i "s/{description}/$description/g" "$target_dir/README.md"
    sed -i "s/{software}/$software/g" "$target_dir/README.md"
    sed -i "s/{target_dir}/$(dirname "$target_dir")\/$software/g" "$target_dir/README.md"
    sed -i "s/{ports}/$ports/g" "$target_dir/README.md"
    sed -i "s|{config_dir}|$config_dir|g" "$target_dir/README.md"
    sed -i "s|{data_dir}|$data_dir|g" "$target_dir/README.md"
    sed -i "s|{log_dir}|$log_dir|g" "$target_dir/README.md"

    echo "  ✓ 已生成 $software/README.md"
}

main() {
    echo "========================================"
    echo "  生成标准化软件文档"
    echo "========================================"
    echo ""

    for software in "${!SOFTWARE_INFO[@]}"; do
        generate_readme "$software"
    done

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
