#!/bin/bash

# CentOS 8 软件部署工具集
# 提供常用的软件安装、配置和管理功能

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}错误：请使用 root 用户运行此脚本${NC}"
        echo "使用方法: sudo $0"
        exit 1
    fi
}

# 检查操作系统
check_centos8() {
    if [ ! -f /etc/centos-release ]; then
        echo -e "${RED}错误：此脚本仅支持 CentOS 8${NC}"
        exit 1
    fi
    
    if ! grep -q "CentOS Linux release 8" /etc/centos-release; then
        echo -e "${RED}错误：此脚本仅支持 CentOS Linux 8${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}检测到 CentOS 8 系统${NC}"
}

# 1. 系统更新
update_system() {
    echo -e "${BLUE}正在更新系统...${NC}"
    dnf update -y
    echo -e "${GREEN}系统更新完成${NC}"
}

# 2. 安装基础开发工具
install_dev_tools() {
    echo -e "${BLUE}正在安装基础开发工具...${NC}"
    dnf groupinstall -y "Development Tools"
    dnf install -y \
        gcc \
        gcc-c++ \
        make \
        cmake \
        autoconf \
        automake \
        libtool \
        pkg-config \
        wget \
        curl \
        git \
        vim \
        nano \
        htop \
        net-tools \
        bind-utils \
        yum-utils \
        device-mapper-persistent-data \
        lvm2 \
        ca-certificates \
        gnupg-agent
    echo -e "${GREEN}基础开发工具安装完成${NC}"
}

# 3. 安装 Nginx
install_nginx() {
    echo -e "${BLUE}正在安装 Nginx...${NC}"
    
    # 添加 Nginx 官方仓库
    cat > /etc/yum.repos.d/nginx.repo << 'EOF'
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
modulehotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
modulehotfixes=true
EOF
    
    dnf install -y nginx
    
    # 启动并设置开机启动
    systemctl start nginx
    systemctl enable nginx
    
    echo -e "${GREEN}Nginx 安装完成${NC}"
    echo "Nginx 已启动，访问 http://your_server_ip 查看默认页面"
    echo "配置文件位置: /etc/nginx/nginx.conf"
    echo "网站根目录: /usr/share/nginx/html"
}

# 4. 安装 Apache
install_apache() {
    echo -e "${BLUE}正在安装 Apache...${NC}"
    dnf install -y httpd
    
    # 启动并设置开机启动
    systemctl start httpd
    systemctl enable httpd
    
    # 配置防火墙
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
    
    echo -e "${GREEN}Apache 安装完成${NC}"
    echo "Apache 已启动，访问 http://your_server_ip 查看默认页面"
    echo "配置文件位置: /etc/httpd/conf/httpd.conf"
    echo "网站根目录: /var/www/html"
}

# 5. 安装 MySQL 8.0
install_mysql() {
    echo -e "${BLUE}正在安装 MySQL 8.0...${NC}"
    
    # 添加 MySQL Yum 仓库
    dnf install -y https://dev.mysql.com/get/mysql80-community-release-el8-4.noarch.rpm
    
    # 安装 MySQL Server
    dnf install -y mysql-community-server
    
    # 启动并设置开机启动
    systemctl start mysqld
    systemctl enable mysqld
    
    # 获取临时密码
    TEMP_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
    
    echo -e "${GREEN}MySQL 安装完成${NC}"
    echo "临时密码: $TEMP_PASSWORD"
    echo "请立即运行 'mysql_secure_installation' 进行安全配置"
    echo "配置文件位置: /etc/my.cnf"
}

