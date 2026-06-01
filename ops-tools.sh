#!/bin/bash

# =========================================
# CentOS 8 运维工具箱
# 包含：监控、SSL、备份、清理等功能
# =========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 检查 root 权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}错误：请使用 root 用户运行此脚本${NC}"
        echo "使用方法: sudo $0 <命令>"
        exit 1
    fi
}

# 显示帮助
show_help() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   CentOS 8 运维工具箱${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${YELLOW}使用语法：${NC}"
    echo "  curl ... | sudo bash -s -- <命令>"
    echo "  或"
    echo "  sudo ./ops-tools.sh <命令>"
    echo ""
    echo -e "${YELLOW}监控管理命令：${NC}"
    echo "  monitor_install    - 安装监控系统"
    echo "  monitor_start      - 启动监控"
    echo "  monitor_status     - 查看监控状态"
    echo "  monitor_stop       - 停止监控"
    echo "  sysmon             - 实时系统监控（终端界面）"
    echo ""
    echo -e "${YELLOW}SSL 证书命令：${NC}"
    echo "  ssl_cert <域名>    - 为域名申请 Let's Encrypt 证书"
    echo "  ssl_renew          - 续期所有证书"
    echo "  ssl_list           - 列出所有证书"
    echo "  ssl_delete <域名>  - 删除指定证书"
    echo ""
    echo -e "${YELLOW}备份管理命令：${NC}"
    echo "  backup_files       - 备份重要文件"
    echo "  backup_db          - 备份所有数据库"
    echo "  backup_all         - 完整备份（文件+数据库）"
    echo "  restore_db         - 恢复数据库"
    echo "  backup_auto        - 配置自动备份"
    echo ""
    echo -e "${YELLOW}系统清理命令：${NC}"
    echo "  cleanup_kernel     - 清理旧内核"
    echo "  cleanup_log        - 清理日志文件"
    echo "  cleanup_cache      - 清理缓存"
    echo "  cleanup_all        - 完整系统清理"
    echo "  cleanup_check      - 检查可清理空间"
    echo ""
    echo -e "${YELLOW}示例：${NC}"
    echo "  curl ... | sudo bash -s -- monitor_install"
    echo "  curl ... | sudo bash -s -- ssl_cert example.com"
    echo "  curl ... | sudo bash -s -- backup_all"
    echo "  curl ... | sudo bash -s -- cleanup_all"
    echo ""
}

# ==========================================
# 第一部分：系统监控
# ==========================================

install_monitor() {
    check_root
    echo -e "${BLUE}正在安装监控系统...${NC}"
    
    # 安装 Prometheus
    echo -e "${YELLOW}安装 Prometheus...${NC}"
    useradd --no-create-home --shell /bin/false prometheus 2>/dev/null || true
    
    cd /tmp
    wget -q https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
    tar xzf prometheus-2.45.0.linux-amd64.tar.gz
    mv prometheus-2.45.0.linux-amd64 /opt/prometheus
    ln -sf /opt/prometheus /usr/local/bin/prometheus
    
    mkdir -p /etc/prometheus /var/lib/prometheus
    cp /opt/prometheus/prometheus.yml /etc/prometheus/
    chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus /opt/prometheus
    
    # 创建 Prometheus 服务
    cat > /etc/systemd/system/prometheus.service << 'EOF'
[Unit]
Description=Prometheus Monitoring
After=network.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus/ \
    --web.console.libraries=/opt/prometheus/consoles \
    --web.console.templates=/opt/prometheus/consoles
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    
    # 安装 Node Exporter (系统监控)
    echo -e "${YELLOW}安装 Node Exporter...${NC}"
    cd /tmp
    wget -q https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
    tar xzf node_exporter-1.6.1.linux-amd64.tar.gz
    mv node_exporter-1.6.1.linux-amd64 /opt/node_exporter
    ln -sf /opt/node_exporter/node_exporter /usr/local/bin/node_exporter
    
    cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
After=network.target

[Service]
ExecStart=/usr/local/bin/node_exporter/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载 systemd
    systemctl daemon-reload
    
    # 启动服务
    systemctl start node_exporter
    systemctl enable node_exporter
    systemctl start prometheus
    systemctl enable prometheus
    
    cd ~
    rm -rf /tmp/prometheus* /tmp/node_exporter*
    
    echo -e "${GREEN}✓ 监控系统安装完成${NC}"
    echo ""
    echo "服务状态："
    systemctl status prometheus --no-pager | grep -E "Active:|● "
    systemctl status node_exporter --no-pager | grep -E "Active:|● "
    echo ""
    echo "访问地址："
    echo "  Prometheus: http://your_server_ip:9090"
    echo "  Node Exporter: http://your_server_ip:9100"
}

