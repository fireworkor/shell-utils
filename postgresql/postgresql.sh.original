#!/bin/bash
# 描述：安装 PostgreSQL 数据库

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_postgresql() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 PostgreSQL...${NC}"
    
    case $pkg_manager in
        dnf)
            dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
            dnf install -y postgresql15-server postgresql15-contrib
            /usr/pgsql-15/bin/postgresql-15-setup initdb
            start_service postgresql-15
            ;;
        yum)
            yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
            yum install -y postgresql15-server postgresql15-contrib
            /usr/pgsql-15/bin/postgresql-15-setup initdb
            start_service postgresql-15
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
            wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
            apt update
            apt install -y postgresql-15
            start_service postgresql
            ;;
    esac
    
    configure_firewall 5432
    
    print_success "PostgreSQL 安装完成"
    echo ""
    echo "管理命令："
    echo "  sudo -u postgres psql"
    echo "  systemctl start postgresql-15/postgresql"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_postgresql
fi
