#!/bin/bash
# 描述：安装 Ruby（支持多版本）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_ruby() {
    local version=${1:-3.2}
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 Ruby $version...${NC}"
    
    case $pkg_manager in
        dnf|yum)
            yum install -y gcc make openssl-devel readline-devel zlib-devel
            cd /tmp
            wget -q https://cache.ruby-lang.org/pub/ruby/${version%.*}/ruby-${version}.0.tar.gz
            tar xzf ruby-${version}.0.tar.gz
            cd ruby-${version}.0
            ./configure > /dev/null 2>&1
            make -j$(nproc) > /dev/null 2>&1
            make install
            cd ~
            rm -rf /tmp/ruby-${version}*
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y ruby-full build-essential
            ;;
    esac
    
    print_success "Ruby $version 安装完成"
    echo ""
    echo "Ruby 版本: $(ruby --version)"
    echo "Gem 版本: $(gem --version)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_ruby "$@"
fi