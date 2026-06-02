#!/bin/bash
# 描述：安装 RabbitMQ 消息队列

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_rabbitmq() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 RabbitMQ...${NC}"
    
    case $pkg_manager in
        dnf)
            dnf install -y epel-release
            dnf install -y erlang
            wget -q https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.12.0/rabbitmq-server-3.12.0-1.el8.noarch.rpm
            rpm --import https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc
            dnf install -y rabbitmq-server-3.12.0-1.el8.noarch.rpm
            rm -f rabbitmq-server-3.12.0-1.el8.noarch.rpm
            ;;
        yum)
            yum install -y epel-release
            yum install -y erlang
            wget -q https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.12.0/rabbitmq-server-3.12.0-1.el7.noarch.rpm
            rpm --import https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc
            yum install -y rabbitmq-server-3.12.0-1.el7.noarch.rpm
            rm -f rabbitmq-server-3.12.0-1.el7.noarch.rpm
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y erlang-nox
            wget -q https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.12.0/rabbitmq-server_3.12.0-1_all.deb
            dpkg -i rabbitmq-server_3.12.0-1_all.deb || apt -f install -y
            rm -f rabbitmq-server_3.12.0-1_all.deb
            ;;
    esac
    
    configure_firewall 5672
    configure_firewall 15672
    
    start_service rabbitmq-server
    
    rabbitmq-plugins enable rabbitmq_management
    
    print_success "RabbitMQ 安装完成"
    echo ""
    echo "管理命令："
    echo "  rabbitmqctl status"
    echo "  systemctl start rabbitmq-server"
    echo "  管理界面: http://localhost:15672 (默认用户: guest/guest)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_rabbitmq
fi