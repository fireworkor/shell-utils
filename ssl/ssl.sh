#!/bin/bash
# 描述：申请 Let's Encrypt SSL 证书

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_ssl() {
    local domain=$1
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    if [ -z "$domain" ]; then
        print_error "请提供域名"
        echo "使用方法: $0 ssl example.com"
        exit 1
    fi
    
    echo -e "${BLUE}正在安装 Certbot...${NC}"
    
    case $pkg_manager in
        dnf|yum)
            yum install -y epel-release
            yum install -y certbot python3-certbot-nginx python3-certbot-apache
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y certbot python3-certbot-nginx python3-certbot-apache
            ;;
    esac
    
    echo -e "${BLUE}正在为 $domain 申请 SSL 证书...${NC}"
    
    if command -v nginx &>/dev/null; then
        certbot --nginx -d $domain --non-interactive --agree-tos -m admin@$domain
    elif command -v httpd &>/dev/null; then
        certbot --apache -d $domain --non-interactive --agree-tos -m admin@$domain
    elif command -v apache2 &>/dev/null; then
        certbot --apache -d $domain --non-interactive --agree-tos -m admin@$domain
    else
        certbot certonly --standalone -d $domain --non-interactive --agree-tos -m admin@$domain
    fi
    
    print_success "SSL 证书申请完成"
    echo ""
    echo "证书位置："
    echo "  证书: /etc/letsencrypt/live/$domain/fullchain.pem"
    echo "  密钥: /etc/letsencrypt/live/$domain/privkey.pem"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_ssl "$@"
fi
