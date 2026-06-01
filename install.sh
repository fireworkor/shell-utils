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
    echo -e "${YELLOW}监控管理命令：${NC}"
    echo "  monitor_install      - 安装监控系统 (Prometheus)"
    echo "  monitor_start        - 启动监控服务"
    echo "  monitor_stop         - 停止监控服务"
    echo "  monitor_status       - 查看监控状态"
    echo "  sysmon               - 实时系统监控（终端界面）"
    echo ""
    echo -e "${YELLOW}SSL 证书命令：${NC}"
    echo "  ssl_cert <域名>      - 为域名申请 Let's Encrypt 证书"
    echo "  ssl_renew            - 续期所有证书"
    echo "  ssl_list             - 列出所有证书"
    echo "  ssl_delete <域名>    - 删除指定证书"
    echo ""
    echo -e "${YELLOW}备份管理命令：${NC}"
    echo "  backup_files         - 备份重要配置文件"
    echo "  backup_db            - 备份所有数据库"
    echo "  backup_all           - 完整备份（文件+数据库）"
    echo "  backup_auto          - 配置自动备份（每天凌晨执行）"
    echo "  restore_db <文件>    - 恢复数据库"
    echo ""
    echo -e "${YELLOW}系统清理命令：${NC}"
    echo "  cleanup_check        - 检查可清理空间"
    echo "  cleanup_kernel       - 清理旧内核"
    echo "  cleanup_log          - 清理日志文件"
    echo "  cleanup_cache        - 清理缓存"
    echo "  cleanup_all          - 完整系统清理"
    echo ""
    echo -e "${YELLOW}一键部署方案：${NC}"
    echo "  lnmp                 - 一键安装 LNMP 栈"
    echo "  lamp                 - 一键安装 LAMP 栈"
    echo "  dev_tools            - 安装开发工具"
    echo "  common_tools         - 安装常用工具"
    echo "  firewall             - 配置防火墙"
    echo "  all                  - 安装所有基础服务"
    echo "  ops_all              - 安装所有运维工具（监控+备份+SSL）"
    echo ""
    echo -e "${YELLOW}示例：${NC}"
    echo "  curl ... | bash -s -- system_info"
    echo "  curl ... | bash -s -- nginx"
    echo "  curl ... | sudo bash -s -- monitor_install"
    echo "  curl ... | sudo bash -s -- ssl_cert example.com"
    echo "  curl ... | sudo bash -s -- backup_all"
    echo "  curl ... | sudo bash -s -- cleanup_all"
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
    
    for port in 22/tcp 80/tcp 443/tcp 3306/tcp 5432/tcp 6379/tcp 8080/tcp 9090/tcp 9100/tcp; do
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
    
    cat > /etc/yum.repos.d/mariadb.repo << 'EOF'
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.5/centos8-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
    
    dnf install -y MariaDB-server MariaDB-client MariaDB-common
    
    systemctl start mariadb
    systemctl enable mariadb
    
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
    
    echo -e "${BLUE}正在应用内核参数...${NC}"
    
    local tcp_mem_max=""
    local tcp_rmem_max=""
    local tcp_wmem_max=""
    local file_max=""
    local nofile_limit=""
    
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
    echo ""
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
    --storage.tsdb.path=/var/lib/prometheus/ \
    --web.console.libraries=/opt/prometheus/consoles \
    --web.console.templates=/opt/prometheus/consoles
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
    systemctl start node_exporter
    systemctl enable node_exporter
    systemctl start prometheus
    systemctl enable prometheus
    
    cd ~
    rm -rf /tmp/prometheus* /tmp/node_exporter*
    
    echo -e "${GREEN}✓ 监控系统安装完成${NC}"
    echo ""
    echo "访问地址："
    echo "  Prometheus: http://your_server_ip:9090"
    echo "  Node Exporter: http://your_server_ip:9100"
}

