#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
通用软件目录脚本生成器
"""

import os

WORKSPACE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 软件信息库
SOFTWARE_INFO = {
    "airflow": {
        "service": "airflow",
        "ports": "8080",
        "name": "Airflow",
        "desc": "Airflow 工作流调度系统"
    },
    "apisix": {
        "service": "apisix",
        "ports": "9080,9443",
        "name": "APISIX",
        "desc": "APISIX API 网关"
    },
    "argocd": {
        "service": "argocd",
        "ports": "8080",
        "name": "ArgoCD",
        "desc": "ArgoCD GitOps 持续部署工具"
    },
    "cassandra": {
        "service": "cassandra",
        "ports": "9042,7000",
        "name": "Cassandra",
        "desc": "Cassandra 分布式数据库"
    },
    "clickhouse": {
        "service": "clickhouse",
        "ports": "8123,9000",
        "name": "ClickHouse",
        "desc": "ClickHouse 列式数据库"
    },
    "haproxy": {
        "service": "haproxy",
        "ports": "80,443",
        "name": "HAProxy",
        "desc": "HAProxy 负载均衡器"
    },
    "keepalived": {
        "service": "keepalived",
        "ports": "112",
        "name": "Keepalived",
        "desc": "Keepalived 高可用"
    },
    "kong": {
        "service": "kong",
        "ports": "8000,8443,8001,8444",
        "name": "Kong",
        "desc": "Kong API 网关"
    },
    "minio": {
        "service": "minio",
        "ports": "9000",
        "name": "MinIO",
        "desc": "MinIO 对象存储"
    },
    "vault": {
        "service": "vault",
        "ports": "8200",
        "name": "Vault",
        "desc": "Vault 密钥管理"
    },
    "nginx-deploy": {
        "service": "nginx-deploy",
        "ports": "80,443",
        "name": "Nginx Deploy",
        "desc": "Nginx 部署工具"
    },
    "flume": {
        "service": "flume",
        "ports": "44444",
        "name": "Flume",
        "desc": "Flume 日志收集"
    },
    "influxdb": {
        "service": "influxdb",
        "ports": "8086",
        "name": "InfluxDB",
        "desc": "InfluxDB 时序数据库"
    },
    "kafka-cluster": {
        "service": "kafka-cluster",
        "ports": "9092",
        "name": "Kafka Cluster",
        "desc": "Kafka 集群"
    },
    "mysql-cluster": {
        "service": "mysql-cluster",
        "ports": "3306",
        "name": "MySQL Cluster",
        "desc": "MySQL 集群"
    },
    "redis-cluster": {
        "service": "redis-cluster",
        "ports": "6379,16379",
        "name": "Redis Cluster",
        "desc": "Redis 集群"
    },
    "postgresql-cluster": {
        "service": "postgresql-cluster",
        "ports": "5432",
        "name": "PostgreSQL Cluster",
        "desc": "PostgreSQL 集群"
    },
    "mongodb-cluster": {
        "service": "mongodb-cluster",
        "ports": "27017",
        "name": "MongoDB Cluster",
        "desc": "MongoDB 集群"
    },
    "rabbitmq-cluster": {
        "service": "rabbitmq-cluster",
        "ports": "5672,15672",
        "name": "RabbitMQ Cluster",
        "desc": "RabbitMQ 集群"
    },
    "elasticsearch-cluster": {
        "service": "elasticsearch-cluster",
        "ports": "9200,9300",
        "name": "Elasticsearch Cluster",
        "desc": "Elasticsearch 集群"
    },
    "zookeeper-cluster": {
        "service": "zookeeper-cluster",
        "ports": "2181",
        "name": "ZooKeeper Cluster",
        "desc": "ZooKeeper 集群"
    }
}


def create_scripts(software, info):
    target_dir = os.path.join(WORKSPACE_DIR, software)
    if not os.path.isdir(target_dir):
        return False

    service = info["service"]
    ports = info["ports"]
    name = info["name"]
    desc = info["desc"]

    print(f"正在为 {software} 生成脚本...")

    # install.sh
    with open(os.path.join(target_dir, "install.sh"), "w") as f:
        f.write(f"""#!/bin/bash
# {name} 安装脚本

SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="{service}"
SOFTWARE_NAME="{software}"
DISPLAY_NAME="{name}"

install() {{
    echo "正在安装 {name}..."
    echo "请手动安装 {name}，或参考 README.md 中的说明"
}}

if [ "${{BASH_SOURCE[0]}}" = "${{0}}" ]; then
    install "$@"
fi
""")

    # version.sh
    with open(os.path.join(target_dir, "version.sh"), "w") as f:
        f.write(f"""#!/bin/bash
# {name} 版本管理脚本

SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

