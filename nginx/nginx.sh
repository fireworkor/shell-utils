#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

install_nginx() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    echo "检测到包管理器: $pkg_manager"
    case $pkg_manager in
        dnf|yum)
            $pkg_manager install -y nginx
            ;;
        apt)
            apt update && apt install -y nginx
            ;;
        *)
            echo "不支持的包管理器: $pkg_manager"
            exit 1
            ;;
    esac
    start_service nginx
    configure_firewall http 80
    configure_firewall https 443
    print_success "Nginx 安装完成"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_nginx
fi
