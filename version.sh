#!/bin/bash

# =========================================
# 软件多版本管理工具
# 支持查看、安装、切换不同版本的软件
# =========================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

CONFIG_FILE="$SCRIPT_DIR/config/versions.conf"
VERSIONS_FILE="$SCRIPT_DIR/config/versions-all.conf"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

list_software() {
    echo -e "${CYAN}支持的软件列表${NC}"
    echo "=========================================="
    
    local software_list=(
        "nginx:Web 服务器"
        "apache:Web 服务器"
        "php:编程语言"
        "python:编程语言"
        "nodejs:编程语言"
        "java:编程语言"
        "go:编程语言"
        "ruby:编程语言"
        "rust:编程语言"
        "mysql:数据库"
        "mariadb:数据库"
        "postgresql:数据库"
        "mongodb:数据库"
        "redis:缓存"
        "memcached:缓存"
        "rabbitmq:消息队列"
        "kafka:消息队列"
        "zookeeper:协调服务"
        "docker:容器"
        "minio:对象存储"
        "elasticsearch:搜索"
        "spark:大数据"
        "hadoop:大数据"
        "flink:大数据"
    )
    
    printf "%-20s %s\n" "软件名称" "分类"
    echo "------------------------------------------"
    
    for item in "${software_list[@]}"; do
        name="${item%%:*}"
        category="${item##*:}"
        printf "%-20s %s\n" "$name" "$category"
    done
    
    echo ""
}

list_versions() {
    local software="$1"
    
    if [ -z "$software" ]; then
        log_error "请指定软件名称"
        return 1
    fi
    
    echo -e "${CYAN}$software 可用版本${NC}"
    echo "=========================================="
    
    local versions
    case "$software" in
        nginx)
            versions=("1.20" "1.22" "1.24" "1.25" "1.26")
            ;;
        apache)
            versions=("2.4" "2.2")
            ;;
        php)
            versions=("7.4" "8.0" "8.1" "8.2" "8.3")
            ;;
        python)
            versions=("3.9" "3.10" "3.11" "3.12" "3.13")
            ;;
        nodejs)
            versions=("18" "20" "21" "22")
            ;;
        java)
            versions=("8" "11" "17" "21")
            ;;
        go)
            versions=("1.20" "1.21" "1.22" "1.23")
            ;;
        ruby)
            versions=("3.0" "3.1" "3.2" "3.3")
            ;;
        mysql)
            versions=("5.7" "8.0" "8.1" "8.2")
            ;;
        mariadb)
            versions=("10.4" "10.5" "10.6" "10.11")
            ;;
        postgresql)
            versions=("13" "14" "15" "16")
            ;;
        mongodb)
            versions=("5.0" "6.0" "7.0")
            ;;
        redis)
            versions=("6.2" "7.0" "7.2")
            ;;
        rabbitmq)
            versions=("3.10" "3.11" "3.12" "3.13")
            ;;
        kafka)
            versions=("3.3" "3.4" "3.5" "3.6")
            ;;
        zookeeper)
            versions=("3.7" "3.8" "3.9")
            ;;
        elasticsearch)
            versions=("7.17" "8.0" "8.10" "8.11")
            ;;
        spark)
            versions=("3.3" "3.4" "3.5")
            ;;
        hadoop)
            versions=("3.3" "3.4")
            ;;
        flink)
            versions=("1.16" "1.17" "1.18")
            ;;
        *)
            log_error "不支持的软件: $software"
            return 1
            ;;
    esac
    
    echo "可用版本:"
    for version in "${versions[@]}"; do
        echo "  $version"
    done
    
    echo ""
}

