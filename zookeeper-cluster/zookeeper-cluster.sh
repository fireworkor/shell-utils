#!/bin/bash
# 描述：部署 Zookeeper 集群 - 支持伪分布式模式

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

ZK_VERSION=${1:-3.8.3}
NODE_COUNT=${2:-3}
BASE_PORT=${3:-2181}
BASE_DATA_DIR="/opt/zookeeper-cluster"

install_zookeeper() {
    print_step 1 4 "安装 Zookeeper"

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

    print_success "Java 已就绪"
}

configure_cluster() {
    print_step 2 4 "配置 Zookeeper 伪集群"

    for i in $(seq 1 $NODE_COUNT); do
        local port=$((BASE_PORT + i - 1))
        local data_dir="$BASE_DATA_DIR/node$i"
        mkdir -p "$data_dir"

        echo $i > "$data_dir/myid"

        cat > "/opt/zookeeper-node$i.properties" << EOF
tickTime=2000
initLimit=10
syncLimit=5
dataDir=$data_dir
clientPort=$port
EOF

        for j in $(seq 1 $NODE_COUNT); do
            local peer_port=$((2880 + j - 1))
            local election_port=$((3880 + j - 1))
            echo "server.$j=127.0.0.1:$peer_port:$election_port" >> "/opt/zookeeper-node$i.properties"
        done

        print_success "节点 $i (端口 $port) 配置完成"
    done
}

start_cluster() {
    print_step 3 4 "启动 Zookeeper 集群"

    if [ ! -d /opt/zookeeper ]; then
        local url="https://dlcdn.apache.org/zookeeper/zookeeper-$ZK_VERSION/apache-zookeeper-$ZK_VERSION-bin.tar.gz"
        download_with_retry "$url" /tmp/zookeeper.tar.gz
        tar xzf /tmp/zookeeper.tar.gz -C /opt
        ln -sf /opt/apache-zookeeper-$ZK_VERSION-bin /opt/zookeeper
    fi

    for i in $(seq 1 $NODE_COUNT); do
        export ZOO_LOG_DIR="$BASE_DATA_DIR/node$i/logs"
        mkdir -p "$ZOO_LOG_DIR"
        ZOOCFGDIR=/opt /opt/zookeeper/bin/zkServer.sh start "/opt/zookeeper-node$i.properties"
    done

    sleep 3
    print_success "Zookeeper 集群启动完成"
}

show_status() {
    print_step 4 4 "集群状态"

    echo -e "\n${YELLOW}Zookeeper 集群节点:${NC}"
    for i in $(seq 1 $NODE_COUNT); do
        local port=$((BASE_PORT + i - 1))
        echo -n "节点 $i (端口 $port): "
        ZOOCFGDIR=/opt /opt/zookeeper/bin/zkServer.sh status "/opt/zookeeper-node$i.properties" 2>&1 || true
    done

    echo -e "\n${YELLOW}连接命令:${NC}"
    echo "  zkCli.sh -server 127.0.0.1:$BASE_PORT"
}

stop_cluster() {
    print_header "停止 Zookeeper 集群"

    for i in $(seq 1 $NODE_COUNT); do
        ZOOCFGDIR=/opt /opt/zookeeper/bin/zkServer.sh stop "/opt/zookeeper-node$i.properties" 2>/dev/null || true
    done

    print_success "集群已停止"
}

show_usage() {
    cat << EOF
${GREEN}Zookeeper 集群部署工具${NC}

${YELLOW}命令:${NC}
  install          - 安装并部署 Zookeeper 伪集群
  start            - 启动集群
  stop             - 停止集群
  status           - 查看集群状态
  test             - 测试集群功能

${YELLOW}集群架构:${NC}
  节点数: $NODE_COUNT
  客户端端口: $BASE_PORT - $((BASE_PORT + NODE_COUNT - 1))

${YELLOW}示例:${NC}
  $0 install
  $0 status
  $0 test
  $0 stop
EOF
}

main() {
    local command=$1
    shift

    check_root

    case $command in
        install)
            print_header "部署 Zookeeper 伪集群"
            install_zookeeper
            configure_cluster
            start_cluster
            show_status
            ;;
        start)
            start_cluster
            ;;
        stop)
            stop_cluster
            ;;
        status)
            show_status
            ;;
        test)
            print_header "测试 Zookeeper 集群"
            /opt/zookeeper/bin/zkCli.sh -server 127.0.0.1:$BASE_PORT ls / 2>/dev/null || echo "请先启动集群"
            ;;
        *)
            show_usage
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
