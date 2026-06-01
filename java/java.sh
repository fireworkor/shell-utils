#!/bin/bash
# 描述：安装 OpenJDK（支持多版本）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_java() {
    local version=${1:-11}
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 OpenJDK $version...${NC}"
    
    case $pkg_manager in
        dnf|yum)
            yum install -y java-${version}-openjdk java-${version}-openjdk-devel
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y openjdk-${version}-jdk openjdk-${version}-jdk-headless
            ;;
    esac
    
    print_success "OpenJDK $version 安装完成"
    echo ""
    echo "Java 版本: $(java -version 2>&1 | head -1)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_java "$@"
fi
