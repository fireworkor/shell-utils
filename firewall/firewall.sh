#!/bin/bash
# 描述：Linux 防火墙管理工具 - 支持 firewalld 和 ufw

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

get_firewall_type() {
    if command -v firewall-cmd &>/dev/null; then
        echo "firewalld"
    elif command -v ufw &>/dev/null; then
        echo "ufw"
    else
        echo "none"
    fi
}

show_status() {
    local firewall=$(get_firewall_type)
    
    print_header "防火墙状态"
    
    case $firewall in
        firewalld)
            echo -e "${YELLOW}防火墙类型: firewalld${NC}"
            echo ""
            
            if systemctl is-active firewalld &>/dev/null; then
                echo -e "${GREEN}状态: 运行中${NC}"
                
                echo ""
                echo -e "${YELLOW}已开放端口:${NC}"
                firewall-cmd --list-ports 2>/dev/null || echo "  无"
                
                echo ""
                echo -e "${YELLOW}已开放服务:${NC}"
                firewall-cmd --list-services 2>/dev/null || echo "  无"
            else
                echo -e "${RED}状态: 已停止${NC}"
            fi
            ;;
        ufw)
            echo -e "${YELLOW}防火墙类型: ufw${NC}"
            echo ""
            
            status=$(ufw status 2>/dev/null)
            if echo "$status" | grep -q "Status: active"; then
                echo -e "${GREEN}状态: 运行中${NC}"
                echo ""
                echo -e "${YELLOW}规则列表:${NC}"
                ufw status numbered 2>/dev/null
            else
                echo -e "${RED}状态: 已停止${NC}"
            fi
            ;;
        *)
            echo -e "${YELLOW}防火墙类型: 未安装${NC}"
            echo -e "${RED}未检测到 firewalld 或 ufw${NC}"
            ;;
    esac
}

start_firewall() {
    local firewall=$(get_firewall_type)
    
    print_header "启动防火墙"
    
    case $firewall in
        firewalld)
            systemctl start firewalld
            systemctl enable firewalld
            print_success "firewalld 已启动"
            ;;
        ufw)
            ufw enable
            print_success "ufw 已启用"
            ;;
        *)
            print_error "未安装防火墙工具"
            exit 1
            ;;
    esac
}

stop_firewall() {
    local firewall=$(get_firewall_type)
    
    print_header "停止防火墙"
    
    case $firewall in
        firewalld)
            systemctl stop firewalld
            systemctl disable firewalld
            print_success "firewalld 已停止"
            ;;
        ufw)
            ufw disable
            print_success "ufw 已禁用"
            ;;
        *)
            print_error "未安装防火墙工具"
            exit 1
            ;;
    esac
}

add_port() {
    local port=$1
    local protocol=${2:-tcp}
    local firewall=$(get_firewall_type)
    
    print_header "开放端口 $port/$protocol"
    
    case $firewall in
        firewalld)
            firewall-cmd --permanent --add-port=$port/$protocol
            firewall-cmd --reload
            print_success "端口 $port/$protocol 已开放"
            ;;
        ufw)
            ufw allow $port/$protocol
            print_success "端口 $port/$protocol 已开放"
            ;;
        *)
            print_error "未安装防火墙工具"
            exit 1
            ;;
    esac
}

remove_port() {
    local port=$1
    local protocol=${2:-tcp}
    local firewall=$(get_firewall_type)
    
    print_header "关闭端口 $port/$protocol"
    
    case $firewall in
        firewalld)
            firewall-cmd --permanent --remove-port=$port/$protocol
            firewall-cmd --reload
            print_success "端口 $port/$protocol 已关闭"
            ;;
        ufw)
            ufw delete allow $port/$protocol
            print_success "端口 $port/$protocol 已关闭"
            ;;
        *)
            print_error "未安装防火墙工具"
            exit 1
            ;;
    esac
}

add_service() {
    local service=$1
    local firewall=$(get_firewall_type)
    
    print_header "开放服务 $service"
    
    case $firewall in
        firewalld)
            firewall-cmd --permanent --add-service=$service
            firewall-cmd --reload
            print_success "服务 $service 已开放"
            ;;
        ufw)
            ufw allow $service
            print_success "服务 $service 已开放"
            ;;
        *)
            print_error "未安装防火墙工具"
            exit 1
            ;;
    esac
}

add_web_server_rules() {
    print_header "设置 Web 服务器规则"
    
    add_port 80 tcp
    add_port 443 tcp
    
    print_success "Web 服务器规则已设置"
}

add_database_rules() {
    print_header "设置数据库规则"
    
    add_port 3306 tcp
    add_port 5432 tcp
    add_port 27017 tcp
    
    print_success "数据库规则已设置"
}

add_ssh_rules() {
    print_header "设置 SSH 规则"
    
    add_service ssh
    
    print_success "SSH 规则已设置"
}

add_all_rules() {
    print_header "设置所有常用规则"
    
    add_ssh_rules
    add_web_server_rules
    add_database_rules
    
    print_success "所有规则已设置"
}

list_available_services() {
    local firewall=$(get_firewall_type)
    
    print_header "可用服务列表"
    
    case $firewall in
        firewalld)
            firewall-cmd --get-services
            ;;
        ufw)
            echo "ufw 默认支持的服务:"
            echo "  ssh, http, https, ftp, smtp, pop3, imap"
            ;;
        *)
            print_error "未安装防火墙工具"
            exit 1
            ;;
    esac
}

main() {
    local command=$1
    shift
    
    check_root
    
    case $command in
        status)
            show_status
            ;;
        start)
            start_firewall
            ;;
        stop)
            stop_firewall
            ;;
        add-port)
            if [ -z "$1" ]; then
                print_error "用法: $0 add-port <端口> [协议]"
                exit 1
            fi
            add_port "$1" "$2"
            ;;
        remove-port)
            if [ -z "$1" ]; then
                print_error "用法: $0 remove-port <端口> [协议]"
                exit 1
            fi
            remove_port "$1" "$2"
            ;;
        add-service)
            if [ -z "$1" ]; then
                print_error "用法: $0 add-service <服务名>"
                exit 1
            fi
            add_service "$1"
            ;;
        services)
            list_available_services
            ;;
        web)
            add_web_server_rules
            ;;
        database)
            add_database_rules
            ;;
        ssh)
            add_ssh_rules
            ;;
        all)
            add_all_rules
            ;;
        *)
            if [ -z "$command" ]; then
                echo -e "${GREEN}防火墙管理工具${NC}"
                echo ""
                echo -e "${YELLOW}命令列表:${NC}"
                echo ""
                echo "  status          - 查看防火墙状态"
                echo "  start           - 启动防火墙"
                echo "  stop            - 停止防火墙"
                echo "  add-port <端口> [协议]   - 开放端口"
                echo "  remove-port <端口> [协议]- 关闭端口"
                echo "  add-service <服务>      - 开放服务"
                echo "  services        - 列出可用服务"
                echo ""
                echo -e "${YELLOW}快捷命令:${NC}"
                echo ""
                echo "  ssh             - 开放 SSH 端口"
                echo "  web             - 开放 Web 端口 (80, 443)"
                echo "  database        - 开放数据库端口 (3306, 5432, 27017)"
                echo "  all             - 开放所有常用端口"
                echo ""
                echo -e "${YELLOW}示例:${NC}"
                echo ""
                echo "  $0 status"
                echo "  $0 start"
                echo "  $0 add-port 8080"
                echo "  $0 add-port 3306 tcp"
                echo "  $0 web"
            else
                print_error "未知命令: $command"
            fi
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
