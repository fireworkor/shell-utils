#!/bin/bash

# =========================================
# Shell 工具一键安装脚本 - 跨平台版
# 支持：CentOS 7, CentOS 8, Ubuntu 18/20/22
# =========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    elif [ -f /etc/centos-release ]; then
        OS="centos"
        VER=$(cat /etc/centos-release | grep -oE '[0-9]+' | head -1)
    else
        OS="unknown"
        VER=""
    fi
    
    echo $OS $VER
}

# 初始化变量
detect_os_result=$(detect_os)
OS=$(echo $detect_os_result | awk '{print $1}')
VER=$(echo $detect_os_result | awk '{print $2}')

# 检查 root 权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}错误：请使用 root 用户运行此脚本${NC}"
        echo "使用方法: sudo $0 $@"
        exit 1
    fi
}

# 包管理器选择
get_pkg_manager() {
    case $OS in
        centos)
            if [ "$VER" = "8" ]; then
                echo "dnf"
            else
                echo "yum"
            fi
            ;;
        ubuntu)
            echo "apt"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

PKG_MANAGER=$(get_pkg_manager)

# 系统更新
system_update() {
    echo -e "${BLUE}正在更新系统...${NC}"
    case $PKG_MANAGER in
        dnf|yum)
            $PKG_MANAGER update -y
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update && apt upgrade -y
            ;;
    esac
    echo -e "${GREEN}✓ 系统更新完成${NC}"
}

# 安装开发工具
install_dev_tools() {
    echo -e "${BLUE}正在安装基础开发工具...${NC}"
    case $PKG_MANAGER in
        dnf|yum)
            yum groupinstall -y "Development Tools"
            yum install -y gcc gcc-c++ make cmake autoconf automake libtool \
                pkg-config wget curl git vim nano htop net-tools \
                bind-utils yum-utils device-mapper-persistent-data \
                lvm2 ca-certificates gnupg
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y build-essential gcc g++ make cmake autoconf automake \
                libtool pkg-config wget curl git vim nano htop net-tools \
                dnsutils software-properties-common ca-certificates gnupg
            ;;
    esac
    echo -e "${GREEN}✓ 开发工具安装完成${NC}"
}

# 配置防火墙
configure_firewall() {
    echo -e "${BLUE}正在配置防火墙...${NC}"
    case $OS in
        centos)
            systemctl start firewalld 2>/dev/null || true
            systemctl enable firewalld 2>/dev/null || true
            for port in 22/tcp 80/tcp 443/tcp 3306/tcp 5432/tcp 6379/tcp 8080/tcp 9090/tcp 9100/tcp; do
                firewall-cmd --permanent --add-port=$port > /dev/null 2>&1 || true
            done
            firewall-cmd --reload > /dev/null 2>&1 || true
            ;;
        ubuntu)
            export DEBIAN_FRONTEND=noninteractive
            apt install -y ufw
            ufw allow 22/tcp
            ufw allow 80/tcp
            ufw allow 443/tcp
            ufw allow 3306/tcp
            ufw allow 5432/tcp
            ufw allow 6379/tcp
            ufw allow 8080/tcp
            ufw allow 9090/tcp
            ufw allow 9100/tcp
            ufw --force enable
            ;;
    esac
    echo -e "${GREEN}✓ 防火墙配置完成${NC}"
}

# 安装 Nginx
install_nginx() {
    echo -e "${BLUE}正在安装 Nginx...${NC}"
    case $PKG_MANAGER in
        dnf|yum)
            if [ "$PKG_MANAGER" = "dnf" ]; then
                cat > /etc/yum.repos.d/nginx.repo << 'EOF'
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
modulehotfixes=true
EOF
            fi
            yum install -y nginx
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y nginx
            ;;
    esac
    systemctl start nginx && systemctl enable nginx
    echo -e "${GREEN}✓ Nginx 安装完成${NC}"
}

# 安装 Apache
install_apache() {
    echo -e "${BLUE}正在安装 Apache...${NC}"
    case $PKG_MANAGER in
        dnf|yum)
            yum install -y httpd
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y apache2
            ;;
    esac
    case $OS in
        centos)
            systemctl start httpd && systemctl enable httpd
            ;;
        ubuntu)
            systemctl start apache2 && systemctl enable apache2
            ;;
    esac
    echo -e "${GREEN}✓ Apache 安装完成${NC}"
}

