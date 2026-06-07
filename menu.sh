#!/bin/bash
# 交互式菜单脚本

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/remote.sh"

# 显示主菜单
show_main_menu() {
    clear
    print_header "🛠️ 运维工具管理平台"
    
    echo ""
echo -e "${YELLOW}请选择操作：${NC}"
    echo ""
echo -e "  ${GREEN}1.${NC} 软件安装"
echo -e "  ${GREEN}2.${NC} 集群部署"
echo -e "  ${GREEN}3.${NC} 运维工具"
echo -e "  ${GREEN}4.${NC} 安全扫描"
echo -e "  ${GREEN}5.${NC} 日常巡检"
echo -e "  ${GREEN}6.${NC} 备份恢复"
echo -e "  ${GREEN}7.${NC} 远程部署"
echo -e "  ${GREEN}8.${NC} 脚本升级"
echo -e "  ${GREEN}9.${NC} Web UI"
echo -e "  ${GREEN}A.${NC} 多云管理"
echo -e "  ${GREEN}B.${NC} 自动化部署"
echo -e "  ${GREEN}C.${NC} 成本优化"
echo -e "  ${GREEN}D.${NC} 合规检查"
echo -e "  ${GREEN}E.${NC} PVE虚拟机部署"
echo -e "  ${GREEN}0.${NC} 退出"
    echo ""
    read -p "请输入选项 [0-9/A-E]: " choice
    
    case $choice in
        1) show_install_menu ;;
        2) show_cluster_menu ;;
        3) show_ops_menu ;;
        4) show_security_menu ;;
        5) run_daily_check ;;
        6) show_backup_menu ;;
        7) show_remote_menu ;;
        8) run_update ;;
        9) start_webui ;;
        a|A) show_cloud_menu ;;
        b|B) execute_deploy ;;
        c|C) execute_cost ;;
        d|D) execute_compliance ;;
        e|E) show_pve_menu ;;
        0) exit 0 ;;
        *) 
            print_error "无效选项，请输入 0-9 或 A-E"
            pause
            show_main_menu
            ;;
    esac
}

# 显示安装菜单
show_install_menu() {
    clear
    print_header "📦 软件安装"
    
    echo ""
echo -e "${YELLOW}请选择要安装的软件：${NC}"
    echo ""
echo -e "  ${GREEN}1.${NC} Web 服务器"
echo -e "  ${GREEN}2.${NC} 数据库"
echo -e "  ${GREEN}3.${NC} 编程语言"
echo -e "  ${GREEN}4.${NC} 容器和缓存"
echo -e "  ${GREEN}5.${NC} 大数据组件"
echo -e "  ${GREEN}6.${NC} 一键部署"
echo -e "  ${GREEN}0.${NC} 返回"
    echo ""
    read -p "请输入选项 [0-6]: " choice
    
    case $choice in
        1) show_web_server_menu ;;
        2) show_database_menu ;;
        3) show_language_menu ;;
        4) show_container_menu ;;
        5) show_bigdata_menu ;;
        6) show_oneclick_menu ;;
        0) show_main_menu ;;
        *) 
            print_error "无效选项，请输入 0-6"
            pause
            show_install_menu
            ;;
    esac
}

# 显示 Web 服务器菜单
show_web_server_menu() {
    clear
    print_header "🌐 Web 服务器"
    
    echo ""
echo -e "${YELLOW}请选择 Web 服务器：${NC}"
    echo ""
echo -e "  ${GREEN}1.${NC} Nginx"
echo -e "  ${GREEN}2.${NC} Apache"
echo -e "  ${GREEN}0.${NC} 返回"
    echo ""
    read -p "请输入选项 [0-2]: " choice
    
    case $choice in
        1) execute_install "nginx" ;;
        2) execute_install "apache" ;;
        0) show_install_menu ;;
        *) 
            print_error "无效选项，请输入 0-2"
            pause
            show_web_server_menu
            ;;
    esac
}

