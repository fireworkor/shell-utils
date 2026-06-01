#!/bin/bash
# 描述：安装 Nginx Web 服务器

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载通用函数
if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_nginx() {
    # 初始化脚本环境
    init_script_env "nginx-install"
    
    # 检查权限
    check_root
    
    # 检查操作系统
    check_os
    
    # 检查网络
    check_network || {
        print_warning "网络不可用，可能影响安装"
    }
    
    # 检查磁盘空间
    check_disk_space "/" 200 || {
        print_warning "磁盘空间不足，可能影响安装"
    }
    
    local pkg_manager=$(get_pkg_manager)
    
    print_info "正在安装 Nginx..."
    
    case $pkg_manager in
        dnf|yum)
            # 创建 Nginx 仓库配置
            local repo_file="/etc/yum.repos.d/nginx.repo"
            backup_file "$repo_file" 2>/dev/null || true
            
            cat > "$repo_file" << 'EOF'
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
modulehotfixes=true
EOF
            
            robust_install nginx || {
                print_error "Nginx 安装失败"
                exit $E_INSTALL_FAILED
            }
            ;;
        apt)
            robust_install nginx || {
                print_error "Nginx 安装失败"
                exit $E_INSTALL_FAILED
            }
            ;;
        *)
            print_error "不支持的包管理器: $pkg_manager"
            exit $E_UNSUPPORTED_OS
            ;;
    esac
    
    # 配置防火墙
    configure_firewall 80
    configure_firewall 443
    
    # 备份配置文件
    backup_file /etc/nginx/nginx.conf 2>/dev/null || true
    
    # 启动服务
    start_service nginx
    
    # 验证安装
    if command -v nginx &>/dev/null; then
        local version=$(nginx -v 2>&1 | grep -oE '[0-9]+\.[0-9]+')
        print_success "Nginx 安装完成 (版本: $version)"
        log_info "Nginx 安装成功 (版本: $version)"
    else
        print_error "Nginx 安装验证失败"
        exit $E_INSTALL_FAILED
    fi
    
    echo ""
    echo "管理命令："
    echo "  systemctl start nginx"
    echo "  systemctl stop nginx"
    echo "  systemctl restart nginx"
    echo "  systemctl status nginx"
}

# 直接运行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_nginx
fi
