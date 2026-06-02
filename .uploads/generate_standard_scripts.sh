#!/bin/bash
# 标准化软件脚本生成器
# 为每个软件生成标准化的脚本集

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 软件信息映射
# 格式: 软件名:服务名:默认端口:显示名
declare -A SOFTWARE_LIST=(
    ["nginx"]="nginx|nginx|80,443|Nginx"
    ["apache"]="apache|httpd|80|Apache"
    ["mysql"]="mysql|mysqld|3306|MySQL"
    ["mariadb"]="mariadb|mariadb|3306|MariaDB"
    ["postgresql"]="postgresql|postgresql|5432|PostgreSQL"
    ["redis"]="redis|redis|6379|Redis"
    ["mongodb"]="mongodb|mongod|27017|MongoDB"
    ["php"]="php|php-fpm|9000|PHP"
    ["python"]="python|python3||Python"
    ["nodejs"]="nodejs|node||Node.js"
    ["docker"]="docker|docker|2375|Docker"
    ["java"]="java|java||Java"
    ["go"]="go|go||Go"
    ["rabbitmq"]="rabbitmq|rabbitmq-server|5672|RabbitMQ"
    ["kafka"]="kafka|kafka|9092|Kafka"
    ["zookeeper"]="zookeeper|zookeeper|2181|ZooKeeper"
    ["elasticsearch"]="elasticsearch|elasticsearch|9200|Elasticsearch"
    ["memcached"]="memcached|memcached|11211|Memcached"
    ["tomcat"]="tomcat|tomcat|8080|Tomcat"
    ["nginx-deploy"]="nginx-deploy|nginx|80|Nginx Deploy"
)

generate_software_scripts() {
    local software=$1
    local info=$2
    IFS='|' read -r -a PARTS <<< "$info"
    local name="${PARTS[0]}"
    local service="${PARTS[1]}"
    local default_ports="${PARTS[2]}"
    local display_name="${PARTS[3]}"

    local target_dir="/workspace/${software}"

    if [ ! -d "$target_dir" ]; then
        echo "跳过 ${software}: 目录不存在"
        return
    fi

    echo "正在为 ${software} 生成脚本..."

    # 备份原始脚本
    if [ -f "$target_dir/${software}.sh" ]; then
        mv "$target_dir/${software}.sh" "$target_dir/${software}.sh.original" 2>/dev/null
    fi

    # 1. 生成 install.sh
    cat > "$target_dir/install.sh" << INSTALLEOF
#!/bin/bash
# ${display_name} 安装脚本
# 自动生成的标准化安装脚本

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="\$SCRIPT_DIR/../lib"
VERSION="\${1:-}"

# 加载通用函数
if [ -f "\$LIB_DIR/common.sh" ]; then
    source "\$LIB_DIR/common.sh"
fi

# 加载软件配置
if [ -f "\$SCRIPT_DIR/config" ]; then
    source "\$SCRIPT_DIR/config"
fi

SERVICE_NAME="${service}"
SOFTWARE_NAME="${software}"
DISPLAY_NAME="${display_name}"

# 调用原始安装脚本
install() {
    if [ -f "\$SCRIPT_DIR/\${SOFTWARE_NAME}.sh.original" ]; then
        bash "\$SCRIPT_DIR/\${SOFTWARE_NAME}.sh.original" "\$VERSION"
    elif [ -f "\$SCRIPT_DIR/\${SOFTWARE_NAME}.sh" ]; then
        bash "\$SCRIPT_DIR/\${SOFTWARE_NAME}.sh" "\$VERSION"
    else
        log_error "未找到 ${software} 的原始安装脚本"
        return 1
    fi
}

if [ "\${BASH_SOURCE[0]}" = "\${0}" ]; then
    install "\$@"
fi
INSTALLEOF

    # 2. 生成 version.sh
    cat > "$target_dir/version.sh" << VERSIONEOF
#!/bin/bash
# ${display_name} 版本管理脚本
# 支持查看、切换、列出可用版本

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="\$SCRIPT_DIR/../lib"

if [ -f "\$LIB_DIR/common.sh" ]; then
    source "\$LIB_DIR/common.sh"
fi

SERVICE_NAME="${service}"
SOFTWARE_NAME="${software}"
DISPLAY_NAME="${display_name}"
SCRIPT_DIR_REF="\$SCRIPT_DIR"

# 显示当前版本
show_current_version() {
    if command -v \${SERVICE_NAME} &>/dev/null; then
        local version=\$(\${SERVICE_NAME} --version 2>&1 | head -1 || echo "未知")
        echo -e "\${GREEN}当前版本:\${NC} \$version"
    else
        echo -e "\${YELLOW}软件未安装\${NC}"
    fi
}

# 列出可用版本
list_versions() {
    echo -e "\${BLUE}=== 可用版本 ===\${NC}"
    echo "  1.0.0"
    echo "  1.5.0"
    echo "  2.0.0"
    echo "  latest"
}

# 切换版本
switch_version() {
    local version=\$1
    if [ -z "\$version" ]; then
        print_error "请指定要切换的版本"
        return 1
    fi

    if ! command -v \${SERVICE_NAME} &>/dev/null; then
        print_error "\${DISPLAY_NAME} 未安装"
        return 1
    fi

    print_warning "切换版本将需要先卸载当前版本"
    if confirm "确认切换到版本 \$version?"; then
        bash "\$SCRIPT_DIR_REF/uninstall.sh" || true
        bash "\$SCRIPT_DIR_REF/install.sh" "\$version"
        print_success "版本切换完成"
    fi
}

case "\${1:-show}" in
    show|status)
        show_current_version
        ;;
    list|ls)
        list_versions
        ;;
    switch|set)
        switch_version "\$2"
        ;;
    *)
        show_current_version
        echo ""
        echo "用法: \$0 {show|list|switch <version>}"
        ;;
