#!/bin/bash
# 描述：NFS 管理脚本 - 配置和管理网络文件系统服务

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载通用函数
if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

# 配置文件路径
EXPORTS="/etc/exports"

show_help() {
    cat << EOF
${GREEN}========================================${NC}
${GREEN}   NFS 管理工具${NC}
${GREEN}========================================${NC}

${YELLOW}使用方法：${NC}
  $0 <命令> [选项]

${YELLOW}命令：${NC}
  config                     配置 NFS 服务（交互式）
  add-export <路径> <IP>     添加 NFS 共享导出
  remove-export <路径>       移除 NFS 共享导出
  set-share-path <路径>      设置默认共享目录
  list-exports               列出所有共享导出
  show-mounts                显示当前挂载
  start                      启动 NFS 服务
  stop                       停止 NFS 服务
  restart                    重启 NFS 服务
  reload                     重新加载配置
  status                     查看 NFS 服务状态
  help                       显示此帮助

${YELLOW}示例：${NC}
  $0 config
  $0 add-export /data/nfs 192.168.1.0/24
  $0 remove-export /data/nfs
  $0 list-exports
  $0 show-mounts
  $0 status
EOF
}

config_nfs() {
    check_root
    
    echo -e "${BLUE}配置 NFS...${NC}"
    echo ""
    
    # 备份原有配置
    if [ -f "$EXPORTS" ]; then
        cp "$EXPORTS" "${EXPORTS}.bak.$(date +%Y%m%d%H%M%S)"
        echo -e "${YELLOW}已备份原配置文件${NC}"
    fi
    
    # 询问共享目录
    read -p "请输入 NFS 共享目录路径（默认：/data/nfs）: " share_path
    share_path=${share_path:-/data/nfs}
    
    # 创建共享目录
    if [ ! -d "$share_path" ]; then
        mkdir -p "$share_path"
        chmod 755 "$share_path"
        echo -e "${GREEN}已创建共享目录：$share_path${NC}"
    fi
    
    # 询问允许访问的 IP 段
    read -p "请输入允许访问的 IP 段（默认：*）: " allowed_ip
    allowed_ip=${allowed_ip:-*}
    
    # 创建基础配置文件
    cat > "$EXPORTS" << EOF
# NFS 共享导出配置
$share_path $allowed_ip(rw,sync,no_root_squash,no_subtree_check)
EOF
    
    echo -e "${GREEN}配置完成${NC}"
    echo -e "${YELLOW}共享目录：$share_path${NC}"
    echo -e "${YELLOW}允许访问：$allowed_ip${NC}"
    echo ""
    
    if confirm "是否现在启动 NFS 服务？"; then
        start_service nfs-server
    fi
}

add_export() {
    check_root
    local share_path=$1
    local allowed_ip=$2
    
    if [ -z "$share_path" ]; then
        read -p "请输入共享目录路径: " share_path
        if [ -z "$share_path" ]; then
            print_error "路径不能为空"
            return 1
        fi
    fi
    
    if [ -z "$allowed_ip" ]; then
        read -p "请输入允许访问的 IP 段（默认：*）: " allowed_ip
        allowed_ip=${allowed_ip:-*}
    fi
    
    # 创建目录
    if [ ! -d "$share_path" ]; then
        mkdir -p "$share_path"
        chmod 755 "$share_path"
        echo -e "${GREEN}已创建共享目录：$share_path${NC}"
    fi
    
    # 检查是否已存在
    if grep -q "^$share_path " "$EXPORTS" 2>/dev/null; then
        print_error "共享 $share_path 已存在"
        return 1
    fi
    
    # 追加导出配置
    echo "$share_path $allowed_ip(rw,sync,no_root_squash,no_subtree_check)" >> "$EXPORTS"
    
    print_success "NFS 导出添加成功"
    print_success "路径：$share_path"
    print_success "允许：$allowed_ip"
    
    if confirm "是否重新加载 NFS 配置？"; then
        exportfs -ra
        print_success "配置已重新加载"
    fi
}

remove_export() {
    check_root
    local share_path=$1
    
    if [ -z "$share_path" ]; then
        read -p "请输入要移除的共享目录路径: " share_path
        if [ -z "$share_path" ]; then
            print_error "路径不能为空"
            return 1
        fi
    fi
    
    if [ ! -f "$EXPORTS" ]; then
        print_error "配置文件 $EXPORTS 不存在"
        return 1
    fi
    
    if ! grep -q "^$share_path " "$EXPORTS"; then
        print_error "共享 $share_path 不存在"
        return 1
    fi
    
    # 移除此共享
    sed -i "/^$share_path /d" "$EXPORTS"
    
    print_success "NFS 导出已移除：$share_path"
    
    if confirm "是否重新加载 NFS 配置？"; then
        exportfs -ra
        print_success "配置已重新加载"
    fi
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
        chmod 755 "$share_path"
        echo -e "${GREEN}已创建共享目录：$share_path${NC}"
    fi
    
    # 更新配置
    if [ -f "$EXPORTS" ]; then
        # 检查是否有 * 的默认共享
        if grep -q " \*(rw,sync,no_root_squash,no_subtree_check)$" "$EXPORTS"; then
            # 更新默认共享
            local old_path=$(grep " \*(rw,sync,no_root_squash,no_subtree_check)$" "$EXPORTS" | awk '{print $1}')
            if [ -n "$old_path" ]; then
                sed -i "s|^$old_path |$share_path |" "$EXPORTS"
            fi
        else
            # 添加默认共享
            echo "$share_path *(rw,sync,no_root_squash,no_subtree_check)" >> "$EXPORTS"
        fi
        print_success "默认共享目录已设置为：$share_path"
        
        if confirm "是否重新加载 NFS 配置？"; then
            exportfs -ra
            print_success "配置已重新加载"
        fi
    else
        # 创建新配置
        cat > "$EXPORTS" << EOF
# NFS 共享导出配置
$share_path *(rw,sync,no_root_squash,no_subtree_check)
EOF
        print_success "配置文件已创建，共享目录：$share_path"
    fi
}

list_exports() {
    echo -e "${BLUE}NFS 共享导出列表：${NC}"
    echo ""
    
    if [ -f "$EXPORTS" ]; then
        cat "$EXPORTS"
    else
        print_error "配置文件 $EXPORTS 不存在"
    fi
}

show_mounts() {
    echo -e "${BLUE}NFS 挂载信息：${NC}"
    echo ""
    showmount -e
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
            config_nfs
            ;;
        add-export)
            add_export "$@"
            ;;
        remove-export)
            remove_export "$@"
            ;;
        set-share-path)
            set_share_path "$@"
            ;;
        list-exports)
            list_exports
            ;;
        show-mounts)
            show_mounts
            ;;
        start)
            start_service nfs-server
            ;;
        stop)
            systemctl stop nfs-server
            print_success "NFS 服务已停止"
            ;;
        restart)
            start_service nfs-server restart
            ;;
        reload)
            exportfs -ra
            systemctl reload nfs-server
            print_success "NFS 配置已重新加载"
            ;;
        status)
            systemctl status nfs-server
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