show_current_version() {{
    echo "{name} 版本管理"
    echo "请手动检查安装的版本"
}}

case "${{1:-show}}" in
    show|status)
        show_current_version
        ;;
    *)
        show_current_version
        echo "用法: $0 {{show}}"
        ;;
esac
""")

    # port.sh
    with open(os.path.join(target_dir, "port.sh"), "w") as f:
        f.write(f"""#!/bin/bash
# {name} 端口管理脚本

SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

DEFAULT_PORTS="{ports}"

show_ports() {{
    echo -e "${{BLUE}}=== {name} 端口配置 ===${{NC}}"
    echo "  默认端口: $DEFAULT_PORTS"
}}

case "${{1:-show}}" in
    show|list)
        show_ports
        ;;
    *)
        show_ports
        echo "用法: $0 {{show}}"
        ;;
esac
""")

    # backup.sh
    with open(os.path.join(target_dir, "backup.sh"), "w") as f:
        f.write(f"""#!/bin/bash
# {name} 备份脚本

SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="{software}"
DISPLAY_NAME="{name}"

BACKUP_ROOT="/var/backups/shell-utils/$SOFTWARE_NAME"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

do_backup() {{
    mkdir -p "$BACKUP_ROOT"
    local backup_dir="$BACKUP_ROOT/backup_$TIMESTAMP"
    mkdir -p "$backup_dir"
    
    # 备份配置
    if [ -d "/opt/{software}/etc" ]; then
        cp -r /opt/{software}/etc "$backup_dir/" 2>/dev/null
        echo -e "${{GREEN}}配置备份完成${{NC}}"
    elif [ -d "/etc/{service}" ]; then
        cp -r /etc/{service} "$backup_dir/" 2>/dev/null
        echo -e "${{GREEN}}配置备份完成${{NC}}"
    fi
    
    # 打包
    tar czf "$BACKUP_ROOT/backup_${{TIMESTAMP}}.tar.gz" -C "$BACKUP_ROOT" "backup_${{TIMESTAMP}}" 2>/dev/null
    rm -rf "$backup_dir"
    
    echo -e "${{GREEN}}备份完成: $BACKUP_ROOT/backup_${{TIMESTAMP}}.tar.gz${{NC}}"
}}

list_backups() {{
    echo "{name} 的备份列表:"
    ls -lt "$BACKUP_ROOT"/backup_*.tar.gz 2>/dev/null | head -10 || echo "  暂无备份"
}}

case "${{1:-all}}" in
    all|config)
        do_backup
        ;;
    list)
        list_backups
        ;;
    *)
        do_backup
        ;;
esac
""")

    # restore.sh
    with open(os.path.join(target_dir, "restore.sh"), "w") as f:
        f.write(f"""#!/bin/bash
# {name} 恢复脚本

SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="{software}"
DISPLAY_NAME="{name}"

BACKUP_ROOT="/var/backups/shell-utils/$SOFTWARE_NAME"

list_available() {{
    ls -1 "$BACKUP_ROOT"/backup_*.tar.gz 2>/dev/null | head -10 || echo "暂无备份"
}}

do_restore() {{
    local backup_file="$1"
    [ -z "$backup_file" ] && {{ echo "请指定备份文件"; return 1; }}
    if [ ! -f "$backup_file" ]; then
        backup_file="$BACKUP_ROOT/$backup_file"
    fi
    [ ! -f "$backup_file" ] && {{ echo "备份文件不存在"; return 1; }}
    
    local temp_dir=$(mktemp -d)
    tar xzf "$backup_file" -C "$temp_dir" 2>/dev/null
    
    echo "请手动恢复配置"
    rm -rf "$temp_dir"
}}

case "${{1:-list}}" in
    list)
        list_available
        ;;
    *)
        do_restore "$@"
        ;;
esac
""")

    # healthcheck.sh
    with open(os.path.join(target_dir, "healthcheck.sh"), "w") as f:
        f.write(f"""#!/bin/bash
# {name} 健康检查脚本

SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="{software}"
DISPLAY_NAME="{name}"

echo -e "${{BLUE}}=== {name} 健康检查 ===${{NC}}"

if [ -d "/opt/{software}" ]; then
    echo -e "${{GREEN}}✓ 安装目录存在${{NC}}"
else
    echo -e "${{RED}}✗ 安装目录不存在${{NC}}"
fi

if [ -d "/var/log/{software}" ]; then
    echo -e "${{GREEN}}✓ 日志目录存在${{NC}}"
else
    echo -e "${{YELLOW}}⚠ 日志目录不存在${{NC}}"
fi

echo -e "${{GREEN}}健康检查完成${{NC}}"
""")

    # uninstall.sh
    with open(os.path.join(target_dir, "uninstall.sh"), "w") as f:
        f.write(f"""#!/bin/bash