# 显示数据库菜单
show_database_menu() {
    clear
    print_header "🗄️ 数据库"
    
    echo ""
echo -e "${YELLOW}请选择数据库：${NC}"
    echo ""
echo -e "  ${GREEN}1.${NC} MySQL"
echo -e "  ${GREEN}2.${NC} MariaDB"
echo -e "  ${GREEN}3.${NC} PostgreSQL"
echo -e "  ${GREEN}4.${NC} MongoDB"
echo -e "  ${GREEN}5.${NC} Redis"
echo -e "  ${GREEN}6.${NC} Elasticsearch"
echo -e "  ${GREEN}0.${NC} 返回"
    echo ""
    read -p "请输入选项 [0-6]: " choice
    
    case $choice in
        1) execute_install "mysql" ;;
        2) execute_install "mariadb" ;;
        3) execute_install "postgresql" ;;
        4) execute_install "mongodb" ;;
        5) execute_install "redis" ;;
        6) execute_install "elasticsearch" ;;
        0) show_install_menu ;;
        *) 
            print_error "无效选项，请输入 0-6"
            pause
            show_database_menu
            ;;
    esac
}

# 显示编程语言菜单
show_language_menu() {
    clear
    print_header "💻 编程语言"
    
    echo ""
echo -e "${YELLOW}请选择编程语言：${NC}"
    echo ""
echo -e "  ${GREEN}1.${NC} PHP"
echo -e "  ${GREEN}2.${NC} Python"
echo -e "  ${GREEN}3.${NC} Node.js"
echo -e "  ${GREEN}4.${NC} Java"
echo -e "  ${GREEN}5.${NC} Go"
echo -e "  ${GREEN}6.${NC} Rust"
echo -e "  ${GREEN}0.${NC} 返回"
    echo ""
    read -p "请输入选项 [0-6]: " choice
    
    case $choice in
        1) install_with_version "php" ;;
        2) install_with_version "python" ;;
        3) install_with_version "nodejs" ;;
        4) install_with_version "java" ;;
        5) install_with_version "go" ;;
        6) execute_install "rust" ;;
        0) show_install_menu ;;
        *) 
            print_error "无效选项，请输入 0-6"
            pause
            show_language_menu
            ;;
    esac
}

# 显示容器和缓存菜单
show_container_menu() {
    clear
    print_header "🐳 容器和缓存"
    
    echo ""
echo -e "${YELLOW}请选择：${NC}"
    echo ""
echo -e "  ${GREEN}1.${NC} Docker"
echo -e "  ${GREEN}2.${NC} Redis"
echo -e "  ${GREEN}3.${NC} Memcached"
echo -e "  ${GREEN}4.${NC} RabbitMQ"
echo -e "  ${GREEN}5.${NC} Kafka"
echo -e "  ${GREEN}6.${NC} MinIO"
echo -e "  ${GREEN}7.${NC} 消息队列"
echo -e "  ${GREEN}0.${NC} 返回"
    echo ""
    read -p "请输入选项 [0-7]: " choice
    
    case $choice in
        1) execute_install "docker" ;;
        2) execute_install "redis" ;;
        3) execute_install "memcached" ;;
        4) execute_install "rabbitmq" ;;
        5) execute_install "kafka" ;;
        6) execute_install "minio" ;;
        7) show_messaging_menu ;;
        0) show_install_menu ;;
        *) 
            print_error "无效选项，请输入 0-7"
            pause
            show_container_menu
            ;;
    esac
}

# 显示消息队列菜单
show_messaging_menu() {
    clear
    print_header "📨 消息队列"
    
    echo ""
echo -e "${YELLOW}请选择消息队列：${NC}"
    echo ""
echo -e "  ${GREEN}1.${NC} NATS (高性能消息系统)"
echo -e "  ${GREEN}2.${NC} Apache Pulsar (云原生消息队列)"
echo -e "  ${GREEN}0.${NC} 返回"
    echo ""
    read -p "请输入选项 [0-2]: " choice
    
    case $choice in
        1) execute_install "nats" ;;
        2) execute_install "pulsar" ;;
        0) show_container_menu ;;
        *) 
            print_error "无效选项，请输入 0-2"
            pause
            show_messaging_menu
            ;;
    esac
}

