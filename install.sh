#!/bin/bash

# =========================================
# Shell 工具一键安装脚本
# 使用方法：
#   curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | bash -s -- <命令>
#   或
#   curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | sudo bash -s -- <命令>
# =========================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 检查参数
if [ $# -eq 0 ]; then
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   Shell 工具一键安装脚本${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${YELLOW}使用方法：${NC}"
    echo "  curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | bash -s -- <命令>"
    echo ""
    echo -e "${YELLOW}基础工具命令：${NC}"
    echo "  system_info          - 显示系统信息"
    echo "  check_disk           - 检查磁盘使用"
    echo "  check_network        - 检查网络连接"
    echo "  backup <文件>        - 备份文件"
    echo ""
    echo -e "${YELLOW}CentOS 8 软件部署命令：${NC}"
    echo "  nginx                - 安装 Nginx"
    echo "  apache               - 安装 Apache"
    echo "  mysql                - 安装 MySQL 8.0"
    echo "  postgresql           - 安装 PostgreSQL"
    echo "  php [版本]           - 安装 PHP (默认: 7.4)"
    echo "  python [版本]        - 安装 Python (默认: 3.11)"
    echo "  nodejs [版本]        - 安装 Node.js (默认: 20)"
    echo "  docker               - 安装 Docker"
    echo "  redis                - 安装 Redis"
    echo "  java [版本]          - 安装 OpenJDK (默认: 11)"
    echo ""
    echo -e "${YELLOW}一键部署方案：${NC}"
    echo "  lnmp                 - 一键安装 LNMP 栈"
    echo "  lamp                 - 一键安装 LAMP 栈"
    echo "  dev_tools            - 安装开发工具"
    echo "  common_tools         - 安装常用工具"
    echo "  firewall             - 配置防火墙"
    echo "  all                  - 安装所有基础服务"
    echo ""
    echo -e "${YELLOW}示例：${NC}"
    echo "  curl ... | bash -s -- system_info"
    echo "  curl ... | bash -s -- nginx"
    echo "  curl ... | bash -s -- php 8.0"
    echo "  curl ... | sudo bash -s -- lnmp"
    echo ""
    exit 0
fi

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}错误：请使用 root 用户运行此脚本${NC}"
        echo "使用方法: sudo $0 $@"
        exit 1
    fi
}

# 检查 CentOS 8
check_centos8() {
    if [ ! -f /etc/centos-release ]; then
        echo -e "${RED}错误：此脚本仅支持 CentOS 8${NC}"
        exit 1
    fi
    
    if ! grep -q "CentOS Linux release 8" /etc/centos-release; then
        echo -e "${RED}错误：此脚本仅支持 CentOS Linux 8${NC}"
        exit 1
    fi
}

# 安装开发工具
install_dev_tools() {
    echo -e "${BLUE}正在安装基础开发工具...${NC}"
    dnf groupinstall -y "Development Tools"
    dnf install -y \
        gcc gcc-c++ make cmake autoconf automake libtool \
        pkg-config wget curl git vim nano htop net-tools \
        bind-utils yum-utils device-mapper-persistent-data \
        lvm2 ca-certificates gnupg-agent
    echo -e "${GREEN}✓ 开发工具安装完成${NC}"
}

# 安装常用工具
install_common_tools() {
    echo -e "${BLUE}正在安装常用工具...${NC}"
    dnf install -y htop nethogs iftop iotop sysstat
    dnf install -y telnet nmap tcpdump strace lsof
    dnf install -y zip unzip bzip2 p7zip p7zip-plugins
    dnf install -y jq bc rsync tree
    systemctl start chronyd && systemctl enable chronyd
    echo -e "${GREEN}✓ 常用工具安装完成${NC}"
}

# 配置防火墙
configure_firewall() {
    echo -e "${BLUE}正在配置防火墙...${NC}"
    dnf install -y firewalld
    systemctl start firewalld && systemctl enable firewalld
    
    for port in 22/tcp 80/tcp 443/tcp 3306/tcp 5432/tcp 6379/tcp 8080/tcp 9090/tcp; do
        firewall-cmd --permanent --add-port=$port > /dev/null 2>&1 || true
    done
    firewall-cmd --reload > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ 防火墙配置完成${NC}"
}

