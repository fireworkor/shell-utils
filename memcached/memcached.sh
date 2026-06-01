#!/bin/bash
# 描述：安装 Memcached 缓存

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_memcached() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 Memcached...${NC}"
    
    case $pkg_manager in
        dnf|yum)
            yum install -y memcached libmemcached
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y memcached libmemcached-tools
            ;;
    esac
    
    sed -i 's/^-l 127.0.0.1$/-l 0.0.0.0/' /etc/memcached.conf 2>/dev/null || true
    
    configure_firewall 11211
    start_service memcached
    
    print_success "Memcached 安装完成"
    echo ""
    echo "Memcached 版本: $(memcached -V 2>/dev/null | head -1)"
    echo "管理命令："
    echo "  memcached-tool localhost:11211 stats"
    echo "  systemctl start memcached"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_memcached
fi