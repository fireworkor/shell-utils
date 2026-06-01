#!/bin/bash
# 描述：安装 InfluxDB 时序数据库

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_influxdb() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 InfluxDB...${NC}"
    
    case $pkg_manager in
        dnf|yum)
            cat > /etc/yum.repos.d/influxdb.repo << 'EOF'
[influxdb]
name = InfluxDB Repository - RHEL $releasever
baseurl = https://repos.influxdata.com/rhel/$releasever/$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdata-archive_compat.key
EOF
            yum install -y influxdb2 influxdb2-cli
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            wget -q https://repos.influxdata.com/influxdata-archive_compat.key
            echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | gpg --dearmor | tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
            echo "deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/influxdata.list
            apt update
            apt install -y influxdb2 influxdb2-cli
            ;;
    esac
    
    configure_firewall 8086
    start_service influxdb
    
    print_success "InfluxDB 安装完成"
    echo ""
    echo "初始化命令："
    echo "  influx setup"
    echo "管理命令："
    echo "  systemctl start influxdb"
    echo "  influx config list"
    echo "  influx bucket list"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_influxdb
fi