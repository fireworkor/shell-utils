#!/bin/bash
# 描述：安装 Kafka 消息队列

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_kafka() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 Kafka...${NC}"
    
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
    wget -q https://dlcdn.apache.org/kafka/3.6.1/kafka_2.13-3.6.1.tgz
    tar xzf kafka_2.13-3.6.1.tgz
    mkdir -p /opt/kafka
    mv kafka_2.13-3.6.1/* /opt/kafka/
    rm -rf kafka_2.13-3.6.1*
    
    mkdir -p /opt/kafka/data/zookeeper /opt/kafka/data/kafka
    
    cat > /etc/systemd/system/zookeeper.service << 'EOF'
[Unit]
Description=Apache Zookeeper
After=network.target

[Service]
Type=simple
User=root
ExecStart=/opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties
ExecStop=/opt/kafka/bin/zookeeper-server-stop.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    cat > /etc/systemd/system/kafka.service << 'EOF'
[Unit]
Description=Apache Kafka
After=zookeeper.service

[Service]
Type=simple
User=root
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    sed -i 's|dataDir=/tmp/zookeeper|dataDir=/opt/kafka/data/zookeeper|' /opt/kafka/config/zookeeper.properties
    sed -i 's|log.dirs=/tmp/kafka-logs|log.dirs=/opt/kafka/data/kafka|' /opt/kafka/config/server.properties
    
    systemctl daemon-reload
    
    configure_firewall 9092
    configure_firewall 2181
    
    start_service zookeeper
    sleep 5
    start_service kafka
    
    print_success "Kafka 安装完成"
    echo ""
    echo "管理命令："
    echo "  systemctl start kafka"
    echo "  systemctl status kafka"
    echo "  创建 topic: /opt/kafka/bin/kafka-topics.sh --create --topic test --bootstrap-server localhost:9092"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_kafka
fi