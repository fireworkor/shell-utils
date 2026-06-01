#!/bin/bash
# 描述：vsftpd 管理脚本 - 配置和管理 FTP 服务

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载通用函数
if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

# 配置文件路径
VSFTPD_CONF="/etc/vsftpd/vsftpd.conf"

show_help() {
    cat << EOF
${GREEN}========================================${NC}
${GREEN}   vsftpd 管理工具${NC}
${GREEN}========================================${NC}

${YELLOW}使用方法：${NC}
  $0 <命令> [选项]

${YELLOW}命令：${NC}
  config               配置 FTP 服务（交互式）
  add-user <用户名>    添加 FTP 用户
  set-share <路径>     设置 FTP 共享目录
  start                启动 FTP 服务
  stop                 停止 FTP 服务
  restart              重启 FTP 服务
  status               查看 FTP 服务状态
  help                 显示此帮助

${YELLOW}示例：${NC}
  $0 config
  $0 add-user ftpuser
  $0 set-share /data/ftp
  $0 status
EOF
}

config_ftp() {
    check_root
    
    echo -e "${BLUE}配置 vsftpd...${NC}"
    echo ""
    
    # 备份原有配置
    if [ -f "$VSFTPD_CONF" ]; then
        cp "$VSFTPD_CONF" "${VSFTPD_CONF}.bak.$(date +%Y%m%d%H%M%S)"
        echo -e "${YELLOW}已备份原配置文件${NC}"
    fi
    
    # 询问共享目录
    read -p "请输入 FTP 共享目录路径（默认：/var/ftp）: " share_path
    share_path=${share_path:-/var/ftp}
    
    # 创建共享目录
    if [ ! -d "$share_path" ]; then
        mkdir -p "$share_path"
        chmod 755 "$share_path"
        echo -e "${GREEN}已创建共享目录：$share_path${NC}"
    fi
    
    # 创建默认配置文件
    cat > "$VSFTPD_CONF" << EOF
# 基础配置
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen=NO
listen_ipv6=YES
pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES

# 安全配置
chroot_local_user=YES
allow_writeable_chroot=YES
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100

# 共享目录配置
local_root=$share_path
EOF
    
    echo -e "${GREEN}配置完成${NC}"
    echo -e "${YELLOW}共享目录：$share_path${NC}"
    echo ""
    
    if confirm "是否现在启动 FTP 服务？"; then
        start_service vsftpd
    fi
}

add_user() {
    check_root
    local username=$1
    
    if [ -z "$username" ]; then
        read -p "请输入要添加的 FTP 用户名: " username
        if [ -z "$username" ]; then
            print_error "用户名不能为空"
            return 1
        fi
    fi
    
    if id "$username" &>/dev/null; then
        print_error "用户 $username 已存在"
        return 1
    fi
    
    # 获取共享目录
    local share_path=$(grep -E "^local_root=" "$VSFTPD_CONF" 2>/dev/null | cut -d'=' -f2)
    if [ -z "$share_path" ]; then
        share_path="/var/ftp"
    fi
    
    # 创建用户
    useradd -m -d "$share_path/$username" -s /sbin/nologin "$username"
    passwd "$username"
    
    print_success "FTP 用户 $username 创建成功"
    echo -e "${YELLOW}用户主目录：$share_path/$username${NC}"
}

set_share() {
    check_root
    local share_path=$1
    
    if [ -z "$share_path" ]; then
        read -p "请输入 FTP 共享目录路径: " share_path
        if [ -z "$share_path" ]; then
            print_error "路径不能为空"
            return 1
        fi
    fi
    
    # 创建目录
    if [ ! -d "$share_path" ]; then
        mkdir -p "$share_path"
        chmod 755 "$share_path"
        echo -e "${GREEN}已创建共享目录：$share_path${NC}"
    fi
    
    # 更新配置
    if [ -f "$VSFTPD_CONF" ]; then
        if grep -q "^local_root=" "$VSFTPD_CONF"; then
            sed -i "s|^local_root=.*|local_root=$share_path|" "$VSFTPD_CONF"
        else
            echo "local_root=$share_path" >> "$VSFTPD_CONF"
        fi
        print_success "共享目录已设置为：$share_path"
        
        if confirm "是否重启 FTP 服务使配置生效？"; then
            start_service vsftpd restart
        fi
    else
        print_error "配置文件 $VSFTPD_CONF 不存在，请先运行 $0 config"
        return 1
    fi
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    local command=$1
    shift
    
    case $command in
        config)
            config_ftp
            ;;
        add-user)
            add_user "$@"
            ;;
        set-share)
            set_share "$@"
            ;;
        start)
            start_service vsftpd
            ;;
        stop)
            systemctl stop vsftpd
            print_success "FTP 服务已停止"
            ;;
        restart)
            start_service vsftpd restart
            ;;
        status)
            systemctl status vsftpd
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
