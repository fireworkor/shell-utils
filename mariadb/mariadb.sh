#!/bin/bash
# 描述：安装 MariaDB 数据库

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_mariadb() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 MariaDB...${NC}"
    
    case $pkg_manager in
        dnf)
            cat > /etc/yum.repos.d/mariadb.repo << 'EOF'
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.5/centos8-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
            dnf install -y MariaDB-server MariaDB-client MariaDB-common
            ;;
        yum)
            cat > /etc/yum.repos.d/mariadb.repo << 'EOF'
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.5/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
            yum install -y MariaDB-server MariaDB-client MariaDB-common
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y mariadb-server mariadb-client
            ;;
    esac
    
    configure_firewall 3306
    start_service mariadb
    
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
    
    print_success "MariaDB 安装完成"
    echo ""
    echo "管理命令："
    echo "  mysql -u root -p"
    echo "  systemctl start mariadb"
    echo "  systemctl status mariadb"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_mariadb
fi