# 安装 MariaDB
install_mariadb() {
    echo -e "${BLUE}正在安装 MariaDB...${NC}"
    case $PKG_MANAGER in
        dnf|yum)
            if [ "$PKG_MANAGER" = "dnf" ]; then
                cat > /etc/yum.repos.d/mariadb.repo << 'EOF'
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.5/centos8-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
            else
                cat > /etc/yum.repos.d/mariadb.repo << 'EOF'
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.5/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
            fi
            yum install -y MariaDB-server MariaDB-client
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y mariadb-server mariadb-client
            ;;
    esac
    systemctl start mariadb && systemctl enable mariadb
    
    echo -e "${YELLOW}正在运行 MariaDB 安全初始化...${NC}"
    mysql_secure_installation << 'MARIADB_EOF'

y
y
y
y
y
y
y
MARIADB_EOF
    
    echo -e "${GREEN}✓ MariaDB 安装完成${NC}"
}

# 安装 MySQL
install_mysql() {
    echo -e "${BLUE}正在安装 MySQL...${NC}"
    case $PKG_MANAGER in
        dnf|yum)
            if [ "$PKG_MANAGER" = "dnf" ]; then
                yum install -y https://dev.mysql.com/get/mysql80-community-release-el8-4.noarch.rpm
            else
                yum install -y https://dev.mysql.com/get/mysql80-community-release-el7-4.noarch.rpm
            fi
            yum install -y mysql-community-server
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            wget -q https://dev.mysql.com/get/mysql-apt-config_0.8.22-1_all.deb
            dpkg -i mysql-apt-config_0.8.22-1_all.deb
            rm mysql-apt-config_0.8.22-1_all.deb
            apt update
            apt install -y mysql-community-server
            ;;
    esac
    systemctl start mysqld && systemctl enable mysqld
    echo -e "${GREEN}✓ MySQL 安装完成${NC}"
}

# 安装 PostgreSQL
install_postgresql() {
    echo -e "${BLUE}正在安装 PostgreSQL...${NC}"
    case $PKG_MANAGER in
        dnf|yum)
            if [ "$PKG_MANAGER" = "dnf" ]; then
                yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
                yum install -y postgresql15-server postgresql15-contrib
                /usr/pgsql-15/bin/postgresql-15-setup initdb
                systemctl start postgresql-15 && systemctl enable postgresql-15
            else
                yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
                yum install -y postgresql15-server postgresql15-contrib
                /usr/pgsql-15/bin/postgresql-15-setup initdb
                systemctl start postgresql-15 && systemctl enable postgresql-15
            fi
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
            wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
            apt update
            apt install -y postgresql-15
            systemctl start postgresql && systemctl enable postgresql
            ;;
    esac
    echo -e "${GREEN}✓ PostgreSQL 安装完成${NC}"
}

# 安装 PHP
install_php() {
    local version=${1:-7.4}
    echo -e "${BLUE}正在安装 PHP $version...${NC}"
    case $PKG_MANAGER in
        dnf|yum)
            yum install -y epel-release
            if [ "$PKG_MANAGER" = "dnf" ]; then
                yum install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
                yum module reset php -y
                yum module enable php:remi-${version} -y
            else
                yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm
                yum module reset php -y
                yum module enable php:remi-${version} -y
            fi
            yum install -y php php-fpm php-mysql php-pdo php-mbstring \
                php-xml php-gd php-curl php-zip php-intl php-bcmath
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y software-properties-common
            add-apt-repository -y ppa:ondrej/php
            apt update
            apt install -y php${version} php${version}-fpm php${version}-mysql php${version}-mbstring \
                php${version}-xml php${version}-gd php${version}-curl php${version}-zip php${version}-intl php${version}-bcmath
            ;;
    esac
    systemctl start php-fpm && systemctl enable php-fpm
    echo -e "${GREEN}✓ PHP $version 安装完成${NC}"
}

# 安装 Python
install_python() {
    local version=${1:-3.11}
    echo -e "${BLUE}正在安装 Python $version...${NC}"
    case $PKG_MANAGER in
        dnf|yum)
            yum install -y gcc openssl-devel bzip2-devel libffi-devel zlib-devel
            cd /tmp
            wget -q https://www.python.org/ftp/python/${version}.0/Python-${version}.0.tgz
            tar xzf Python-${version}.0.tgz
            cd Python-${version}.0
            ./configure --enable-optimizations > /dev/null 2>&1
            make altinstall -j$(nproc) > /dev/null 2>&1
            cd ~
            rm -rf /tmp/Python-${version}*
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y software-properties-common
            add-apt-repository -y ppa:deadsnakes/ppa
            apt update
            apt install -y python${version} python${version}-dev python${version}-venv python3-pip
            ;;
    esac
    echo -e "${GREEN}✓ Python $version 安装完成${NC}"
}

