#!/bin/bash
# 描述：安装 Elasticsearch 搜索引擎

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_elasticsearch() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 Elasticsearch...${NC}"
    
    case $pkg_manager in
        dnf|yum)
            rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
            cat > /etc/yum.repos.d/elasticsearch.repo << 'EOF'
[elasticsearch]
name=Elasticsearch repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
            yum install -y elasticsearch
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
            echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-8.x.list
            apt update
            apt install -y elasticsearch
            ;;
    esac
    
    mkdir -p /var/lib/elasticsearch /var/log/elasticsearch
    chown elasticsearch:elasticsearch /var/lib/elasticsearch /var/log/elasticsearch
    
    sed -i 's/#network.host: 192.168.0.1/network.host: 0.0.0.0/' /etc/elasticsearch/elasticsearch.yml
    sed -i 's/#discovery.type: single-node/discovery.type: single-node/' /etc/elasticsearch/elasticsearch.yml
    
    configure_firewall 9200
    start_service elasticsearch
    
    print_success "Elasticsearch 安装完成"
    echo ""
    echo "测试命令："
    echo "  curl http://localhost:9200"
    echo "管理命令："
    echo "  systemctl start elasticsearch"
    echo "  systemctl status elasticsearch"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_elasticsearch
fi