#!/bin/bash
# 描述：卸载软件

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

uninstall_software() {
    local software=$1
    local force=${2:-false}
    
    print_header "卸载 $software"
    
    if ! $force; then
        if ! confirm "确定要卸载 $software 吗？"; then
            print_info "取消卸载"
            return 1
        fi
    fi
    
    case $software in
        nginx)
            uninstall_nginx
            ;;
        apache|httpd)
            uninstall_apache
            ;;
        php)
            uninstall_php
            ;;
        mysql)
            uninstall_mysql
            ;;
        mariadb)
            uninstall_mariadb
            ;;
        postgresql|postgres)
            uninstall_postgresql
            ;;
        redis)
            uninstall_redis
            ;;
        docker)
            uninstall_docker
            ;;
        mongodb)
            uninstall_mongodb
            ;;
        elasticsearch)
            uninstall_elasticsearch
            ;;
        *)
            print_error "不支持卸载 $software"
            return 1
            ;;
    esac
}

uninstall_nginx() {
    print_info "开始卸载 Nginx..."
    
    systemctl stop nginx 2>/dev/null || true
    systemctl disable nginx 2>/dev/null || true
    
    local pkg_manager=$(get_pkg_manager)
    case $pkg_manager in
        dnf|yum)
            yum remove -y nginx
            ;;
        apt)
            apt purge -y nginx nginx-common nginx-full nginx-utils
            ;;
    esac
    
    rm -rf /etc/nginx /var/log/nginx /var/cache/nginx
    rm -f /etc/systemd/system/nginx.service
    
    print_success "Nginx 卸载完成"
}

uninstall_apache() {
    print_info "开始卸载 Apache..."
    
    systemctl stop httpd 2>/dev/null || true
    systemctl stop apache2 2>/dev/null || true
    systemctl disable httpd 2>/dev/null || true
    systemctl disable apache2 2>/dev/null || true
    
    local pkg_manager=$(get_pkg_manager)
    case $pkg_manager in
        dnf|yum)
            yum remove -y httpd
            ;;
        apt)
            apt purge -y apache2 apache2-utils apache2-bin
            ;;
    esac
    
    rm -rf /etc/httpd /etc/apache2 /var/log/httpd /var/log/apache2
    rm -f /etc/systemd/system/httpd.service
    
    print_success "Apache 卸载完成"
}

uninstall_php() {
    print_info "开始卸载 PHP..."
    
    local pkg_manager=$(get_pkg_manager)
    case $pkg_manager in
        dnf|yum)
            yum remove -y php php-* php-fpm
            ;;
        apt)
            apt purge -y php* php-* php-fpm
            ;;
    esac
    
    rm -rf /etc/php /etc/php-fpm.d
    rm -f /etc/systemd/system/php-fpm.service
    
    print_success "PHP 卸载完成"
}

uninstall_mysql() {
    print_info "开始卸载 MySQL..."
    
    systemctl stop mysqld 2>/dev/null || true
    systemctl disable mysqld 2>/dev/null || true
    
    local pkg_manager=$(get_pkg_manager)
    case $pkg_manager in
        dnf|yum)
            yum remove -y mysql mysql-server mysql-community-server
            ;;
        apt)
            apt purge -y mysql-server mysql-server mysql-client mysql-community-server mysql-community-client
            ;;
    esac
    
    rm -rf /var/lib/mysql /etc/my.cnf /etc/mysql
    rm -rf /var/log/mysql /var/log/mysqld.log
    rm -f /etc/systemd/system/mysqld.service
    
    print_success "MySQL 卸载完成"
}

uninstall_mariadb() {
    print_info "开始卸载 MariaDB..."
    
    systemctl stop mariadb 2>/dev/null || true
    systemctl disable mariadb 2>/dev/null || true
    
    local pkg_manager=$(get_pkg_manager)
    case $pkg_manager in
        dnf|yum)
            yum remove -y MariaDB-server MariaDB-client MariaDB-common
            ;;
        apt)
            apt purge -y mariadb-server mariadb-client mariadb-common
            ;;
    esac
    
    rm -rf /var/lib/mysql /etc/my.cnf /etc/mysql
    rm -rf /var/log/mysql
    rm -f /etc/systemd/system/mariadb.service
    rm -f /etc/yum.repos.d/mariadb.repo
    
    print_success "MariaDB 卸载完成"
}

