#!/bin/bash

# =========================================
# Shell 工具一键安装脚本
# 使用方法：
#   curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | bash -s -- <命令>
#   或
#   curl -fsSL https://raw.githubusercontent.com/fireworkor/shell-utils/main/install.sh | sudo bash -s -- <命令>
# =========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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
    echo "  mariadb              - 安装 MariaDB 10.5"
    echo "  postgresql           - 安装 PostgreSQL"
    echo "  php [版本]           - 安装 PHP (默认: 7.4)"
    echo "  python [版本]         - 安装 Python (默认: 3.11)"
    echo "  nodejs [版本]         - 安装 Node.js (默认: 20)"
    echo "  docker               - 安装 Docker"
    echo "  redis                - 安装 Redis"
    echo "  java [版本]          - 安装 OpenJDK (默认: 11)"
    echo ""
    echo -e "${YELLOW}性能优化命令：${NC}"
    echo "  tune_kernel          - 自动调优内核参数（根据内存大小）"
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
    echo "  curl ... | sudo bash -s -- tune_kernel"
    echo "  curl ... | sudo bash -s -- lnmp"
    echo ""
    exit 0
fi

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}错误：请使用 root 用户运行此脚本${NC}"
        echo "使用方法: sudo $0 $@"
        exit 1
    fi
}

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

# 安装 MariaDB
install_mariadb() {
    echo -e "${BLUE}正在安装 MariaDB 10.5...${NC}"
    
    # 创建 MariaDB 仓库
    cat > /etc/yum.repos.d/mariadb.repo << 'EOF'
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.5/centos8-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
    
    # 安装 MariaDB
    dnf install -y MariaDB-server MariaDB-client MariaDB-common
    
    # 启动并设置开机启动
    systemctl start mariadb
    systemctl enable mariadb
    
    # 安全初始化
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
    echo ""
    echo "管理命令:"
    echo "  启动: systemctl start mariadb"
    echo "  停止: systemctl stop mariadb"
    echo "  重启: systemctl restart mariadb"
    echo "  状态: systemctl status mariadb"
    echo ""
    echo "连接命令:"
    echo "  mysql -u root -p"
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

# 内核调优
tune_kernel() {
    check_root
    
    local mem_gb=$(free -g | awk 'NR==2 {print $2}')
    local mem_mb=$(free -m | awk 'NR==2 {print $2}')
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   CentOS 8 内核调优${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${YELLOW}检测到内存: ${mem_gb}GB${NC}"
    
    # 确定配置方案
    local profile=""
    if [ $mem_gb -lt 1 ]; then
        profile="tiny"
    elif [ $mem_gb -lt 2 ]; then
        profile="small"
    elif [ $mem_gb -lt 4 ]; then
        profile="medium"
    elif [ $mem_gb -lt 8 ]; then
        profile="large"
    elif [ $mem_gb -lt 16 ]; then
        profile="xlarge"
    elif [ $mem_gb -lt 32 ]; then
        profile="2xlarge"
    elif [ $mem_gb -lt 64 ]; then
        profile="4xlarge"
    else
        profile="8xlarge"
    fi
    
    echo -e "${YELLOW}配置方案: ${profile}${NC}"
    echo ""
    
    # 根据内存大小应用不同配置
    echo -e "${BLUE}正在应用内核参数...${NC}"
    
    local tcp_mem_max=""
    local tcp_rmem_max=""
    local tcp_wmem_max=""
    local file_max=""
    local nofile_limit=""
    
    # 计算参数
    if [ $mem_gb -lt 2 ]; then
        tcp_mem_max="786432 1048576 1572864"
        tcp_rmem_max="4096 87380 4194304"
        tcp_wmem_max="4096 65536 4194304"
        file_max="65536"
        nofile_limit="65536"
    elif [ $mem_gb -lt 4 ]; then
        tcp_mem_max="1572864 2097152 3145728"
        tcp_rmem_max="4096 87380 16777216"
        tcp_wmem_max="4096 65536 16777216"
        file_max="2097152"
        nofile_limit="131072"
    elif [ $mem_gb -lt 8 ]; then
        tcp_mem_max="3145728 4194304 6291456"
        tcp_rmem_max="4096 87380 67108864"
        tcp_wmem_max="4096 65536 67108864"
        file_max="4194304"
        nofile_limit="262144"
    elif [ $mem_gb -lt 16 ]; then
        tcp_mem_max="6291456 8388608 12582912"
        tcp_rmem_max="4096 87380 134217728"
        tcp_wmem_max="4096 65536 134217728"
        file_max="4194304"
        nofile_limit="524288"
    elif [ $mem_gb -lt 32 ]; then
        tcp_mem_max="12582912 16777216 25165824"
        tcp_rmem_max="4096 87380 268435456"
        tcp_wmem_max="4096 65536 268435456"
        file_max="8388608"
        nofile_limit="524288"
    else
        tcp_mem_max="25165824 33554432 50331648"
        tcp_rmem_max="4096 87380 536870912"
        tcp_wmem_max="4096 65536 536870912"
        file_max="16777216"
        nofile_limit="524288"
    fi
    
    # 创建配置文件
    cat > /etc/sysctl.d/99-tuning.conf << EOF
# CentOS 8 内核调优配置 - $profile 方案
# 内存: ${mem_gb}GB

# 网络参数
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
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 15

# 文件系统参数
fs.file-max = $file_max
fs.inotify.max_user_watches = 524288
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 5
vm.overcommit_memory = 1
vm.max_map_count = 262144

# 内核参数
kernel.shmmax = $((mem_gb * 1024 * 1024 * 1024 / 4))
kernel.shmall = $((mem_gb * 1024 * 1024 * 1024 / 4096))
kernel.sem = 250 64000 100 512
kernel.pid_max = 65536
EOF
    
    # 应用配置
    sysctl -p /etc/sysctl.d/99-tuning.conf > /dev/null 2>&1 || true
    
    # 配置 limits
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
    echo ""
    echo -e "${YELLOW}建议重启系统使配置完全生效: reboot${NC}"
}

# 安装 LNMP
install_lnmp() {
    echo -e "${PURPLE}开始安装 LNMP 栈...${NC}"
    install_nginx
    install_mariadb
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
    install_mariadb
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
    install_mariadb
    install_php 7.4
    install_docker
    configure_firewall
    tune_kernel
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ 所有基础服务安装完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# 系统信息
show_system_info() {
    echo -e "${BLUE}系统信息：${NC}"
    echo "  主机名: $(hostname)"
    echo "  操作系统: $(cat /etc/centos-release 2>/dev/null || cat /etc/redhat-release 2>/dev/null || uname -s)"
    echo "  内核版本: $(uname -r)"
    echo "  架构: $(uname -m)"
    echo "  运行时间: $(uptime -p 2>/dev/null || uptime)"
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
        mariadb)
            check_root "$@"
            install_mariadb
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
        tune_kernel)
            tune_kernel
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