# 6. 安装 PostgreSQL
install_postgresql() {
    echo -e "${BLUE}正在安装 PostgreSQL...${NC}"
    
    # 添加 PostgreSQL Yum 仓库
    dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
    
    # 安装 PostgreSQL
    dnf install -y postgresql15-server postgresql15-contrib
    
    # 初始化数据库
    /usr/pgsql-15/bin/postgresql-15-setup initdb
    
    # 启动并设置开机启动
    systemctl start postgresql-15
    systemctl enable postgresql-15
    
    echo -e "${GREEN}PostgreSQL 安装完成${NC}"
    echo "配置文件位置: /var/lib/pgsql/15/data/postgresql.conf"
    echo "数据目录: /var/lib/pgsql/15/data"
    echo ""
    echo "使用以下命令连接数据库:"
    echo "  sudo -u postgres psql"
}

# 7. 安装 PHP
install_php() {
    local php_version=${1:-7.4}
    echo -e "${BLUE}正在安装 PHP $php_version...${NC}"
    
    # 安装 EPEL 和 Remi 仓库
    dnf install -y epel-release
    dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
    
    # 启用 PHP 模块
    dnf module reset php
    dnf module enable php:remi-${php_version} -y
    
    # 安装 PHP 及常用扩展
    dnf install -y php \
        php-fpm \
        php-mysql \
        php-pdo \
        php-mbstring \
        php-xml \
        php-gd \
        php-curl \
        php-zip \
        php-intl \
        php-bcmath \
        php-json
    
    # 启动 PHP-FPM
    systemctl start php-fpm
    systemctl enable php-fpm
    
    echo -e "${GREEN}PHP $php_version 安装完成${NC}"
    echo "PHP-FPM 已启动"
    echo "配置文件位置: /etc/php.ini"
}

# 8. 安装 Python
install_python() {
    local py_version=${1:-3.11}
    echo -e "${BLUE}正在安装 Python $py_version...${NC}"
    
    # 安装 Python 编译依赖
    dnf install -y gcc openssl-devel bzip2-devel libffi-devel zlib-devel
    
    # 下载 Python 源码
    cd /tmp
    wget https://www.python.org/ftp/python/${py_version}.0/Python-${py_version}.0.tgz
    tar xzf Python-${py_version}.0.tgz
    cd Python-${py_version}.0
    
    # 编译安装
    ./configure --enable-optimizations
    make altinstall
    
    # 创建符号链接（可选）
    # ln -sf /usr/local/bin/python${py_version} /usr/bin/python3
    
    # 安装 pip
    curl https://bootstrap.pypa.io/get-pip.py | python${py_version}
    
    cd ~
    rm -rf /tmp/Python-${py_version}*
    
    echo -e "${GREEN}Python $py_version 安装完成${NC}"
    echo "使用方法: python${py_version}"
}

# 9. 安装 Node.js
install_nodejs() {
    local node_version=${1:-20}
    echo -e "${BLUE}正在安装 Node.js $node_version...${NC}"
    
    # 添加 NodeSource 仓库
    curl -fsSL https://rpm.nodesource.com/setup_${node_version}.x | bash -
    
    # 安装 Node.js
    dnf install -y nodejs
    
    # 安装 npm 和 yarn
    npm install -g npm
    npm install -g yarn
    
    echo -e "${GREEN}Node.js $node_version 安装完成${NC}"
    echo "Node.js 版本: $(node -v)"
    echo "npm 版本: $(npm -v)"
}

# 10. 安装 Docker
install_docker() {
    echo -e "${BLUE}正在安装 Docker...${NC}"
    
    # 卸载旧版本
    dnf remove -y docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate \
        docker-engine
    
    # 安装依赖
    dnf install -y \
        dnf-plugins-core \
        device-mapper-persistent-data \
        lvm2
    
    # 添加 Docker 仓库
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    # 安装 Docker
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # 启动 Docker
    systemctl start docker
    systemctl enable docker
    
    # 配置 Docker 镜像加速
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
    
    # 添加当前用户到 docker 组（如果是非 root 用户）
    # usermod -aG docker $USER
    
    echo -e "${GREEN}Docker 安装完成${NC}"
    echo "Docker 版本: $(docker --version)"
    echo "Docker Compose 版本: $(docker compose version)"
}

