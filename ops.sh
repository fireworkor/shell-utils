#!/bin/bash

# =========================================
# 快捷运维命令集
# 常用运维命令的快捷方式
# =========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

cmd_system_info() {
    echo -e "${CYAN}系统信息${NC}"
    echo "=========================================="
    echo "主机名: $(hostname)"
    echo "IP 地址: $(hostname -I | awk '{print $1}')"
    echo "操作系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "内核版本: $(uname -r)"
    echo "运行时间: $(uptime -p)"
    echo "系统负载: $(uptime | awk '{print $10 $11 $12}')"
    echo ""
}

cmd_cpu() {
    echo -e "${CYAN}CPU 使用情况${NC}"
    echo "=========================================="
    top -bn1 | grep "Cpu(s)"
    echo ""
    echo "进程 CPU 排行:"
    ps aux --sort=-%cpu | head -6 | awk '{print $11 " - " $3 "%"}'
    echo ""
}

cmd_mem() {
    echo -e "${CYAN}内存使用情况${NC}"
    echo "=========================================="
    free -h
    echo ""
    echo "进程内存排行:"
    ps aux --sort=-%mem | head -6 | awk '{print $11 " - " $4 "%"}'
    echo ""
}

cmd_disk() {
    echo -e "${CYAN}磁盘使用情况${NC}"
    echo "=========================================="
    df -h
    echo ""
}

cmd_net() {
    echo -e "${CYAN}网络状态${NC}"
    echo "=========================================="
    echo "网络接口:"
    ip addr show | grep -A 2 "state UP" | grep -v "LOOPBACK"
    echo ""
    echo "连接状态:"
    ss -tuln | head -20
    echo ""
}

cmd_ps() {
    echo -e "${CYAN}进程列表${NC}"
    echo "=========================================="
    if [ -n "$1" ]; then
        ps aux | grep "$1"
    else
        ps aux | head -20
    fi
    echo ""
}

cmd_kill() {
    if [ -z "$1" ]; then
        log_error "请指定进程名或PID"
        return 1
    fi
    
    echo -e "${CYAN}终止进程${NC}"
    echo "=========================================="
    
    if echo "$1" | grep -q "^[0-9]*$"; then
        log_info "终止 PID: $1"
        kill -9 "$1"
    else
        log_info "终止进程: $1"
        pkill "$1"
    fi
    
    log_success "进程已终止"
}

cmd_logs() {
    local service="${1:-system}"
    
    echo -e "${CYAN}查看日志: $service${NC}"
    echo "=========================================="
    
    case "$service" in
        nginx)
            tail -50 /var/log/nginx/access.log
            echo ""
            echo "错误日志:"
            tail -20 /var/log/nginx/error.log
            ;;
        mysql|mariadb)
            tail -50 /var/log/mariadb/mariadb.log 2>/dev/null || tail -50 /var/log/mysql/error.log 2>/dev/null
            ;;
        php)
            tail -50 /var/log/php-fpm/www-error.log 2>/dev/null || tail -50 /var/log/php7.4-fpm.log 2>/dev/null
            ;;
        docker)
            tail -50 /var/log/docker.log 2>/dev/null || journalctl -u docker --no-pager -n 50
            ;;
        system)
            tail -50 /var/log/messages 2>/dev/null || tail -50 /var/log/syslog 2>/dev/null
            ;;
        *)
            if [ -f "$service" ]; then
                tail -50 "$service"
            else
                journalctl -u "$service" --no-pager -n 50 2>/dev/null || log_error "未知服务: $service"
            fi
            ;;
    esac
    echo ""
}

cmd_service() {
    local action="${1:-status}"
    local service="${2:-}"
    
    echo -e "${CYAN}服务管理: $action $service${NC}"
    echo "=========================================="
    
    if [ -z "$service" ]; then
        log_info "列出所有服务状态:"
        systemctl list-units --type=service --state=running | head -20
    else
        case "$action" in
            start)
                systemctl start "$service"
                ;;
            stop)
                systemctl stop "$service"
                ;;
            restart)
                systemctl restart "$service"
                ;;
            status)
                systemctl status "$service"
                ;;
            enable)
                systemctl enable "$service"
                ;;
            disable)
                systemctl disable "$service"
                ;;
            *)
                log_error "未知操作: $action"
                return 1
                ;;
        esac
        
        if [ "$action" != "status" ]; then
            systemctl is-active --quiet "$service" && log_success "$service 操作成功" || log_error "$service 操作失败"
        fi
    fi
    echo ""
}

cmd_backup() {
    local target="${1:-all}"
    
    echo -e "${CYAN}执行备份: $target${NC}"
    echo "=========================================="
    
    bash "$SCRIPT_DIR/backup/backup.sh" backup "$target"
    
    log_success "备份完成"
    echo ""
}

cmd_restore() {
    local target="${1:-all}"
    
    echo -e "${CYAN}执行恢复: $target${NC}"
    echo "=========================================="
    
    bash "$SCRIPT_DIR/backup/backup.sh" restore "$target"
    
    log_success "恢复完成"
    echo ""
}

cmd_health() {
    echo -e "${CYAN}健康检查${NC}"
    echo "=========================================="
    
    bash "$SCRIPT_DIR/healthcheck/healthcheck.sh"
    echo ""
}

