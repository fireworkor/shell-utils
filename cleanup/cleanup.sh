#!/bin/bash
# 描述：系统清理

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

cleanup_system() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}系统清理...${NC}"
    
    case $pkg_manager in
        dnf|yum)
            yum clean all
            ;;
        apt)
            apt clean
            apt autoclean
            apt autoremove -y
            ;;
    esac
    
    rm -rf /tmp/* 2>/dev/null || true
    rm -rf /var/tmp/* 2>/dev/null || true
    
    print_success "系统清理完成"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cleanup_system
fi