# 11. 安装 Redis
install_redis() {
    echo -e "${BLUE}正在安装 Redis...${NC}"
    dnf install -y redis
    
    # 启动并设置开机启动
    systemctl start redis
    systemctl enable redis
    
    echo -e "${GREEN}Redis 安装完成${NC}"
    echo "Redis 已启动"
    echo "配置文件位置: /etc/redis.conf"
    echo ""
    echo "常用命令:"
    echo "  启动: systemctl start redis"
    echo "  停止: systemctl stop redis"
    echo "  重启: systemctl restart redis"
    echo "  连接: redis-cli"
}

# 12. 安装 Memcached
install_memcached() {
    echo -e "${BLUE}正在安装 Memcached...${NC}"
    dnf install -y memcached libmemcached
    systemctl start memcached
    systemctl enable memcached
    
    echo -e "${GREEN}Memcached 安装完成${NC}"
    echo "Memcached 已启动"
    echo "配置文件位置: /etc/sysconfig/memcached"
}

# 13. 安装 GitLab
install_gitlab() {
    echo -e "${BLUE}正在安装 GitLab...${NC}"
    
    # 安装依赖
    dnf install -y curl policycoreutils python3-sh
    
    # 添加 GitLab 仓库
    curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh | bash
    
    # 安装 GitLab
    EXTERNAL_URL="http://gitlab.example.com" dnf install -y gitlab-ce
    
    # 配置 GitLab
    gitlab-ctl reconfigure
    
    echo -e "${GREEN}GitLab 安装完成${NC}"
    echo "访问地址: http://your_server_ip"
    echo "配置文件: /etc/gitlab/gitlab.rb"
    echo ""
    echo "首次访问会要求设置 root 密码"
}

# 14. 安装 Prometheus
install_prometheus() {
    echo -e "${BLUE}正在安装 Prometheus...${NC}"
    
    # 创建用户
    useradd --no-create-home --shell /bin/false prometheus
    
    # 下载 Prometheus
    cd /tmp
    wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
    tar xzf prometheus-2.45.0.linux-amd64.tar.gz
    
    # 移动文件
    mv prometheus-2.45.0.linux-amd64 /opt/prometheus
    ln -s /opt/prometheus /usr/local/bin/prometheus
    
    # 创建配置目录
    mkdir -p /etc/prometheus
    mkdir -p /var/lib/prometheus
    
    # 复制配置文件
    cp /opt/prometheus/prometheus.yml /etc/prometheus/
    
    # 设置权限
    chown -R prometheus:prometheus /etc/prometheus
    chown -R prometheus:prometheus /var/lib/prometheus
    
    # 创建 systemd 服务
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
    
    # 启动服务
    systemctl daemon-reload
    systemctl start prometheus
    systemctl enable prometheus
    
    cd ~
    rm -rf /tmp/prometheus*
    
    echo -e "${GREEN}Prometheus 安装完成${NC}"
    echo "Prometheus 已启动"
    echo "访问地址: http://your_server_ip:9090"
}

# 15. 配置防火墙
configure_firewall() {
    echo -e "${BLUE}正在配置防火墙...${NC}"
    
    # 安装 firewalld（如果没有）
    dnf install -y firewalld
    systemctl start firewalld
    systemctl enable firewalld
    
    # 开放常用端口
    local ports=(
        22/tcp    # SSH
        80/tcp    # HTTP
        443/tcp   # HTTPS
        3306/tcp  # MySQL
        5432/tcp  # PostgreSQL
        6379/tcp  # Redis
        8080/tcp  # 自定义应用
        9090/tcp  # Prometheus
    )
    
    for port in "${ports[@]}"; do
        firewall-cmd --permanent --add-port=$port
    done
    
    # 重载防火墙
    firewall-cmd --reload
    
    echo -e "${GREEN}防火墙配置完成${NC}"
    echo "已开放的端口:"
    firewall-cmd --list-ports
}

