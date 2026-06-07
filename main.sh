#!/bin/bash

# =========================================
# Shell 工具 - 总控脚本 v3.0
# 支持 CentOS 7, CentOS 8, Ubuntu 18/20/22
# =========================================

# 设置错误处理，但不使用 set -e，因为我们需要更好的控制
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/lib/common.sh" ]; then
    source "$SCRIPT_DIR/lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/lib/logging.sh" ]; then
    source "$SCRIPT_DIR/lib/logging.sh"
fi

if [ -f "$SCRIPT_DIR/lib/config.sh" ]; then
    source "$SCRIPT_DIR/lib/config.sh"
fi

# 加载插件管理器
if [ -f "$SCRIPT_DIR/lib/plugin-manager.sh" ]; then
    source "$SCRIPT_DIR/lib/plugin-manager.sh"
fi

show_help() {
    cat << EOF
${GREEN}========================================${NC}
${GREEN}   Shell 工具 - 总控脚本 v3.0${NC}
${GREEN}========================================${NC}

${YELLOW}使用方法：${NC}
  $0 <命令> [选项]

${YELLOW}基础命令：${NC}
  help              显示帮助
  list              列出所有可用脚本
  system-info       显示系统信息
  status            检查软件安装状态
  log [行数]        查看安装日志

${YELLOW}安装命令：${NC}
  install <软件> [版本]   安装软件
  upgrade <软件>          升级软件
  uninstall <软件>        卸载软件

${YELLOW}Web 服务器：${NC}
  nginx             安装 Nginx
  apache            安装 Apache

${YELLOW}数据库：${NC}
  mariadb           安装 MariaDB
  mysql             安装 MySQL
  postgresql        安装 PostgreSQL
  mongodb           安装 MongoDB
  sqlite            安装 SQLite
  elasticsearch     安装 Elasticsearch
  clickhouse        安装 ClickHouse
  cassandra         安装 Cassandra
  influxdb          安装 InfluxDB

${YELLOW}编程语言：${NC}
  php [版本]        安装 PHP (默认: 8.0)
  python [版本]      安装 Python (默认: 3.11)
  nodejs [版本]      安装 Node.js (默认: 20)
  java [版本]       安装 Java (默认: 11)
  go [版本]         安装 Go (默认: 1.22)
  rust              安装 Rust
  ruby [版本]       安装 Ruby (默认: 3.2)
  perl [版本]       安装 Perl (默认: 5.36)

${YELLOW}容器和缓存：${NC}
  docker            安装 Docker
  redis             安装 Redis
  memcached         安装 Memcached
  minio             安装 MinIO
  rabbitmq          安装 RabbitMQ
  kafka             安装 Kafka
  zookeeper         安装 Zookeeper

${YELLOW}运维工具：${NC}
  monitor           安装监控系统
  ssl <域名>        申请 SSL 证书
  backup            备份数据库
  cleanup           系统清理
  tune-kernel       内核调优
  mirror [源]       设置镜像源
  firewall          防火墙管理

${YELLOW}大数据组件:${NC}
  hadoop [mode]     - 部署 Hadoop (pseudo/stop/status)
  spark [mode]      - 部署 Spark (local/standalone/stop/status/shell)
  flink [mode]      - 部署 Flink (local/cluster/stop/status/sql)
  hbase [mode]      - 部署 HBase (standalone/pseudo/stop/status/shell)
  hive [mode]       - 部署 Hive (install/shell/beeline/metastore/hiveserver2/status)
  airflow [mode]    - 部署 Airflow (install/start/stop/status/webserver/scheduler)
  flume [mode]      - 部署 Flume (install/start/status)
  zeppelin [mode]   - 部署 Zeppelin (install/start/stop/restart/status)

${YELLOW}负载均衡与高可用：${NC}
  haproxy          安装 HAProxy 负载均衡
  keepalived       安装 Keepalived 高可用

${YELLOW}一键部署：${NC}
  lnmp              LNMP 栈
  lamp              LAMP 栈
  dev-tools         开发工具
  bigdata           大数据组件栈
  nginx-deploy      Nginx 网站一键部署

${YELLOW}集群部署：${NC}
  redis-cluster     Redis 集群部署
  mysql-cluster     MySQL 主从集群
  mongodb-cluster   MongoDB 副本集
  postgresql-cluster PostgreSQL 主从集群
  kafka-cluster     Kafka 集群 (含Zookeeper)
  zookeeper-cluster Zookeeper 集群
  elasticsearch-cluster Elasticsearch 集群
  rabbitmq-cluster  RabbitMQ 集群

${YELLOW}健康检查与备份：${NC}
  healthcheck       运行健康检查
  backup [软件]     备份数据 (mysql/mongodb/redis/all)
  restore [软件]   恢复数据

${YELLOW}安全扫描：${NC}
  security          运行安全基线检查
  security os       操作系统安全检查
  security database 数据库安全检查
  security web      Web 服务器安全检查
  security docker   Docker 安全检查
  security network  网络安全检查

${YELLOW}日常巡检：${NC}
  daily             执行日常巡检
  daily check       仅检查不发送邮件
  daily report      生成巡检报告

${YELLOW}版本管理：${NC}
  version list      列出支持的软件版本
  version set <软件> <版本>  设置软件版本
  version install <软件> <版本> 安装指定版本

${YELLOW}快捷运维：${NC}
  ops               显示快捷运维命令
  ops <命令>        执行快捷运维命令

${YELLOW}脚本升级：${NC}
  update check      检查脚本更新
  update           执行脚本更新
  update force      强制更新脚本

${YELLOW}配置管理：${NC}
  config show       显示当前配置
  config set <key> <value>  设置配置项

${YELLOW}Web UI：${NC}
  webui            启动运维管理平台
  webui start      启动服务
  webui stop       停止服务

${YELLOW}Kubernetes 工具：${NC}
  argo-cd          安装 Argo CD (GitOps)
  jaeger           安装 Jaeger (分布式追踪)
  istio            安装 Istio (服务网格)
  linkerd          安装 Linkerd (服务网格)
  kong             安装 Kong (API Gateway)
  apisix           安装 Apache APISIX (API 网关)
  consul           安装 Consul (服务发现)
  vault            安装 HashiCorp Vault (密钥管理)

${YELLOW}消息队列：${NC}
  nats             安装 NATS (高性能消息系统)
  pulsar           安装 Apache Pulsar (云原生消息队列)

${YELLOW}多云管理：${NC}
  cloud            多云账户管理
  deploy           自动化部署平台
  cost             成本优化工具
  compliance       合规性检查

${YELLOW}PVE虚拟机部署：${NC}
  pve              PVE虚拟机管理
  pve config       配置PVE连接信息
  pve list         列出当前配置
  pve create       显示VM创建说明
  pve start <ID>   显示VM启动说明
  pve stop <ID>    显示VM停止说明
  pve destroy <ID> 显示VM销毁说明
  pve status <ID>  显示VM状态查看说明
  pve deploy <ID> <软件>... 部署软件到VM
                        支持软件: nginx, mysql, mariadb, php, redis, 
                        docker, nodejs, python, java, postgresql, 
                        mongodb, elasticsearch, kubernetes

${YELLOW}插件管理 (v3.0):${NC}
  plugin discover           发现所有可用插件
  plugin list [分类]        列出所有插件
  plugin search <关键词>    搜索插件
  plugin install <名称>     安装插件
  plugin uninstall <名称>   卸载插件
  plugin enable <名称>       启用插件
  plugin disable <名称>      禁用插件
  plugin info <名称>        显示插件详情
  plugin status            显示插件状态
  plugin market            浏览插件市场
  plugin diagnose           诊断插件系统

${YELLOW}交互式菜单：${NC}
  menu             启动交互式安装菜单
  menu <host> <user> <password> [port]  远程部署

${YELLOW}示例：${NC}
  $0 install nginx
  $0 install php 8.0
  $0 install python 3.11
  $0 upgrade nginx
  $0 uninstall mysql
  $0 status
  $0 log 50
  $0 pve config
  $0 pve create myvm
  $0 pve deploy 100 nginx mysql

EOF
}