# 显示多云管理菜单
show_cloud_menu() {
    clear
    print_header "☁️ 多云管理"
    
    echo ""
echo -e "${YELLOW}请选择操作：${NC}"
    echo ""
echo -e "  ${GREEN}1.${NC} 列出账户"
echo -e "  ${GREEN}2.${NC} 添加账户"
echo -e "  ${GREEN}3.${NC} 删除账户"
echo -e "  ${GREEN}4.${NC} 设置默认账户"
echo -e "  ${GREEN}5.${NC} 列出所有实例"
echo -e "  ${GREEN}6.${NC} 查看所有费用"
echo -e "  ${GREEN}0.${NC} 返回"
    echo ""
    read -p "请输入选项 [0-6]: " choice
    
    case $choice in
        1) bash "$SCRIPT_DIR/cloud-manager/cloud-manager.sh" list ;;
        2) bash "$SCRIPT_DIR/cloud-manager/cloud-manager.sh" add ;;
        3) 
            read -p "请输入账户名称: " name
            bash "$SCRIPT_DIR/cloud-manager/cloud-manager.sh" remove "$name"
            ;;
        4)
            read -p "请输入账户名称: " name
            bash "$SCRIPT_DIR/cloud-manager/cloud-manager.sh" set-default "$name"
            ;;
        5) bash "$SCRIPT_DIR/cloud-manager/cloud-manager.sh" all instances ;;
        6) bash "$SCRIPT_DIR/cloud-manager/cloud-manager.sh" all costs ;;
        0) show_main_menu ;;
        *) 
            print_error "无效选项，请输入 0-6"
            pause
            show_cloud_menu
            ;;
    esac
    
    pause
    show_main_menu
}

# 执行自动化部署
execute_deploy() {
    clear
    print_header "🚀 自动化部署"
    
    echo ""
echo -e "${YELLOW}请选择操作：${NC}"
    echo ""
echo -e "  ${GREEN}1.${NC} 列出已部署应用"
echo -e "  ${GREEN}2.${NC} 部署新应用"
echo -e "  ${GREEN}3.${NC} 扩缩容"
echo -e "  ${GREEN}4.${NC} 查看状态"
echo -e "  ${GREEN}5.${NC} 回滚"
echo -e "  ${GREEN}6.${NC} 删除应用"
echo -e "  ${GREEN}0.${NC} 返回"
    echo ""
    read -p "请输入选项 [0-6]: " choice
    
    case $choice in
        1) bash "$SCRIPT_DIR/deploy-platform/deploy-platform.sh" list ;;
        2)
            read -p "请输入应用名称: " app_name
            bash "$SCRIPT_DIR/deploy-platform/deploy-platform.sh" deploy "$app_name"
            ;;
        3)
            read -p "请输入应用名称: " app_name
            read -p "请输入副本数: " replicas
            bash "$SCRIPT_DIR/deploy-platform/deploy-platform.sh" scale "$app_name" "$replicas"
            ;;
        4)
            read -p "请输入应用名称: " app_name
            bash "$SCRIPT_DIR/deploy-platform/deploy-platform.sh" status "$app_name"
            ;;
        5)
            read -p "请输入应用名称: " app_name
            bash "$SCRIPT_DIR/deploy-platform/deploy-platform.sh" rollback "$app_name"
            ;;
        6)
            read -p "请输入应用名称: " app_name
            bash "$SCRIPT_DIR/deploy-platform/deploy-platform.sh" delete "$app_name"
            ;;
        0) show_main_menu ;;
        *) 
            print_error "无效选项，请输入 0-6"
            pause
            execute_deploy
            ;;
    esac
    
    pause
    show_main_menu
}