# 实时系统监控
sysmon() {
    while true; do
        clear
        echo -e "${CYAN}========================================${NC}"
        echo -e "${CYAN}   系统实时监控$(date '+%Y-%m-%d %H:%M:%S')${NC}"
        echo -e "${CYAN}========================================${NC}"
        echo ""
        
        echo -e "${YELLOW}【系统信息】${NC}"
        echo "  主机名: $(hostname)"
        echo "  运行时间: $(uptime -p)"
        echo "  负载: $(uptime | awk -F'load average:' '{print $2}')"
        echo ""
        
        echo -e "${YELLOW}【CPU 使用】${NC}"
        top -bn1 | head -5 | tail -4 | awk '{printf "  %s %s %s%%\n", $2, $4, $9}'
        echo ""
        
        echo -e "${YELLOW}【内存使用】${NC}"
        free -h | awk 'NR==2 {printf "  总计: %s | 已用: %s | 空闲: %s | 使用率: %.1f%%\n", $2, $3, $4, ($3/$2)*100}'
        echo ""
        
        echo -e "${YELLOW}【磁盘使用】${NC}"
        df -h | grep -E '^/dev/' | awk '{printf "  %s: %s / %s (%.0f%%)\n", $1, $3, $2, $5+0}'
        echo ""
        
        echo -e "${YELLOW}【网络连接】${NC}"
        echo "  SSH 连接数: $(who | wc -l)"
        echo "  网络连接数: $(netstat -an 2>/dev/null | grep ESTABLISHED | wc -l)"
        echo ""
        
        echo -e "${YELLOW}【Top 5 进程（CPU）】${NC}"
        ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "  %-10s %6s%% %6s%% %s\n", $11, $3, $4, $1}'
        echo ""
        
        sleep 3
    done
}

monitor_start() {
    check_root
    systemctl start prometheus node_exporter
    systemctl enable prometheus node_exporter
    echo -e "${GREEN}✓ 监控服务已启动${NC}"
}

monitor_stop() {
    check_root
    systemctl stop prometheus node_exporter
    echo -e "${GREEN}✓ 监控服务已停止${NC}"
}

monitor_status() {
    echo -e "${BLUE}监控服务状态：${NC}"
    systemctl status prometheus --no-pager | grep -E "Active:|● |Main PID"
    echo ""
    systemctl status node_exporter --no-pager | grep -E "Active:|● |Main PID"
    echo ""
    echo "访问地址："
    echo "  Prometheus: http://your_server_ip:9090"
    echo "  Node Exporter: http://your_server_ip:9100"
}

# SSL 证书
install_certbot() {
    check_root
    echo -e "${BLUE}正在安装 Certbot...${NC}"
    dnf install -y epel-release
    dnf install -y certbot python3-certbot-nginx python3-certbot-apache
    echo -e "${GREEN}✓ Certbot 安装完成${NC}"
}

ssl_cert() {
    local domain=$1
    check_root
    
    if [ -z "$domain" ]; then
        echo -e "${RED}错误：请提供域名${NC}"
        echo "使用方法: $0 ssl_cert example.com"
        exit 1
    fi
    
    echo -e "${BLUE}正在为 ${domain} 申请 SSL 证书...${NC}"
    install_certbot
    
    if command -v nginx &>/dev/null; then
        certbot --nginx -d $domain --non-interactive --agree-tos -m admin@$domain
    elif command -v httpd &>/dev/null; then
        certbot --apache -d $domain --non-interactive --agree-tos -m admin@$domain
    else
        certbot certonly --standalone -d $domain --non-interactive --agree-tos -m admin@$domain
    fi
    
    echo -e "${GREEN}✓ SSL 证书申请完成${NC}"
}

ssl_renew() {
    check_root
    echo -e "${BLUE}续期所有 SSL 证书...${NC}"
    certbot renew --quiet
    systemctl restart nginx httpd 2>/dev/null || true
    echo -e "${GREEN}✓ 证书续期完成${NC}"
}

ssl_list() {
    echo -e "${BLUE}已申请的 SSL 证书：${NC}"
    if [ -d /etc/letsencrypt/live ]; then
        ls -1 /etc/letsencrypt/live/
    else
        echo "暂无证书"
    fi
}

ssl_delete() {
    local domain=$1
    check_root
    
    if [ -z "$domain" ]; then
        echo -e "${RED}错误：请提供域名${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}删除证书：${domain}${NC}"
    certbot delete --cert-name $domain
    echo -e "${GREEN}✓ 证书已删除${NC}"
}

