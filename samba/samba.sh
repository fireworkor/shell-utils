#!/bin/bash
# 描述：安装 Samba 文件共享服务

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载通用函数
if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_samba() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 Samba...${NC}"
    
    case $pkg_manager in
        dnf)
            dnf install -y samba samba-client
            ;;
        yum)
            yum install -y samba samba-client
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y samba samba-common-bin
            ;;
    esac
    
    # 配置防火墙
    configure_firewall 139
    configure_firewall 445
    
    print_success "Samba 安装完成"
    echo ""
    echo "使用管理脚本进行配置："
    echo "  $SCRIPT_DIR/samba-manage.sh"
    echo ""
    echo "管理命令："
    echo "  systemctl start smb"
    echo "  systemctl stop smb"
    echo "  systemctl restart smb"
    echo "  systemctl status smb"
}

# 直接运行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_samba
fi