# 16. 安装 Java
install_java() {
    local java_version=${1:-11}
    echo -e "${BLUE}正在安装 OpenJDK $java_version...${NC}"
    
    dnf install -y java-${java_version}-openjdk java-${java_version}-openjdk-devel
    
    # 设置 JAVA_HOME
    export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
    echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc
    
    echo -e "${GREEN}OpenJDK $java_version 安装完成${NC}"
    echo "JAVA_HOME: $JAVA_HOME"
    echo "Java 版本: $(java -version 2>&1 | head -1)"
}

# 17. 安装 Maven
install_maven() {
    echo -e "${BLUE}正在安装 Maven...${NC}"
    
    cd /tmp
    wget https://archive.apache.org/dist/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz
    tar xzf apache-maven-3.9.5-bin.tar.gz
    mv apache-maven-3.9.5 /opt/maven
    
    # 设置环境变量
    cat > /etc/profile.d/maven.sh << 'EOF'
export MAVEN_HOME=/opt/maven
export PATH=$PATH:$MAVEN_HOME/bin
EOF
    
    chmod +x /etc/profile.d/maven.sh
    source /etc/profile.d/maven.sh
    
    cd ~
    rm -rf /tmp/apache-maven*
    
    echo -e "${GREEN}Maven 安装完成${NC}"
    echo "Maven 版本: $(mvn -version | head -1)"
}

# 18. 一键 LNMP 栈
install_lnmp() {
    echo -e "${BLUE}开始安装 LNMP 栈（Nginx + MySQL + PHP）...${NC}"
    echo ""
    
    install_nginx
    echo ""
    
    install_mysql
    echo ""
    
    install_php 7.4
    echo ""
    
    configure_firewall
    
    echo -e "${GREEN}LNMP 栈安装完成！${NC}"
    echo ""
    echo "已安装:"
    echo "  ✓ Nginx $(nginx -v 2>&1 | awk '{print $3}')"
    echo "  ✓ MySQL 8.0"
    echo "  ✓ PHP 7.4"
    echo "  ✓ 防火墙已配置"
    echo ""
    echo "下一步建议:"
    echo "  1. 配置 MySQL: mysql_secure_installation"
    echo "  2. 配置 PHP: 编辑 /etc/php.ini"
    echo "  3. 配置 Nginx: 编辑 /etc/nginx/nginx.conf"
    echo "  4. 重启服务: systemctl restart nginx php-fpm"
}

# 19. 一键 LAMP 栈
install_lamp() {
    echo -e "${BLUE}开始安装 LAMP 栈（Apache + MySQL + PHP）...${NC}"
    echo ""
    
    install_apache
    echo ""
    
    install_mysql
    echo ""
    
    install_php 7.4
    echo ""
    
    configure_firewall
    
    echo -e "${GREEN}LAMP 栈安装完成！${NC}"
    echo ""
    echo "已安装:"
    echo "  ✓ Apache $(httpd -v 2>&1 | grep version | awk '{print $3}' | tr -d '/')"
    echo "  ✓ MySQL 8.0"
    echo "  ✓ PHP 7.4"
    echo "  ✓ 防火墙已配置"
    echo ""
    echo "下一步建议:"
    echo "  1. 配置 MySQL: mysql_secure_installation"
    echo "  2. 配置 PHP: 编辑 /etc/php.ini"
    echo "  3. 重启服务: systemctl restart httpd php-fpm"
}

