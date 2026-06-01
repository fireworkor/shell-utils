#!/bin/bash
# 描述：安装 Prometheus 监控系统

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_monitor() {
    check_root
    check_os
    
    echo -e "${BLUE}正在安装 Prometheus 监控系统...${NC}"
    
    useradd --no-create-home --shell /bin/false prometheus 2>/dev/null || true
    
    cd /tmp
    wget -q https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
    tar xzf prometheus-2.45.0.linux-amd64.tar.gz
    mv prometheus-2.45.0.linux-amd64 /opt/prometheus
    ln -sf /opt/prometheus /usr/local/bin/prometheus
    
    mkdir -p /etc/prometheus /var/lib/prometheus
    cp /opt/prometheus/prometheus.yml /etc/prometheus/
    chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus /opt/prometheus
    
    cat > /etc/systemd/system/prometheus.service << 'EOF'
[Unit]
Description=Prometheus Monitoring
After=network.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus/
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    
    echo -e "${YELLOW}安装 Node Exporter...${NC}"
    cd /tmp
    wget -q https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
    tar xzf node_exporter-1.6.1.linux-amd64.tar.gz
    mv node_exporter-1.6.1.linux-amd64 /opt/node_exporter
    ln -sf /opt/node_exporter/node_exporter /usr/local/bin/node_exporter
    
    cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
After=network.target

[Service]
ExecStart=/usr/local/bin/node_exporter/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl start node_exporter && systemctl enable node_exporter
    systemctl start prometheus && systemctl enable prometheus
    
    cd ~
    rm -rf /tmp/prometheus* /tmp/node_exporter*
    
    configure_firewall 9090
    configure_firewall 9100
    
    print_success "监控系统安装完成"
    echo ""
    echo "访问地址："
    echo "  Prometheus: http://your_server_ip:9090"
    echo "  Node Exporter: http://your_server_ip:9100"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_monitor
fi
