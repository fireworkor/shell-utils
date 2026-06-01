#!/bin/bash
# 描述：部署 Flink - 支持本地和集群模式

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

FLINK_VERSION=${1:-1.18.1}
SCALA_VERSION=2.12
FLINK_HOME="/opt/flink"
FLINK_TAR="flink-$FLINK_VERSION-bin-scala_$SCALA_VERSION.tgz"
FLINK_URL="https://dlcdn.apache.org/flink/flink-$FLINK_VERSION/$FLINK_TAR"

install_jdk() {
    print_step 1 5 "检查/安装 JDK"
    
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
    
    local java_home=$(readlink -f $(which java) | sed 's:/bin/java::')
    print_success "JDK 已就绪: $java_home"
    echo "$java_home"
}

download_flink() {
    print_step 2 5 "下载 Flink $FLINK_VERSION"
    
    if [ -f "/tmp/$FLINK_TAR" ]; then
        print_info "使用已下载的文件"
    else
        download_with_retry "$FLINK_URL" "/tmp/$FLINK_TAR"
    fi
}

extract_and_install() {
    print_step 3 5 "解压并安装 Flink"
    
    tar xzf "/tmp/$FLINK_TAR" -C /opt
    rm -rf "$FLINK_HOME"
    ln -sf "/opt/flink-$FLINK_VERSION" "$FLINK_HOME"
    
    mkdir -p "$FLINK_HOME/log"
    
    print_success "Flink 安装完成: $FLINK_HOME"
}

config_local_mode() {
    print_step 4 5 "配置本地模式"
    
    local java_home=$(readlink -f $(which java) | sed 's:/bin/java::')
    
    cat > "$FLINK_HOME/conf/flink-conf.yaml" << 'EOF'
jobmanager.rpc.address: localhost
jobmanager.rpc.port: 6123
jobmanager.memory.process.size: 1600m
taskmanager.memory.process.size: 1728m
taskmanager.numberOfTaskSlots: 1
parallelism.default: 1
state.backend: filesystem
state.checkpoints.dir: file:///opt/flink/checkpoints
state.savepoints.dir: file:///opt/flink/savepoints
EOF
    
    cat > "$FLINK_HOME/conf/flink-env.sh" << EOF
export JAVA_HOME=$java_home
export FLINK_HOME=$FLINK_HOME
EOF
    
    mkdir -p "$FLINK_HOME/checkpoints" "$FLINK_HOME/savepoints"
    
    print_success "本地模式配置完成"
}

config_cluster_mode() {
    print_step 4 5 "配置 Standalone 集群模式"
    
    local java_home=$(readlink -f $(which java) | sed 's:/bin/java::')
    
    cat > "$FLINK_HOME/conf/flink-conf.yaml" << 'EOF'
jobmanager.rpc.address: localhost
jobmanager.rpc.port: 6123
jobmanager.memory.process.size: 1600m
taskmanager.memory.process.size: 1728m
taskmanager.numberOfTaskSlots: 4
parallelism.default: 4
state.backend: filesystem
state.checkpoints.dir: file:///opt/flink/checkpoints
state.savepoints.dir: file:///opt/flink/savepoints
rest.port: 8081
rest.address: localhost
EOF
    
    cat > "$FLINK_HOME/conf/flink-env.sh" << EOF
export JAVA_HOME=$java_home
export FLINK_HOME=$FLINK_HOME
EOF
    
    echo "localhost" > "$FLINK_HOME/conf/workers"
    
    mkdir -p "$FLINK_HOME/checkpoints" "$FLINK_HOME/savepoints"
    
    print_success "集群模式配置完成"
}

start_flink() {
    print_step 5 5 "启动 Flink"
    
    if [ "$1" = "cluster" ]; then
        $FLINK_HOME/bin/start-cluster.sh
    else
        print_info "本地模式无需启动服务"
    fi
    
    print_success "Flink 启动完成"
}

show_usage() {
    cat << EOF
${GREEN}Flink 部署工具${NC}

${YELLOW}命令:${NC}
  local       - 本地模式
  cluster     - Standalone 集群模式
  stop        - 停止 Flink
  status      - 查看状态
  sql         - 启动 Flink SQL Client

${YELLOW}示例:${NC}
  $0 local
  $0 cluster
  $0 stop
  $0 status
  $0 sql
EOF
}

show_status() {
    print_header "Flink 状态"
    
    if command -v jps &>/dev/null; then
        echo -e "${YELLOW}Java 进程:${NC}"
        jps
    fi
    
    echo ""
    echo -e "${YELLOW}Web 界面:${NC}"
    echo "  Dashboard: http://localhost:8081"
    echo ""
    echo -e "${YELLOW}环境变量:${NC}"
    echo "  export FLINK_HOME=$FLINK_HOME"
    echo "  export PATH=\$PATH:$FLINK_HOME/bin"
    echo ""
    echo -e "${YELLOW}快速启动:${NC}"
    echo "  $FLINK_HOME/bin/flink run -c org.apache.flink.examples.java.wordcount.WordCount \$FLINK_HOME/examples/batch/WordCount.jar"
    echo "  $FLINK_HOME/bin/sql-client.sh"
}

stop_flink() {
    print_header "停止 Flink"
    $FLINK_HOME/bin/stop-cluster.sh
    print_success "Flink 已停止"
}

start_sql_client() {
    print_header "启动 Flink SQL Client"
    $FLINK_HOME/bin/sql-client.sh
}

main() {
    local command=$1
    shift
    
    check_root
    check_os
    
    case $command in
        local)
            print_header "部署 Flink 本地模式"
            install_jdk
            download_flink
            extract_and_install
            config_local_mode
            
            echo ""
            show_status
            ;;
        cluster)
            print_header "部署 Flink Standalone 集群模式"
            install_jdk
            download_flink
            extract_and_install
            config_cluster_mode
            start_flink cluster
            
            echo ""
            show_status
            ;;
        stop)
            stop_flink
            ;;
        status)
            show_status
            ;;
        sql)
            start_sql_client
            ;;
        *)
            show_usage
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