# {name} 卸载脚本

SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="{software}"
DISPLAY_NAME="{name}"

echo "正在卸载 {name}..."
echo -e "${{YELLOW}}警告: 将删除相关目录${{NC}}"
read -p "确认卸载? [y/N] " confirm
[ "$confirm" != "y" ] && {{ echo "取消卸载"; exit 0; }}

sudo systemctl stop {service} 2>/dev/null || true
sudo rm -rf /opt/{software} /var/log/{software} /var/lib/{software} 2>/dev/null || true

echo -e "${{GREEN}}{name} 卸载完成${{NC}}"
""")

    # info.sh
    with open(os.path.join(target_dir, "info.sh"), "w") as f:
        f.write(f"""#!/bin/bash
# {name} 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="{software}"
DISPLAY_NAME="{name}"

echo -e "${{BLUE}}=== {name} 信息 ===${{NC}}"
echo "  软件名称: $DISPLAY_NAME"
echo "  安装目录: /opt/{software}"
echo "  日志目录: /var/log/{software}"
echo "  数据目录: /var/lib/{software}"
echo "  默认端口: {ports}"
echo ""

if [ -d "/opt/{software}" ]; then
    echo -e "${{GREEN}}状态: 已安装${{NC}}"
else
    echo -e "${{RED}}状态: 未安装${{NC}}"
fi
""")

    # config
    with open(os.path.join(target_dir, "config"), "w") as f:
        f.write(f"""# {name} 配置文件
SOFTWARE_NAME="{software}"
SERVICE_NAME="{service}"
DISPLAY_NAME="{name}"
DEFAULT_PORTS="{ports}"
""")

    # 设置权限
    for script in ["install.sh", "version.sh", "port.sh", "backup.sh", "restore.sh",
                   "healthcheck.sh", "uninstall.sh", "info.sh"]:
        os.chmod(os.path.join(target_dir, script), 0o755)

    return True


def create_readme(software, info):
    target_dir = os.path.join(WORKSPACE_DIR, software)
    if not os.path.isdir(target_dir):
        return False

    service = info["service"]
    ports = info["ports"]
    name = info["name"]
    desc = info["desc"]

    readme_content = f"""# {name}

## 简介
{desc}

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
"""
    for port in ports.split(","):
        readme_content += f"| {port} | 默认端口 |  |\n"

    readme_content += f"""
### 主要组件

- **{service}**: 主服务

### 访问入口

- **服务地址**: 根据实际配置确定

---

## 首次安装后必做设置

### 1. 安装 {name}
请根据官方文档或 README.md 说明进行安装

### 2. 配置环境变量
```bash
# 根据需要配置环境变量
```

### 3. 启动服务
```bash
# 启动 {name} 服务
sudo systemctl start {service}
```

---

## 详细使用说明

### 健康检查
```bash
bash healthcheck.sh
```

### 备份与恢复
```bash
bash backup.sh all
bash backup.sh list
bash restore.sh /path/to/backup.tar.gz
```

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 安装目录 | /opt/{software} |
| 配置目录 | /etc/{service} |
| 日志目录 | /var/log/{software} |
| 数据目录 | /var/lib/{software} |

---

## 常见问题

### Q: 如何安装 {name}？
A: 请参考官方文档或 README.md 中的说明。

### Q: 服务无法启动？
A: 查看日志文件 /var/log/{software} 中的错误信息。

---

## 后续改进方向

1. **集群部署**：配置高可用集群
2. **监控**：集成 Prometheus + Grafana
3. **安全**：启用认证和加密
4. **优化**：调整性能参数

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
"""

    with open(os.path.join(target_dir, "README.md"), "w", encoding="utf-8") as f:
        f.write(readme_content)

    return True


def main():
    print("=" * 50)
    print("  生成软件脚本和文档")
    print("=" * 50)
    print()

    count = 0
    for software, info in SOFTWARE_INFO.items():
        target_dir = os.path.join(WORKSPACE_DIR, software)
        if not os.path.isdir(target_dir):
            continue

        scripts_ok = True
        scripts = ["install.sh", "version.sh", "port.sh", "backup.sh", "restore.sh",
                   "healthcheck.sh", "uninstall.sh", "info.sh", "config"]
        for script in scripts:
            if not os.path.exists(os.path.join(target_dir, script)):
                scripts_ok = False
                break

        readme_ok = os.path.exists(os.path.join(target_dir, "README.md"))

        if not scripts_ok:
            create_scripts(software, info)

        if not readme_ok:
            create_readme(software, info)

        count += 1

    print()
    print("=" * 50)
    print(f"  完成，处理了 {count} 个软件目录")
    print("=" * 50)


if __name__ == "__main__":
    main()
