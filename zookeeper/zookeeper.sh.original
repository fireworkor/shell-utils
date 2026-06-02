#!/bin/bash
# 描述：安装 Zookeeper

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_zookeeper() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 Zookeeper...${NC}"
    
    case $pkg_manager in
        dnf|yum)
            yum install -y wget tar java-11-openjdk
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y wget tar openjdk-11-jre
            ;;
    esac
    
    cd /tmp
    wget -q https://dlcdn.apache.org/zookeeper/zookeeper-3.9.1/apache-zookeeper-3.9.1-bin.tar.gz
    tar xzf apache-zookeeper-3.9.1-bin.tar.gz
    mkdir -p /opt/zookeeper
    mv apache-zookeeper-3.9.1-bin/* /opt/zookeeper/
    rm -rf apache-zookeeper-3.9.1-bin*
    
    mkdir -p /opt/zookeeper/data /opt/zookeeper/logs
    
    cp /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg
    sed -i 's|dataDir=/tmp/zookeeper|dataDir=/opt/zookeeper/data|' /opt/zookeeper/conf/zoo.cfg
    echo "dataLogDir=/opt/zookeeper/logs" >> /opt/zookeeper/conf/zoo.cfg
    
    cat > /etc/systemd/system/zookeeper.service << 'EOF'
[Unit]
Description=Apache Zookeeper
After=network.target

[Service]
Type=simple
User=root
ExecStart=/opt/zookeeper/bin/zkServer.sh start-foreground
ExecStop=/opt/zookeeper/bin/zkServer.sh stop
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    configure_firewall 2181
    start_service zookeeper
    
    print_success "Zookeeper 安装完成"
    echo ""
    echo "管理命令："
    echo "  /opt/zookeeper/bin/zkServer.sh status"
    echo "  /opt/zookeeper/bin/zkCli.sh"
    echo "  systemctl start zookeeper"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_zookeeper
fi