list_scripts() {
    print_header "可用脚本列表"
    
    for dir in "$SCRIPT_DIR"/*/; do
        if [ -d "$dir" ] && [ "$(basename "$dir")" != "lib" ] && [ "$(basename "$dir")" != "config" ] && [ "$(basename "$dir")" != "uninstall" ]; then
            name=$(basename "$dir")
            script_file="$dir${name}.sh"
            
            if [ -f "$script_file" ]; then
                desc=$(grep -m1 "^#.*描述" "$script_file" | sed 's/^#.*描述：//' || echo "无描述")
                
                if check_installed "$name"; then
                    version=$(get_installed_version "$name")
                    printf "${GREEN}%s${NC} - $desc ${YELLOW}[已安装: $version]${NC}\n" "$name"
                else
                    printf "${GREEN}%s${NC} - $desc\n" "$name"
                fi
            fi
        fi
    done
}

show_system_info() {
    print_header "系统信息"
    get_system_info
}

show_status() {
    print_header "软件安装状态"
    
    local software_list=(
        "nginx:nginx"
        "apache:apache"
        "php:php"
        "mysql:mysql"
        "mariadb:mariadb"
        "postgresql:postgresql"
        "redis:redis-server"
        "docker:docker"
        "mongodb:mongod"
        "python:python3"
        "nodejs:node"
        "java:java"
        "go:go"
    )
    
    printf "${YELLOW}软件名称          状态          版本${NC}\n"
    echo "----------------------------------------"
    
    for item in "${software_list[@]}"; do
        name="${item%%:*}"
        cmd="${item##*:}"
        
        if command -v $cmd &>/dev/null; then
            version=$(get_installed_version "$name" 2>/dev/null || echo "unknown")
            printf "%-17s %-14s %s\n" "$name" "${GREEN}已安装${NC}" "$version"
        else
            printf "%-17s %-14s\n" "$name" "${RED}未安装${NC}"
        fi
    done
}

install_software() {
    local software=$1
    local version=${2:-""}
    
    log_info "开始安装 $software${version:+ ($version)}"
    
    # 首先检查是否是内置插件
    if [ -d "$PLUGIN_DIR/$software" ] || [ -d "$CUSTOM_PLUGIN_DIR/$software" ]; then
        print_header "使用插件系统安装 $software${version:+ ($version)}"
        
        # 初始化插件管理器（如果需要）
        if [ ${#PLUGIN_METADATA[@]} -eq 0 ]; then
            discover_plugins
        fi
        
        # 注册插件
        local plugin_path="$PLUGIN_DIR/$software"
        if [ ! -d "$plugin_path" ]; then
            plugin_path="$CUSTOM_PLUGIN_DIR/$software"
        fi
        
        if [ -d "$plugin_path" ]; then
            register_plugin "$software" "$plugin_path"
            
            # 检查依赖
            if check_plugin_dependencies "$software"; then
                plugin_install "$software" "false"
                local status=$?
                if [ $status -eq 0 ]; then
                    log_info "插件安装成功: $software${version:+ ($version)}"
                    print_success "$software 安装完成"
                else
                    log_error "插件安装失败: $software${version:+ ($version)}"
                    print_error "$software 安装失败"
                fi
                return $status
            else
                print_error "$software 依赖检查失败"
                return 1
            fi
        fi
    fi
    
    # 回退到传统脚本安装方式
    # 首先尝试使用新的标准脚本 install.sh
    local script_file="$SCRIPT_DIR/${software}/install.sh"
    
    # 如果找不到标准脚本，再尝试旧的格式
    if [ ! -f "$script_file" ]; then
        script_file="$SCRIPT_DIR/${software}/${software}.sh"
    fi
    
    if [ ! -f "$script_file" ]; then
        print_error "未找到脚本: $script_file"
        log_error "脚本不存在: $script_file"
        exit 1
    fi
    
    print_header "安装 $software${version:+ 版本 $version}"
    
    check_prerequisites
    backup_service_configs "$software"
    
    if [ -n "$version" ]; then
        bash "$script_file" "$version"
    else
        bash "$script_file"
    fi
    
    local status=$?
    if [ $status -eq 0 ]; then
        log_info "安装成功: $software${version:+ ($version)}"
        print_success "$software 安装完成"
    else
        log_error "安装失败: $software${version:+ ($version)}"
        print_error "$software 安装失败"
    fi
    
    return $status
}

uninstall_software() {
    local software=$1
    
    log_info "开始卸载 $software"
    
    local script_file="$SCRIPT_DIR/uninstall/uninstall.sh"
    
    if [ ! -f "$script_file" ]; then
        print_error "未找到卸载脚本: $script_file"
        exit 1
    fi
    
    if confirm "确定要卸载 $software 吗？"; then
        print_header "卸载 $software"
        bash "$script_file" "$software"
        
        log_info "卸载完成: $software"
        print_success "$software 卸载完成"
    else
        print_info "取消卸载"
    fi
}

upgrade_software() {
    local software=$1
    local current_version=""
    
    print_header "升级 $software"
    
    if ! check_installed "$software"; then
        print_error "$software 未安装，请先安装"
        return 1
    fi
    
    current_version=$(get_installed_version "$software" 2>/dev/null || echo "unknown")
    print_info "当前版本: $current_version"
    
    if confirm "是否继续升级？"; then
        install_software "$software"
    else
        print_info "取消升级"
    fi
}

install_lnmp() {
    print_header "安装 LNMP 栈"
    local total=3
    local current=1
    
    print_step $current $total "安装 Nginx"
    install_software nginx
    current=$((current + 1))
    
    print_step $current $total "安装 MariaDB"
    install_software mariadb
    current=$((current + 1))
    
    print_step $current $total "安装 PHP"
    install_software php
}

install_lamp() {
    print_header "安装 LAMP 栈"
    local total=3
    local current=1
    
    print_step $current $total "安装 Apache"
    install_software apache
    current=$((current + 1))
    
    print_step $current $total "安装 MariaDB"
    install_software mariadb
    current=$((current + 1))
    
    print_step $current $total "安装 PHP"
    install_software php
}

handle_config() {
    local action=$1
    shift
    
    case $action in
        show)
            list_config
            ;;
        set)
            local key=$1
            local value=$2
            if [ -z "$key" ] || [ -z "$value" ]; then
                print_error "用法: config set <key> <value>"
                exit 1
            fi
            set_config "$key" "$value"
            print_success "配置已更新: $key = $value"
            ;;
        *)
            print_error "未知配置操作: $action"
            echo "用法: config show | config set <key> <value>"
            exit 1
            ;;
    esac
}

main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    local command=$1
    shift
    
    case $command in
        help|--help|-h)
            show_help
            ;;
        list)
            list_scripts
            ;;
        system-info|info)
            show_system_info
            ;;
        status)
            show_status
            ;;
        log)
            show_log "${1:-50}"
            ;;
        install|i)
            if [ -z "$1" ]; then
                print_error "请指定要安装的软件"
                exit 1
            fi
            install_software "$@"
            ;;
        uninstall|remove|rm)
            if [ -z "$1" ]; then
                print_error "请指定要卸载的软件"
                exit 1
            fi
            uninstall_software "$@"
            ;;
        upgrade|update)
            if [ -z "$1" ]; then
                print_error "请指定要升级的软件"
                exit 1
            fi
            upgrade_software "$@"
            ;;
        config)
            handle_config "$@"
            ;;
        nginx)
            install_software nginx
            ;;
        apache)
            install_software apache
            ;;
        mariadb)
            install_software mariadb
            ;;
        mysql)
            install_software mysql
            ;;
        postgresql)
            install_software postgresql
            ;;
        php)
            install_software php "$@"
            ;;
        python)
            install_software python "$@"
            ;;
        nodejs)
            install_software nodejs "$@"
            ;;
        java)
            install_software java "$@"
            ;;
        go)
            install_software go "$@"
            ;;
        rust)
            install_software rust
            ;;
        ruby)
            install_software ruby "$@"
            ;;
        perl)
            install_software perl "$@"
            ;;
        mongodb)
            install_software mongodb
            ;;
        sqlite)
            install_software sqlite
            ;;
        elasticsearch)
            install_software elasticsearch
            ;;
        clickhouse)
            install_software clickhouse
            ;;
        cassandra)
            install_software cassandra
            ;;
        influxdb)
            install_software influxdb
            ;;
        memcached)
            install_software memcached
            ;;
        minio)
            install_software minio
            ;;
        rabbitmq)
            install_software rabbitmq
            ;;
        kafka)
            install_software kafka
            ;;
        zookeeper)
            install_software zookeeper
            ;;
        docker)
            install_software docker
            ;;
        redis)
            install_software redis
            ;;
        monitor)
            install_software monitor
            ;;
        ssl)
            install_software ssl "$@"
            ;;
        backup)
            install_software backup
            ;;
        cleanup)
            install_software cleanup
            ;;
        tune-kernel|tune_kernel)
            install_software tune-kernel
            ;;
        mirror)
            install_software mirror "$@"
            ;;
        firewall)
            install_software firewall "$@"
            ;;
        hadoop)
            install_software hadoop "$@"
            ;;
        spark)
            install_software spark "$@"
            ;;
        flink)
            install_software flink "$@"
            ;;
        hbase)
            install_software hbase "$@"
            ;;
        hive)
            install_software hive "$@"
            ;;
        airflow)
            install_software airflow "$@"
            ;;
        flume)
            install_software flume "$@"
            ;;
        zeppelin)
            install_software zeppelin "$@"
            ;;
        lnmp)
            install_lnmp
            ;;
        lamp)
            install_lamp
            ;;
        bigdata)
            install_software hadoop pseudo
            install_software spark standalone
            install_software flink cluster
            print_success "大数据组件栈部署完成"
            ;;
        redis-cluster)
            bash "$SCRIPT_DIR/redis-cluster/redis-cluster.sh" "$@"
            ;;
        mysql-cluster)
            bash "$SCRIPT_DIR/mysql-cluster/mysql-cluster.sh" "$@"
            ;;
        mongodb-cluster)
            bash "$SCRIPT_DIR/mongodb-cluster/mongodb-cluster.sh" "$@"
            ;;
        postgresql-cluster)
            bash "$SCRIPT_DIR/postgresql-cluster/postgresql-cluster.sh" "$@"
            ;;
        kafka-cluster)
            bash "$SCRIPT_DIR/kafka-cluster/kafka-cluster.sh" "$@"
            ;;
        zookeeper-cluster)
            bash "$SCRIPT_DIR/zookeeper-cluster/zookeeper-cluster.sh" "$@"
            ;;
        elasticsearch-cluster)
            bash "$SCRIPT_DIR/elasticsearch-cluster/elasticsearch-cluster.sh" "$@"
            ;;
        rabbitmq-cluster)
            bash "$SCRIPT_DIR/rabbitmq-cluster/rabbitmq-cluster.sh" "$@"
            ;;
        haproxy)
            bash "$SCRIPT_DIR/haproxy/haproxy.sh" "$@"
            ;;
        keepalived)
            bash "$SCRIPT_DIR/keepalived/keepalived.sh" "$@"
            ;;
        nginx-deploy)
            bash "$SCRIPT_DIR/nginx-deploy/nginx-deploy.sh" "$@"
            ;;
        healthcheck)
            bash "$SCRIPT_DIR/healthcheck/healthcheck.sh" "$@"
            ;;
        backup)
            bash "$SCRIPT_DIR/backup/backup.sh" backup "$@"
            ;;
        restore)
            bash "$SCRIPT_DIR/backup/backup.sh" restore "$@"
            ;;
        dev-tools)
            install_software dev-tools
            ;;
        security)
            bash "$SCRIPT_DIR/security-baseline/security-baseline.sh" "$@"
            ;;
        daily)
            bash "$SCRIPT_DIR/daily-check.sh" "$@"
            ;;
        version)
            bash "$SCRIPT_DIR/version.sh" "$@"
            ;;
        ops)
            bash "$SCRIPT_DIR/ops.sh" "$@"
            ;;
        update)
            bash "$SCRIPT_DIR/update.sh" "$@"
            ;;
        webui)
            if [ "$1" = "stop" ]; then
                bash "$SCRIPT_DIR/webui/stop.sh"
            else
                bash "$SCRIPT_DIR/webui/start.sh"
            fi
            ;;
        argo-cd)
            bash "$SCRIPT_DIR/argocd/argocd.sh" "$@"
            ;;
        jaeger)
            bash "$SCRIPT_DIR/jaeger/jaeger.sh" "$@"
            ;;
        istio)
            bash "$SCRIPT_DIR/istio/istio.sh" "$@"
            ;;
        kong)
            bash "$SCRIPT_DIR/kong/kong.sh" "$@"
            ;;
        consul)
            bash "$SCRIPT_DIR/consul/consul.sh" "$@"
            ;;
        vault)
            bash "$SCRIPT_DIR/vault/vault.sh" "$@"
            ;;
        apisix)
            bash "$SCRIPT_DIR/apisix/apisix.sh" "$@"
            ;;
        linkerd)
            bash "$SCRIPT_DIR/linkerd/linkerd.sh" "$@"
            ;;
        nats)
            bash "$SCRIPT_DIR/nats/nats.sh" "$@"
            ;;
        pulsar)
            bash "$SCRIPT_DIR/pulsar/pulsar.sh" "$@"
            ;;
        cloud)
            bash "$SCRIPT_DIR/cloud-manager/cloud-manager.sh" "$@"
            ;;
        deploy)
            bash "$SCRIPT_DIR/deploy-platform/deploy-platform.sh" "$@"
            ;;
        cost)
            bash "$SCRIPT_DIR/cost-optimizer/cost-optimizer.sh" "$@"
            ;;
        compliance)
            bash "$SCRIPT_DIR/compliance/compliance.sh" "$@"
            ;;
        pve)
            bash "$SCRIPT_DIR/pve/pve.sh" "$@"
            ;;
        menu)
            bash "$SCRIPT_DIR/menu.sh" "$@"
            ;;
        plugin)
            plugin_main "$@"
            ;;
        *)
            print_error "未知命令: $command"
            echo "运行 '$0 help' 查看帮助"
            exit 1
            ;;
    esac
}

main "$@"
