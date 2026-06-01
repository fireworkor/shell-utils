#!/bin/bash
# 描述：部署 Keepalived 高可用

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

VIP=${1:-"192.168.1.100"}
NETMASK=${2:-"24"}
INTERFACE=${3:-"eth0"}
STATE=${4:-"MASTER"}  # MASTER 或 BACKUP
PRIORITY=${5:-"100"}   # MASTER: 100, BACKUP: 90

install_keepalived() {
    print_step 1 3 "安装 Keepalived"
    
    local pkg_manager=$(get_pkg_manager)
    case $pkg_manager in
        dnf|yum)
            yum install -y keepalived
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y keepalived
            ;;
    esac
    
    print_success "Keepalived 安装完成"
}

configure_keepalived() {
    print_step 2 3 "配置 Keepalived"
    
    if [ "$STATE" = "MASTER" ]; then
        priority=100
    else
        priority=90
    fi
    
    cat > /etc/keepalived/keepalived.conf << EOF
! Configuration File for keepalived

global_defs {
    router_id LVS_DEVEL
    script_user root
    enable_script_security
}

vrrp_script chk_nginx {
    script "/bin/bash -c 'killall -0 nginx'"
    interval 2
    weight -20
    fall 2
    rise 1
}

vrrp_instance VI_1 {
    state $STATE
    interface $INTERFACE
    virtual_router_id 51
    priority $priority
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    
    virtual_ipaddress {
        $VIP/$NETMASK dev $INTERFACE
    }
    
    track_script {
        chk_nginx
    }
    
    notify_master "/bin/bash -c 'systemctl start nginx && echo MASTER > /tmp/keepalived.state'"
    notify_backup "/bin/bash -c 'echo BACKUP > /tmp/keepalived.state'"
    notify_fault "/bin/bash -c 'echo FAULT > /tmp/keepalived.state && systemctl stop nginx'"
}
EOF
    
    print_success "Keepalived 配置完成"
    print_info "VIP: $VIP"
    print_info "State: $STATE"
    print_info "Priority: $priority"
}

start_keepalived() {
    print_step 3 3 "启动 Keepalived"
    
    systemctl enable keepalived
    systemctl start keepalived
    
    print_success "Keepalived 启动完成"
    print_info "VIP: $VIP"
    print_info "检查 VIP: ip addr show $INTERFACE | grep $VIP"
}

show_status() {
    print_header "Keepalived 状态"
    
    systemctl status keepalived --no-pager
    
    echo ""
    echo -e "${YELLOW}VIP 状态:${NC}"
    ip addr show $INTERFACE | grep -E "inet.*$VIP" || echo "VIP 未绑定"
    
    echo ""
    echo -e "${YELLOW}VRRP 状态:${NC}"
    grep -E "vrrp|BACKUP|MASTER|FAULT" /var/log/messages | tail -5
}

stop_keepalived() {
    print_header "停止 Keepalived"
    systemctl stop keepalived
    print_success "Keepalived 已停止"
}

show_usage() {
    cat << EOF
${GREEN}Keepalived 高可用部署工具${NC}

${YELLOW}用法:${NC}
  $0 [VIP] [NETMASK] [INTERFACE] [STATE] [PRIORITY]

${YELLOW}参数:${NC}
  VIP         - 虚拟IP (默认: 192.168.1.100)
  NETMASK     - 网络掩码位数 (默认: 24)
  INTERFACE   - 网卡名称 (默认: eth0)
  STATE       - MASTER 或 BACKUP (默认: MASTER)
  PRIORITY    - 优先级 (默认: 100)

${YELLOW}示例:${NC}
  # 主节点
  $0 192.168.1.100 24 eth0 MASTER
  
  # 备节点
  $0 192.168.1.100 24 eth0 BACKUP

${YELLOW}其他命令:${NC}
  $0 status    - 查看状态
  $0 stop      - 停止服务
EOF
}

main() {
    local command=$1
    
    check_root
    
    case $command in
        status)
            show_status
            ;;
        stop)
            stop_keepalived
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_header "部署 Keepalived 高可用"
            install_keepalived
            configure_keepalived
            start_keepalived
            show_status
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