# 执行成本优化
execute_cost() {
    clear
    print_header "💰 成本优化"
    
    echo ""
echo -e "${YELLOW}请选择操作：${NC}"
    echo ""
echo -e "  ${GREEN}1.${NC} 成本分析"
echo -e "  ${GREEN}2.${NC} 生成报告"
echo -e "  ${GREEN}3.${NC} 右尺寸建议"
echo -e "  ${GREEN}4.${NC} 闲置资源"
echo -e "  ${GREEN}5.${NC} 设置预算"
echo -e "  ${GREEN}6.${NC} 执行优化"
echo -e "  ${GREEN}0.${NC} 返回"
    echo ""
    read -p "请输入选项 [0-6]: " choice
    
    case $choice in
        1) bash "$SCRIPT_DIR/cost-optimizer/cost-optimizer.sh" analyze ;;
        2) bash "$SCRIPT_DIR/cost-optimizer/cost-optimizer.sh" report ;;
        3) bash "$SCRIPT_DIR/cost-optimizer/cost-optimizer.sh" right-size ;;
        4) bash "$SCRIPT_DIR/cost-optimizer/cost-optimizer.sh" idle-resources ;;
        5)
            read -p "请输入月度预算: " budget
            bash "$SCRIPT_DIR/cost-optimizer/cost-optimizer.sh" set-budget "$budget"
            ;;
        6) bash "$SCRIPT_DIR/cost-optimizer/cost-optimizer.sh" optimize ;;
        0) show_main_menu ;;
        *) 
            print_error "无效选项，请输入 0-6"
            pause
            execute_cost
            ;;
    esac
    
    pause
    show_main_menu
}

# 执行合规检查
execute_compliance() {
    clear
    print_header "🔐 合规检查"
    
    echo ""
echo -e "${YELLOW}请选择操作：${NC}"
    echo ""
echo -e "  ${GREEN}1.${NC} CIS Benchmark 检查"
echo -e "  ${GREEN}2.${NC} PCI DSS 检查"
echo -e "  ${GREEN}3.${NC} HIPAA 检查"
echo -e "  ${GREEN}4.${NC} GDPR 检查"
echo -e "  ${GREEN}5.${NC} SOC 2 检查"
echo -e "  ${GREEN}6.${NC} 查看规则"
echo -e "  ${GREEN}7.${NC} 生成报告"
echo -e "  ${GREEN}0.${NC} 返回"
    echo ""
    read -p "请输入选项 [0-7]: " choice
    
    case $choice in
        1) bash "$SCRIPT_DIR/compliance/compliance.sh" check cis-benchmark ;;
        2) bash "$SCRIPT_DIR/compliance/compliance.sh" check pci-dss ;;
        3) bash "$SCRIPT_DIR/compliance/compliance.sh" check hipaa ;;
        4) bash "$SCRIPT_DIR/compliance/compliance.sh" check gdpr ;;
        5) bash "$SCRIPT_DIR/compliance/compliance.sh" check soc2 ;;
        6) bash "$SCRIPT_DIR/compliance/compliance.sh" rules ;;
        7) bash "$SCRIPT_DIR/compliance/compliance.sh" report ;;
        0) show_main_menu ;;
        *) 
            print_error "无效选项，请输入 0-7"
            pause
            execute_compliance
            ;;
    esac
    
    pause
    show_main_menu
}