# 备份管理
backup_files() {
    check_root
    echo -e "${BLUE}备份重要文件...${NC}"
    
    local BACKUP_DIR="/var/backups"
    local FILES_BACKUP_DIR="$BACKUP_DIR/files"
    mkdir -p $FILES_BACKUP_DIR
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$FILES_BACKUP_DIR/configs_${timestamp}.tar.gz"
    
    tar czf $backup_file \
        /etc/nginx \
        /etc/httpd \
        /etc/mysql \
        /etc/mariadb \
        /etc/php* \
        /etc/redis \
        /var/www/html 2>/dev/null || true
    
    echo -e "${GREEN}✓ 配置文件已备份到：$backup_file${NC}"
    find $FILES_BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
}

backup_db() {
    check_root
    echo -e "${BLUE}备份所有数据库...${NC}"
    
    local BACKUP_DIR="/var/backups"
    local DB_BACKUP_DIR="$BACKUP_DIR/databases"
    mkdir -p $DB_BACKUP_DIR
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    if command -v mysql &>/dev/null; then
        echo "备份 MySQL/MariaDB..."
        mkdir -p $DB_BACKUP_DIR/mysql
        mysqldump --all-databases --single-transaction --quick --lock-tables=false \
            > $DB_BACKUP_DIR/mysql/all_databases_${timestamp}.sql 2>/dev/null || \
        mysqldump --all-databases --single-transaction --quick --lock-tables=false \
            > $DB_BACKUP_DIR/mysql/all_databases_${timestamp}.sql
        
        gzip $DB_BACKUP_DIR/mysql/all_databases_${timestamp}.sql
        echo -e "${GREEN}✓ MySQL/MariaDB 已备份${NC}"
    fi
    
    if command -v pg_dumpall &>/dev/null; then
        echo "备份 PostgreSQL..."
        mkdir -p $DB_BACKUP_DIR/postgresql
        sudo -u postgres pg_dumpall > $DB_BACKUP_DIR/postgresql/all_postgres_${timestamp}.sql
        gzip $DB_BACKUP_DIR/postgresql/all_postgres_${timestamp}.sql
        echo -e "${GREEN}✓ PostgreSQL 已备份${NC}"
    fi
    
    find $DB_BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
}

backup_all() {
    check_root
    echo -e "${PURPLE}开始完整备份...${NC}"
    backup_files
    backup_db
    echo -e "${GREEN}✓ 完整备份完成！${NC}"
}

backup_auto() {
    check_root
    echo -e "${BLUE}配置自动备份...${NC}"
    
    cat > /usr/local/bin/auto-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups"
DB_BACKUP_DIR="$BACKUP_DIR/databases"
mkdir -p $DB_BACKUP_DIR/mysql
timestamp=$(date +%Y%m%d_%H%M%S)
if command -v mysqldump &>/dev/null; then
    mysqldump --all-databases --single-transaction --quick --lock-tables=false > $DB_BACKUP_DIR/mysql/all_databases_${timestamp}.sql 2>/dev/null
    gzip $DB_BACKUP_DIR/mysql/all_databases_${timestamp}.sql
fi
find $DB_BACKUP_DIR -name "*.sql.gz" -mtime +30 -delete
EOF
    
    chmod +x /usr/local/bin/auto-backup.sh
    echo "0 2 * * * /usr/local/bin/auto-backup.sh >> /var/log/backup.log 2>&1" >> /var/spool/cron/root
    systemctl restart crond
    
    echo -e "${GREEN}✓ 自动备份已配置（每天凌晨 2:00）${NC}"
}

# 系统清理
cleanup_check() {
    echo -e "${BLUE}检查可清理空间：${NC}"
    echo ""
    
    echo -e "${YELLOW}【旧内核】${NC}"
    current_kernel=$(uname -r)
    old_kernels=$(rpm -qa | grep kernel | grep -v $current_kernel | wc -l)
    echo "  当前内核: $current_kernel"
    echo "  旧内核数量: $old_kernels 个"
    
    echo ""
    echo -e "${YELLOW}【日志文件】${NC}"
    log_size=$(du -sh /var/log 2>/dev/null | awk '{print $1}')
    echo "  日志目录大小: $log_size"
    
    echo ""
    echo -e "${YELLOW}【缓存文件】${NC}"
    dnf_cache=$(du -sh /var/cache/dnf 2>/dev/null | awk '{print $1}')
    echo "  DNF 缓存: $dnf_cache"
}

