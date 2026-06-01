#!/bin/bash
# 描述：安装 vsftpd (FTP 服务器)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载通用函数
if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_vsftpd() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 vsftpd...${NC}"
    
    case $pkg_manager in
        dnf)
            dnf install -y vsftpd
            ;;
        yum)
            yum install -y vsftpd
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y vsftpd
            ;;
    esac
    
    # 配置防火墙
    configure_firewall 21
    
    print_success "vsftpd 安装完成"
    echo ""
    echo "使用管理脚本进行配置："
    echo "  $SCRIPT_DIR/ftp-manage.sh"
    echo ""
    echo "管理命令："
    echo "  systemctl start vsftpd"
    echo "  systemctl stop vsftpd"
    echo "  systemctl restart vsftpd"
    echo "  systemctl status vsftpd"
}

# 直接运行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_vsftpd
fi