# 显示大数据组件菜单
show_bigdata_menu() {
    clear
    print_header "📊 大数据组件"
    
    echo ""
echo -e "${YELLOW}请选择大数据组件：${NC}"
    echo ""
echo -e "  ${GREEN}1.${NC} Hadoop"
echo -e "  ${GREEN}2.${NC} Spark"
echo -e "  ${GREEN}3.${NC} Flink"
echo -e "  ${GREEN}4.${NC} HBase"
echo -e "  ${GREEN}5.${NC} Hive"
echo -e "  ${GREEN}6.${NC} Airflow"
echo -e "  ${GREEN}0.${NC} 返回"
    echo ""
    read -p "请输入选项 [0-6]: " choice
    
    case $choice in
        1) execute_install "hadoop" "pseudo" ;;
        2) execute_install "spark" "standalone" ;;
        3) execute_install "flink" "cluster" ;;
        4) execute_install "hbase" "pseudo" ;;
        5) execute_install "hive" "install" ;;
        6) execute_install "airflow" "install" ;;
        0) show_install_menu ;;
        *) 
            print_error "无效选项，请输入 0-6"
            pause
            show_bigdata_menu
            ;;
    esac
}

# 显示一键部署菜单
show_oneclick_menu() {
    clear
    print_header "⚡ 一键部署"
    
    echo ""
echo -e "${YELLOW}请选择一键部署方案：${NC}"
    echo ""
echo -e "  ${GREEN}1.${NC} LNMP 栈 (Nginx + MySQL + PHP)"
echo -e "  ${GREEN}2.${NC} LAMP 栈 (Apache + MySQL + PHP)"
echo -e "  ${GREEN}3.${NC} 开发工具"
echo -e "  ${GREEN}4.${NC} 大数据组件栈"
echo -e "  ${GREEN}0.${NC} 返回"
    echo ""
    read -p "请输入选项 [0-4]: " choice
    
    case $choice in
        1) execute_install "lnmp" ;;
        2) execute_install "lamp" ;;
        3) execute_install "dev-tools" ;;
        4) execute_install "bigdata" ;;
        0) show_install_menu ;;
        *) 
            print_error "无效选项，请输入 0-4"
            pause
            show_oneclick_menu
            ;;
    esac
}

# 显示集群部署菜单
show_cluster_menu() {
    clear
    print_header "🏗️ 集群部署"
    
    echo ""
echo -e "${YELLOW}请选择集群类型：${NC}"
    echo ""
echo -e "  ${GREEN}1.${NC} Redis 集群"
echo -e "  ${GREEN}2.${NC} MySQL 集群"
echo -e "  ${GREEN}3.${NC} MongoDB 集群"
echo -e "  ${GREEN}4.${NC} PostgreSQL 集群"
echo -e "  ${GREEN}5.${NC} Kafka 集群"
echo -e "  ${GREEN}6.${NC} Elasticsearch 集群"
echo -e "  ${GREEN}7.${NC} Kubernetes 工具"
echo -e "  ${GREEN}0.${NC} 返回"
    echo ""
    read -p "请输入选项 [0-7]: " choice
    
    case $choice in
        1) execute_install "redis-cluster" ;;
        2) execute_install "mysql-cluster" ;;
        3) execute_install "mongodb-cluster" ;;
        4) execute_install "postgresql-cluster" ;;
        5) execute_install "kafka-cluster" ;;
        6) execute_install "elasticsearch-cluster" ;;
        7) show_k8s_menu ;;
        0) show_main_menu ;;
        *) 
            print_error "无效选项，请输入 0-7"
            pause
            show_cluster_menu
            ;;
    esac
}

# 显示 Kubernetes 工具菜单
show_k8s_menu() {
    clear
    print_header "☸️ Kubernetes 工具"
    
    echo ""
echo -e "${YELLOW}请选择 Kubernetes 工具：${NC}"
    echo ""
echo -e "  ${GREEN}1.${NC} Argo CD (GitOps)"
echo -e "  ${GREEN}2.${NC} Jaeger (分布式追踪)"
echo -e "  ${GREEN}3.${NC} Istio (服务网格)"
echo -e "  ${GREEN}4.${NC} Linkerd (服务网格)"
echo -e "  ${GREEN}5.${NC} Kong (API 网关)"
echo -e "  ${GREEN}6.${NC} Apache APISIX (API 网关)"
echo -e "  ${GREEN}7.${NC} Consul (服务发现)"
echo -e "  ${GREEN}8.${NC} Vault (密钥管理)"
echo -e "  ${GREEN}0.${NC} 返回"
    echo ""
    read -p "请输入选项 [0-8]: " choice
    
    case $choice in
        1) execute_install "argo-cd" ;;
        2) execute_install "jaeger" ;;
        3) execute_install "istio" ;;
        4) execute_install "linkerd" ;;
        5) execute_install "kong" ;;
        6) execute_install "apisix" ;;
        7) execute_install "consul" ;;
        8) execute_install "vault" ;;
        0) show_cluster_menu ;;
        *) 
            print_error "无效选项，请输入 0-8"
            pause
            show_k8s_menu
            ;;
    esac
}