# 安装 Nginx
install_nginx() {
    echo -e "${BLUE}正在安装 Nginx...${NC}"
    cat > /etc/yum.repos.d/nginx.repo << 'EOF'
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
modulehotfixes=true
EOF
    dnf install -y nginx
    systemctl start nginx && systemctl enable nginx
    echo -e "${GREEN}✓ Nginx 安装完成${NC}"
}

# 安装 Apache
install_apache() {
    echo -e "${BLUE}正在安装 Apache...${NC}"
    dnf install -y httpd
    systemctl start httpd && systemctl enable httpd
    configure_firewall
    echo -e "${GREEN}✓ Apache 安装完成${NC}"
}

# 安装 MySQL
install_mysql() {
    echo -e "${BLUE}正在安装 MySQL 8.0...${NC}"
    dnf install -y https://dev.mysql.com/get/mysql80-community-release-el8-4.noarch.rpm
    dnf install -y mysql-community-server
    systemctl start mysqld && systemctl enable mysqld
    echo -e "${GREEN}✓ MySQL 安装完成${NC}"
    echo "临时密码: $(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')"
}

# 安装 PostgreSQL
install_postgresql() {
    echo -e "${BLUE}正在安装 PostgreSQL...${NC}"
    dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
    dnf install -y postgresql15-server postgresql15-contrib
    /usr/pgsql-15/bin/postgresql-15-setup initdb
    systemctl start postgresql-15 && systemctl enable postgresql-15
    echo -e "${GREEN}✓ PostgreSQL 安装完成${NC}"
}

# 安装 PHP
install_php() {
    local version=${1:-7.4}
    echo -e "${BLUE}正在安装 PHP $version...${NC}"
    dnf install -y epel-release
    dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
    dnf module reset php -y
    dnf module enable php:remi-${version} -y
    dnf install -y php php-fpm php-mysql php-pdo php-mbstring \
        php-xml php-gd php-curl php-zip php-intl php-bcmath
    systemctl start php-fpm && systemctl enable php-fpm
    echo -e "${GREEN}✓ PHP $version 安装完成${NC}"
}

# 安装 Python
install_python() {
    local version=${1:-3.11}
    echo -e "${BLUE}正在安装 Python $version...${NC}"
    dnf install -y gcc openssl-devel bzip2-devel libffi-devel zlib-devel
    cd /tmp
    wget -q https://www.python.org/ftp/python/${version}.0/Python-${version}.0.tgz
    tar xzf Python-${version}.0.tgz
    cd Python-${version}.0
    ./configure --enable-optimizations > /dev/null 2>&1
    make altinstall -j$(nproc) > /dev/null 2>&1
    cd ~
    rm -rf /tmp/Python-${version}*
    echo -e "${GREEN}✓ Python $version 安装完成${NC}"
}

# 安装 Node.js
install_nodejs() {
    local version=${1:-20}
    echo -e "${BLUE}正在安装 Node.js $version...${NC}"
    curl -fsSL https://rpm.nodesource.com/setup_${version}.x | bash -
    dnf install -y nodejs
    npm install -g npm yarn
    echo -e "${GREEN}✓ Node.js $version 安装完成${NC}"
}

# 安装 Java
install_java() {
    local version=${1:-11}
    echo -e "${BLUE}正在安装 OpenJDK $version...${NC}"
    dnf install -y java-${version}-openjdk java-${version}-openjdk-devel
    echo -e "${GREEN}✓ OpenJDK $version 安装完成${NC}"
}

# 安装 Docker
install_docker() {
    echo -e "${BLUE}正在安装 Docker...${NC}"
    dnf remove -y docker docker-client docker-client-latest \
        docker-common docker-latest docker-latest-logrotate \
        docker-logrotate docker-engine > /dev/null 2>&1 || true
    dnf install -y dnf-plugins-core device-mapper-persistent-data lvm2
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl start docker && systemctl enable docker
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << 'EOF'
{
    "registry-mirrors": [
        "https://docker.mirrors.ustc.edu.cn",
        "https://hub-mirror.c.163.com"
    ]
}
EOF
    systemctl restart docker
    echo -e "${GREEN}✓ Docker 安装完成${NC}"
}

# 安装 Redis
install_redis() {
    echo -e "${BLUE}正在安装 Redis...${NC}"
    dnf install -y redis
    systemctl start redis && systemctl enable redis
    echo -e "${GREEN}✓ Redis 安装完成${NC}"
}

