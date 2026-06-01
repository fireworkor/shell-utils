#!/bin/bash
# 描述：部署 Spark - 支持单机和集群模式

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

SPARK_VERSION=${1:-3.5.0}
SCALA_VERSION=2.12
SPARK_HOME="/opt/spark"
SPARK_TAR="spark-$SPARK_VERSION-bin-hadoop3.tgz"
SPARK_URL="https://dlcdn.apache.org/spark/spark-$SPARK_VERSION/$SPARK_TAR"

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

download_spark() {
    print_step 2 5 "下载 Spark $SPARK_VERSION"
    
    if [ -f "/tmp/$SPARK_TAR" ]; then
        print_info "使用已下载的文件"
    else
        download_with_retry "$SPARK_URL" "/tmp/$SPARK_TAR"
    fi
}

extract_and_install() {
    print_step 3 5 "解压并安装 Spark"
    
    tar xzf "/tmp/$SPARK_TAR" -C /opt
    rm -rf "$SPARK_HOME"
    ln -sf "/opt/spark-$SPARK_VERSION-bin-hadoop3" "$SPARK_HOME"
    
    mkdir -p "$SPARK_HOME/logs"
    mkdir -p "$SPARK_HOME/work"
    
    print_success "Spark 安装完成: $SPARK_HOME"
}

config_local_mode() {
    print_step 4 5 "配置单机模式"
    
    local java_home=$(readlink -f $(which java) | sed 's:/bin/java::')
    
    cat > "$SPARK_HOME/conf/spark-env.sh" << EOF
export JAVA_HOME=$java_home
export SPARK_HOME=$SPARK_HOME
export SPARK_LOG_DIR=$SPARK_HOME/logs
export SPARK_WORKER_DIR=$SPARK_HOME/work
export SPARK_DRIVER_MEMORY=2G
export SPARK_EXECUTOR_MEMORY=2G
EOF
    
    cp "$SPARK_HOME/conf/spark-defaults.conf.template" "$SPARK_HOME/conf/spark-defaults.conf"
    
    print_success "单机模式配置完成"
}

config_standalone_mode() {
    print_step 4 5 "配置 Standalone 模式"
    
    local java_home=$(readlink -f $(which java) | sed 's:/bin/java::')
    
    cat > "$SPARK_HOME/conf/spark-env.sh" << EOF
export JAVA_HOME=$java_home
export SPARK_HOME=$SPARK_HOME
export SPARK_LOG_DIR=$SPARK_HOME/logs
export SPARK_WORKER_DIR=$SPARK_HOME/work
export SPARK_DRIVER_MEMORY=2G
export SPARK_EXECUTOR_MEMORY=2G
export SPARK_MASTER_HOST=localhost
export SPARK_MASTER_PORT=7077
EOF
    
    cp "$SPARK_HOME/conf/spark-defaults.conf.template" "$SPARK_HOME/conf/spark-defaults.conf"
    
    echo "localhost" > "$SPARK_HOME/conf/workers"
    
    print_success "Standalone 模式配置完成"
}

start_spark() {
    print_step 5 5 "启动 Spark"
    
    if [ "$1" = "standalone" ]; then
        $SPARK_HOME/sbin/start-master.sh
        $SPARK_HOME/sbin/start-workers.sh
    else
        print_info "单机模式无需启动服务"
    fi
    
    print_success "Spark 启动完成"
}

show_usage() {
    cat << EOF
${GREEN}Spark 部署工具${NC}

${YELLOW}命令:${NC}
  local       - 单机模式
  standalone  - Standalone 模式
  stop        - 停止 Spark
  status      - 查看状态
  shell       - 启动 Spark Shell

${YELLOW}示例:${NC}
  $0 local
  $0 standalone
  $0 stop
  $0 status
  $0 shell
EOF
}

show_status() {
    print_header "Spark 状态"
    
    if command -v jps &>/dev/null; then
        echo -e "${YELLOW}Java 进程:${NC}"
        jps
    fi
    
    echo ""
    echo -e "${YELLOW}Web 界面:${NC}"
    echo "  Master UI: http://localhost:8080"
    echo "  Application UI: http://localhost:4040 (运行时)"
    echo ""
    echo -e "${YELLOW}环境变量:${NC}"
    echo "  export SPARK_HOME=$SPARK_HOME"
    echo "  export PATH=\$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin"
    echo ""
    echo -e "${YELLOW}快速启动:${NC}"
    echo "  $SPARK_HOME/bin/spark-shell"
    echo "  $SPARK_HOME/bin/spark-submit --class org.apache.spark.examples.SparkPi \$SPARK_HOME/examples/jars/spark-examples_2.12-$SPARK_VERSION.jar 10"
}

stop_spark() {
    print_header "停止 Spark"
    $SPARK_HOME/sbin/stop-workers.sh
    $SPARK_HOME/sbin/stop-master.sh
    print_success "Spark 已停止"
}

start_shell() {
    print_header "启动 Spark Shell"
    $SPARK_HOME/bin/spark-shell
}

main() {
    local command=$1
    shift
    
    check_root
    check_os
    
    case $command in
        local)
            print_header "部署 Spark 单机模式"
            install_jdk
            download_spark
            extract_and_install
            config_local_mode
            
            echo ""
            show_status
            ;;
        standalone)
            print_header "部署 Spark Standalone 模式"
            install_jdk
            download_spark
            extract_and_install
            config_standalone_mode
            start_spark standalone
            
            echo ""
            show_status
            ;;
        stop)
            stop_spark
            ;;
        status)
            show_status
            ;;
        shell)
            start_shell
            ;;
        *)
            show_usage
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