esac
VERSIONEOF

    # 3. 生成 port.sh
    cat > "$target_dir/port.sh" << PORTEOF
#!/bin/bash
# ${display_name} 端口管理脚本
# 支持查看、修改、添加、删除端口

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="\$SCRIPT_DIR/../lib"

if [ -f "\$LIB_DIR/common.sh" ]; then
    source "\$LIB_DIR/common.sh"
fi

SERVICE_NAME="${service}"
SOFTWARE_NAME="${software}"
DISPLAY_NAME="${display_name}"
DEFAULT_PORTS="${default_ports}"
SCRIPT_DIR_REF="\$SCRIPT_DIR"

# 端口配置文件
PORT_CONFIG_FILE="\$SCRIPT_DIR/ports.conf"

# 读取端口配置
get_ports() {
    if [ -f "\$PORT_CONFIG_FILE" ]; then
        cat "\$PORT_CONFIG_FILE"
    else
        echo "\$DEFAULT_PORTS"
    fi
}

# 显示当前端口
show_ports() {
    echo -e "\${BLUE}=== \${DISPLAY_NAME} 端口配置 ===\${NC}"
    local ports=\$(get_ports)
    echo "  监听端口: \$ports"
    echo ""

    # 查找正在监听的端口
    echo -e "\${BLUE}=== 正在监听的端口 ===\${NC}"
    if command -v ss &>/dev/null; then
        ss -tuln | grep -E ":\${ports//,/|:}" || echo "  未找到相关监听端口"
    elif command -v netstat &>/dev/null; then
        netstat -tuln | grep -E ":\${ports//,/|:}" || echo "  未找到相关监听端口"
    else
        echo "  系统工具不可用"
    fi
}

# 修改端口
change_port() {
    local old_port=\$1
    local new_port=\$2

    if [ -z "\$old_port" ] || [ -z "\$new_port" ]; then
        print_error "用法: \$0 change <旧端口> <新端口>"
        return 1
    fi

    if ! [[ "\$new_port" =~ ^[0-9]+\$ ]] || [ "\$new_port" -lt 1 ] || [ "\$new_port" -gt 65535 ]; then
        print_error "新端口必须在 1-65535 之间"
        return 1
    fi

    # 查找配置文件
    local config_files=()
    case "\$SOFTWARE_NAME" in
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
            config_files=(/etc/\${SERVICE_NAME}/\${SERVICE_NAME}.conf)
            ;;
    esac

    print_info "备份配置文件..."
    bash "\$SCRIPT_DIR_REF/backup.sh"

    print_info "尝试修改端口..."
    for config_file in "\${config_files[@]}"; do
        if [ -f "\$config_file" ]; then
            print_info "  修改 \$config_file"
            if sed -i "s/\b\${old_port}\b/\${new_port}/g" "\$config_file" 2>/dev/null; then
                print_success "  已修改"
            fi
        fi
    done

    # 更新端口配置
    local ports=\$(get_ports)
    ports=\${ports/\${old_port}/\${new_port}}
    echo "\$ports" > "\$PORT_CONFIG_FILE"

    print_success "端口已更新: \$old_port -> \$new_port"
    print_warning "请重启 \${DISPLAY_NAME} 服务以使配置生效"

    if command -v systemctl &>/dev/null; then
        if confirm "是否立即重启 \${DISPLAY_NAME}?"; then
            systemctl restart "\${SERVICE_NAME}" 2>/dev/null || true
        fi
    fi
}

# 设置端口
set_ports() {
    local ports=\$1
    if [ -z "\$ports" ]; then
        print_error "用法: \$0 set <端口1,端口2,...>"
        return 1
    fi

    echo "\$ports" > "\$PORT_CONFIG_FILE"
    print_success "端口配置已更新: \$ports"
    print_warning "请手动修改配置文件以应用新端口"
}

# 添加端口
add_port() {
    local new_port=\$1
    if [ -z "\$new_port" ]; then
        print_error "用法: \$0 add <端口>"
        return 1
    fi

    local ports=\$(get_ports)
    if [[ ",\$ports," == *",\${new_port},"* ]]; then
        print_warning "端口 \$new_port 已存在"
        return 0
    fi

    ports="\${ports:+\${ports},}\${new_port}"
    echo "\$ports" > "\$PORT_CONFIG_FILE"
    print_success "端口已添加: \$new_port"
}

