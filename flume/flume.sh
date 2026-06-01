#!/bin/bash
# 描述：部署 Apache Flume - 日志收集工具

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

FLUME_VERSION=${1:-1.11.0}
FLUME_HOME="/opt/flume"
FLUME_TAR="apache-flume-$FLUME_VERSION-bin.tar.gz"
FLUME_URL="https://dlcdn.apache.org/flume/$FLUME_VERSION/$FLUME_TAR"

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

download_flume() {
    print_step 2 5 "下载 Flume $FLUME_VERSION"
    
    if [ -f "/tmp/$FLUME_TAR" ]; then
        print_info "使用已下载的文件"
    else
        download_with_retry "$FLUME_URL" "/tmp/$FLUME_TAR"
    fi
}

extract_and_install() {
    print_step 3 5 "解压并安装 Flume"
    
    tar xzf "/tmp/$FLUME_TAR" -C /opt
    rm -rf "$FLUME_HOME"
    ln -sf "/opt/apache-flume-$FLUME_VERSION-bin" "$FLUME_HOME"
    
    mkdir -p "$FLUME_HOME/logs"
    mkdir -p "$FLUME_HOME/conf"
    
    print_success "Flume 安装完成: $FLUME_HOME"
}

configure_flume() {
    print_step 4 5 "配置 Flume"
    
    local java_home=$(readlink -f $(which java) | sed 's:/bin/java::')
    
    cat > "$FLUME_HOME/conf/flume-env.sh" << EOF
export JAVA_HOME=$java_home
export FLUME_HOME=$FLUME_HOME
export FLUME_CONF_DIR=$FLUME_HOME/conf
export FLUME_LOG_DIR=$FLUME_HOME/logs
EOF
    
    cat > "$FLUME_HOME/conf/example.conf" << 'EOF'
# example.conf: A single-node Flume configuration

# Name the components on this agent
agent.sources = netcatSource
agent.sinks = loggerSink
agent.channels = memoryChannel

# Configure source
agent.sources.netcatSource.type = netcat
agent.sources.netcatSource.bind = 0.0.0.0
agent.sources.netcatSource.port = 44444

# Describe sink
agent.sinks.loggerSink.type = logger

# Use a channel which buffers events in memory
agent.channels.memoryChannel.type = memory
agent.channels.memoryChannel.capacity = 1000
agent.channels.memoryChannel.transactionCapacity = 100

# Bind the source and sink to the channel
agent.sources.netcatSource.channels = memoryChannel
agent.sinks.loggerSink.channel = memoryChannel
EOF
    
    print_success "Flume 配置完成"
}

show_usage() {
    cat << EOF
${GREEN}Apache Flume 部署工具${NC}

${YELLOW}命令:${NC}
  install       - 安装并配置 Flume
  start         - 启动 Flume Agent (指定配置)
  status        - 查看状态

${YELLOW}示例:${NC}
  $0 install
  $0 start example.conf agent
  $0 status
EOF
}

show_status() {
    print_header "Flume 状态"
    
    echo -e "${YELLOW}环境变量:${NC}"
    echo "  export FLUME_HOME=$FLUME_HOME"
    echo "  export PATH=\$PATH:$FLUME_HOME/bin"
    echo ""
    echo -e "${YELLOW}配置目录:${NC}"
    echo "  $FLUME_HOME/conf"
    echo ""
    echo -e "${YELLOW}快速启动:${NC}"
    echo "  $FLUME_HOME/bin/flume-ng agent --conf $FLUME_HOME/conf --conf-file $FLUME_HOME/conf/example.conf --name agent -Dflume.root.logger=INFO,console"
}

start_agent() {
    local config_file=$1
    local agent_name=$2
    
    if [ -z "$config_file" ] || [ -z "$agent_name" ]; then
        print_error "用法: $0 start <config-file> <agent-name>"
        exit 1
    fi
    
    if [ ! -f "$FLUME_HOME/conf/$config_file" ]; then
        print_error "配置文件不存在: $FLUME_HOME/conf/$config_file"
        exit 1
    fi
    
    print_header "启动 Flume Agent"
    
    $FLUME_HOME/bin/flume-ng agent \
        --conf $FLUME_HOME/conf \
        --conf-file $FLUME_HOME/conf/$config_file \
        --name $agent_name \
        -Dflume.root.logger=INFO,console \
        > $FLUME_HOME/logs/$agent_name.log 2>&1 &
    
    print_success "Flume Agent 已启动，日志: $FLUME_HOME/logs/$agent_name.log"
}

main() {
    local command=$1
    shift
    
    check_root
    check_os
    
    case $command in
        install)
            print_header "部署 Apache Flume"
            install_jdk
            download_flume
            extract_and_install
            configure_flume
            
            echo ""
            show_status
            ;;
        start)
            start_agent "$1" "$2"
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
