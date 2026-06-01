#!/bin/bash
# 描述：安装 Cassandra 数据库

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_cassandra() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 Cassandra...${NC}"
    
    case $pkg_manager in
        dnf|yum)
            yum install -y wget java-11-openjdk
            wget -q https://dlcdn.apache.org/cassandra/4.1.4/apache-cassandra-4.1.4-bin.tar.gz
            tar xzf apache-cassandra-4.1.4-bin.tar.gz
            mv apache-cassandra-4.1.4 /opt/cassandra
            rm -f apache-cassandra-4.1.4-bin.tar.gz
            
            mkdir -p /var/lib/cassandra /var/log/cassandra
            
            cat > /etc/systemd/system/cassandra.service << 'EOF'
[Unit]
Description=Apache Cassandra
After=network.target

[Service]
Type=simple
User=root
ExecStart=/opt/cassandra/bin/cassandra -f
ExecStop=/opt/cassandra/bin/nodetool stop
Restart=always
Environment="JAVA_HOME=/usr/lib/jvm/java-11-openjdk"

[Install]
WantedBy=multi-user.target
EOF
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y wget openjdk-11-jre
            wget -q https://dlcdn.apache.org/cassandra/4.1.4/apache-cassandra-4.1.4-bin.tar.gz
            tar xzf apache-cassandra-4.1.4-bin.tar.gz
            mv apache-cassandra-4.1.4 /opt/cassandra
            rm -f apache-cassandra-4.1.4-bin.tar.gz
            
            mkdir -p /var/lib/cassandra /var/log/cassandra
            
            cat > /etc/systemd/system/cassandra.service << 'EOF'
[Unit]
Description=Apache Cassandra
After=network.target

[Service]
Type=simple
User=root
ExecStart=/opt/cassandra/bin/cassandra -f
ExecStop=/opt/cassandra/bin/nodetool stop
Restart=always
Environment="JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"

[Install]
WantedBy=multi-user.target
EOF
            ;;
    esac
    
    systemctl daemon-reload
    configure_firewall 9042
    start_service cassandra
    
    print_success "Cassandra 安装完成"
    echo ""
    echo "管理命令："
    echo "  /opt/cassandra/bin/cqlsh"
    echo "  systemctl start cassandra"
    echo "  systemctl status cassandra"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_cassandra
fi