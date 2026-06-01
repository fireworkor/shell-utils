#!/bin/bash
# 描述：Samba 管理脚本 - 配置和管理文件共享服务

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载通用函数
if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

# 配置文件路径
SMB_CONF="/etc/samba/smb.conf"

show_help() {
    cat << EOF
${GREEN}========================================${NC}
${GREEN}   Samba 管理工具${NC}
${GREEN}========================================${NC}

${YELLOW}使用方法：${NC}
  $0 <命令> [选项]

${YELLOW}命令：${NC}
  config                   配置 Samba 服务（交互式）
  add-share <共享名>       添加 Samba 共享
  add-user <用户名>        添加 Samba 用户
  set-share-path <路径>    设置默认共享目录
  list-shares              列出所有共享
  start                    启动 Samba 服务
  stop                     停止 Samba 服务
  restart                  重启 Samba 服务
  status                   查看 Samba 服务状态
  help                     显示此帮助

${YELLOW}示例：${NC}
  $0 config
  $0 add-share myshare
  $0 add-user sambauser
  $0 set-share-path /data/share
  $0 list-shares
  $0 status
EOF
}

config_samba() {
    check_root
    
    echo -e "${BLUE}配置 Samba...${NC}"
    echo ""
    
    # 备份原有配置
    if [ -f "$SMB_CONF" ]; then
        cp "$SMB_CONF" "${SMB_CONF}.bak.$(date +%Y%m%d%H%M%S)"
        echo -e "${YELLOW}已备份原配置文件${NC}"
    fi
    
    # 询问共享目录
    read -p "请输入默认共享目录路径（默认：/data/share）: " share_path
    share_path=${share_path:-/data/share}
    
    # 创建共享目录
    if [ ! -d "$share_path" ]; then
        mkdir -p "$share_path"
        chmod 777 "$share_path"
        echo -e "${GREEN}已创建共享目录：$share_path${NC}"
    fi
    
    # 创建基础配置文件
    cat > "$SMB_CONF" << EOF
[global]
   workgroup = WORKGROUP
   security = user
   map to guest = Bad User
   server string = Samba Server
   netbios name = $(hostname)
   log file = /var/log/samba/log.%m
   max log size = 1000
   logging = file
   panic action = /usr/share/samba/panic-action %d
   server role = standalone server
   passdb backend = tdbsam
   obey pam restrictions = yes
   unix password sync = yes
   passwd program = /usr/bin/passwd %u
   passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
   pam password change = yes
   map to guest = bad user
   usershare allow guests = yes

[data]
   path = $share_path
   browseable = yes
   read only = no
   create mask = 0777
   directory mask = 0777
   valid users = @sambashare
EOF
    
    # 创建 sambashare 组（如果不存在）
    if ! getent group sambashare &>/dev/null; then
        groupadd sambashare
    fi
    
    echo -e "${GREEN}配置完成${NC}"
    echo -e "${YELLOW}默认共享名：data${NC}"
    echo -e "${YELLOW}共享目录：$share_path${NC}"
    echo ""
    echo "请添加用户到 Samba 并设置密码："
    echo "  $0 add-user <用户名>"
    echo ""
    
    if confirm "是否现在启动 Samba 服务？"; then
        start_service smb
    fi
}

add_share() {
    check_root
    local share_name=$1
    
    if [ -z "$share_name" ]; then
        read -p "请输入共享名称: " share_name
        if [ -z "$share_name" ]; then
            print_error "共享名不能为空"
            return 1
        fi
    fi
    
    # 检查共享是否已存在
    if grep -q "^\[$share_name\]" "$SMB_CONF"; then
        print_error "共享 $share_name 已存在"
        return 1
    fi
    
    # 询问共享路径
    read -p "请输入共享路径: " share_path
    if [ -z "$share_path" ]; then
        print_error "路径不能为空"
        return 1
    fi
    
    # 创建目录
    if [ ! -d "$share_path" ]; then
        mkdir -p "$share_path"
        chmod 777 "$share_path"
        echo -e "${GREEN}已创建共享目录：$share_path${NC}"
    fi
    
    # 追加共享配置
    cat >> "$SMB_CONF" << EOF

[$share_name]
   path = $share_path
   browseable = yes
   read only = no
   create mask = 0777
   directory mask = 0777
   valid users = @sambashare
EOF
    
    print_success "共享 $share_name 添加成功"
    print_success "路径：$share_path"
    
    if confirm "是否重启 Samba 服务使配置生效？"; then
        start_service smb restart
    fi
}

add_user() {
    check_root
    local username=$1
    
    if [ -z "$username" ]; then
        read -p "请输入要添加的 Samba 用户名: " username
        if [ -z "$username" ]; then
            print_error "用户名不能为空"
            return 1
        fi
    fi
    
    # 首先添加系统用户
    if ! id "$username" &>/dev/null; then
        useradd -M -s /sbin/nologin "$username"
        echo -e "${GREEN}已创建系统用户：$username${NC}"
    fi
    
    # 添加到 sambashare 组
    usermod -aG sambashare "$username"
    
    # 设置 Samba 密码
    echo -e "${YELLOW}请设置 Samba 密码：${NC}"
    smbpasswd -a "$username"
    
    print_success "Samba 用户 $username 创建成功"
}

set_share_path() {
    check_root
    local share_path=$1
    
    if [ -z "$share_path" ]; then
        read -p "请输入默认共享目录路径: " share_path
        if [ -z "$share_path" ]; then
            print_error "路径不能为空"
            return 1
        fi
    fi
    
    # 创建目录
    if [ ! -d "$share_path" ]; then
        mkdir -p "$share_path"
        chmod 777 "$share_path"
        echo -e "${GREEN}已创建共享目录：$share_path${NC}"
    fi
    
    # 更新配置
    if [ -f "$SMB_CONF" ]; then
        # 更新 [data] 共享的 path
        if grep -q "^\[data\]" "$SMB_CONF"; then
            sed -i "/^\[data\]/,/^$/ s|path = .*|path = $share_path|" "$SMB_CONF"
        else
            # 如果没有 data 共享，添加一个
            cat >> "$SMB_CONF" << EOF

[data]
   path = $share_path
   browseable = yes
   read only = no
   create mask = 0777
   directory mask = 0777
   valid users = @sambashare
EOF
        fi
        print_success "默认共享目录已设置为：$share_path"
        
        if confirm "是否重启 Samba 服务使配置生效？"; then
            start_service smb restart
        fi
    else
        print_error "配置文件 $SMB_CONF 不存在，请先运行 $0 config"
        return 1
    fi
}

list_shares() {
    echo -e "${BLUE}Samba 共享列表：${NC}"
    echo ""
    
    if [ -f "$SMB_CONF" ]; then
        # 使用 testparm 查看共享
        testparm -s -v 2>/dev/null | grep "^\["
    else
        print_error "配置文件 $SMB_CONF 不存在"
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
            config_samba
            ;;
        add-share)
            add_share "$@"
            ;;
        add-user)
            add_user "$@"
            ;;
        set-share-path)
            set_share_path "$@"
            ;;
        list-shares)
            list_shares
            ;;
        start)
            start_service smb
            ;;
        stop)
            systemctl stop smb
            print_success "Samba 服务已停止"
            ;;
        restart)
            start_service smb restart
            ;;
        status)
            systemctl status smb
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