show_current_version() {
    local software="$1"
    
    if [ -z "$software" ]; then
        log_error "请指定软件名称"
        return 1
    fi
    
    echo -e "${CYAN}$software 版本信息${NC}"
    echo "=========================================="
    
    # 检查当前配置版本
    local config_version=$(grep "^${software^^}_VERSION" "$CONFIG_FILE" 2>/dev/null | awk -F'=' '{print $2}')
    
    # 检查已安装版本
    local installed_version
    case "$software" in
        nginx)
            installed_version=$(/usr/sbin/nginx -v 2>&1 | grep -o "[0-9.]*" | head -1)
            ;;
        apache)
            installed_version=$(httpd -v 2>&1 | grep -o "[0-9.]*" | head -1)
            ;;
        php)
            installed_version=$(php -v 2>&1 | grep -o "[0-9.]*" | head -1)
            ;;
        python)
            installed_version=$(python3 -V 2>&1 | grep -o "[0-9.]*" | head -1)
            ;;
        nodejs)
            installed_version=$(node -v 2>&1 | grep -o "[0-9.]*" | head -1)
            ;;
        java)
            installed_version=$(java -version 2>&1 | grep -o "[0-9.]*" | head -1)
            ;;
        go)
            installed_version=$(go version 2>&1 | grep -o "[0-9.]*" | head -1)
            ;;
        mysql)
            installed_version=$(mysql -V 2>&1 | grep -o "[0-9.]*" | head -1)
            ;;
        mariadb)
            installed_version=$(mariadb -V 2>&1 | grep -o "[0-9.]*" | head -1)
            ;;
        postgresql)
            installed_version=$(psql --version 2>&1 | grep -o "[0-9.]*" | head -1)
            ;;
        redis)
            installed_version=$(redis-server --version 2>&1 | grep -o "[0-9.]*" | head -1)
            ;;
        *)
            installed_version="unknown"
            ;;
    esac
    
    echo "配置版本: ${config_version:-未配置}"
    echo "已安装版本: ${installed_version:-未安装}"
    
    if [ "$config_version" = "$installed_version" ] && [ -n "$installed_version" ] && [ "$installed_version" != "unknown" ]; then
        log_success "版本一致"
    elif [ -n "$installed_version" ] && [ "$installed_version" != "unknown" ]; then
        log_warn "版本不一致"
    fi
    
    echo ""
}

set_version() {
    local software="$1"
    local version="$2"
    
    if [ -z "$software" ] || [ -z "$version" ]; then
        log_error "用法: version set <软件> <版本>"
        return 1
    fi
    
    echo -e "${CYAN}设置 $software 版本为 $version${NC}"
    echo "=========================================="
    
    local upper_software=$(echo "$software" | tr '[:lower:]' '[:upper:]')
    
    # 更新配置文件
    if grep -q "^${upper_software}_VERSION" "$CONFIG_FILE"; then
        sed -i "s/^${upper_software}_VERSION=.*/${upper_software}_VERSION=$version/" "$CONFIG_FILE"
    else
        echo "${upper_software}_VERSION=$version" >> "$CONFIG_FILE"
    fi
    
    log_success "配置已更新"
    echo ""
    
    read -p "是否立即安装此版本? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        bash "$SCRIPT_DIR/main.sh" install "$software" "$version"
    fi
}

install_version() {
    local software="$1"
    local version="$2"
    
    if [ -z "$software" ] || [ -z "$version" ]; then
        log_error "用法: version install <软件> <版本>"
        return 1
    fi
    
    echo -e "${CYAN}安装 $software $version${NC}"
    echo "=========================================="
    
    bash "$SCRIPT_DIR/main.sh" install "$software" "$version"
}

show_all_versions() {
    echo -e "${CYAN}所有软件当前配置版本${NC}"
    echo "=========================================="
    
    printf "%-20s %s\n" "软件名称" "配置版本"
    echo "------------------------------------------"
    
    while IFS='=' read -r key value; do
        if [[ "$key" == *_VERSION ]]; then
            name=$(echo "$key" | sed 's/_VERSION//' | tr '[:upper:]' '[:lower:]')
            printf "%-20s %s\n" "$name" "$value"
        fi
    done < "$CONFIG_FILE"
    
    echo ""
}

show_help() {
    cat <<EOF
${CYAN}========================================${NC}
${CYAN}       软件多版本管理工具${NC}
${CYAN}========================================${NC}

${YELLOW}使用方法:${NC}
  version <命令> [选项]

${YELLOW}命令列表:${NC}
  list              列出支持的软件
  versions <软件>   查看软件可用版本
  show <软件>       查看软件当前版本信息
  set <软件> <版本>  设置软件默认版本
  install <软件> <版本> 安装指定版本
  all               显示所有软件配置版本

${YELLOW}支持的软件:${NC}
  nginx, apache, php, python, nodejs, java, go, ruby, rust
  mysql, mariadb, postgresql, mongodb
  redis, memcached, rabbitmq, kafka, zookeeper
  docker, minio, elasticsearch
  spark, hadoop, flink

${YELLOW}示例:${NC}
  version list                   # 列出所有软件
  version versions nginx         # 查看 Nginx 可用版本
  version show nginx             # 查看 Nginx 当前版本
  version set nginx 1.24         # 设置 Nginx 默认版本为 1.24
  version install php 8.2        # 安装 PHP 8.2

EOF
}

main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        list)
            list_software
            ;;
        versions)
            list_versions "$@"
            ;;
        show)
            show_current_version "$@"
            ;;
        set)
            set_version "$@"
            ;;
        install)
            install_version "$@"
            ;;
        all)
            show_all_versions
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            echo "运行 'version help' 查看帮助"
            exit 1
            ;;
    esac
}

main "$@"