cmd_security() {
    echo -e "${CYAN}安全扫描${NC}"
    echo "=========================================="
    
    bash "$SCRIPT_DIR/security-baseline/security-baseline.sh" all
    echo ""
}

cmd_update() {
    echo -e "${CYAN}检查更新${NC}"
    echo "=========================================="
    
    bash "$SCRIPT_DIR/update.sh" check
    echo ""
}

cmd_cleanup() {
    echo -e "${CYAN}系统清理${NC}"
    echo "=========================================="
    
    bash "$SCRIPT_DIR/cleanup/cleanup.sh"
    echo ""
}

cmd_firewall() {
    local action="${1:-status}"
    
    echo -e "${CYAN}防火墙管理: $action${NC}"
    echo "=========================================="
    
    bash "$SCRIPT_DIR/firewall/firewall.sh" "$action"
    echo ""
}

cmd_monitor() {
    echo -e "${CYAN}启动监控${NC}"
    echo "=========================================="
    
    watch -n 2 "echo '=== CPU ===' && top -bn1 | grep 'Cpu(s)' && echo '' && echo '=== Memory ===' && free -h && echo '' && echo '=== Disk ===' && df -h / && echo '' && echo '=== Network ===' && ss -tuln | head -10"
}

cmd_docker() {
    local action="${1:-ps}"
    
    echo -e "${CYAN}Docker 管理: $action${NC}"
    echo "=========================================="
    
    bash "$SCRIPT_DIR/docker-manager/docker-manager.sh" "$action"
    echo ""
}

cmd_k8s() {
    local action="${1:-info}"
    
    echo -e "${CYAN}Kubernetes 管理: $action${NC}"
    echo "=========================================="
    
    bash "$SCRIPT_DIR/kubernetes/k8s-manage.sh" "$action"
    echo ""
}

cmd_nginx() {
    local action="${1:-status}"
    
    echo -e "${CYAN}Nginx 管理: $action${NC}"
    echo "=========================================="
    
    case "$action" in
        status)
            systemctl status nginx
            ;;
        start)
            systemctl start nginx
            ;;
        stop)
            systemctl stop nginx
            ;;
        restart)
            systemctl restart nginx
            ;;
        reload)
            systemctl reload nginx
            ;;
        configtest)
            nginx -t
            ;;
        logs)
            tail -50 /var/log/nginx/access.log
            ;;
        *)
            log_error "未知操作: $action"
            ;;
    esac
    echo ""
}

show_help() {
    cat <<EOF
${CYAN}========================================${NC}
${CYAN}       快捷运维命令集${NC}
${CYAN}========================================${NC}

${YELLOW}系统信息:${NC}
  sysinfo           显示系统信息
  cpu               显示 CPU 使用情况
  mem               显示内存使用情况
  disk              显示磁盘使用情况
  net               显示网络状态
  ps [进程名]       显示进程列表
  kill <进程/PID>   终止进程

${YELLOW}服务管理:${NC}
  service [操作] [服务]   服务管理
    操作: start/stop/restart/status/enable/disable
    示例: service restart nginx

${YELLOW}日志查看:${NC}
  logs [服务]       查看日志
    支持: nginx, mysql, php, docker, system

${YELLOW}Nginx 管理:${NC}
  nginx [操作]      Nginx 快捷命令
    操作: status/start/stop/restart/reload/configtest/logs

${YELLOW}运维工具:${NC}
  health            健康检查
  security          安全扫描
  backup [目标]     执行备份
  restore [目标]    执行恢复
  cleanup           系统清理
  update            检查更新
  firewall [操作]   防火墙管理
  monitor           实时监控

${YELLOW}容器管理:${NC}
  docker [命令]     Docker 管理
  k8s [命令]        Kubernetes 管理

${YELLOW}示例:${NC}
  ops cpu           # 查看 CPU 使用
  ops mem           # 查看内存使用
  ops service status nginx  # 查看 Nginx 状态
  ops service restart nginx # 重启 Nginx
  ops logs nginx    # 查看 Nginx 日志
  ops backup mysql  # 备份 MySQL
  ops monitor       # 启动实时监控

EOF
}

main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        sysinfo|system-info)
            cmd_system_info
            ;;
        cpu)
            cmd_cpu
            ;;
        mem|memory)
            cmd_mem
            ;;
        disk|df)
            cmd_disk
            ;;
        net|network)
            cmd_net
            ;;
        ps)
            cmd_ps "$@"
            ;;
        kill)
            cmd_kill "$@"
            ;;
        logs)
            cmd_logs "$@"
            ;;
        service)
            cmd_service "$@"
            ;;
        backup)
            cmd_backup "$@"
            ;;
        restore)
            cmd_restore "$@"
            ;;
        health|healthcheck)
            cmd_health
            ;;
        security)
            cmd_security
            ;;
        update)
            cmd_update
            ;;
        cleanup)
            cmd_cleanup
            ;;
        firewall)
            cmd_firewall "$@"
            ;;
        monitor)
            cmd_monitor
            ;;
        docker)
            cmd_docker "$@"
            ;;
        k8s|kubernetes)
            cmd_k8s "$@"
            ;;
        nginx)
            cmd_nginx "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            echo "运行 'ops help' 查看帮助"
            exit 1
            ;;
    esac
}

main "$@"
