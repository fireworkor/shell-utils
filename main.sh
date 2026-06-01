#!/bin/bash

# =========================================
# Shell 工具 - 总控脚本
# 支持 CentOS 7, CentOS 8, Ubuntu 18/20/22
# =========================================

set -e

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载通用函数
if [ -f "$SCRIPT_DIR/lib/common.sh" ]; then
    source "$SCRIPT_DIR/lib/common.sh"
fi

# 显示帮助
show_help() {
    cat << EOF
${GREEN}========================================${NC}
${GREEN}   Shell 工具 - 总控脚本${NC}
${GREEN}========================================${NC}

${YELLOW}使用方法：${NC}
  $0 <命令> [选项]

${YELLOW}基础命令：${NC}
  help              显示帮助
  list              列出所有可用脚本
  system-info       显示系统信息

${YELLOW}Web 服务器：${NC}
  nginx             安装 Nginx
  apache            安装 Apache

${YELLOW}数据库：${NC}
  mariadb           安装 MariaDB
  mysql             安装 MySQL
  postgresql        安装 PostgreSQL
  mongodb           安装 MongoDB
  sqlite            安装 SQLite
  elasticsearch     安装 Elasticsearch
  clickhouse        安装 ClickHouse

${YELLOW}编程语言：${NC}
  php [版本]        安装 PHP (默认: 7.4)
  python [版本]      安装 Python (默认: 3.11)
  nodejs [版本]      安装 Node.js (默认: 20)
  java [版本]       安装 Java (默认: 11)
  go [版本]         安装 Go (默认: 1.22)
  rust              安装 Rust
  ruby [版本]       安装 Ruby (默认: 3.2)
  perl [版本]       安装 Perl (默认: 5.36)

${YELLOW}容器和缓存：${NC}
  docker            安装 Docker
  redis             安装 Redis
  memcached         安装 Memcached
  minio             安装 MinIO
  rabbitmq          安装 RabbitMQ
  kafka             安装 Kafka
  zookeeper         安装 Zookeeper

${YELLOW}运维工具：${NC}
  monitor           安装监控系统
  ssl <域名>        申请 SSL 证书
  backup            备份数据库
  cleanup           系统清理
  tune-kernel       内核调优

${YELLOW}一键部署：${NC}
  lnmp              LNMP 栈
  lamp              LAMP 栈
  dev-tools         开发工具

${YELLOW}示例：${NC}
  $0 nginx
  $0 php 8.0
  $0 python 3.11
  $0 go 1.22
  $0 rust
  $0 mongodb
  $0 rabbitmq
  $0 elasticsearch
  $0 ssl example.com
  $0 lnmp

EOF
}

# 列出所有脚本
list_scripts() {
    echo -e "${YELLOW}可用脚本：${NC}"
    echo ""
    
    for dir in "$SCRIPT_DIR"/*/; do
        if [ -d "$dir" ]; then
            name=$(basename "$dir")
            script_file="$dir${name}.sh"
            
            if [ -f "$script_file" ]; then
                desc=$(grep -m1 "^#.*描述" "$script_file" | sed 's/^#.*描述：//' || echo "无描述")
                echo -e "${GREEN}$name${NC} - $desc"
            fi
        fi
    done
}

# 显示系统信息
show_system_info() {
    source "$SCRIPT_DIR/lib/common.sh"
    detect_os
    
    echo -e "${GREEN}系统信息：${NC}"
    echo "  操作系统: $OS $VER"
    echo "  内核版本: $(uname -r)"
    echo "  架构: $(uname -m)"
    echo "  主机名: $(hostname)"
    echo "  运行时间: $(uptime -p 2>/dev/null || uptime)"
    echo ""
    echo "  内存使用:"
    free -h | awk 'NR==2 {printf "    总计: %s | 已用: %s | 空闲: %s\n", $2, $3, $4}'
    echo ""
    echo "  磁盘使用:"
    df -h | grep -E '^/dev/' | awk '{printf "    %s: %s / %s (使用率: %s)\n", $1, $3, $2, $5}'
}

# 安装单个软件
install_software() {
    local software=$1
    local version=${2:-""}
    local script_file="$SCRIPT_DIR/${software}/${software}.sh"
    
    if [ ! -f "$script_file" ]; then
        echo -e "${RED}错误：未找到脚本 $script_file${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}正在安装 $software${NC}"
    if [ -n "$version" ]; then
        bash "$script_file" "$version"
    else
        bash "$script_file"
    fi
}

# LNMP 安装
install_lnmp() {
    echo -e "${PURPLE}开始安装 LNMP 栈...${NC}"
    install_software nginx
    install_software mariadb
    install_software php 7.4
    echo -e "${GREEN}✓ LNMP 栈安装完成！${NC}"
}

# LAMP 安装
install_lamp() {
    echo -e "${PURPLE}开始安装 LAMP 栈...${NC}"
    install_software apache
    install_software mariadb
    install_software php 7.4
    echo -e "${GREEN}✓ LAMP 栈安装完成！${NC}"
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    local command=$1
    shift
    
    case $command in
        help|--help|-h)
            show_help
            ;;
        list)
            list_scripts
            ;;
        system-info)
            show_system_info
            ;;
        nginx)
            install_software nginx
            ;;
        apache)
            install_software apache
            ;;
        mariadb)
            install_software mariadb
            ;;
        mysql)
            install_software mysql
            ;;
        postgresql)
            install_software postgresql
            ;;
        php)
            install_software php "$@"
            ;;
        python)
            install_software python "$@"
            ;;
        nodejs)
            install_software nodejs "$@"
            ;;
        java)
            install_software java "$@"
            ;;
        go)
            install_software go "$@"
            ;;
        rust)
            install_software rust
            ;;
        ruby)
            install_software ruby "$@"
            ;;
        perl)
            install_software perl "$@"
            ;;
        mongodb)
            install_software mongodb
            ;;
        sqlite)
            install_software sqlite
            ;;
        elasticsearch)
            install_software elasticsearch
            ;;
        clickhouse)
            install_software clickhouse
            ;;
        memcached)
            install_software memcached
            ;;
        minio)
            install_software minio
            ;;
        rabbitmq)
            install_software rabbitmq
            ;;
        kafka)
            install_software kafka
            ;;
        zookeeper)
            install_software zookeeper
            ;;
        docker)
            install_software docker
            ;;
        redis)
            install_software redis
            ;;
        monitor)
            install_software monitor
            ;;
        ssl)
            install_software ssl "$@"
            ;;
        backup)
            install_software backup
            ;;
        cleanup)
            install_software cleanup
            ;;
        tune-kernel|tune_kernel)
            install_software tune-kernel
            ;;
        lnmp)
            install_lnmp
            ;;
        lamp)
            install_lamp
            ;;
        dev-tools)
            install_software dev-tools
            ;;
        *)
            echo -e "${RED}错误：未知命令 '$command'${NC}"
            echo "运行 '$0 help' 查看帮助"
            exit 1
            ;;
    esac
}

main "$@"
