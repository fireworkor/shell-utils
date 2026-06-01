#!/bin/bash
# 描述：安装 MinIO 对象存储

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_minio() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 MinIO...${NC}"
    
    cd /tmp
    wget -q https://dl.min.io/server/minio/release/linux-amd64/minio
    chmod +x minio
    mv minio /usr/local/bin/
    
    mkdir -p /opt/minio/data /opt/minio/config
    
    cat > /etc/systemd/system/minio.service << 'EOF'
[Unit]
Description=MinIO
Documentation=https://docs.min.io
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/minio server /opt/minio/data --console-address ":9090"
Restart=always
Environment="MINIO_ROOT_USER=admin"
Environment="MINIO_ROOT_PASSWORD=minioadmin"

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    configure_firewall 9000
    configure_firewall 9090
    start_service minio
    
    print_success "MinIO 安装完成"
    echo ""
    echo "管理界面: http://localhost:9090"
    echo "默认用户名: admin"
    echo "默认密码: minioadmin"
    echo "管理命令："
    echo "  systemctl start minio"
    echo "  systemctl status minio"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_minio
fi