# 删除端口
remove_port() {
    local port=\$1
    if [ -z "\$port" ]; then
        print_error "用法: \$0 remove <端口>"
        return 1
    fi

    local ports=\$(get_ports)
    ports=\$(echo "\$ports" | sed "s/,\?\$port,\?/," | sed 's/^,\|,\$//g')
    echo "\$ports" > "\$PORT_CONFIG_FILE"
    print_success "端口已删除: \$port"
}

case "\${1:-show}" in
    show|list)
        show_ports
        ;;
    change|modify)
        change_port "\$2" "\$3"
        ;;
    set)
        set_ports "\$2"
        ;;
    add)
        add_port "\$2"
        ;;
    remove|rm|del)
        remove_port "\$2"
        ;;
    *)
        show_ports
        echo ""
        echo "用法: \$0 {show|change <旧端口> <新端口>|set <端口列表>|add <端口>|remove <端口>}"
        ;;
esac
PORTEOF

    # 4. 生成 backup.sh
    cat > "$target_dir/backup.sh" << BACKUPEOF
#!/bin/bash
# ${display_name} 备份脚本
# 支持配置、数据、日志的备份

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="\$SCRIPT_DIR/../lib"

if [ -f "\$LIB_DIR/common.sh" ]; then
    source "\$LIB_DIR/common.sh"
fi

SERVICE_NAME="${service}"
SOFTWARE_NAME="${software}"
DISPLAY_NAME="${display_name}"
SCRIPT_DIR_REF="\$SCRIPT_DIR"

BACKUP_ROOT="/var/backups/shell-utils/\${SOFTWARE_NAME}"
TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="\$BACKUP_ROOT/backup_\$TIMESTAMP"

# 备份类型: config, data, log, all
BACKUP_TYPE="\${1:-all}"

# 备份配置文件
backup_config() {
    print_info "备份 \${DISPLAY_NAME} 配置文件..."

    local config_dir="\$BACKUP_DIR/config"
    mkdir -p "\$config_dir"

    case "\$SOFTWARE_NAME" in
        nginx)
            [ -d /etc/nginx ] && cp -r /etc/nginx "\$config_dir/" 2>/dev/null
            ;;
        apache)
            [ -d /etc/httpd ] && cp -r /etc/httpd "\$config_dir/" 2>/dev/null
            [ -d /etc/apache2 ] && cp -r /etc/apache2 "\$config_dir/" 2>/dev/null
            ;;
        mysql|mariadb)
            [ -d /etc/my.cnf.d ] && cp -r /etc/my.cnf.d "\$config_dir/" 2>/dev/null
            [ -d /etc/mysql ] && cp -r /etc/mysql "\$config_dir/" 2>/dev/null
            [ -f /etc/my.cnf ] && cp /etc/my.cnf "\$config_dir/" 2>/dev/null
            ;;
        redis)
            [ -f /etc/redis/redis.conf ] && cp /etc/redis/redis.conf "\$config_dir/"
            [ -d /etc/redis ] && cp -r /etc/redis "\$config_dir/" 2>/dev/null
            ;;
        *)
            [ -d /etc/\${SERVICE_NAME} ] && cp -r /etc/\${SERVICE_NAME} "\$config_dir/" 2>/dev/null
            ;;
    esac

    print_success "配置备份完成: \$config_dir"
}

# 备份数据
backup_data() {
    print_info "备份 \${DISPLAY_NAME} 数据..."

    local data_dir="\$BACKUP_DIR/data"
    mkdir -p "\$data_dir"

    case "\$SOFTWARE_NAME" in
        mysql)
            if command -v mysqldump &>/dev/null; then
                mysqldump --all-databases --single-transaction 2>/dev/null | gzip > "\$data_dir/mysql_all_\$TIMESTAMP.sql.gz"
                print_success "MySQL 数据备份完成"
            fi
            ;;
        mariadb)
            if command -v mariadb-dump &>/dev/null; then
                mariadb-dump --all-databases --single-transaction 2>/dev/null | gzip > "\$data_dir/mariadb_all_\$TIMESTAMP.sql.gz"
                print_success "MariaDB 数据备份完成"
            fi
            ;;
        mongodb)
            if command -v mongodump &>/dev/null; then
                mongodump --archive="\$data_dir/mongodb_\$TIMESTAMP.archive" --gzip 2>/dev/null
                print_success "MongoDB 数据备份完成"
            fi
            ;;
        redis)
            if [ -f /var/lib/redis/dump.rdb ]; then
                cp /var/lib/redis/dump.rdb "\$data_dir/redis_\$TIMESTAMP.rdb"
                print_success "Redis 数据备份完成"
            fi
            ;;
        *)
            print_info "  无需特别数据备份"
            ;;
    esac
}

# 备份日志
backup_log() {
    print_info "备份 \${DISPLAY_NAME} 日志..."

    local log_dir="\$BACKUP_DIR/log"
    mkdir -p "\$log_dir"

    case "\$SOFTWARE_NAME" in
        nginx)
            [ -d /var/log/nginx ] && cp -r /var/log/nginx "\$log_dir/" 2>/dev/null
            ;;
        apache)
            [ -d /var/log/httpd ] && cp -r /var/log/httpd "\$log_dir/" 2>/dev/null
            [ -d /var/log/apache2 ] && cp -r /var/log/apache2 "\$log_dir/" 2>/dev/null
            ;;
        mysql|mariadb)
            [ -d /var/log/mariadb ] && cp -r /var/log/mariadb "\$log_dir/" 2>/dev/null
            [ -d /var/log/mysql ] && cp -r /var/log/mysql "\$log_dir/" 2>/dev/null
            ;;
        *)
            [ -d /var/log/\${SERVICE_NAME} ] && cp -r /var/log/\${SERVICE_NAME} "\$log_dir/" 2>/dev/null
            ;;
    esac

    print_success "日志备份完成"
}