# 实时系统监控
sysmon() {
    echo -e "${BLUE}实时系统监控（按 Ctrl+C 退出）${NC}"
    echo ""
    
    while true; do
        clear
        echo -e "${CYAN}========================================${NC}"
        echo -e "${CYAN}   系统实时监控$(date '+%Y-%m-%d %H:%M:%S')${NC}"
        echo -e "${CYAN}========================================${NC}"
        echo ""
        
        # 系统信息
        echo -e "${YELLOW}【系统信息】${NC}"
        echo "  主机名: $(hostname)"
        echo "  运行时间: $(uptime -p)"
        echo "  负载: $(uptime | awk -F'load average:' '{print $2}')"
        echo ""
        
        # CPU 使用
        echo -e "${YELLOW}【CPU 使用】${NC}"
        top -bn1 | head -5 | tail -4 | awk '{printf "  %s %s %s%%\n", $2, $4, $9}'
        echo ""
        
        # 内存使用
        echo -e "${YELLOW}【内存使用】${NC}"
        free -h | awk 'NR==2 {printf "  总计: %s | 已用: %s | 空闲: %s | 使用率: %.1f%%\n", $2, $3, $4, ($3/$2)*100}'
        echo ""
        
        # 磁盘使用
        echo -e "${YELLOW}【磁盘使用】${NC}"
        df -h | grep -E '^/dev/' | awk '{printf "  %s: %s / %s (%.0f%%)\n", $1, $3, $2, $5+0}'
        echo ""
        
        # 网络连接
        echo -e "${YELLOW}【网络连接】${NC}"
        echo "  SSH 连接数: $(who | wc -l)"
        echo "  网络连接数: $(netstat -an 2>/dev/null | grep ESTABLISHED | wc -l)"
        echo "  总连接数: $(netstat -an 2>/dev/null | grep -c tcp)"
        echo ""
        
        # Top 5 进程
        echo -e "${YELLOW}【Top 5 进程（CPU）】${NC}"
        ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "  %-10s %6s%% %6s%% %s\n", $11, $3, $4, $1}'
        echo ""
        
        # Top 5 进程（内存）
        echo -e "${YELLOW}【Top 5 进程（内存）】${NC}"
        ps aux --sort=-%mem | head -6 | tail -5 | awk '{printf "  %-10s %6s%% %6s%% %s\n", $11, $3, $4, $1}'
        echo ""
        
        # 服务状态
        echo -e "${YELLOW}【关键服务状态】${NC}"
        for service in nginx httpd mysqld mariadb redis docker php-fpm; do
            if systemctl is-active $service &>/dev/null; then
                status="${GREEN}● 运行中${NC}"
            else
                status="${RED}○ 已停止${NC}"
            fi
            printf "  %-15s %s\n" "$service" "$status"
        done
        echo ""
        
        sleep 3
    done
}

start_monitor() {
    check_root
    systemctl start prometheus node_exporter
    systemctl enable prometheus node_exporter
    echo -e "${GREEN}✓ 监控服务已启动${NC}"
}

stop_monitor() {
    check_root
    systemctl stop prometheus node_exporter
    echo -e "${GREEN}✓ 监控服务已停止${NC}"
}

monitor_status() {
    echo -e "${BLUE}监控服务状态：${NC}"
    systemctl status prometheus --no-pager | grep -E "Active:|● |Main PID"
    echo ""
    systemctl status node_exporter --no-pager | grep -E "Active:|● |Main PID"
    echo ""
    echo "访问地址："
    echo "  Prometheus: http://your_server_ip:9090"
    echo "  Node Exporter: http://your_server_ip:9100"
}

# ==========================================
# 第二部分：SSL 证书管理
# ==========================================

install_certbot() {
    check_root
    echo -e "${BLUE}正在安装 Certbot...${NC}"
    dnf install -y epel-release
    dnf install -y certbot python3-certbot-nginx python3-certbot-apache
    echo -e "${GREEN}✓ Certbot 安装完成${NC}"
}

