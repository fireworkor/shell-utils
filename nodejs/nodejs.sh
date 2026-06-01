#!/bin/bash
# 描述：安装 Node.js（支持多版本）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_nodejs() {
    local version=${1:-20}
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 Node.js $version...${NC}"
    
    case $pkg_manager in
        dnf|yum)
            curl -fsSL https://rpm.nodesource.com/setup_${version}.x | bash -
            yum install -y nodejs
            ;;
        apt)
            curl -fsSL https://deb.nodesource.com/setup_${version}.x | bash -
            apt install -y nodejs
            ;;
    esac
    
    npm install -g npm yarn
    
    print_success "Node.js $version 安装完成"
    echo ""
    echo "Node.js 版本: $(node -v)"
    echo "npm 版本: $(npm -v)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_nodejs "$@"
fi
