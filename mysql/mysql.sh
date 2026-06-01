#!/bin/bash
# 描述：安装 MySQL 数据库

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_mysql() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 MySQL...${NC}"
    
    case $pkg_manager in
        dnf)
            dnf install -y https://dev.mysql.com/get/mysql80-community-release-el8-4.noarch.rpm
            dnf install -y mysql-community-server
            ;;
        yum)
            yum install -y https://dev.mysql.com/get/mysql80-community-release-el7-4.noarch.rpm
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
    
    configure_firewall 3306
    start_service mysqld
    
    local temp_password=$(grep 'temporary password' /var/log/mysqld.log 2>/dev/null | awk '{print $NF}')
    
    print_success "MySQL 安装完成"
    if [ -n "$temp_password" ]; then
        echo ""
        echo -e "${YELLOW}临时密码: $temp_password${NC}"
        echo "请立即运行 'mysql_secure_installation' 进行安全配置"
    fi
    echo ""
    echo "管理命令："
    echo "  mysql -u root -p"
    echo "  systemctl start mysqld"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_mysql
fi