# 安装 Node.js
install_nodejs() {
    local version=${1:-20}
    echo -e "${BLUE}正在安装 Node.js $version...${NC}"
    case $PKG_MANAGER in
        dnf|yum)
            curl -fsSL https://rpm.nodesource.com/setup_${version}.x | bash -
            yum install -y nodejs
            npm install -g npm yarn
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            curl -fsSL https://deb.nodesource.com/setup_${version}.x | bash -
            apt install -y nodejs
            npm install -g npm yarn
            ;;
    esac
    echo -e "${GREEN}✓ Node.js $version 安装完成${NC}"
}

# 安装 Java
install_java() {
    local version=${1:-11}
    echo -e "${BLUE}正在安装 OpenJDK $version...${NC}"
    case $PKG_MANAGER in
        dnf|yum)
            yum install -y java-${version}-openjdk java-${version}-openjdk-devel
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y openjdk-${version}-jdk openjdk-${version}-jdk-headless
            ;;
    esac
    echo -e "${GREEN}✓ OpenJDK $version 安装完成${NC}"
}

# 安装 Docker
install_docker() {
    echo -e "${BLUE}正在安装 Docker...${NC}"
    case $PKG_MANAGER in
        dnf|yum)
            yum remove -y docker docker-client docker-client-latest \
                docker-common docker-latest docker-latest-logrotate \
                docker-logrotate docker-engine > /dev/null 2>&1 || true
            yum install -y dnf-plugins-core device-mapper-persistent-data lvm2
            yum config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y ca-certificates curl gnupg lsb-release
            mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            apt update
            apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
    esac
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
    case $PKG_MANAGER in
        dnf|yum)
            yum install -y redis
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y redis-server
            ;;
    esac
    systemctl start redis && systemctl enable redis
    echo -e "${GREEN}✓ Redis 安装完成${NC}"
}

