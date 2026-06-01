#!/bin/bash
# 描述：安装开发工具

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_dev_tools() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装开发工具...${NC}"
    
    case $pkg_manager in
        dnf|yum)
            yum groupinstall -y "Development Tools"
            yum install -y gcc gcc-c++ make cmake autoconf automake libtool \
                pkg-config wget curl git vim nano htop net-tools \
                bind-utils yum-utils device-mapper-persistent-data \
                lvm2 ca-certificates gnupg
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y build-essential gcc g++ make cmake autoconf automake \
                libtool pkg-config wget curl git vim nano htop net-tools \
                dnsutils software-properties-common ca-certificates gnupg
            ;;
    esac
    
    print_success "开发工具安装完成"
    echo ""
    echo "已安装："
    echo "  GCC: $(gcc --version | head -1)"
    echo "  Git: $(git --version)"
    echo "  Python: $(python3 --version)"
    echo "  Make: $(make --version | head -1)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_dev_tools
fi
