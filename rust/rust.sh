#!/bin/bash
# 描述：安装 Rust 语言

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_rust() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 Rust...${NC}"
    
    case $pkg_manager in
        dnf|yum)
            yum install -y curl gcc make
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y curl gcc make
            ;;
    esac
    
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    
    source "$HOME/.cargo/env"
    
    print_success "Rust 安装完成"
    echo ""
    echo "Rust 版本: $(rustc --version)"
    echo "Cargo 版本: $(cargo --version)"
    echo "配置已添加到 ~/.cargo/env，重启终端或执行 source ~/.cargo/env 使配置生效"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_rust "$@"
fi