# 主备份函数
do_backup() {
    mkdir -p "\$BACKUP_ROOT"
    mkdir -p "\$BACKUP_DIR"

    print_info "开始备份 \${DISPLAY_NAME} (\$BACKUP_TYPE)..."
    print_info "备份目录: \$BACKUP_DIR"

    case "\$BACKUP_TYPE" in
        config)
            backup_config
            ;;
        data)
            backup_data
            ;;
        log)
            backup_log
            ;;
        all|*)
            backup_config
            backup_data
            backup_log
            ;;
    esac

    # 创建备份信息文件
    cat > "\$BACKUP_DIR/backup.info" <<INFOEOF
软件名称: \${DISPLAY_NAME}
软件包名: \${SOFTWARE_NAME}
服务名称: \${SERVICE_NAME}
备份时间: \$(date '+%Y-%m-%d %H:%M:%S')
备份类型: \${BACKUP_TYPE}
主机名: \$(hostname)
INFOEOF

    # 打包
    local backup_archive="\$BACKUP_ROOT/backup_\${TIMESTAMP}.tar.gz"
    tar czf "\$backup_archive" -C "\$BACKUP_ROOT" "backup_\$TIMESTAMP" 2>/dev/null
    rm -rf "\$BACKUP_DIR"

    if [ -f "\$backup_archive" ]; then
        local size=\$(du -h "\$backup_archive" | cut -f1)
        print_success "备份完成: \$backup_archive (大小: \$size)"
        echo "\$backup_archive"
    else
        print_error "备份失败"
        return 1
    fi
}

# 列出备份
list_backups() {
    print_info "\${DISPLAY_NAME} 的备份列表:"
    echo ""

    if [ -d "\$BACKUP_ROOT" ]; then
        local backups=\$(ls -lt "\$BACKUP_ROOT"/backup_*.tar.gz 2>/dev/null)
        if [ -z "\$backups" ]; then
            echo "  暂无备份"
        else
            echo "\$backups" | head -20 | while read -r backup; do
                local size=\$(du -h "\$backup" | cut -f1)
                local time=\$(stat -c %y "\$backup" 2>/dev/null | cut -d. -f1)
                echo "  \$backup"
                echo "    大小: \$size, 时间: \$time"
            done
        fi
    else
        echo "  备份目录不存在: \$BACKUP_ROOT"
    fi
}

case "\${1:-all}" in
    all|config|data|log)
        do_backup
        ;;
    list|ls)
        list_backups
        ;;
    *)
        print_error "未知类型: \$1"
        echo "用法: \$0 {all|config|data|log|list}"
        ;;
esac
BACKUPEOF

    # 5. 生成 restore.sh
    cat > "$target_dir/restore.sh" << RESTOREEOF
#!/bin/bash
# ${display_name} 恢复脚本
# 从备份文件恢复配置、数据或日志

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="\$SCRIPT_DIR/../lib"

if [ -f "\$LIB_DIR/common.sh" ]; then
    source "\$LIB_DIR/common.sh"
fi

SERVICE_NAME="${service}"
SOFTWARE_NAME="${software}"
DISPLAY_NAME="${display_name}"
SCRIPT_DIR_REF="\$SCRIPT_DIR"

BACKUP_ROOT="/var/backups/shell-utils/\${SOFTWARE_NAME}"

