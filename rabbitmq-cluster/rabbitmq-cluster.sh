#!/bin/bash
# 描述：部署 RabbitMQ 集群

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

RABBITMQ_VERSION=${1:-3.12.13}
ERLANG_VERSION=${2:-26.2}
NODE_COUNT=${3:-3}
BASE_AMQP_PORT=${4:-5672}
BASE_UI_PORT=${5:-15672}

install_rabbitmq() {
    print_step 1 4 "安装 Erlang 和 RabbitMQ"

    local pkg_manager=$(get_pkg_manager)
    case $pkg_manager in
        dnf|yum)
            yum install -y epel-release
            yum install -y erlang rabbitmq-server
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y rabbitmq-server erlang
            ;;
    esac

    print_success "RabbitMQ 和 Erlang 安装完成"
}

configure_rabbitmq_cluster() {
    print_step 2 4 "配置 RabbitMQ 集群准备"

    # 启用管理插件
    rabbitmq-plugins enable rabbitmq_management 2>/dev/null || true

    # 确保相同的 erlang cookie
    local cookie="/var/lib/rabbitmq/.erlang.cookie"
    if [ -f "$cookie" ]; then
        local cookie_val=$(cat "$cookie")
        mkdir -p /tmp/rabbitmq-nodes
        for i in $(seq 1 $NODE_COUNT); do
            echo "$cookie_val" > "/tmp/rabbitmq-nodes/.erlang.cookie.$i"
        done
    fi

    print_success "RabbitMQ 插件配置完成"
}

start_rabbitmq_cluster() {
    print_step 3 4 "启动 RabbitMQ 伪集群"

    # 启动第一个节点
    RABBITMQ_NODENAME=rabbit1@localhost \
    RABBITMQ_NODE_PORT=$BASE_AMQP_PORT \
    RABBITMQ_DIST_PORT=$((BASE_AMQP_PORT + 20000)) \
    rabbitmq-server -detached 2>/dev/null || true

    sleep 3

    for i in $(seq 2 $NODE_COUNT); do
        local amqp_port=$((BASE_AMQP_PORT + i - 1))
        local ui_port=$((BASE_UI_PORT + i - 1))
        local dist_port=$((amqp_port + 20000))

        RABBITMQ_NODENAME=rabbit$i@localhost \
        RABBITMQ_NODE_PORT=$amqp_port \
        RABBITMQ_DIST_PORT=$dist_port \
        rabbitmq-server -detached 2>/dev/null || true

        sleep 2

        rabbitmqctl -n rabbit$i@localhost stop_app 2>/dev/null || true
        rabbitmqctl -n rabbit$i@localhost reset 2>/dev/null || true
        rabbitmqctl -n rabbit$i@localhost join_cluster rabbit1@localhost 2>/dev/null || true
        rabbitmqctl -n rabbit$i@localhost start_app 2>/dev/null || true
    done

    # 配置高可用策略
    rabbitmqctl -n rabbit1@localhost set_policy ha-all "^" '{"ha-mode":"all"}' 2>/dev/null || true

    sleep 3
    print_success "RabbitMQ 集群启动完成"
}

show_rabbitmq_status() {
    print_step 4 4 "RabbitMQ 集群状态"

    echo -e "\n${YELLOW}集群状态:${NC}"
    rabbitmqctl -n rabbit1@localhost cluster_status 2>&1 || echo "请先启动集群"

    echo -e "\n${YELLOW}Web UI:${NC}"
    for i in $(seq 1 $NODE_COUNT); do
        echo -e "  Node $i: http://127.0.0.1:$((BASE_UI_PORT + i - 1))"
    done

    echo -e "\n${YELLOW}连接端口:${NC}"
    for i in $(seq 1 $NODE_COUNT); do
        echo -e "  Node $i: amqp://127.0.0.1:$((BASE_AMQP_PORT + i - 1))"
    done

    echo -e "\n默认用户: guest / guest (仅localhost)"
}

stop_rabbitmq() {
    print_header "停止 RabbitMQ 集群"

    for i in $(seq 1 $NODE_COUNT); do
        rabbitmqctl -n rabbit$i@localhost stop 2>/dev/null || true
    done

    print_success "RabbitMQ 集群已停止"
}

show_usage() {
    cat << EOF
${GREEN}RabbitMQ 集群部署工具${NC}

${YELLOW}命令:${NC}
  install          - 安装并部署 RabbitMQ 伪集群
  start            - 启动集群
  stop             - 停止集群
  status           - 查看集群状态

${YELLOW}集群架构:${NC}
  节点数: $NODE_COUNT
  AMQP 端口: $BASE_AMQP_PORT - $((BASE_AMQP_PORT + NODE_COUNT - 1))
  Web UI 端口: $BASE_UI_PORT - $((BASE_UI_PORT + NODE_COUNT - 1))

${YELLOW}示例:${NC}
  $0 install
  $0 status
  $0 stop
EOF
}

main() {
    local command=$1
    shift

    check_root

    case $command in
        install)
            print_header "部署 RabbitMQ 伪集群"
            install_rabbitmq
            configure_rabbitmq_cluster
            start_rabbitmq_cluster
            show_rabbitmq_status
            ;;
        start)
            start_rabbitmq_cluster
            ;;
        stop)
            stop_rabbitmq
            ;;
        status)
            show_rabbitmq_status
            ;;
        *)
            show_usage
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
