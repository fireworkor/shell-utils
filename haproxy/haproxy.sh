#!/bin/bash
# 描述：部署 HAProxy 负载均衡器

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

HAPROXY_PORT=${1:-80}
HTTPS_PORT=${2:-443}
STATS_PORT=${3:-8404}

install_haproxy() {
    print_step 1 4 "安装 HAProxy"
    
    local pkg_manager=$(get_pkg_manager)
    case $pkg_manager in
        dnf|yum)
            yum install -y haproxy
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y haproxy
            ;;
    esac
    
    print_success "HAProxy 安装完成"
}

config_haproxy() {
    print_step 2 4 "配置 HAProxy"
    
    cat > /etc/haproxy/haproxy.cfg << 'EOF'
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon
    maxconn 4096

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000ms
    timeout client  50000ms
    timeout server  50000ms
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

# HAProxy 统计页面
listen stats
    bind *:STATS_PORT
    mode http
    stats enable
    stats uri /stats
    stats refresh 30s
    stats auth admin:admin

# HTTP 负载均衡
frontend http_front
    bind *:HAPROXY_PORT
    mode http
    default_backend web_backend

backend web_backend
    mode http
    balance roundrobin
    option httpchk GET /health
    http-check expect status 200
    server web1 127.0.0.1:8080 check inter 2000 rise 2 fall 3
    server web2 127.0.0.1:8081 check inter 2000 rise 2 fall 3
    server web3 127.0.0.1:8082 check inter 2000 rise 2 fall 3

# HTTPS 负载均衡 (需要证书)
# frontend https_front
#     bind *:HTTPS_PORT ssl crt /etc/ssl/certs/example.com.pem
#     mode http
#     default_backend web_backend

# TCP 负载均衡 (用于 MySQL 等)
# listen mysql_cluster
#     bind *:3306
#     mode tcp
#     balance source
#     option tcp-check
#     server mysql1 127.0.0.1:3306 check
#     server mysql2 127.0.0.1:3307 check backup
EOF

    sed -i "s/STATS_PORT/$STATS_PORT/g" /etc/haproxy/haproxy.cfg
    sed -i "s/HAPROXY_PORT/$HAPROXY_PORT/g" /etc/haproxy/haproxy.cfg
    
    print_success "HAProxy 配置完成"
    print_info "HTTP 端口: $HAPROXY_PORT"
    print_info "HTTPS 端口: $HTTPS_PORT"
    print_info "统计页面: http://localhost:$STATS_PORT/stats"
}

start_haproxy() {
    print_step 3 4 "启动 HAProxy"
    
    systemctl enable haproxy
    systemctl start haproxy
    
    print_success "HAProxy 启动完成"
}

show_status() {
    print_step 4 4 "HAProxy 状态"
    
    echo ""
    echo -e "${YELLOW}服务状态:${NC}"
    systemctl status haproxy --no-pager
    
    echo ""
    echo -e "${YELLOW}统计页面:${NC}"
    echo "  http://localhost:$STATS_PORT/stats"
    echo "  用户名: admin"
    echo "  密码: admin"
    
    echo ""
    echo -e "${YELLOW}后端服务器:${NC}"
    ss -tlnp | grep -E "$HAPROXY_PORT|$HTTPS_PORT|$STATS_PORT"
}

show_usage() {
    cat << EOF
${GREEN}HAProxy 负载均衡部署工具${NC}

${YELLOW}用法:${NC}
  $0 [HTTP端口] [HTTPS端口] [统计页面端口]

${YELLOW}示例:${NC}
  $0                  # 默认端口
  $0 80 443 8404      # 自定义端口
  $0 status           # 查看状态
  $0 stop             # 停止服务

${YELLOW}配置后端服务器:${NC}
  vim /etc/haproxy/haproxy.cfg
  # 修改 backend web_backend 下的 server 配置

${YELLOW}命令:${NC}
  status    - 查看状态
  stop      - 停止服务
EOF
}

main() {
    local command=$1
    
    check_root
    
    case $command in
        status)
            print_header "HAProxy 状态"
            systemctl status haproxy --no-pager
            ;;
        stop)
            print_header "停止 HAProxy"
            systemctl stop haproxy
            print_success "HAProxy 已停止"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_header "部署 HAProxy 负载均衡"
            install_haproxy
            config_haproxy
            start_haproxy
            show_status
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
