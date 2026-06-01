#!/bin/bash
# 描述：部署 Elasticsearch 集群

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

ES_VERSION=${1:-8.11.0}
NODE_COUNT=${2:-3}
BASE_PORT=${3:-9200}
TRANSPORT_BASE_PORT=${4:-9300}
BASE_DATA_DIR="/opt/elasticsearch-cluster"

install_elasticsearch() {
    print_step 1 4 "检查 Java 并准备"

    if ! command -v java &>/dev/null; then
        local pkg_manager=$(get_pkg_manager)
        case $pkg_manager in
            dnf|yum)
                yum install -y java-17-openjdk java-17-openjdk-devel
                ;;
            apt)
                export DEBIAN_FRONTEND=noninteractive
                apt update
                apt install -y openjdk-17-jdk
                ;;
        esac
    fi

    if [ ! -d /opt/elasticsearch ]; then
        local url="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$ES_VERSION-linux-x86_64.tar.gz"
        print_step "Download" "下载 Elasticsearch"
        download_with_retry "$url" /tmp/elasticsearch.tar.gz
        tar xzf /tmp/elasticsearch.tar.gz -C /opt
        ln -sf "/opt/elasticsearch-$ES_VERSION" /opt/elasticsearch
        print_success "Elasticsearch 安装完成"
    fi
}

configure_es_cluster() {
    print_step 2 4 "配置 Elasticsearch 伪集群"

    for i in $(seq 1 $NODE_COUNT); do
        local http_port=$((BASE_PORT + i - 1))
        local transport_port=$((TRANSPORT_BASE_PORT + i - 1))
        local data_dir="$BASE_DATA_DIR/node$i"
        local log_dir="$BASE_DATA_DIR/node$i/logs"
        mkdir -p "$data_dir" "$log_dir"

        cat > "/opt/elasticsearch-node$i.yml" << EOF
cluster.name: shell-utils-cluster
node.name: node-$i
node.master: true
node.data: true
node.ingest: true
node.roles: [master, data, ingest]
path.data: $data_dir
path.logs: $log_dir
http.port: $http_port
transport.port: $transport_port
network.host: 127.0.0.1
discovery.seed_hosts:
EOF
        for j in $(seq 1 $NODE_COUNT); do
            local tp=$((TRANSPORT_BASE_PORT + j - 1))
            echo "  - 127.0.0.1:$tp" >> "/opt/elasticsearch-node$i.yml"
        done
        echo "cluster.initial_master_nodes: [\"node-1\", \"node-2\", \"node-3\"]" >> "/opt/elasticsearch-node$i.yml"
        echo "xpack.security.enabled: false" >> "/opt/elasticsearch-node$i.yml"

        print_success "节点 $i (HTTP: $http_port, Transport: $transport_port) 配置完成"
    done
}

start_es_cluster() {
    print_step 3 4 "启动 Elasticsearch 集群"

    for i in $(seq 1 $NODE_COUNT); do
        local log_dir="$BASE_DATA_DIR/node$i/logs"
        mkdir -p "$log_dir"
        export ES_PATH_CONF="/opt"
        export ES_JAVA_OPTS="-Xms512m -Xmx512m"
        /opt/elasticsearch/bin/elasticsearch -E path.conf=/opt -E node.config=elasticsearch-node$i.yml -d -p "$log_dir/pid"
    done

    sleep 10
    print_success "Elasticsearch 集群启动完成"
}

show_es_status() {
    print_step 4 4 "Elasticsearch 集群状态"

    echo -e "\n${YELLOW}Elasticsearch 节点:${NC}"
    for i in $(seq 1 $NODE_COUNT); do
        local http_port=$((BASE_PORT + i - 1))
        echo -e "  Node $i: http://127.0.0.1:$http_port"
    done

    echo -e "\n${YELLOW}集群健康检查:${NC}"
    curl -s "http://127.0.0.1:$BASE_PORT/_cluster/health?pretty" 2>/dev/null || echo "请先启动集群"
}

stop_es() {
    print_header "停止 Elasticsearch 集群"

    for i in $(seq 1 $NODE_COUNT); do
        local log_dir="$BASE_DATA_DIR/node$i/logs"
        if [ -f "$log_dir/pid" ]; then
            kill "$(cat $log_dir/pid)" 2>/dev/null || true
            rm -f "$log_dir/pid"
        fi
    done

    print_success "Elasticsearch 集群已停止"
}

show_usage() {
    cat << EOF
${GREEN}Elasticsearch 集群部署工具${NC}

${YELLOW}命令:${NC}
  install          - 安装并部署伪集群
  start            - 启动集群
  stop             - 停止集群
  status           - 查看集群状态

${YELLOW}集群架构:${NC}
  节点数: $NODE_COUNT
  HTTP 端口: $BASE_PORT - $((BASE_PORT + NODE_COUNT - 1))
  Transport 端口: $TRANSPORT_BASE_PORT - $((TRANSPORT_BASE_PORT + NODE_COUNT - 1))

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
            print_header "部署 Elasticsearch 伪集群"
            install_elasticsearch
            configure_es_cluster
            start_es_cluster
            show_es_status
            ;;
        start)
            start_es_cluster
            ;;
        stop)
            stop_es
            ;;
        status)
            show_es_status
            ;;
        *)
            show_usage
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