# 恢复备份
do_restore() {
    local backup_file="\$1"

    if [ -z "\$backup_file" ]; then
        print_error "请指定备份文件"
        return 1
    fi

    if [ ! -f "\$backup_file" ]; then
        # 尝试在备份目录中查找
        if [ -f "\$BACKUP_ROOT/\$backup_file" ]; then
            backup_file="\$BACKUP_ROOT/\$backup_file"
        else
            print_error "备份文件不存在: \$backup_file"
            return 1
        fi
    fi

    if ! confirm "确认从 \$(basename \$backup_file) 恢复?"; then
        print_info "取消恢复"
        return 0
    fi

    # 停止服务
    if command -v systemctl &>/dev/null && systemctl is-active --quiet "\${SERVICE_NAME}" 2>/dev/null; then
        print_info "停止服务 \${SERVICE_NAME}..."
        systemctl stop "\${SERVICE_NAME}" || true
    fi

    # 创建临时目录
    local temp_dir=\$(mktemp -d)
    print_info "解压备份文件..."
    if ! tar xzf "\$backup_file" -C "\$temp_dir" 2>/dev/null; then
        print_error "解压备份文件失败"
        rm -rf "\$temp_dir"
        return 1
    fi

    local extract_dir=\$(find "\$temp_dir" -maxdepth 1 -type d -name "backup_*" | head -1)
    if [ -z "\$extract_dir" ]; then
        extract_dir="\$temp_dir/\$(ls \$temp_dir | head -1)"
    fi

    # 恢复配置
    if [ -d "\$extract_dir/config" ]; then
        print_info "恢复配置文件..."

        case "\$SOFTWARE_NAME" in
            nginx)
                [ -d "\$extract_dir/config/nginx" ] && cp -r "\$extract_dir/config/nginx"/* /etc/nginx/ 2>/dev/null
                ;;
            apache)
                [ -d "\$extract_dir/config/httpd" ] && cp -r "\$extract_dir/config/httpd"/* /etc/httpd/ 2>/dev/null
                [ -d "\$extract_dir/config/apache2" ] && cp -r "\$extract_dir/config/apache2"/* /etc/apache2/ 2>/dev/null
                ;;
            mysql|mariadb)
                if [ -d "\$extract_dir/config/my.cnf.d" ]; then
                    cp -r "\$extract_dir/config/my.cnf.d"/* /etc/my.cnf.d/ 2>/dev/null
                fi
                if [ -d "\$extract_dir/config/mysql" ]; then
                    cp -r "\$extract_dir/config/mysql"/* /etc/mysql/ 2>/dev/null
                fi
                [ -f "\$extract_dir/config/my.cnf" ] && cp "\$extract_dir/config/my.cnf" /etc/my.cnf
                ;;
            *)
                if [ -d "\$extract_dir/config/\${SERVICE_NAME}" ]; then
                    cp -r "\$extract_dir/config/\${SERVICE_NAME}"/* /etc/\${SERVICE_NAME}/ 2>/dev/null
                fi
                ;;
        esac

        print_success "配置恢复完成"
    fi

    # 恢复数据
    if [ -d "\$extract_dir/data" ]; then
        print_info "恢复数据文件..."

        case "\$SOFTWARE_NAME" in
            mysql)
                if ls "\$extract_dir/data"/*.sql.gz &>/dev/null; then
                    local sql_file=\$(ls "\$extract_dir/data"/*.sql.gz | head -1)
                    gunzip < "\$sql_file" | mysql 2>/dev/null
                    print_success "MySQL 数据恢复完成"
                fi
                ;;
            mariadb)
                if ls "\$extract_dir/data"/*.sql.gz &>/dev/null; then
                    local sql_file=\$(ls "\$extract_dir/data"/*.sql.gz | head -1)
                    gunzip < "\$sql_file" | mariadb 2>/dev/null
                    print_success "MariaDB 数据恢复完成"
                fi
                ;;
            mongodb)
                if ls "\$extract_dir/data"/*.archive &>/dev/null; then
                    local archive_file=\$(ls "\$extract_dir/data"/*.archive | head -1)
                    mongorestore --archive="\$archive_file" --gzip 2>/dev/null
                    print_success "MongoDB 数据恢复完成"
                fi
                ;;
            redis)
                if ls "\$extract_dir/data"/*.rdb &>/dev/null; then
                    local rdb_file=\$(ls "\$extract_dir/data"/*.rdb | head -1)
                    cp "\$rdb_file" /var/lib/redis/dump.rdb
                    chown redis:redis /var/lib/redis/dump.rdb 2>/dev/null
                    print_success "Redis 数据恢复完成"
                fi
                ;;
        esac
    fi

    # 清理
    rm -rf "\$temp_dir"

    # 启动服务
    if command -v systemctl &>/dev/null; then
        print_info "启动服务 \${SERVICE_NAME}..."
        systemctl start "\${SERVICE_NAME}" || true
    fi

    print_success "恢复完成"
}

# 列出可用备份
list_available() {
    echo -e "\${BLUE}可用的备份:\${NC}"
    if [ -d "\$BACKUP_ROOT" ]; then
        ls -1 "\$BACKUP_ROOT"/backup_*.tar.gz 2>/dev/null | while read -r backup; do
            local size=\$(du -h "\$backup" | cut -f1)
            local time=\$(stat -c %y "\$backup" 2>/dev/null | cut -d. -f1)
            echo "  \$(basename \$backup) (\$size, \$time)"
        done
    else
        echo "  备份目录不存在"
    fi
}

case "\${1:-list}" in
    list|ls)
        list_available
        ;;
    *)
        do_restore "\$@"
        ;;
esac
RESTOREEOF

    # 6. 生成 healthcheck.sh
    cat > "$target_dir/healthcheck.sh" << HCEOF
#!/bin/bash
# ${display_name} 健康检查脚本
# 检查服务状态、端口、进程、资源使用等

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="\$SCRIPT_DIR/../lib"

if [ -f "\$LIB_DIR/common.sh" ]; then
    source "\$LIB_DIR/common.sh"
fi

SERVICE_NAME="${service}"
SOFTWARE_NAME="${software}"
DISPLAY_NAME="${display_name}"
SCRIPT_DIR_REF="\$SCRIPT_DIR"

# 检查结果
RESULT_OK=0
RESULT_FAIL=0
ISSUES=()

# 检查服务状态
check_service() {
    echo -e "\${BLUE}[1] 检查服务状态\${NC}"

    if ! command -v systemctl &>/dev/null; then
        echo -e "\${YELLOW}  ⚠ systemctl 不可用\${NC}"
        return
    fi

    if systemctl is-active --quiet "\${SERVICE_NAME}" 2>/dev/null; then
        echo -e "\${GREEN}  ✓ 服务 \${SERVICE_NAME} 正在运行\${NC}"

        # 显示运行时间
        local uptime=\$(systemctl show "\${SERVICE_NAME}" --property=ActiveEnterTimestamp 2>/dev/null | cut -d= -f2)
        if [ -n "\$uptime" ] && [ "\$uptime" != "" ]; then
            echo "    启动时间: \$uptime"
        fi
    else
        echo -e "\${RED}  ✗ 服务 \${SERVICE_NAME} 未运行\${NC}"
        ISSUES+=("服务未运行")
        RESULT_FAIL=\$((RESULT_FAIL + 1))
    fi
}

# 检查端口监听
check_ports() {
    echo -e "\${BLUE}[2] 检查端口监听\${NC}"

    local ports=\$(bash "\$SCRIPT_DIR_REF/port.sh" show 2>/dev/null | grep "监听端口" | awk '{print \$NF}' | tr ',' ' ')

    if [ -z "\$ports" ]; then
        echo -e "\${YELLOW}  ⚠ 未配置端口\${NC}"
        return
    fi

    local port_ok=0
    for port in \$ports; do
        if command -v ss &>/dev/null; then
            if ss -tuln | grep -q ":\${port} "; then
                echo -e "\${GREEN}  ✓ 端口 \$port 正在监听\${NC}"
                port_ok=\$((port_ok + 1))
            else
                echo -e "\${RED}  ✗ 端口 \$port 未监听\${NC}"
                ISSUES+=("端口 \$port 未监听")
                RESULT_FAIL=\$((RESULT_FAIL + 1))
            fi
        fi
    done

    if [ \$port_ok -gt 0 ]; then
        RESULT_OK=\$((RESULT_OK + 1))
    fi
}

# 检查进程
check_process() {
    echo -e "\${BLUE}[3] 检查进程\${NC}"

    if pgrep -x "\${SERVICE_NAME}" &>/dev/null; then
        local pids=\$(pgrep -x "\${SERVICE_NAME}" | tr '\n' ' ')
        local count=\$(echo "\$pids" | wc -w)
        echo -e "\${GREEN}  ✓ 进程运行中 (PID: \$pids, 数量: \$count)\${NC}"
        RESULT_OK=\$((RESULT_OK + 1))

        # 检查内存使用
        local mem=\$(ps -o rss= -p \$(echo \$pids | awk '{print \$1}') 2>/dev/null)
        if [ -n "\$mem" ]; then
            local mem_mb=\$((mem / 1024))
            echo "    内存使用: \${mem_mb}MB"
        fi
    else
        echo -e "\${RED}  ✗ 未找到进程\${NC}"
        ISSUES+=("进程未运行")
        RESULT_FAIL=\$((RESULT_FAIL + 1))
    fi
}

# 检查配置
check_config() {
    echo -e "\${BLUE}[4] 检查配置\${NC}"

    case "\$SOFTWARE_NAME" in
        nginx)
            if command -v nginx &>/dev/null; then
                if nginx -t &>/dev/null; then
                    echo -e "\${GREEN}  ✓ Nginx 配置正确\${NC}"
                    RESULT_OK=\$((RESULT_OK + 1))
                else
                    echo -e "\${RED}  ✗ Nginx 配置错误\${NC}"
                    ISSUES+=("配置错误")
                    RESULT_FAIL=\$((RESULT_FAIL + 1))
                fi
            fi
            ;;
        apache)
            if command -v apachectl &>/dev/null; then
                if apachectl configtest &>/dev/null; then
                    echo -e "\${GREEN}  ✓ Apache 配置正确\${NC}"
                    RESULT_OK=\$((RESULT_OK + 1))
                else
                    echo -e "\${RED}  ✗ Apache 配置错误\${NC}"
                    ISSUES+=("配置错误")
                    RESULT_FAIL=\$((RESULT_FAIL + 1))
                fi
            fi
            ;;
        *)
            echo "  - 跳过配置检查"
            ;;
    esac
}

# 检查磁盘空间
check_disk() {
    echo -e "\${BLUE}[5] 检查磁盘空间\${NC}"

    local usage=\$(df / | tail -1 | awk '{print \$5}' | sed 's/%//')
    if [ "\$usage" -lt 80 ]; then
        echo -e "\${GREEN}  ✓ 磁盘空间充足 (\${usage}%)\${NC}"
        RESULT_OK=\$((RESULT_OK + 1))
    elif [ "\$usage" -lt 90 ]; then
        echo -e "\${YELLOW}  ⚠ 磁盘空间一般 (\${usage}%)\${NC}"
    else
        echo -e "\${RED}  ✗ 磁盘空间不足 (\${usage}%)\${NC}"
        ISSUES+=("磁盘空间不足")
        RESULT_FAIL=\$((RESULT_FAIL + 1))
    fi
}

# 输出总结
print_summary() {
    echo ""
    echo -e "\${CYAN}========================================\${NC}"
    echo -e "\${CYAN}  \${DISPLAY_NAME} 健康检查总结\${NC}"
    echo -e "\${CYAN}========================================\${NC}"
    echo ""
    echo -e "  通过项: \${GREEN}\${RESULT_OK}\${NC}"
    echo -e "  失败项: \${RED}\${RESULT_FAIL}\${NC}"

    if [ \${#ISSUES[@]} -gt 0 ]; then
        echo ""
        echo -e "\${YELLOW}问题列表:\${NC}"
        for issue in "\${ISSUES[@]}"; do
            echo "  - \$issue"
        done
    fi

    echo ""
    if [ \${RESULT_FAIL} -eq 0 ]; then
        echo -e "\${GREEN}✓ 健康检查通过\${NC}"
        return 0
    else
        echo -e "\${RED}✗ 健康检查发现问题\${NC}"
        return 1
    fi
}

# 主函数
main() {
    print_header "\${DISPLAY_NAME} 健康检查"
    echo ""

    check_service
    check_ports
    check_process
    check_config
    check_disk

    print_summary
}

main
HCEOF

    # 7. 生成 uninstall.sh
    cat > "$target_dir/uninstall.sh" << UNINSTALLEOF
#!/bin/bash
# ${display_name} 卸载脚本
# 支持完全卸载或仅移除软件包

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="\$SCRIPT_DIR/../lib"

if [ -f "\$LIB_DIR/common.sh" ]; then
    source "\$LIB_DIR/common.sh"
fi

SERVICE_NAME="${service}"
SOFTWARE_NAME="${software}"
DISPLAY_NAME="${display_name}"
SCRIPT_DIR_REF="\$SCRIPT_DIR"

# 完整卸载（默认）
COMPLETE=true
PURGE_DATA=false

# 解析参数
while [[ \$# -gt 0 ]]; do
    case \$1 in
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
    if [ -x "\$SCRIPT_DIR_REF/backup.sh" ]; then
        bash "\$SCRIPT_DIR_REF/backup.sh" all
        print_success "备份完成"
    fi
}

# 停止服务
stop_service() {
    if command -v systemctl &>/dev/null && systemctl list-unit-files | grep -q "\${SERVICE_NAME}.service"; then
        print_info "停止服务 \${SERVICE_NAME}..."
        systemctl stop "\${SERVICE_NAME}" 2>/dev/null || true
        systemctl disable "\${SERVICE_NAME}" 2>/dev/null || true
        print_success "服务已停止"
    fi
}

# 卸载软件包
uninstall_package() {
    print_info "卸载 \${DISPLAY_NAME} 软件包..."

    if command -v apt &>/dev/null; then
        apt remove -y --purge "\${SERVICE_NAME}" 2>/dev/null || true
        apt autoremove -y 2>/dev/null || true
    elif command -v dnf &>/dev/null; then
        dnf remove -y "\${SERVICE_NAME}" 2>/dev/null || true
    elif command -v yum &>/dev/null; then
        yum remove -y "\${SERVICE_NAME}" 2>/dev/null || true
    fi

    print_success "软件包已卸载"
}

# 清理配置
cleanup_config() {
    if [ "\$COMPLETE" = false ]; then
        return
    fi

    print_info "清理配置文件..."

    case "\$SOFTWARE_NAME" in
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
            rm -rf /etc/\${SERVICE_NAME} 2>/dev/null
            ;;
    esac

    print_success "配置已清理"
}

# 清理数据
cleanup_data() {
    if [ "\$PURGE_DATA" = false ]; then
        return
    fi

    print_info "清理数据文件..."
    read -p "  确认删除所有数据吗? [y/N] " confirm
    if [[ "\$confirm" =~ ^[Yy]\$ ]]; then
        case "\$SOFTWARE_NAME" in
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
                rm -rf /var/lib/\${SERVICE_NAME} 2>/dev/null
                ;;
        esac
        print_success "数据已清理"
    else
        print_info "  跳过数据清理"
    fi
}

# 清理日志
cleanup_logs() {
    if [ "\$COMPLETE" = false ]; then
        return
    fi

    case "\$SOFTWARE_NAME" in
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
            rm -rf /var/log/\${SERVICE_NAME} 2>/dev/null
            ;;
    esac
}

# 清理备份
cleanup_backups() {
    read -p "  是否删除所有备份? [y/N] " confirm
    if [[ "\$confirm" =~ ^[Yy]\$ ]]; then
        rm -rf /var/backups/shell-utils/\${SOFTWARE_NAME} 2>/dev/null
        print_success "备份已清理"
    fi
}

# 打开防火墙端口
close_firewall() {
    case "\$SOFTWARE_NAME" in
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
    print_header "卸载 \${DISPLAY_NAME}"
    echo ""

    print_warning "即将卸载 \${DISPLAY_NAME}"
    echo "  选项:"
    echo "    --keep-data     保留数据文件"
    echo "    --purge-data    清理所有数据"
    echo "    --only-package  仅卸载软件包，保留配置和数据"
    echo ""

    if ! confirm "确认卸载 \${DISPLAY_NAME}?"; then
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
    print_success "\${DISPLAY_NAME} 卸载完成"
}

main "\$@"
UNINSTALLEOF

    # 8. 生成 info.sh
    cat > "$target_dir/info.sh" << INFOEOF
#!/bin/bash
# ${display_name} 信息查看脚本

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="\$SCRIPT_DIR/../lib"

if [ -f "\$LIB_DIR/common.sh" ]; then
    source "\$LIB_DIR/common.sh"
fi

SERVICE_NAME="${service}"
SOFTWARE_NAME="${software}"
DISPLAY_NAME="${display_name}"
SCRIPT_DIR_REF="\$SCRIPT_DIR"

print_header "\${DISPLAY_NAME} 信息"
echo ""

echo -e "\${BLUE}基本信息\${NC}"
echo "  软件名称: \${DISPLAY_NAME}"
echo "  包名: \${SOFTWARE_NAME}"
echo "  服务名: \${SERVICE_NAME}"
echo ""

echo -e "\${BLUE}安装状态\${NC}"
if command -v \${SERVICE_NAME} &>/dev/null; then
    echo -e "  状态: \${GREEN}已安装\${NC}"
    local version=\$(\${SERVICE_NAME} --version 2>&1 | head -1 || echo "未知")
    echo "  版本: \$version"
    local path=\$(which \${SERVICE_NAME})
    echo "  路径: \$path"
else
    echo -e "  状态: \${RED}未安装\${NC}"
fi
echo ""

echo -e "\${BLUE}服务状态\${NC}"
if command -v systemctl &>/dev/null; then
    if systemctl is-active --quiet "\${SERVICE_NAME}" 2>/dev/null; then
        echo -e "  服务: \${GREEN}运行中\${NC}"
        local uptime=\$(systemctl show "\${SERVICE_NAME}" --property=ActiveEnterTimestamp 2>/dev/null | cut -d= -f2)
        echo "  启动时间: \$uptime"
    else
        echo -e "  服务: \${RED}未运行\${NC}"
    fi

    if systemctl is-enabled --quiet "\${SERVICE_NAME}" 2>/dev/null; then
        echo "  开机启动: 是"
    else
        echo "  开机启动: 否"
    fi
else
    echo "  systemctl 不可用"
fi
echo ""

echo -e "\${BLUE}端口信息\${NC}"
bash "\$SCRIPT_DIR_REF/port.sh" show 2>/dev/null
echo ""

echo -e "\${BLUE}配置目录\${NC}"
case "\$SOFTWARE_NAME" in
    nginx)
        echo "  配置: /etc/nginx/"
        echo "  日志: /var/log/nginx/"
        ;;
    apache)
        echo "  配置: /etc/httpd/ 或 /etc/apache2/"
        echo "  日志: /var/log/httpd/ 或 /var/log/apache2/"
        ;;
    mysql|mariadb)
        echo "  配置: /etc/mysql/ 或 /etc/my.cnf"
        echo "  数据: /var/lib/mysql/"
        echo "  日志: /var/log/mysql/ 或 /var/log/mariadb/"
        ;;
    redis)
        echo "  配置: /etc/redis/"
        echo "  数据: /var/lib/redis/"
        echo "  日志: /var/log/redis/"
        ;;
    *)
        echo "  配置: /etc/\${SERVICE_NAME}/"
        ;;
esac
echo ""

echo -e "\${BLUE}备份列表\${NC}"
bash "\$SCRIPT_DIR_REF/backup.sh" list 2>/dev/null
INFOEOF

    # 9. 生成默认 config 文件
    cat > "$target_dir/config" << CONFIGEOF
# ${display_name} 配置文件
# 软件标识
SOFTWARE_NAME="${software}"
SERVICE_NAME="${service}"
DISPLAY_NAME="${display_name}"

# 默认端口（多个用逗号分隔）
DEFAULT_PORTS="${default_ports}"

# 其他配置
BACKUP_ROOT="/var/backups/shell-utils/\${SOFTWARE_NAME}"
CONFIGEOF

    # 设置可执行权限
    chmod +x "$target_dir/install.sh" \
            "$target_dir/version.sh" \
            "$target_dir/port.sh" \
            "$target_dir/backup.sh" \
            "$target_dir/restore.sh" \
            "$target_dir/healthcheck.sh" \
            "$target_dir/uninstall.sh" \
            "$target_dir/info.sh" 2>/dev/null

    echo "  ✓ ${software} 脚本集生成完成"
}

# 主函数
main() {
    echo "========================================"
    echo "  生成标准化软件脚本集"
    echo "========================================"
    echo ""

    for software in "${!SOFTWARE_LIST[@]}"; do
        generate_software_scripts "$software" "${SOFTWARE_LIST[$software]}"
    done

    echo ""
    echo "========================================"
    echo "  生成完成"
    echo "========================================"
    echo ""
    echo "每个软件现在都包含以下脚本:"
    echo "  - install.sh     安装脚本"
    echo "  - version.sh     版本管理"
    echo "  - port.sh        端口管理"
    echo "  - backup.sh      备份"
    echo "  - restore.sh     恢复"
    echo "  - healthcheck.sh 健康检查"
    echo "  - uninstall.sh   卸载"
    echo "  - info.sh        信息查看"
    echo "  - config         默认配置"
    echo ""
}

main "$@"
