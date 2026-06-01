#!/bin/bash
# 描述：安装 ClickHouse 数据库

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_clickhouse() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 ClickHouse...${NC}"
    
    case $pkg_manager in
        dnf|yum)
            yum install -y yum-utils
            yum-config-manager --add-repo https://packages.clickhouse.com/rpm/clickhouse.repo
            yum install -y clickhouse-server clickhouse-client
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y apt-transport-https ca-certificates dirmngr
            GNUPGHOME=$(mktemp -d)
            gpg --no-default-keyring --keyring $GNUPGHOME/trustedkeys.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 8919F6BD2B48D754
            echo "deb https://packages.clickhouse.com/deb stable main" | tee /etc/apt/sources.list.d/clickhouse.list
            apt update
            apt install -y clickhouse-server clickhouse-client
            rm -rf $GNUPGHOME
            ;;
    esac
    
    configure_firewall 8123
    start_service clickhouse-server
    
    print_success "ClickHouse 安装完成"
    echo ""
    echo "管理命令："
    echo "  clickhouse-client"
    echo "  systemctl start clickhouse-server"
    echo "  systemctl status clickhouse-server"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_clickhouse
fi