# 内核调优
tune_kernel() {
    check_root
    
    local mem_gb=$(free -g | awk 'NR==2 {print $2}')
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   内核调优（检测到内存: ${mem_gb}GB）${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    local profile=""
    if [ $mem_gb -lt 2 ]; then
        profile="small"
        tcp_mem_max="786432 1048576 1572864"
        tcp_rmem_max="4096 87380 4194304"
        tcp_wmem_max="4096 65536 4194304"
        file_max="65536"
        nofile_limit="65536"
    elif [ $mem_gb -lt 8 ]; then
        profile="medium"
        tcp_mem_max="3145728 4194304 6291456"
        tcp_rmem_max="4096 87380 67108864"
        tcp_wmem_max="4096 65536 67108864"
        file_max="4194304"
        nofile_limit="262144"
    else
        profile="large"
        tcp_mem_max="12582912 16777216 25165824"
        tcp_rmem_max="4096 87380 268435456"
        tcp_wmem_max="4096 65536 268435456"
        file_max="8388608"
        nofile_limit="524288"
    fi
    
    echo -e "${YELLOW}应用配置方案: ${profile}${NC}"
    
    cat > /etc/sysctl.d/99-tuning.conf << EOF
# 内核调优配置 - $profile 方案
# 内存: ${mem_gb}GB

net.core.rmem_max = $tcp_rmem_max
net.core.wmem_max = $tcp_wmem_max
net.ipv4.tcp_rmem = $tcp_rmem_max
net.ipv4.tcp_wmem = $tcp_wmem_max
net.ipv4.tcp_mem = $tcp_mem_max
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_tw_buckets = 262144
net.ipv4.ip_local_port_range = 10240 65535
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 8192
net.ipv4.tcp_max_syn_backlog = 8192

fs.file-max = $file_max
fs.inotify.max_user_watches = 524288
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 5
vm.overcommit_memory = 1
vm.max_map_count = 262144

kernel.shmmax = $((mem_gb * 1024 * 1024 * 1024 / 4))
kernel.shmall = $((mem_gb * 1024 * 1024 * 1024 / 4096))
kernel.sem = 250 64000 100 512
kernel.pid_max = 65536
EOF
    
    sysctl -p /etc/sysctl.d/99-tuning.conf > /dev/null 2>&1 || true
    
    cat > /etc/security/limits.d/99-tuning.conf << EOF
* soft nofile $nofile_limit
* hard nofile $nofile_limit
* soft nproc 65536
* hard nproc 65536
root soft nofile $nofile_limit
root hard nofile $nofile_limit
EOF
    
    ulimit -n $nofile_limit 2>/dev/null || true
    
    echo -e "${GREEN}✓ 内核调优完成${NC}"
    echo -e "${YELLOW}建议重启系统使配置完全生效: reboot${NC}"
}

# 安装监控
install_monitor() {
    check_root
    echo -e "${BLUE}正在安装监控系统...${NC}"
    
    useradd --no-create-home --shell /bin/false prometheus 2>/dev/null || true
    
    cd /tmp
    wget -q https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
    tar xzf prometheus-2.45.0.linux-amd64.tar.gz
    mv prometheus-2.45.0.linux-amd64 /opt/prometheus
    ln -sf /opt/prometheus /usr/local/bin/prometheus
    
    mkdir -p /etc/prometheus /var/lib/prometheus
    cp /opt/prometheus/prometheus.yml /etc/prometheus/
    chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus /opt/prometheus
    
    cat > /etc/systemd/system/prometheus.service << 'EOF'
[Unit]
Description=Prometheus Monitoring
After=network.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus/
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    
    echo -e "${YELLOW}安装 Node Exporter...${NC}"
    cd /tmp
    wget -q https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
    tar xzf node_exporter-1.6.1.linux-amd64.tar.gz
    mv node_exporter-1.6.1.linux-amd64 /opt/node_exporter
    ln -sf /opt/node_exporter/node_exporter /usr/local/bin/node_exporter
    
    cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
After=network.target

[Service]
ExecStart=/usr/local/bin/node_exporter/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl start node_exporter && systemctl enable node_exporter
    systemctl start prometheus && systemctl enable prometheus
    
    cd ~
    rm -rf /tmp/prometheus* /tmp/node_exporter*
    
    echo -e "${GREEN}✓ 监控系统安装完成${NC}"
    echo "访问地址："
    echo "  Prometheus: http://your_server_ip:9090"
    echo "  Node Exporter: http://your_server_ip:9100"
}

# SSL 证书
install_certbot() {
    check_root
    echo -e "${BLUE}正在安装 Certbot...${NC}"
    case $PKG_MANAGER in
        dnf|yum)
            yum install -y epel-release
            yum install -y certbot python3-certbot-nginx python3-certbot-apache
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y certbot python3-certbot-nginx python3-certbot-apache
            ;;
    esac
    echo -e "${GREEN}✓ Certbot 安装完成${NC}"
}

ssl_cert() {
    local domain=$1
    check_root
    
    if [ -z "$domain" ]; then
        echo -e "${RED}错误：请提供域名${NC}"
        exit 1
    fi
    
    install_certbot
    
    case $OS in
        centos)
            if command -v nginx &>/dev/null; then
                certbot --nginx -d $domain --non-interactive --agree-tos -m admin@$domain
            elif command -v httpd &>/dev/null; then
                certbot --apache -d $domain --non-interactive --agree-tos -m admin@$domain
            else
                certbot certonly --standalone -d $domain --non-interactive --agree-tos -m admin@$domain
            fi
            ;;
        ubuntu)
            if command -v nginx &>/dev/null; then
                certbot --nginx -d $domain --non-interactive --agree-tos -m admin@$domain
            elif command -v apache2 &>/dev/null; then
                certbot --apache -d $domain --non-interactive --agree-tos -m admin@$domain
            else
                certbot certonly --standalone -d $domain --non-interactive --agree-tos -m admin@$domain
            fi
            ;;
    esac
    
    echo -e "${GREEN}✓ SSL 证书申请完成${NC}"
}

ssl_renew() {
    check_root
    echo -e "${BLUE}续期所有 SSL 证书...${NC}"
    certbot renew --quiet
    systemctl restart nginx apache2 httpd 2>/dev/null || true
    echo -e "${GREEN}✓ 证书续期完成${NC}"
}

# 备份
backup_all() {
    check_root
    echo -e "${BLUE}备份系统...${NC}"
    
    local BACKUP_DIR="/var/backups"
    local DB_BACKUP_DIR="$BACKUP_DIR/databases"
    mkdir -p $DB_BACKUP_DIR
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    if command -v mysql &>/dev/null || command -v mysqldump &>/dev/null; then
        mkdir -p $DB_BACKUP_DIR/mysql
        mysqldump --all-databases --single-transaction --quick --lock-tables=false \
            > $DB_BACKUP_DIR/mysql/all_databases_${timestamp}.sql 2>/dev/null || true
        gzip $DB_BACKUP_DIR/mysql/all_databases_${timestamp}.sql
    fi
    
    echo -e "${GREEN}✓ 备份完成${NC}"
    echo "备份位置: $DB_BACKUP_DIR"
}

