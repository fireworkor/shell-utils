#!/bin/bash
# 描述：安装 Python（支持多版本）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_python() {
    local version=${1:-3.11}
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 Python $version...${NC}"
    
    case $pkg_manager in
        dnf|yum)
            yum install -y gcc openssl-devel bzip2-devel libffi-devel zlib-devel
            cd /tmp
            wget -q https://www.python.org/ftp/python/${version}.0/Python-${version}.0.tgz
            tar xzf Python-${version}.0.tgz
            cd Python-${version}.0
            ./configure --enable-optimizations > /dev/null 2>&1
            make altinstall -j$(nproc) > /dev/null 2>&1
            cd ~
            rm -rf /tmp/Python-${version}*
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y software-properties-common
            add-apt-repository -y ppa:deadsnakes/ppa
            apt update
            apt install -y python${version} python${version}-dev python${version}-venv python3-pip
            ;;
    esac
    
    print_success "Python $version 安装完成"
    echo ""
    echo "Python 版本: $(python${version} --version 2>/dev/null || python3 --version)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_python "$@"
fi
