#!/bin/bash
# 描述：部署 Apache Airflow - 工作流调度平台

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

AIRFLOW_VERSION=${1:-2.8.3}
AIRFLOW_HOME="/opt/airflow"

install_python() {
    print_step 1 6 "检查/安装 Python"
    
    if ! command -v python3 &>/dev/null; then
        local pkg_manager=$(get_pkg_manager)
        case $pkg_manager in
            dnf|yum)
                yum install -y python3 python3-pip python3-devel
                ;;
            apt)
                export DEBIAN_FRONTEND=noninteractive
                apt update
                apt install -y python3 python3-pip python3-dev
                ;;
        esac
    fi
    
    print_success "Python 已就绪"
}

install_airflow() {
    print_step 2 6 "安装 Airflow"
    
    export AIRFLOW_HOME="$AIRFLOW_HOME"
    
    pip3 install --break-system-packages "apache-airflow==$AIRFLOW_VERSION" --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-$AIRFLOW_VERSION/constraints-3.8.txt"
    
    print_success "Airflow 安装完成"
}

initialize_airflow() {
    print_step 3 6 "初始化 Airflow"
    
    export AIRFLOW_HOME="$AIRFLOW_HOME"
    mkdir -p "$AIRFLOW_HOME/dags"
    mkdir -p "$AIRFLOW_HOME/logs"
    mkdir -p "$AIRFLOW_HOME/plugins"
    
    # 初始化数据库
    airflow db init
    
    # 创建默认用户
    airflow users create \
        --username admin \
        --firstname Admin \
        --lastname User \
        --role Admin \
        --email admin@example.com \
        --password admin
    
    print_success "Airflow 初始化完成"
}

configure_airflow() {
    print_step 4 6 "配置 Airflow"
    
    cat > "$AIRFLOW_HOME/airflow.cfg" << 'EOF'
[core]
dags_folder = /opt/airflow/dags
base_log_folder = /opt/airflow/logs
executor = SequentialExecutor
sql_alchemy_conn = sqlite:////opt/airflow/airflow.db
parallelism = 32
dag_concurrency = 16
max_active_runs_per_dag = 16
load_examples = False
plugins_folder = /opt/airflow/plugins

[scheduler]
job_heartbeat_sec = 5
scheduler_heartbeat_sec = 5
dag_dir_list_interval = 300

[webserver]
host = 0.0.0.0
port = 8080
dag_default_view = tree
dag_orientation = LR

[api]
auth_backend = airflow.api.auth.backend.basic_auth
EOF
    
    print_success "Airflow 配置完成"
}

start_airflow() {
    print_step 5 6 "启动 Airflow"
    
    export AIRFLOW_HOME="$AIRFLOW_HOME"
    
    # 启动 Web Server
    airflow webserver -p 8080 > "$AIRFLOW_HOME/logs/webserver.log" 2>&1 &
    
    # 启动 Scheduler
    airflow scheduler > "$AIRFLOW_HOME/logs/scheduler.log" 2>&1 &
    
    print_success "Airflow 已启动"
    print_info "Web UI: http://localhost:8080"
    print_info "用户名: admin"
    print_info "密码: admin"
}

show_usage() {
    cat << EOF
${GREEN}Apache Airflow 部署工具${NC}

${YELLOW}命令:${NC}
  install       - 安装并配置 Airflow
  start         - 启动 Airflow (Web Server + Scheduler)
  stop          - 停止 Airflow
  status        - 查看状态
  webserver     - 仅启动 Web Server
  scheduler     - 仅启动 Scheduler

${YELLOW}示例:${NC}
  $0 install
  $0 start
  $0 stop
  $0 status
EOF
}

show_status() {
    print_header "Airflow 状态"
    
    echo -e "${YELLOW}环境变量:${NC}"
    echo "  export AIRFLOW_HOME=$AIRFLOW_HOME"
    echo "  export PATH=\$PATH:\$HOME/.local/bin"
    echo ""
    echo -e "${YELLOW}Web UI:${NC}"
    echo "  http://localhost:8080"
    echo "  用户名: admin"
    echo "  密码: admin"
    echo ""
    echo -e "${YELLOW}目录结构:${NC}"
    echo "  DAGs: $AIRFLOW_HOME/dags"
    echo "  日志: $AIRFLOW_HOME/logs"
    echo "  插件: $AIRFLOW_HOME/plugins"
}

stop_airflow() {
    print_header "停止 Airflow"
    
    pkill -f "airflow webserver" 2>/dev/null || true
    pkill -f "airflow scheduler" 2>/dev/null || true
    
    print_success "Airflow 已停止"
}

start_webserver() {
    export AIRFLOW_HOME="$AIRFLOW_HOME"
    airflow webserver -p 8080 > "$AIRFLOW_HOME/logs/webserver.log" 2>&1 &
    print_success "Web Server 已启动"
}

start_scheduler() {
    export AIRFLOW_HOME="$AIRFLOW_HOME"
    airflow scheduler > "$AIRFLOW_HOME/logs/scheduler.log" 2>&1 &
    print_success "Scheduler 已启动"
}

main() {
    local command=$1
    shift
    
    check_root
    check_os
    
    case $command in
        install)
            print_header "部署 Apache Airflow"
            install_python
            install_airflow
            initialize_airflow
            configure_airflow
            
            echo ""
            show_status
            ;;
        start)
            start_airflow
            ;;
        stop)
            stop_airflow
            ;;
        webserver)
            start_webserver
            ;;
        scheduler)
            start_scheduler
            ;;
        status)
            show_status
            ;;
        *)
            show_usage
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