# 显示运维工具菜单
show_ops_menu() {
    clear
    print_header "🔧 运维工具"
    
    echo ""
echo -e "${YELLOW}请选择运维工具：${NC}"
    echo ""
echo -e "  ${GREEN}1.${NC} 内核调优"
echo -e "  ${GREEN}2.${NC} 防火墙管理"
echo -e "  ${GREEN}3.${NC} 镜像源设置"
echo -e "  ${GREEN}4.${NC} 系统清理"
echo -e "  ${GREEN}5.${NC} 健康检查"
echo -e "  ${GREEN}0.${NC} 返回"
    echo ""
    read -p "请输入选项 [0-5]: " choice
    
    case $choice in
        1) execute_install "tune-kernel" ;;
        2) execute_install "firewall" ;;
        3) execute_install "mirror" ;;
        4) execute_install "cleanup" ;;
        5) run_healthcheck ;;
        0) show_main_menu ;;
        *) 
            print_error "无效选项，请输入 0-5"
            pause
            show_ops_menu
            ;;
    esac
}

# 显示安全扫描菜单
show_security_menu() {
    clear
    print_header "🔒 安全扫描"
    
    echo ""
echo -e "${YELLOW}请选择安全检查类型：${NC}"
    echo ""
echo -e "  ${GREEN}1.${NC} 完整安全扫描"
echo -e "  ${GREEN}2.${NC} 操作系统安全"
echo -e "  ${GREEN}3.${NC} 数据库安全"
echo -e "  ${GREEN}4.${NC} Web 服务器安全"
echo -e "  ${GREEN}5.${NC} Docker 安全"
echo -e "  ${GREEN}6.${NC} 网络安全"
echo -e "  ${GREEN}0.${NC} 返回"
    echo ""
    read -p "请输入选项 [0-6]: " choice
    
    case $choice in
        1) execute_install "security" "all" ;;
        2) execute_install "security" "os" ;;
        3) execute_install "security" "database" ;;
        4) execute_install "security" "web" ;;
        5) execute_install "security" "docker" ;;
        6) execute_install "security" "network" ;;
        0) show_main_menu ;;
        *) 
            print_error "无效选项，请输入 0-6"
            pause
            show_security_menu
            ;;
    esac
}

# 显示备份恢复菜单
show_backup_menu() {
    clear
    print_header "💾 备份恢复"
    
    echo ""
echo -e "${YELLOW}请选择操作：${NC}"
    echo ""
echo -e "  ${GREEN}1.${NC} MySQL 备份"
echo -e "  ${GREEN}2.${NC} MongoDB 备份"
echo -e "  ${GREEN}3.${NC} Redis 备份"
echo -e "  ${GREEN}4.${NC} 全部备份"
echo -e "  ${GREEN}5.${NC} MySQL 恢复"
echo -e "  ${GREEN}6.${NC} MongoDB 恢复"
echo -e "  ${GREEN}7.${NC} Redis 恢复"
echo -e "  ${GREEN}0.${NC} 返回"
    echo ""
    read -p "请输入选项 [0-7]: " choice
    
    case $choice in
        1) execute_install "backup" "mysql" ;;
        2) execute_install "backup" "mongodb" ;;
        3) execute_install "backup" "redis" ;;
        4) execute_install "backup" "all" ;;
        5) execute_install "restore" "mysql" ;;
        6) execute_install "restore" "mongodb" ;;
        7) execute_install "restore" "redis" ;;
        0) show_main_menu ;;
        *) 
            print_error "无效选项，请输入 0-7"
            pause
            show_backup_menu
            ;;
    esac
}

