#!/bin/bash
# Redis 端口管理脚本
# 支持查看、修改、添加、删除端口

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="redis"
SOFTWARE_NAME="redis"
DISPLAY_NAME="Redis"
DEFAULT_PORTS="6379"
SCRIPT_DIR_REF="$SCRIPT_DIR"

# 端口配置文件
PORT_CONFIG_FILE="$SCRIPT_DIR/ports.conf"

# 读取端口配置
get_ports() {
    if [ -f "$PORT_CONFIG_FILE" ]; then
        cat "$PORT_CONFIG_FILE"
    else
        echo "$DEFAULT_PORTS"
    fi
}

# 显示当前端口
show_ports() {
    echo -e "${BLUE}=== ${DISPLAY_NAME} 端口配置 ===${NC}"
    local ports=$(get_ports)
    echo "  监听端口: $ports"
    echo ""

    # 查找正在监听的端口
    echo -e "${BLUE}=== 正在监听的端口 ===${NC}"
    if command -v ss &>/dev/null; then
        ss -tuln | grep -E ":${ports//,/|:}" || echo "  未找到相关监听端口"
    elif command -v netstat &>/dev/null; then
        netstat -tuln | grep -E ":${ports//,/|:}" || echo "  未找到相关监听端口"
    else
        echo "  系统工具不可用"
    fi
}

# 修改端口
change_port() {
    local old_port=$1
    local new_port=$2

    if [ -z "$old_port" ] || [ -z "$new_port" ]; then
        print_error "用法: $0 change <旧端口> <新端口>"
        return 1
    fi

    if ! [[ "$new_port" =~ ^[0-9]+$ ]] || [ "$new_port" -lt 1 ] || [ "$new_port" -gt 65535 ]; then
        print_error "新端口必须在 1-65535 之间"
        return 1
    fi

    # 查找配置文件
    local config_files=()
    case "$SOFTWARE_NAME" in
        nginx)
            config_files=(/etc/nginx/nginx.conf /etc/nginx/conf.d/*.conf)
            ;;
        apache)
            config_files=(/etc/httpd/conf/httpd.conf /etc/apache2/ports.conf /etc/apache2/sites-enabled/*.conf)
            ;;
        mysql|mariadb)
            config_files=(/etc/my.cnf /etc/mysql/my.cnf /etc/mysql/mariadb.conf.d/*.cnf)
            ;;
        *)
            config_files=(/etc/${SERVICE_NAME}/${SERVICE_NAME}.conf)
            ;;
    esac

    print_info "备份配置文件..."
    bash "$SCRIPT_DIR_REF/backup.sh"

    print_info "尝试修改端口..."
    for config_file in "${config_files[@]}"; do
        if [ -f "$config_file" ]; then
            print_info "  修改 $config_file"
            if sed -i "s/\b${old_port}\b/${new_port}/g" "$config_file" 2>/dev/null; then
                print_success "  已修改"
            fi
        fi
    done

    # 更新端口配置
    local ports=$(get_ports)
    ports=${ports/${old_port}/${new_port}}
    echo "$ports" > "$PORT_CONFIG_FILE"

    print_success "端口已更新: $old_port -> $new_port"
    print_warning "请重启 ${DISPLAY_NAME} 服务以使配置生效"

    if command -v systemctl &>/dev/null; then
        if confirm "是否立即重启 ${DISPLAY_NAME}?"; then
            systemctl restart "${SERVICE_NAME}" 2>/dev/null || true
        fi
    fi
}

# 设置端口
set_ports() {
    local ports=$1
    if [ -z "$ports" ]; then
        print_error "用法: $0 set <端口1,端口2,...>"
        return 1
    fi

    echo "$ports" > "$PORT_CONFIG_FILE"
    print_success "端口配置已更新: $ports"
    print_warning "请手动修改配置文件以应用新端口"
}

# 添加端口
add_port() {
    local new_port=$1
    if [ -z "$new_port" ]; then
        print_error "用法: $0 add <端口>"
        return 1
    fi

    local ports=$(get_ports)
    if [[ ",$ports," == *",${new_port},"* ]]; then
        print_warning "端口 $new_port 已存在"
        return 0
    fi

    ports="${ports:+${ports},}${new_port}"
    echo "$ports" > "$PORT_CONFIG_FILE"
    print_success "端口已添加: $new_port"
}

# 删除端口
remove_port() {
    local port=$1
    if [ -z "$port" ]; then
        print_error "用法: $0 remove <端口>"
        return 1
    fi

    local ports=$(get_ports)
    ports=$(echo "$ports" | sed "s/,\?$port,\?/," | sed 's/^,\|,$//g')
    echo "$ports" > "$PORT_CONFIG_FILE"
    print_success "端口已删除: $port"
}

case "${1:-show}" in
    show|list)
        show_ports
        ;;
    change|modify)
        change_port "$2" "$3"
        ;;
    set)
        set_ports "$2"
        ;;
    add)
        add_port "$2"
        ;;
    remove|rm|del)
        remove_port "$2"
        ;;
    *)
        show_ports
        echo ""
        echo "用法: $0 {show|change <旧端口> <新端口>|set <端口列表>|add <端口>|remove <端口>}"
        ;;
esac