ssl_cert() {
    local domain=$1
    check_root
    
    if [ -z "$domain" ]; then
        echo -e "${RED}错误：请提供域名${NC}"
        echo "使用方法: $0 ssl_cert example.com"
        exit 1
    fi
    
    echo -e "${BLUE}正在为 ${domain} 申请 SSL 证书...${NC}"
    
    # 安装 Certbot
    install_certbot
    
    # 申请证书
    if command -v nginx &>/dev/null; then
        certbot --nginx -d $domain --non-interactive --agree-tos -m admin@$domain
    elif command -v httpd &>/dev/null; then
        certbot --apache -d $domain --non-interactive --agree-tos -m admin@$domain
    else
        certbot certonly --standalone -d $domain --non-interactive --agree-tos -m admin@$domain
    fi
    
    echo -e "${GREEN}✓ SSL 证书申请完成${NC}"
    echo ""
    echo "证书位置："
    echo "  证书: /etc/letsencrypt/live/$domain/fullchain.pem"
    echo "  密钥: /etc/letsencrypt/live/$domain/privkey.pem"
}

ssl_renew() {
    check_root
    echo -e "${BLUE}续期所有 SSL 证书...${NC}"
    certbot renew --quiet
    systemctl restart nginx httpd 2>/dev/null || true
    echo -e "${GREEN}✓ 证书续期完成${NC}"
}

ssl_list() {
    echo -e "${BLUE}已申请的 SSL 证书：${NC}"
    if [ -d /etc/letsencrypt/live ]; then
        ls -1 /etc/letsencrypt/live/
    else
        echo "暂无证书"
    fi
}

ssl_delete() {
    local domain=$1
    check_root
    
    if [ -z "$domain" ]; then
        echo -e "${RED}错误：请提供域名${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}删除证书：${domain}${NC}"
    certbot delete --cert-name $domain
    echo -e "${GREEN}✓ 证书已删除${NC}"
}

# ==========================================
# 第三部分：自动备份
# ==========================================

BACKUP_DIR="/var/backups"
DB_BACKUP_DIR="$BACKUP_DIR/databases"
FILES_BACKUP_DIR="$BACKUP_DIR/files"

backup_files() {
    check_root
    echo -e "${BLUE}备份重要文件...${NC}"
    
    mkdir -p $FILES_BACKUP_DIR
    
    # 备份配置文件
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$FILES_BACKUP_DIR/configs_${timestamp}.tar.gz"
    
    tar czf $backup_file \
        /etc/nginx \
        /etc/httpd \
        /etc/mysql \
        /etc/mariadb \
        /etc/php* \
        /etc/redis \
        /var/www/html 2>/dev/null || true
    
    echo -e "${GREEN}✓ 配置文件已备份到：$backup_file${NC}"
    
    # 自动清理 7 天前的备份
    find $FILES_BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
    echo "已清理 7 天前的旧备份"
}

backup_db() {
    check_root
    echo -e "${BLUE}备份所有数据库...${NC}"
    
    mkdir -p $DB_BACKUP_DIR
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    # MySQL/MariaDB 备份
    if command -v mysql &>/dev/null; then
        echo "备份 MySQL/MariaDB..."
        mkdir -p $DB_BACKUP_DIR/mysql
        mysqldump --all-databases --single-transaction --quick --lock-tables=false \
            -uroot -p"$(cat /etc/mariadbroot.pass 2>/dev/null || echo '')" \
            > $DB_BACKUP_DIR/mysql/all_databases_${timestamp}.sql 2>/dev/null || \
        mysqldump --all-databases --single-transaction --quick --lock-tables=false \
            > $DB_BACKUP_DIR/mysql/all_databases_${timestamp}.sql
        
        gzip $DB_BACKUP_DIR/mysql/all_databases_${timestamp}.sql
        echo -e "${GREEN}✓ MySQL/MariaDB 已备份到：$DB_BACKUP_DIR/mysql/all_databases_${timestamp}.sql.gz${NC}"
    fi
    
    # PostgreSQL 备份
    if command -v pg_dumpall &>/dev/null; then
        echo "备份 PostgreSQL..."
        mkdir -p $DB_BACKUP_DIR/postgresql
        sudo -u postgres pg_dumpall > $DB_BACKUP_DIR/postgresql/all_postgres_${timestamp}.sql
        gzip $DB_BACKUP_DIR/postgresql/all_postgres_${timestamp}.sql
        echo -e "${GREEN}✓ PostgreSQL 已备份到：$DB_BACKUP_DIR/postgresql/all_postgres_${timestamp}.sql.gz${NC}"
    fi
    
    # 自动清理 7 天前的备份
    find $DB_BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
    echo "已清理 7 天前的旧备份"
}

