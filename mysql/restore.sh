#!/bin/bash
# MySQL 恢复脚本
# 从备份文件恢复配置、数据或日志

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="mysqld"
SOFTWARE_NAME="mysql"
DISPLAY_NAME="MySQL"
SCRIPT_DIR_REF="$SCRIPT_DIR"

BACKUP_ROOT="/var/backups/shell-utils/${SOFTWARE_NAME}"

# 恢复备份
do_restore() {
    local backup_file="$1"

    if [ -z "$backup_file" ]; then
        print_error "请指定备份文件"
        return 1
    fi

    if [ ! -f "$backup_file" ]; then
        # 尝试在备份目录中查找
        if [ -f "$BACKUP_ROOT/$backup_file" ]; then
            backup_file="$BACKUP_ROOT/$backup_file"
        else
            print_error "备份文件不存在: $backup_file"
            return 1
        fi
    fi

    if ! confirm "确认从 $(basename $backup_file) 恢复?"; then
        print_info "取消恢复"
        return 0
    fi

    # 停止服务
    if command -v systemctl &>/dev/null && systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
        print_info "停止服务 ${SERVICE_NAME}..."
        systemctl stop "${SERVICE_NAME}" || true
    fi

    # 创建临时目录
    local temp_dir=$(mktemp -d)
    print_info "解压备份文件..."
    if ! tar xzf "$backup_file" -C "$temp_dir" 2>/dev/null; then
        print_error "解压备份文件失败"
        rm -rf "$temp_dir"
        return 1
    fi

    local extract_dir=$(find "$temp_dir" -maxdepth 1 -type d -name "backup_*" | head -1)
    if [ -z "$extract_dir" ]; then
        extract_dir="$temp_dir/$(ls $temp_dir | head -1)"
    fi

    # 恢复配置
    if [ -d "$extract_dir/config" ]; then
        print_info "恢复配置文件..."

        case "$SOFTWARE_NAME" in
            nginx)
                [ -d "$extract_dir/config/nginx" ] && cp -r "$extract_dir/config/nginx"/* /etc/nginx/ 2>/dev/null
                ;;
            apache)
                [ -d "$extract_dir/config/httpd" ] && cp -r "$extract_dir/config/httpd"/* /etc/httpd/ 2>/dev/null
                [ -d "$extract_dir/config/apache2" ] && cp -r "$extract_dir/config/apache2"/* /etc/apache2/ 2>/dev/null
                ;;
            mysql|mariadb)
                if [ -d "$extract_dir/config/my.cnf.d" ]; then
                    cp -r "$extract_dir/config/my.cnf.d"/* /etc/my.cnf.d/ 2>/dev/null
                fi
                if [ -d "$extract_dir/config/mysql" ]; then
                    cp -r "$extract_dir/config/mysql"/* /etc/mysql/ 2>/dev/null
                fi
                [ -f "$extract_dir/config/my.cnf" ] && cp "$extract_dir/config/my.cnf" /etc/my.cnf
                ;;
            *)
                if [ -d "$extract_dir/config/${SERVICE_NAME}" ]; then
                    cp -r "$extract_dir/config/${SERVICE_NAME}"/* /etc/${SERVICE_NAME}/ 2>/dev/null
                fi
                ;;
        esac

        print_success "配置恢复完成"
    fi

    # 恢复数据
    if [ -d "$extract_dir/data" ]; then
        print_info "恢复数据文件..."

        case "$SOFTWARE_NAME" in
            mysql)
                if ls "$extract_dir/data"/*.sql.gz &>/dev/null; then
                    local sql_file=$(ls "$extract_dir/data"/*.sql.gz | head -1)
                    gunzip < "$sql_file" | mysql 2>/dev/null
                    print_success "MySQL 数据恢复完成"
                fi
                ;;
            mariadb)
                if ls "$extract_dir/data"/*.sql.gz &>/dev/null; then
                    local sql_file=$(ls "$extract_dir/data"/*.sql.gz | head -1)
                    gunzip < "$sql_file" | mariadb 2>/dev/null
                    print_success "MariaDB 数据恢复完成"
                fi
                ;;
            mongodb)
                if ls "$extract_dir/data"/*.archive &>/dev/null; then
                    local archive_file=$(ls "$extract_dir/data"/*.archive | head -1)
                    mongorestore --archive="$archive_file" --gzip 2>/dev/null
                    print_success "MongoDB 数据恢复完成"
                fi
                ;;
            redis)
                if ls "$extract_dir/data"/*.rdb &>/dev/null; then
                    local rdb_file=$(ls "$extract_dir/data"/*.rdb | head -1)
                    cp "$rdb_file" /var/lib/redis/dump.rdb
                    chown redis:redis /var/lib/redis/dump.rdb 2>/dev/null
                    print_success "Redis 数据恢复完成"
                fi
                ;;
        esac
    fi

    # 清理
    rm -rf "$temp_dir"

    # 启动服务
    if command -v systemctl &>/dev/null; then
        print_info "启动服务 ${SERVICE_NAME}..."
        systemctl start "${SERVICE_NAME}" || true
    fi

    print_success "恢复完成"
}

# 列出可用备份
list_available() {
    echo -e "${BLUE}可用的备份:${NC}"
    if [ -d "$BACKUP_ROOT" ]; then
        ls -1 "$BACKUP_ROOT"/backup_*.tar.gz 2>/dev/null | while read -r backup; do
            local size=$(du -h "$backup" | cut -f1)
            local time=$(stat -c %y "$backup" 2>/dev/null | cut -d. -f1)
            echo "  $(basename $backup) ($size, $time)"
        done
    else
        echo "  备份目录不存在"
    fi
}

case "${1:-list}" in
    list|ls)
        list_available
        ;;
    *)
        do_restore "$@"
        ;;
esac
