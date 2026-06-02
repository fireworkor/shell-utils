#!/bin/bash
# MongoDB 卸载脚本
# 支持完全卸载或仅移除软件包

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="mongod"
SOFTWARE_NAME="mongodb"
DISPLAY_NAME="MongoDB"
SCRIPT_DIR_REF="$SCRIPT_DIR"

# 完整卸载（默认）
COMPLETE=true
PURGE_DATA=false

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --keep-data)
            COMPLETE=false
            shift
            ;;
        --purge-data)
            PURGE_DATA=true
            shift
            ;;
        --only-package)
            COMPLETE=false
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# 备份配置
backup_before_uninstall() {
    print_info "卸载前备份配置和数据..."
    if [ -x "$SCRIPT_DIR_REF/backup.sh" ]; then
        bash "$SCRIPT_DIR_REF/backup.sh" all
        print_success "备份完成"
    fi
}

# 停止服务
stop_service() {
    if command -v systemctl &>/dev/null && systemctl list-unit-files | grep -q "${SERVICE_NAME}.service"; then
        print_info "停止服务 ${SERVICE_NAME}..."
        systemctl stop "${SERVICE_NAME}" 2>/dev/null || true
        systemctl disable "${SERVICE_NAME}" 2>/dev/null || true
        print_success "服务已停止"
    fi
}

# 卸载软件包
uninstall_package() {
    print_info "卸载 ${DISPLAY_NAME} 软件包..."

    if command -v apt &>/dev/null; then
        apt remove -y --purge "${SERVICE_NAME}" 2>/dev/null || true
        apt autoremove -y 2>/dev/null || true
    elif command -v dnf &>/dev/null; then
        dnf remove -y "${SERVICE_NAME}" 2>/dev/null || true
    elif command -v yum &>/dev/null; then
        yum remove -y "${SERVICE_NAME}" 2>/dev/null || true
    fi

    print_success "软件包已卸载"
}

# 清理配置
cleanup_config() {
    if [ "$COMPLETE" = false ]; then
        return
    fi

    print_info "清理配置文件..."

    case "$SOFTWARE_NAME" in
        nginx)
            rm -rf /etc/nginx 2>/dev/null
            ;;
        apache)
            rm -rf /etc/httpd /etc/apache2 2>/dev/null
            ;;
        mysql|mariadb)
            rm -rf /etc/my.cnf /etc/my.cnf.d /etc/mysql 2>/dev/null
            ;;
        redis)
            rm -rf /etc/redis 2>/dev/null
            ;;
        *)
            rm -rf /etc/${SERVICE_NAME} 2>/dev/null
            ;;
    esac

    print_success "配置已清理"
}

# 清理数据
cleanup_data() {
    if [ "$PURGE_DATA" = false ]; then
        return
    fi

    print_info "清理数据文件..."
    read -p "  确认删除所有数据吗? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        case "$SOFTWARE_NAME" in
            mysql)
                rm -rf /var/lib/mysql 2>/dev/null
                ;;
            mariadb)
                rm -rf /var/lib/mysql /var/lib/mariadb 2>/dev/null
                ;;
            redis)
                rm -rf /var/lib/redis 2>/dev/null
                ;;
            mongodb)
                rm -rf /var/lib/mongodb 2>/dev/null
                ;;
            *)
                rm -rf /var/lib/${SERVICE_NAME} 2>/dev/null
                ;;
        esac
        print_success "数据已清理"
    else
        print_info "  跳过数据清理"
    fi
}

# 清理日志
cleanup_logs() {
    if [ "$COMPLETE" = false ]; then
        return
    fi

    case "$SOFTWARE_NAME" in
        nginx)
            rm -rf /var/log/nginx 2>/dev/null
            ;;
        apache)
            rm -rf /var/log/httpd /var/log/apache2 2>/dev/null
            ;;
        mysql|mariadb)
            rm -rf /var/log/mysql /var/log/mariadb 2>/dev/null
            ;;
        redis)
            rm -rf /var/log/redis 2>/dev/null
            ;;
        *)
            rm -rf /var/log/${SERVICE_NAME} 2>/dev/null
            ;;
    esac
}

# 清理备份
cleanup_backups() {
    read -p "  是否删除所有备份? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -rf /var/backups/shell-utils/${SOFTWARE_NAME} 2>/dev/null
        print_success "备份已清理"
    fi
}

# 打开防火墙端口
close_firewall() {
    case "$SOFTWARE_NAME" in
        nginx|apache)
            if command -v firewall-cmd &>/dev/null; then
                firewall-cmd --permanent --remove-port=80/tcp 2>/dev/null || true
                firewall-cmd --permanent --remove-port=443/tcp 2>/dev/null || true
                firewall-cmd --reload 2>/dev/null || true
            fi
            if command -v ufw &>/dev/null; then
                ufw delete allow 80/tcp 2>/dev/null || true
                ufw delete allow 443/tcp 2>/dev/null || true
            fi
            ;;
        mysql|mariadb)
            if command -v firewall-cmd &>/dev/null; then
                firewall-cmd --permanent --remove-port=3306/tcp 2>/dev/null || true
                firewall-cmd --reload 2>/dev/null || true
            fi
            ;;
        redis)
            if command -v firewall-cmd &>/dev/null; then
                firewall-cmd --permanent --remove-port=6379/tcp 2>/dev/null || true
                firewall-cmd --reload 2>/dev/null || true
            fi
            ;;
    esac
}

# 主函数
main() {
    print_header "卸载 ${DISPLAY_NAME}"
    echo ""

    print_warning "即将卸载 ${DISPLAY_NAME}"
    echo "  选项:"
    echo "    --keep-data     保留数据文件"
    echo "    --purge-data    清理所有数据"
    echo "    --only-package  仅卸载软件包，保留配置和数据"
    echo ""

    if ! confirm "确认卸载 ${DISPLAY_NAME}?"; then
        print_info "取消卸载"
        return 0
    fi

    # 1. 备份
    backup_before_uninstall

    # 2. 停止服务
    stop_service

    # 3. 关闭防火墙
    close_firewall

    # 4. 卸载软件包
    uninstall_package

    # 5. 清理配置
    cleanup_config

    # 6. 清理数据
    cleanup_data

    # 7. 清理日志
    cleanup_logs

    # 8. 清理备份
    cleanup_backups

    echo ""
    print_success "${DISPLAY_NAME} 卸载完成"
}

main "$@"