# 20. 常用工具一键安装
install_common_tools() {
    echo -e "${BLUE}正在安装常用工具...${NC}"
    
    # 监控工具
    dnf install -y htop nethogs iftop iotop sysstat
    
    # 网络工具
    dnf install -y telnet nmap tcpdump strace lsof
    
    # 压缩工具
    dnf install -y zip unzip bzip2 p7zip p7zip-plugins
    
    # 文本工具
    dnf install -y jq bc rsync tree
    
    # 时间同步
    dnf install -y chrony
    systemctl start chronyd
    systemctl enable chronyd
    chronyc tracking
    
    echo -e "${GREEN}常用工具安装完成${NC}"
}

# 使用说明
usage() {
    echo "=========================================="
    echo "CentOS 8 软件部署工具集"
    echo "=========================================="
    echo ""
    echo "使用前提："
    echo "  sudo $0 <命令>"
    echo ""
    echo "基础命令："
    echo "  update_system       - 更新系统"
    echo "  install_dev_tools   - 安装开发工具"
    echo "  configure_firewall  - 配置防火墙"
    echo "  install_common_tools - 安装常用工具"
    echo ""
    echo "Web 服务器："
    echo "  install_nginx       - 安装 Nginx"
    echo "  install_apache      - 安装 Apache"
    echo ""
    echo "数据库："
    echo "  install_mysql       - 安装 MySQL 8.0"
    echo "  install_postgresql  - 安装 PostgreSQL 15"
    echo "  install_redis       - 安装 Redis"
    echo "  install_memcached   - 安装 Memcached"
    echo ""
    echo "编程语言："
    echo "  install_php <版本>  - 安装 PHP (默认: 7.4)"
    echo "  install_python <版本> - 安装 Python (默认: 3.11)"
    echo "  install_nodejs <版本> - 安装 Node.js (默认: 20)"
    echo "  install_java <版本> - 安装 OpenJDK (默认: 11)"
    echo "  install_maven       - 安装 Maven"
    echo ""
    echo "容器："
    echo "  install_docker      - 安装 Docker"
    echo ""
    echo "完整解决方案："
    echo "  install_lnmp        - 一键安装 LNMP 栈"
    echo "  install_lamp        - 一键安装 LAMP 栈"
    echo ""
    echo "开发工具："
    echo "  install_gitlab      - 安装 GitLab"
    echo "  install_prometheus  - 安装 Prometheus"
    echo ""
    echo "示例："
    echo "  sudo $0 update_system"
    echo "  sudo $0 install_nginx"
    echo "  sudo $0 install_lnmp"
    echo "  sudo $0 install_php 8.0"
    echo ""
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        usage
        exit 0
    fi
    
    local command=$1
    shift
    
    case $command in
        update_system)
            check_root
            update_system
            ;;
        install_dev_tools)
            check_root
            install_dev_tools
            ;;
        configure_firewall)
            check_root
            configure_firewall
            ;;
        install_common_tools)
            check_root
            install_common_tools
            ;;
        install_nginx)
            check_root
            install_nginx
            ;;
        install_apache)
            check_root
            install_apache
            ;;
        install_mysql)
            check_root
            install_mysql
            ;;
        install_postgresql)
            check_root
            install_postgresql
            ;;
        install_php)
            check_root
            install_php "$@"
            ;;
        install_python)
            check_root
            install_python "$@"
            ;;
        install_nodejs)
            check_root
            install_nodejs "$@"
            ;;
        install_java)
            check_root
            install_java "$@"
            ;;
        install_maven)
            check_root
            install_maven
            ;;
        install_docker)
            check_root
            install_docker
            ;;
        install_redis)
            check_root
            install_redis
            ;;
        install_memcached)
            check_root
            install_memcached
            ;;
        install_gitlab)
            check_root
            install_gitlab
            ;;
        install_prometheus)
            check_root
            install_prometheus
            ;;
        install_lnmp)
            check_root
            install_lnmp
            ;;
        install_lamp)
            check_root
            install_lamp
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            echo -e "${RED}错误：未知命令 '$command'${NC}"
            echo ""
            usage
            exit 1
            ;;
    esac
}

# 如果直接运行脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
