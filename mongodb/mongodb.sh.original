#!/bin/bash
# 描述：安装 MongoDB 数据库

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_mongodb() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 MongoDB...${NC}"
    
    case $pkg_manager in
        dnf)
            cat > /etc/yum.repos.d/mongodb-org.repo << 'EOF'
[mongodb-org]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOF
            dnf install -y mongodb-org
            ;;
        yum)
            cat > /etc/yum.repos.d/mongodb-org.repo << 'EOF'
[mongodb-org]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOF
            yum install -y mongodb-org
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add -
            echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
            apt update
            apt install -y mongodb-org
            ;;
    esac
    
    mkdir -p /var/lib/mongo /var/log/mongodb
    chown mongod:mongod /var/lib/mongo /var/log/mongodb
    
    configure_firewall 27017
    start_service mongod
    
    print_success "MongoDB 安装完成"
    echo ""
    echo "管理命令："
    echo "  mongo"
    echo "  systemctl start mongod"
    echo "  systemctl status mongod"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_mongodb
fi