# 显示远程部署菜单
show_remote_menu() {
    clear
    print_header "🌍 远程部署"
    
    echo ""
echo -e "${YELLOW}请输入远程服务器信息：${NC}"
    echo ""
    
    read -p "远程服务器地址 (按回车跳过，使用本机): " REMOTE_HOST
    
    if [ -n "$REMOTE_HOST" ]; then
        read -p "远程用户名 (默认: root): " REMOTE_USER
        REMOTE_USER=${REMOTE_USER:-root}
        
        read -p "远程端口 (默认: 22): " REMOTE_PORT
        REMOTE_PORT=${REMOTE_PORT:-22}
        
        read -p "远程密码 (留空使用密钥): " REMOTE_PASSWORD
        
        init_remote "$REMOTE_HOST" "$REMOTE_USER" "$REMOTE_PASSWORD" "$REMOTE_PORT"
        
        echo ""
        echo "🔗 测试远程连接..."
        if test_remote_connection; then
            print_success "远程连接配置成功"
        else
            print_error "远程连接失败，请检查信息"
            pause
            show_main_menu
            return
        fi
    else
        print_info "使用本机部署模式"
    fi
    
    pause
    show_install_menu
}

# 带版本选择的安装
install_with_version() {
    local software=$1
    
    clear
    print_header "📦 安装 $software"
    
    echo ""
    read -p "请输入版本号 (按回车使用默认版本): " version
    
    if [ -n "$version" ]; then
        execute_install "$software" "$version"
    else
        execute_install "$software"
    fi
}

# 执行安装
execute_install() {
    local software=$1
    local options=$2
    
    clear
    print_header "🚀 正在安装 $software"
    
    if is_remote; then
        echo "🌍 远程部署到: $REMOTE_USER@$REMOTE_HOST:$REMOTE_PORT"
        echo ""
        
        # 首先尝试使用新的标准脚本 install.sh
        local script_path="$SCRIPT_DIR/${software}/install.sh"
        
        # 如果找不到标准脚本，再尝试旧的格式
        if [ ! -f "$script_path" ]; then
            script_path="$SCRIPT_DIR/${software}/${software}.sh"
        fi
        
        if [ -f "$script_path" ]; then
            remote_exec_script "$script_path" "$options"
        else
            # 对于复合命令（如 lnmp, lamp 等）
            local cmd="./main.sh $software"
            if [ -n "$options" ]; then
                cmd="$cmd $options"
            fi
            
            # 创建临时脚本
            local tmp_script="/tmp/remote_install.sh"
            cat > "$tmp_script" <<EOF
#!/bin/bash
cd $SCRIPT_DIR
$cmd
EOF
            chmod +x "$tmp_script"
            remote_exec_script "$tmp_script"
            rm -f "$tmp_script"
        fi
    else
        if [ -n "$options" ]; then
            bash "$SCRIPT_DIR/main.sh" "$software" "$options"
        else
            bash "$SCRIPT_DIR/main.sh" "$software"
        fi
    fi
    
    pause
    show_main_menu
}

# 运行健康检查
run_healthcheck() {
    clear
    print_header "✅ 运行健康检查"
    bash "$SCRIPT_DIR/main.sh" healthcheck
    pause
    show_main_menu
}

# 运行日常巡检
run_daily_check() {
    clear
    print_header "📋 执行日常巡检"
    bash "$SCRIPT_DIR/main.sh" daily
    pause
    show_main_menu
}

# 运行脚本升级
run_update() {
    clear
    print_header "🔄 脚本升级"
    bash "$SCRIPT_DIR/main.sh" update
    pause
    show_main_menu
}

