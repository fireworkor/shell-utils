#!/bin/bash
# 描述：安装 Apache Web 服务器

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_apache() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 Apache...${NC}"
    
    case $pkg_manager in
        dnf|yum)
            yum install -y httpd
            start_service httpd
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y apache2
            case $OS in
                ubuntu|debian)
                    start_service apache2
                    ;;
            esac
            ;;
    esac
    
    configure_firewall 80
    configure_firewall 443
    
    print_success "Apache 安装完成"
    echo ""
    echo "管理命令："
    echo "  systemctl start httpd/apache2"
    echo "  systemctl stop httpd/apache2"
    echo "  systemctl restart httpd/apache2"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_apache
fi
