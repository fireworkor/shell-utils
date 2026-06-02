#!/bin/bash
# 描述：安装 Redis 缓存

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_redis() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 Redis...${NC}"
    
    case $pkg_manager in
        dnf|yum)
            yum install -y redis
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y redis-server
            ;;
    esac
    
    configure_firewall 6379
    start_service redis
    
    print_success "Redis 安装完成"
    echo ""
    echo "管理命令："
    echo "  redis-cli"
    echo "  systemctl start/stop/restart redis"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_redis
fi
