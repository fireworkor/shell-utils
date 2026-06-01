#!/bin/bash
# 描述：部署 Apache Zeppelin - 交互式数据分析笔记本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

ZEPPELIN_VERSION=${1:-0.11.0}
ZEPPELIN_HOME="/opt/zeppelin"
ZEPPELIN_TAR="zeppelin-$ZEPPELIN_VERSION-bin-all.tgz"
ZEPPELIN_URL="https://dlcdn.apache.org/zeppelin/zeppelin-$ZEPPELIN_VERSION/$ZEPPELIN_TAR"

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

download_zeppelin() {
    print_step 2 5 "下载 Zeppelin $ZEPPELIN_VERSION"
    
    if [ -f "/tmp/$ZEPPELIN_TAR" ]; then
        print_info "使用已下载的文件"
    else
        download_with_retry "$ZEPPELIN_URL" "/tmp/$ZEPPELIN_TAR"
    fi
}

extract_and_install() {
    print_step 3 5 "解压并安装 Zeppelin"
    
    tar xzf "/tmp/$ZEPPELIN_TAR" -C /opt
    rm -rf "$ZEPPELIN_HOME"
    ln -sf "/opt/zeppelin-$ZEPPELIN_VERSION-bin-all" "$ZEPPELIN_HOME"
    
    mkdir -p "$ZEPPELIN_HOME/logs"
    mkdir -p "$ZEPPELIN_HOME/notebook"
    
    print_success "Zeppelin 安装完成: $ZEPPELIN_HOME"
}

configure_zeppelin() {
    print_step 4 5 "配置 Zeppelin"
    
    local java_home=$(readlink -f $(which java) | sed 's:/bin/java::')
    
    cat > "$ZEPPELIN_HOME/conf/zeppelin-env.sh" << EOF
export JAVA_HOME=$java_home
export ZEPPELIN_HOME=$ZEPPELIN_HOME
export ZEPPELIN_CONF_DIR=$ZEPPELIN_HOME/conf
export ZEPPELIN_LOG_DIR=$ZEPPELIN_HOME/logs
export ZEPPELIN_NOTEBOOK_DIR=$ZEPPELIN_HOME/notebook
export ZEPPELIN_PORT=8088
EOF
    
    print_success "Zeppelin 配置完成"
}

start_zeppelin() {
    print_step 5 5 "启动 Zeppelin"
    
    $ZEPPELIN_HOME/bin/zeppelin-daemon.sh start
    
    print_success "Zeppelin 已启动"
    print_info "Web UI: http://localhost:8088"
}

show_usage() {
    cat << EOF
${GREEN}Apache Zeppelin 部署工具${NC}

${YELLOW}命令:${NC}
  install       - 安装并配置 Zeppelin
  start         - 启动 Zeppelin
  stop          - 停止 Zeppelin
  status        - 查看状态
  restart       - 重启 Zeppelin

${YELLOW}示例:${NC}
  $0 install
  $0 start
  $0 stop
  $0 status
EOF
}

show_status() {
    print_header "Zeppelin 状态"
    
    echo -e "${YELLOW}环境变量:${NC}"
    echo "  export ZEPPELIN_HOME=$ZEPPELIN_HOME"
    echo "  export PATH=\$PATH:$ZEPPELIN_HOME/bin"
    echo ""
    echo -e "${YELLOW}Web UI:${NC}"
    echo "  http://localhost:8088"
    echo ""
    echo -e "${YELLOW}目录结构:${NC}"
    echo "  Notebook: $ZEPPELIN_HOME/notebook"
    echo "  日志: $ZEPPELIN_HOME/logs"
    echo "  配置: $ZEPPELIN_HOME/conf"
}

stop_zeppelin() {
    print_header "停止 Zeppelin"
    $ZEPPELIN_HOME/bin/zeppelin-daemon.sh stop
    print_success "Zeppelin 已停止"
}

restart_zeppelin() {
    print_header "重启 Zeppelin"
    $ZEPPELIN_HOME/bin/zeppelin-daemon.sh restart
    print_success "Zeppelin 已重启"
}

main() {
    local command=$1
    shift
    
    check_root
    check_os
    
    case $command in
        install)
            print_header "部署 Apache Zeppelin"
            install_jdk
            download_zeppelin
            extract_and_install
            configure_zeppelin
            start_zeppelin
            
            echo ""
            show_status
            ;;
        start)
            start_zeppelin
            ;;
        stop)
            stop_zeppelin
            ;;
        restart)
            restart_zeppelin
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
