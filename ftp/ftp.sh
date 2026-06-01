#!/bin/bash
# 描述：安装 vsftpd (FTP 服务器)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载通用函数
if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_vsftpd() {
    # 初始化脚本环境
    init_script_env "ftp-install"
    
    # 检查权限
    check_root
    
    # 检查操作系统
    check_os
    
    # 检查网络
    check_network || {
        print_warning "网络不可用，可能影响安装"
    }
    
    # 检查磁盘空间
    check_disk_space "/" 100 || {
        print_warning "磁盘空间不足，可能影响安装"
    }
    
    local pkg_manager=$(get_pkg_manager)
    
    print_info "正在安装 vsftpd..."
    
    # 使用健壮的安装函数
    case $pkg_manager in
        dnf|yum)
            robust_install vsftpd || {
                print_error "vsftpd 安装失败"
                exit $E_INSTALL_FAILED
            }
            ;;
        apt)
            robust_install vsftpd || {
                print_error "vsftpd 安装失败"
                exit $E_INSTALL_FAILED
            }
            ;;
        *)
            print_error "不支持的包管理器: $pkg_manager"
            exit $E_UNSUPPORTED_OS
            ;;
    esac
    
    # 配置防火墙
    configure_firewall 21
    
    # 备份配置文件
    backup_file /etc/vsftpd/vsftpd.conf 2>/dev/null || true
    
    # 启动服务
    start_service vsftpd
    
    print_success "vsftpd 安装完成"
    log_info "vsftpd 安装成功"
    
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
