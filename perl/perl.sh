#!/bin/bash
# 描述：安装 Perl（支持多版本）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_perl() {
    local version=${1:-5.36}
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 Perl $version...${NC}"
    
    case $pkg_manager in
        dnf|yum)
            yum install -y gcc make openssl-devel zlib-devel
            cd /tmp
            wget -q https://www.cpan.org/src/5.0/perl-${version}.tar.gz
            tar xzf perl-${version}.tar.gz
            cd perl-${version}
            ./Configure -des > /dev/null 2>&1
            make -j$(nproc) > /dev/null 2>&1
            make install
            cd ~
            rm -rf /tmp/perl-${version}*
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y perl perl-doc build-essential
            ;;
    esac
    
    print_success "Perl $version 安装完成"
    echo ""
    echo "Perl 版本: $(perl --version | head -2)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_perl "$@"
fi