# 系统清理
cleanup_all() {
    check_root
    echo -e "${BLUE}系统清理...${NC}"
    
    case $PKG_MANAGER in
        dnf|yum)
            yum clean all
            ;;
        apt)
            apt clean
            apt autoclean
            apt autoremove -y
            ;;
    esac
    
    rm -rf /tmp/* 2>/dev/null || true
    rm -rf /var/tmp/* 2>/dev/null || true
    
    echo -e "${GREEN}✓ 系统清理完成${NC}"
}

# 安装 LNMP/LAMP
install_lnmp() {
    echo -e "${PURPLE}安装 LNMP 栈...${NC}"
    install_nginx
    install_mariadb
    install_php 7.4
    configure_firewall
    echo -e "${GREEN}✓ LNMP 安装完成${NC}"
}

install_lamp() {
    echo -e "${PURPLE}安装 LAMP 栈...${NC}"
    install_apache
    install_mariadb
    install_php 7.4
    configure_firewall
    echo -e "${GREEN}✓ LAMP 安装完成${NC}"
}

# 显示帮助
show_help() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   跨平台 Shell 工具一键安装脚本${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${YELLOW}检测到系统：${NC} $OS $VER"
    echo -e "${YELLOW}包管理器：${NC} $PKG_MANAGER"
    echo ""
    echo -e "${YELLOW}使用方法：${NC}"
    echo "  curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | bash -s -- <命令>"
    echo ""
    echo -e "${YELLOW}基础命令：${NC}"
    echo "  update          - 更新系统"
    echo "  system_info     - 显示系统信息"
    echo ""
    echo -e "${YELLOW}软件安装：${NC}"
    echo "  nginx/apache    - Web 服务器"
    echo "  mariadb/mysql   - 数据库"
    echo "  postgresql      - PostgreSQL"
    echo "  php [版本]      - PHP (默认: 7.4)"
    echo "  python [版本]   - Python (默认: 3.11)"
    echo "  nodejs [版本]   - Node.js (默认: 20)"
    echo "  java [版本]     - OpenJDK (默认: 11)"
    echo "  docker/redis    - 容器和缓存"
    echo ""
    echo -e "${YELLOW}运维工具：${NC}"
    echo "  monitor         - 安装监控系统"
    echo "  tune_kernel     - 内核调优"
    echo "  ssl <域名>      - 申请 SSL 证书"
    echo "  backup          - 备份数据库"
    echo "  cleanup         - 系统清理"
    echo ""
    echo -e "${YELLOW}一键部署：${NC}"
    echo "  lnmp            - LNMP 栈"
    echo "  lamp            - LAMP 栈"
    echo "  dev_tools       - 开发工具"
    echo "  firewall        - 防火墙"
    echo ""
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
        update)
            check_root
            system_update
            ;;
        system_info)
            echo "操作系统: $OS $VER"
            echo "内核版本: $(uname -r)"
            echo "架构: $(uname -m)"
            ;;
        nginx)
            check_root
            install_nginx
            ;;
        apache)
            check_root
            install_apache
            ;;
        mariadb)
            check_root
            install_mariadb
            ;;
        mysql)
            check_root
            install_mysql
            ;;
        postgresql)
            check_root
            install_postgresql
            ;;
        php)
            check_root
            install_php "$@"
            ;;
        python)
            check_root
            install_python "$@"
            ;;
        nodejs)
            check_root
            install_nodejs "$@"
            ;;
        java)
            check_root
            install_java "$@"
            ;;
        docker)
            check_root
            install_docker
            ;;
        redis)
            check_root
            install_redis
            ;;
        tune_kernel)
            tune_kernel
            ;;
        monitor)
            install_monitor
            ;;
        ssl)
            ssl_cert "$@"
            ;;
        backup)
            backup_all
            ;;
        cleanup)
            cleanup_all
            ;;
        lnmp)
            check_root
            install_lnmp
            ;;
        lamp)
            check_root
            install_lamp
            ;;
        dev_tools)
            check_root
            install_dev_tools
            ;;
        firewall)
            check_root
            configure_firewall
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}错误：未知命令 '$command'${NC}"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