# 启动 Web UI
start_webui() {
    clear
    print_header "🌐 启动 Web UI"
    bash "$SCRIPT_DIR/main.sh" webui
    pause
    show_main_menu
}

# 显示PVE部署菜单
show_pve_menu() {
    clear
    print_header "🖥️ PVE虚拟机部署"
    
    echo ""
echo -e "${YELLOW}请选择PVE操作：${NC}"
    echo ""
echo -e "  ${GREEN}1.${NC} 配置PVE连接"
echo -e "  ${GREEN}2.${NC} 查看当前配置"
echo -e "  ${GREEN}3.${NC} 列出所有VM"
echo -e "  ${GREEN}4.${NC} 创建新VM（配置文件）"
echo -e "  ${GREEN}5.${NC} 创建新VM（交互式）"
echo -e "  ${GREEN}6.${NC} 启动VM"
echo -e "  ${GREEN}7.${NC} 停止VM"
echo -e "  ${GREEN}8.${NC} 查看VM状态"
echo -e "  ${GREEN}9.${NC} 部署软件到VM"
echo -e "  ${GREEN}10.${NC} 销毁VM"
echo -e "  ${GREEN}0.${NC} 返回主菜单"
    echo ""
    read -p "请输入选项 [0-10]: " choice
    
    case $choice in
        1) 
            bash "$SCRIPT_DIR/pve/pve.sh" config
            pause
            show_pve_menu
            ;;
        2) 
            bash "$SCRIPT_DIR/pve/pve.sh" list
            pause
            show_pve_menu
            ;;
        3) 
            bash "$SCRIPT_DIR/pve/pve.sh" list-vm
            pause
            show_pve_menu
            ;;
        4) 
            read -p "请输入VM名称（可选）: " vm_name
            if [ -n "$vm_name" ]; then
                bash "$SCRIPT_DIR/pve/pve.sh" create "$vm_name"
            else
                bash "$SCRIPT_DIR/pve/pve.sh" create
            fi
            pause
            show_pve_menu
            ;;
        5) 
            bash "$SCRIPT_DIR/pve/pve.sh" create --interactive
            pause
            show_pve_menu
            ;;
        6) 
            read -p "请输入VM ID: " vm_id
            bash "$SCRIPT_DIR/pve/pve.sh" start "$vm_id"
            pause
            show_pve_menu
            ;;
        7) 
            read -p "请输入VM ID: " vm_id
            bash "$SCRIPT_DIR/pve/pve.sh" stop "$vm_id"
            pause
            show_pve_menu
            ;;
        8) 
            read -p "请输入VM ID: " vm_id
            bash "$SCRIPT_DIR/pve/pve.sh" status "$vm_id"
            pause
            show_pve_menu
            ;;
        9) 
            read -p "请输入VM ID: " vm_id
            echo "请选择要部署的软件（可多选，用空格分隔）："
            echo "nginx mysql mariadb php redis docker nodejs python java postgresql mongodb elasticsearch kubernetes"
            echo ""
            read -p "软件列表: " software_list
            bash "$SCRIPT_DIR/pve/pve.sh" deploy "$vm_id" $software_list
            pause
            show_pve_menu
            ;;
        10) 
            read -p "请输入VM ID: " vm_id
            bash "$SCRIPT_DIR/pve/pve.sh" destroy "$vm_id"
            pause
            show_pve_menu
            ;;
        0) show_main_menu ;;
        *) 
            print_error "无效选项，请输入 0-10"
            pause
            show_pve_menu
            ;;
    esac
}

# 暂停函数
pause() {
    echo ""
    read -p "按任意键继续..." -n 1 -s
    echo ""
}

# 主函数
main() {
    # 检查参数
    if [ $# -ge 3 ]; then
        # 远程部署模式
        init_remote "$1" "$2" "$3" "${4:-22}"
        if ! test_remote_connection; then
            exit 1
        fi
    fi
    
    show_main_menu
}

main "$@"