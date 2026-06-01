#!/bin/bash
# 描述：安装 Go 语言（支持多版本）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_go() {
    local version=${1:-1.22}
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 Go $version...${NC}"
    
    case $pkg_manager in
        dnf|yum)
            yum install -y wget tar
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y wget tar
            ;;
    esac
    
    cd /tmp
    wget -q https://dl.google.com/go/go${version}.linux-amd64.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go${version}.linux-amd64.tar.gz
    rm -f go${version}.linux-amd64.tar.gz
    
    if ! grep -q "export PATH=\$PATH:/usr/local/go/bin" /etc/profile; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    fi
    
    print_success "Go $version 安装完成"
    echo ""
    echo "Go 版本: $(/usr/local/go/bin/go version)"
    echo "配置已添加到 /etc/profile，重启终端或执行 source /etc/profile 使配置生效"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_go "$@"
fi