cleanup_kernel() {
    check_root
    echo -e "${BLUE}清理旧内核...${NC}"
    
    current_kernel=$(uname -r)
    old_kernels=$(rpm -qa | grep kernel | grep -v $current_kernel)
    
    if [ -z "$old_kernels" ]; then
        echo "没有旧内核需要清理"
        return
    fi
    
    read -p "确认删除旧内核? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "已取消"
        return
    fi
    
    rpm -e $old_kernels
    echo -e "${GREEN}✓ 旧内核清理完成${NC}"
}

cleanup_log() {
    check_root
    echo -e "${BLUE}清理日志文件...${NC}"
    
    find /var/log -name "*.gz" -mtime +7 -delete 2>/dev/null || true
    journalctl --vacuum-size=500M 2>/dev/null || true
    
    echo -e "${GREEN}✓ 日志清理完成${NC}"
}

cleanup_cache() {
    check_root
    echo -e "${BLUE}清理缓存...${NC}"
    
    dnf clean all
    pip3 cache purge 2>/dev/null || true
    npm cache clean --force 2>/dev/null || true
    rm -rf /tmp/* 2>/dev/null || true
    rm -rf /var/tmp/* 2>/dev/null || true
    
    echo -e "${GREEN}✓ 缓存清理完成${NC}"
}

cleanup_all() {
    check_root
    echo -e "${PURPLE}开始完整系统清理...${NC}"
    cleanup_kernel
    cleanup_log
    cleanup_cache
    echo -e "${GREEN}✓ 系统清理完成！${NC}"
}

# 安装 LNMP
install_lnmp() {
    echo -e "${PURPLE}开始安装 LNMP 栈...${NC}"
    install_nginx
    install_mariadb
    install_php 7.4
    configure_firewall
    echo ""
    echo -e "${GREEN}✓ LNMP 栈安装完成！${NC}"
}

# 安装 LAMP
install_lamp() {
    echo -e "${PURPLE}开始安装 LAMP 栈...${NC}"
    install_apache
    install_mariadb
    install_php 7.4
    echo ""
    echo -e "${GREEN}✓ LAMP 栈安装完成！${NC}"
}

# 安装所有基础服务
install_all() {
    echo -e "${PURPLE}开始安装所有基础服务...${NC}"
    install_dev_tools
    install_common_tools
    install_nginx
    install_mariadb
    install_php 7.4
    install_docker
    configure_firewall
    tune_kernel
    echo ""
    echo -e "${GREEN}✓ 所有基础服务安装完成！${NC}"
}

# 安装所有运维工具
install_ops_all() {
    echo -e "${PURPLE}开始安装所有运维工具...${NC}"
    install_monitor
    backup_auto
    install_certbot
    tune_kernel
    configure_firewall
    echo ""
    echo -e "${GREEN}✓ 所有运维工具安装完成！${NC}"
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

check_network() {
    echo -e "${BLUE}网络连接检查...${NC}"
    if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ 网络连接正常${NC}"
    else
        echo -e "  ${RED}✗ 网络连接失败${NC}"
    fi
}

backup_file() {
    local file=$1
    if [ -z "$file" ]; then
        echo -e "${RED}错误：请指定要备份的文件${NC}"
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
        monitor_install)
            install_monitor
            ;;
        sysmon)
            sysmon
            ;;
        monitor_start)
            monitor_start
            ;;
        monitor_stop)
            monitor_stop
            ;;
        monitor_status)
            monitor_status
            ;;
        ssl_cert)
            ssl_cert "$@"
            ;;
        ssl_renew)
            ssl_renew
            ;;
        ssl_list)
            ssl_list
            ;;
        ssl_delete)
            ssl_delete "$@"
            ;;
        backup_files)
            backup_files
            ;;
        backup_db)
            backup_db
            ;;
        backup_all)
            backup_all
            ;;
        backup_auto)
            backup_auto
            ;;
        cleanup_check)
            cleanup_check
            ;;
        cleanup_kernel)
            cleanup_kernel
            ;;
        cleanup_log)
            cleanup_log
            ;;
        cleanup_cache)
            cleanup_cache
            ;;
        cleanup_all)
            cleanup_all
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
        ops_all)
            check_root "$@"
            install_ops_all
            ;;
        *)
            echo -e "${RED}错误：未知命令 '$command'${NC}"
            echo "运行 '$0' 查看帮助"
            exit 1
            ;;
    esac
}

main "$@"