# 安装 LNMP
install_lnmp() {
    echo -e "${PURPLE}开始安装 LNMP 栈...${NC}"
    install_nginx
    install_mysql
    install_php 7.4
    configure_firewall
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ LNMP 栈安装完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# 安装 LAMP
install_lamp() {
    echo -e "${PURPLE}开始安装 LAMP 栈...${NC}"
    install_apache
    install_mysql
    install_php 7.4
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ LAMP 栈安装完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# 安装所有基础服务
install_all() {
    echo -e "${PURPLE}开始安装所有基础服务...${NC}"
    echo ""
    install_dev_tools
    install_common_tools
    install_nginx
    install_mysql
    install_php 7.4
    install_docker
    configure_firewall
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ 所有基础服务安装完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# 系统信息
show_system_info() {
    echo -e "${BLUE}系统信息：${NC}"
    echo "  主机名: $(hostname)"
    echo "  操作系统: $(cat /etc/centos-release)"
    echo "  内核版本: $(uname -r)"
    echo "  架构: $(uname -m)"
    echo "  运行时间: $(uptime -p)"
    echo "  负载: $(uptime | awk -F'load average:' '{print $2}')"
    echo "  内存使用:"
    free -h | awk 'NR==2 {printf "    总计: %s\n    已用: %s\n    空闲: %s\n", $2, $3, $4}'
    echo "  磁盘使用:"
    df -h | grep -E '^/dev/' | awk '{printf "    %s: %s / %s (使用率: %s)\n", $1, $3, $2, $5}'
}

# 检查磁盘
check_disk() {
    local threshold=${1:-90}
    echo -e "${BLUE}磁盘使用情况 (阈值: ${threshold}%)：${NC}"
    df -h | grep -E '^/dev/' | while read line; do
        usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
        if [ "$usage" -ge "$threshold" ]; then
            echo -e "  ${RED}$line${NC}"
        else
            echo "  $line"
        fi
    done
}

# 检查网络
check_network() {
    echo -e "${BLUE}网络连接检查...${NC}"
    if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ 网络连接正常${NC}"
    else
        echo -e "  ${RED}✗ 网络连接失败${NC}"
    fi
}

# 备份文件
backup_file() {
    local file=$1
    if [ -z "$file" ]; then
        echo -e "${RED}错误：请指定要备份的文件${NC}"
        echo "使用方法: $0 backup <文件路径>"
        exit 1
    fi
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}错误：文件不存在: $file${NC}"
        exit 1
    fi
    
    local backup="${file}.$(date +%Y%m%d_%H%M%S).bak"
    cp "$file" "$backup"
    echo -e "${GREEN}✓ 文件已备份到: $backup${NC}"
}

# 主函数
main() {
    local command=$1
    shift
    
    case $command in
        system_info)
            show_system_info
            ;;
        check_disk)
            check_disk "$@"
            ;;
        check_network)
            check_network
            ;;
        backup)
            backup_file "$1"
            ;;
        dev_tools)
            check_root "$@"
            install_dev_tools
            ;;
        common_tools)
            check_root "$@"
            install_common_tools
            ;;
        firewall)
            check_root "$@"
            configure_firewall
            ;;
        nginx)
            check_root "$@"
            install_nginx
            ;;
        apache)
            check_root "$@"
            install_apache
            ;;
        mysql)
            check_root "$@"
            install_mysql
            ;;
        postgresql)
            check_root "$@"
            install_postgresql
            ;;
        php)
            check_root "$@"
            install_php "$@"
            ;;
        python)
            check_root "$@"
            install_python "$@"
            ;;
        nodejs)
            check_root "$@"
            install_nodejs "$@"
            ;;
        java)
            check_root "$@"
            install_java "$@"
            ;;
        docker)
            check_root "$@"
            install_docker
            ;;
        redis)
            check_root "$@"
            install_redis
            ;;
        lnmp)
            check_root "$@"
            install_lnmp
            ;;
        lamp)
            check_root "$@"
            install_lamp
            ;;
        all)
            check_root "$@"
            install_all
            ;;
        *)
            echo -e "${RED}错误：未知命令 '$command'${NC}"
            echo "运行 '$0' 查看帮助"
            exit 1
            ;;
    esac
}

main "$@"
