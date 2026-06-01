#!/bin/bash
# 描述：部署 Kafka 集群 - 支持伪分布式模式

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

KAFKA_VERSION=${1:-3.6.0}
SCALA_VERSION=${2:-2.13}
BROKER_COUNT=${3:-3}
BASE_PORT=${4:-9092}
ZK_BASE_PORT=${5:-2181}
BASE_DATA_DIR="/opt/kafka-cluster"

install_kafka() {
    print_step 1 4 "检查 Zookeeper 和安装 Kafka"

    if ! command -v java &>/dev/null; then
        local pkg_manager=$(get_pkg_manager)
        case $pkg_manager in
            dnf|yum)
                yum install -y java-11-openjdk java-11-openjdk-devel
                ;;
            apt)
                export DEBIAN_FRONTEND=noninteractive
                apt update
                apt install -y openjdk-11-jdk
                ;;
        esac
    fi

    local url="https://dlcdn.apache.org/kafka/$KAFKA_VERSION/kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz"

    if [ ! -d /opt/kafka ]; then
        print_step "Download" "下载 Kafka"
        download_with_retry "$url" /tmp/kafka.tar.gz
        tar xzf /tmp/kafka.tar.gz -C /opt
        ln -sf "/opt/kafka_$SCALA_VERSION-$KAFKA_VERSION" /opt/kafka
        print_success "Kafka 安装完成"
    fi
}

configure_kafka_cluster() {
    print_step 2 4 "配置 Kafka 伪集群"

    for i in $(seq 1 $BROKER_COUNT); do
        local port=$((BASE_PORT + i - 1))
        local data_dir="$BASE_DATA_DIR/broker$i"
        mkdir -p "$data_dir"

        local zk_connect="127.0.0.1:$ZK_BASE_PORT"
        for j in $(seq 2 $BROKER_COUNT); do
            local zk_p=$((ZK_BASE_PORT + j - 1))
            zk_connect="$zk_connect,127.0.0.1:$zk_p"
        done

        cat > "/opt/kafka-broker$i.properties" << EOF
broker.id=$((i - 1))
listeners=PLAINTEXT://127.0.0.1:$port
advertised.listeners=PLAINTEXT://127.0.0.1:$port
log.dirs=$data_dir
zookeeper.connect=$zk_connect
num.partitions=3
default.replication.factor=2
offsets.topic.replication.factor=2
transaction.state.log.replication.factor=2
transaction.state.log.min.isr=1
EOF

        print_success "Broker $i (端口 $port) 配置完成"
    done
}

start_kafka_cluster() {
    print_step 3 4 "启动 Kafka 集群"

    if [ ! -f "$SCRIPT_DIR/../zookeeper-cluster/zookeeper-cluster.sh" ]; then
        print_warning "未找到 Zookeeper 脚本，请先部署 Zookeeper 集群"
    fi

    for i in $(seq 1 $BROKER_COUNT); do
        local log_dir="$BASE_DATA_DIR/broker$i/logs"
        mkdir -p "$log_dir"
        export LOG_DIR="$log_dir"
        /opt/kafka/bin/kafka-server-start.sh -daemon "/opt/kafka-broker$i.properties"
    done

    sleep 3
    print_success "Kafka 集群启动完成"
}

show_kafka_status() {
    print_step 4 4 "Kafka 集群状态"

    echo -e "\n${YELLOW}Kafka 集群节点:${NC}"
    for i in $(seq 1 $BROKER_COUNT); do
        local port=$((BASE_PORT + i - 1))
        echo -e "  Broker $((i - 1)): 127.0.0.1:$port"
    done

    echo -e "\n${YELLOW}快速测试命令:${NC}"
    echo "  # 创建测试主题"
    echo "  /opt/kafka/bin/kafka-topics.sh --create --topic test --bootstrap-server 127.0.0.1:$BASE_PORT --partitions 3 --replication-factor 2"
    echo ""
    echo "  # 列出主题"
    echo "  /opt/kafka/bin/kafka-topics.sh --list --bootstrap-server 127.0.0.1:$BASE_PORT"
    echo ""
    echo "  # 生产者测试"
    echo "  /opt/kafka/bin/kafka-console-producer.sh --topic test --bootstrap-server 127.0.0.1:$BASE_PORT"
    echo ""
    echo "  # 消费者测试"
    echo "  /opt/kafka/bin/kafka-console-consumer.sh --topic test --from-beginning --bootstrap-server 127.0.0.1:$BASE_PORT"
}

stop_kafka() {
    print_header "停止 Kafka 集群"

    for i in $(seq 1 $BROKER_COUNT); do
        /opt/kafka/bin/kafka-server-stop.sh 2>/dev/null || true
    done

    print_success "Kafka 集群已停止"
}

show_usage() {
    cat << EOF
${GREEN}Kafka 集群部署工具${NC}

${YELLOW}命令:${NC}
  install          - 安装并部署 Kafka 伪集群
  start            - 启动集群
  stop             - 停止集群
  status           - 查看集群状态
  test             - 测试集群功能

${YELLOW}集群架构:${NC}
  Broker 数: $BROKER_COUNT
  端口: $BASE_PORT - $((BASE_PORT + BROKER_COUNT - 1))

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
            print_header "部署 Kafka 伪集群"
            install_kafka
            configure_kafka_cluster
            start_kafka_cluster
            show_kafka_status
            ;;
        start)
            start_kafka_cluster
            ;;
        stop)
            stop_kafka
            ;;
        status)
            show_kafka_status
            ;;
        *)
            show_usage
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
