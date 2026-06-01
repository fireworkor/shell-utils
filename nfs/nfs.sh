#!/bin/bash
# 描述：安装 NFS 网络文件系统服务

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载通用函数
if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_nfs() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 NFS...${NC}"
    
    case $pkg_manager in
        dnf)
            dnf install -y nfs-utils
            ;;
        yum)
            yum install -y nfs-utils
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y nfs-kernel-server
            ;;
    esac
    
    # 配置防火墙
    configure_firewall 2049
    configure_firewall 111
    
    print_success "NFS 安装完成"
    echo ""
    echo "使用管理脚本进行配置："
    echo "  $SCRIPT_DIR/nfs-manage.sh"
    echo ""
    echo "管理命令："
    echo "  systemctl start nfs-server"
    echo "  systemctl stop nfs-server"
    echo "  systemctl restart nfs-server"
    echo "  systemctl status nfs-server"
}

# 直接运行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_nfs
fi
