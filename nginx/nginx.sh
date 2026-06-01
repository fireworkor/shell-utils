#!/bin/bash
# 描述：安装 Nginx Web 服务器

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载通用函数
if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_nginx() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 Nginx...${NC}"
    
    case $pkg_manager in
        dnf)
            cat > /etc/yum.repos.d/nginx.repo << 'EOF'
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
modulehotfixes=true
EOF
            dnf install -y nginx
            ;;
        yum)
            cat > /etc/yum.repos.d/nginx.repo << 'EOF'
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
EOF
            yum install -y nginx
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y nginx
            ;;
    esac
    
    configure_firewall 80
    configure_firewall 443
    start_service nginx
    
    print_success "Nginx 安装完成"
    echo ""
    echo "管理命令："
    echo "  systemctl start nginx"
    echo "  systemctl stop nginx"
    echo "  systemctl restart nginx"
    echo "  systemctl status nginx"
}

# 直接运行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_nginx
fi