backup_all() {
    check_root
    echo -e "${PURPLE}开始完整备份...${NC}"
    echo ""
    backup_files
    echo ""
    backup_db
    echo ""
    echo -e "${GREEN}✓ 完整备份完成！${NC}"
    echo "备份位置："
    echo "  文件备份: $FILES_BACKUP_DIR"
    echo "  数据库备份: $DB_BACKUP_DIR"
}

restore_db() {
    check_root
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        echo -e "${RED}错误：请提供备份文件${NC}"
        echo "最近的备份文件："
        ls -lh $DB_BACKUP_DIR/*/*.sql.gz 2>/dev/null | tail -5
        exit 1
    fi
    
    echo -e "${YELLOW}警告：即将恢复数据库！${NC}"
    read -p "确认恢复? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "已取消恢复操作"
        exit 0
    fi
    
    gunzip -c $backup_file | mysql -uroot
    echo -e "${GREEN}✓ 数据库恢复完成${NC}"
}

backup_auto() {
    check_root
    echo -e "${BLUE}配置自动备份...${NC}"
    
    # 创建备份脚本
    cat > /usr/local/bin/auto-backup.sh << 'EOF'
#!/bin/bash
# 自动备份脚本

BACKUP_DIR="/var/backups"
DB_BACKUP_DIR="$BACKUP_DIR/databases"
FILES_BACKUP_DIR="$BACKUP_DIR/files"

# 备份数据库
mkdir -p $DB_BACKUP_DIR
timestamp=$(date +%Y%m%d_%H%M%S)

if command -v mysqldump &>/dev/null; then
    mkdir -p $DB_BACKUP_DIR/mysql
    mysqldump --all-databases --single-transaction --quick --lock-tables=false > $DB_BACKUP_DIR/mysql/all_databases_${timestamp}.sql 2>/dev/null
    gzip $DB_BACKUP_DIR/mysql/all_databases_${timestamp}.sql
fi

# 清理旧备份（保留 30 天）
find $DB_BACKUP_DIR -name "*.sql.gz" -mtime +30 -delete
EOF
    
    chmod +x /usr/local/bin/auto-backup.sh
    
    # 添加定时任务
    echo "0 2 * * * /usr/local/bin/auto-backup.sh >> /var/log/backup.log 2>&1" >> /var/spool/cron/root
    
    systemctl restart crond
    
    echo -e "${GREEN}✓ 自动备份已配置${NC}"
    echo "备份时间：每天凌晨 2:00"
    echo "备份位置：$DB_BACKUP_DIR"
    echo "保留期限：30 天"
}

# ==========================================
# 第四部分：系统清理
# ==========================================

cleanup_check() {
    echo -e "${BLUE}检查可清理空间：${NC}"
    echo ""
    
    # 旧内核
    echo -e "${YELLOW}【旧内核】${NC}"
    current_kernel=$(uname -r)
    old_kernels=$(rpm -qa | grep kernel | grep -v $current_kernel | wc -l)
    echo "  当前内核: $current_kernel"
    echo "  旧内核数量: $old_kernels 个"
    if [ $old_kernels -gt 0 ]; then
        echo "  旧内核包:"
        rpm -qa | grep kernel | grep -v $current_kernel | awk '{printf "    %s\n", $0}'
        echo "  预计释放: $(rpm -qa | grep kernel | grep -v $current_kernel | xargs -I {} rpm -qf {} --queryformat '%{SIZE}\n' | awk '{sum+=$1} END {printf "%.2f MB\n", sum/1024/1024}')"
    fi
    
    # 日志文件
    echo ""
    echo -e "${YELLOW}【日志文件】${NC}"
    log_size=$(du -sh /var/log 2>/dev/null | awk '{print $1}')
    echo "  日志目录大小: $log_size"
    echo "  大日志文件:"
    find /var/log -name "*.gz" -o -name "*.log.*" 2>/dev/null | xargs -I {} ls -lh {} 2>/dev/null | awk '{printf "    %s %s\n", $5, $9}' | head -5
    
    # 缓存文件
    echo ""
    echo -e "${YELLOW}【缓存文件】${NC}"
    dnf_cache=$(du -sh /var/cache/dnf 2>/dev/null | awk '{print $1}')
    yum_cache=$(du -sh /var/cache/yum 2>/dev/null | awk '{print $1}')
    echo "  DNF 缓存: $dnf_cache"
    echo "  Yum 缓存: $yum_cache"
    
    # 临时文件
    echo ""
    echo -e "${YELLOW}【临时文件】${NC}"
    tmp_size=$(du -sh /tmp 2>/dev/null | awk '{print $1}')
    echo "  /tmp 目录: $tmp_size"
    
    # 总计
    echo ""
    total_cleanable=$(echo "$(rpm -qa | grep kernel | grep -v $(uname -r) | xargs -I {} rpm -qf {} --queryformat '%{SIZE}\n' 2>/dev/null | awk '{sum+=$1} END {print sum/1024/1024}')" | awk '{printf "%.2f", $1}')
    echo -e "${GREEN}【总计可清理】约 ${total_cleanable} MB${NC}"
}

cleanup_kernel() {
    check_root
    echo -e "${BLUE}清理旧内核...${NC}"
    
    current_kernel=$(uname -r)
    old_kernels=$(rpm -qa | grep kernel | grep -v $current_kernel)
    
    if [ -z "$old_kernels" ]; then
        echo "没有旧内核需要清理"
        return
    fi
    
    echo -e "${YELLOW}将删除以下旧内核：${NC}"
    echo "$old_kernels" | awk '{printf "  %s\n", $0}'
    
    read -p "确认删除? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "已取消"
        return
    fi
    
    rpm -e $old_kernels
    dnf install -y kernel-tools
    echo -e "${GREEN}✓ 旧内核清理完成${NC}"
}

cleanup_log() {
    check_root
    echo -e "${BLUE}清理日志文件...${NC}"
    
    # 清理压缩的旧日志
    find /var/log -name "*.gz" -mtime +7 -delete 2>/dev/null || true
    
    # 清理超过 100MB 的日志文件
    while IFS= read -r logfile; do
        if [ -f "$logfile" ]; then
            size=$(stat -c %s "$logfile" 2>/dev/null || echo 0)
            if [ $size -gt 104857600 ]; then  # 100MB
                echo "  清理: $logfile (${size}/104857600*100 | awk '{printf "%.1f", $1}%') MB)"
                > "$logfile"
            fi
        fi
    done < <(find /var/log -name "*.log" 2>/dev/null)
    
    # 清理 systemd 日志
    journalctl --vacuum-size=500M 2>/dev/null || true
    
    echo -e "${GREEN}✓ 日志清理完成${NC}"
}

cleanup_cache() {
    check_root
    echo -e "${BLUE}清理缓存...${NC}"
    
    # 清理 DNF/Yum 缓存
    dnf clean all
    
    # 清理 pip 缓存
    pip3 cache purge 2>/dev/null || true
    
    # 清理 npm 缓存
    npm cache clean --force 2>/dev/null || true
    
    # 清理临时文件
    rm -rf /tmp/* 2>/dev/null || true
    rm -rf /var/tmp/* 2>/dev/null || true
    
    echo -e "${GREEN}✓ 缓存清理完成${NC}"
}

cleanup_all() {
    check_root
    echo -e "${PURPLE}开始完整系统清理...${NC}"
    echo ""
    
    echo -e "${YELLOW}1/4 清理旧内核...${NC}"
    cleanup_kernel
    echo ""
    
    echo -e "${YELLOW}2/4 清理日志文件...${NC}"
    cleanup_log
    echo ""
    
    echo -e "${YELLOW}3/4 清理缓存...${NC}"
    cleanup_cache
    echo ""
    
    echo -e "${YELLOW}4/4 检查磁盘空间...${NC}"
    df -h | grep -E '^/dev/'
    echo ""
    
    echo -e "${GREEN}✓ 系统清理完成！${NC}"
}

# ==========================================
# 主函数
# ==========================================

main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    local command=$1
    shift
    
    case $command in
        monitor_install)
            install_monitor
            ;;
        sysmon)
            sysmon
            ;;
        monitor_start)
            start_monitor
            ;;
        monitor_stop)
            stop_monitor
            ;;
        monitor_status)
            monitor_status
            ;;
        ssl_cert)
            ssl_cert "$@"
            ;;
        ssl_renew)
            ssl_renew
            ;;
        ssl_list)
            ssl_list
            ;;
        ssl_delete)
            ssl_delete "$@"
            ;;
        backup_files)
            backup_files
            ;;
        backup_db)
            backup_db
            ;;
        backup_all)
            backup_all
            ;;
        restore_db)
            restore_db "$@"
            ;;
        backup_auto)
            backup_auto
            ;;
        cleanup_check)
            cleanup_check
            ;;
        cleanup_kernel)
            cleanup_kernel
            ;;
        cleanup_log)
            cleanup_log
            ;;
        cleanup_cache)
            cleanup_cache
            ;;
        cleanup_all)
            cleanup_all
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}错误：未知命令 '$command'${NC}"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