uninstall_postgresql() {
    print_info "开始卸载 PostgreSQL..."
    
    systemctl stop postgresql 2>/dev/null || true
    systemctl disable postgresql 2>/dev/null || true
    
    local pkg_manager=$(get_pkg_manager)
    case $pkg_manager in
        dnf|yum)
            yum remove -y postgresql postgresql-server postgresql-devel postgresql-libs
            ;;
        apt)
            apt purge -y postgresql postgresql-* postgresql-client postgresql-common
            ;;
    esac
    
    rm -rf /var/lib/pgsql /etc/postgresql
    rm -rf /var/log/postgresql
    rm -f /etc/systemd/system/postgresql.service
    
    print_success "PostgreSQL 卸载完成"
}

uninstall_redis() {
    print_info "开始卸载 Redis..."
    
    systemctl stop redis 2>/dev/null || true
    systemctl disable redis 2>/dev/null || true
    
    local pkg_manager=$(get_pkg_manager)
    case $pkg_manager in
        dnf|yum)
            yum remove -y redis
            ;;
        apt)
            apt purge -y redis-server redis-cli
            ;;
    esac
    
    rm -rf /etc/redis /var/lib/redis /var/log/redis
    rm -f /etc/systemd/system/redis.service
    
    print_success "Redis 卸载完成"
}

uninstall_docker() {
    print_info "开始卸载 Docker..."
    
    systemctl stop docker 2>/dev/null || true
    systemctl disable docker 2>/dev/null || true
    
    local pkg_manager=$(get_pkg_manager)
    case $pkg_manager in
        dnf|yum)
            yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
            ;;
        apt)
            apt purge -y docker.io docker-engine docker.io docker-doc
            ;;
    esac
    
    rm -rf /var/lib/docker /var/lib/containerd /etc/docker
    rm -f /etc/systemd/system/docker.service
    rm -f /etc/systemd/system/containerd.service
    
    print_success "Docker 卸载完成"
}

uninstall_mongodb() {
    print_info "开始卸载 MongoDB..."
    
    systemctl stop mongod 2>/dev/null || true
    systemctl disable mongod 2>/dev/null || true
    
    local pkg_manager=$(get_pkg_manager)
    case $pkg_manager in
        dnf|yum)
            yum remove -y mongodb-org mongodb-org-server mongodb-org-shell mongodb-org-mongos mongodb-org-tools
            ;;
        apt)
            apt purge -y mongodb-org mongodb-org-server mongodb-org-shell mongodb-org-mongos mongodb-org-tools
            ;;
    esac
    
    rm -rf /var/lib/mongo /var/log/mongodb
    rm -f /etc/systemd/system/mongod.service
    rm -f /etc/yum.repos.d/mongodb-org.repo
    
    print_success "MongoDB 卸载完成"
}

uninstall_elasticsearch() {
    print_info "开始卸载 Elasticsearch..."
    
    systemctl stop elasticsearch 2>/dev/null || true
    systemctl disable elasticsearch 2>/dev/null || true
    
    local pkg_manager=$(get_pkg_manager)
    case $pkg_manager in
        dnf|yum)
            yum remove -y elasticsearch
            ;;
        apt)
            apt purge -y elasticsearch
            ;;
    esac
    
    rm -rf /var/lib/elasticsearch /var/log/elasticsearch /usr/share/elasticsearch
    rm -f /etc/elasticsearch/elasticsearch.yml
    rm -f /etc/systemd/system/elasticsearch.service
    rm -f /etc/apt/sources.list.d/elastic-8.x.list
    
    print_success "Elasticsearch 卸载完成"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    uninstall_software "$@"
fi
