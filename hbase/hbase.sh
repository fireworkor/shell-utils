#!/bin/bash
# 描述：部署 HBase - 支持单机和伪分布式模式

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

HBASE_VERSION=${1:-2.5.6}
HBASE_HOME="/opt/hbase"
HBASE_TAR="hbase-$HBASE_VERSION-bin.tar.gz"
HBASE_URL="https://dlcdn.apache.org/hbase/$HBASE_VERSION/$HBASE_TAR"

install_jdk() {
    print_step 1 6 "检查/安装 JDK"
    
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

download_hbase() {
    print_step 2 6 "下载 HBase $HBASE_VERSION"
    
    if [ -f "/tmp/$HBASE_TAR" ]; then
        print_info "使用已下载的文件"
    else
        download_with_retry "$HBASE_URL" "/tmp/$HBASE_TAR"
    fi
}

extract_and_install() {
    print_step 3 6 "解压并安装 HBase"
    
    tar xzf "/tmp/$HBASE_TAR" -C /opt
    rm -rf "$HBASE_HOME"
    ln -sf "/opt/hbase-$HBASE_VERSION" "$HBASE_HOME"
    
    mkdir -p "$HBASE_HOME/logs"
    mkdir -p "$HBASE_HOME/data"
    
    print_success "HBase 安装完成: $HBASE_HOME"
}

config_standalone_mode() {
    print_step 4 6 "配置单机模式"
    
    local java_home=$(readlink -f $(which java) | sed 's:/bin/java::')
    
    cat > "$HBASE_HOME/conf/hbase-env.sh" << EOF
export JAVA_HOME=$java_home
export HBASE_HOME=$HBASE_HOME
export HBASE_LOG_DIR=$HBASE_HOME/logs
export HBASE_MANAGES_ZK=true
EOF
    
    cat > "$HBASE_HOME/conf/hbase-site.xml" << 'EOF'
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>hbase.rootdir</name>
    <value>file:///opt/hbase/data</value>
  </property>
  <property>
    <name>hbase.zookeeper.property.dataDir</name>
    <value>/opt/hbase/zookeeper</value>
  </property>
  <property>
    <name>hbase.zookeeper.quorum</name>
    <value>localhost</value>
  </property>
  <property>
    <name>hbase.cluster.distributed</name>
    <value>false</value>
  </property>
</configuration>
EOF
    
    print_success "单机模式配置完成"
}

config_pseudo_distributed_mode() {
    print_step 4 6 "配置伪分布式模式"
    
    local java_home=$(readlink -f $(which java) | sed 's:/bin/java::')
    
    cat > "$HBASE_HOME/conf/hbase-env.sh" << EOF
export JAVA_HOME=$java_home
export HBASE_HOME=$HBASE_HOME
export HBASE_LOG_DIR=$HBASE_HOME/logs
export HBASE_MANAGES_ZK=true
EOF
    
    cat > "$HBASE_HOME/conf/hbase-site.xml" << 'EOF'
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>hbase.rootdir</name>
    <value>hdfs://localhost:9000/hbase</value>
  </property>
  <property>
    <name>hbase.zookeeper.property.dataDir</name>
    <value>/opt/hbase/zookeeper</value>
  </property>
  <property>
    <name>hbase.zookeeper.quorum</name>
    <value>localhost</value>
  </property>
  <property>
    <name>hbase.cluster.distributed</name>
    <value>true</value>
  </property>
</configuration>
EOF
    
    echo "localhost" > "$HBASE_HOME/conf/regionservers"
    
    print_success "伪分布式模式配置完成"
}

start_hbase() {
    print_step 5 6 "启动 HBase"
    $HBASE_HOME/bin/start-hbase.sh
    print_success "HBase 启动完成"
}

show_usage() {
    cat << EOF
${GREEN}HBase 部署工具${NC}

${YELLOW}命令:${NC}
  standalone    - 单机模式
  pseudo        - 伪分布式模式（需要 Hadoop）
  stop          - 停止 HBase
  status        - 查看状态
  shell         - 启动 HBase Shell

${YELLOW}示例:${NC}
  $0 standalone
  $0 pseudo
  $0 stop
  $0 status
  $0 shell
EOF
}

show_status() {
    print_header "HBase 状态"
    
    if command -v jps &>/dev/null; then
        echo -e "${YELLOW}Java 进程:${NC}"
        jps
    fi
    
    echo ""
    echo -e "${YELLOW}Web UI:${NC}"
    echo "  Master: http://localhost:16010"
    echo "  RegionServer: http://localhost:16030"
    echo ""
    echo -e "${YELLOW}环境变量:${NC}"
    echo "  export HBASE_HOME=$HBASE_HOME"
    echo "  export PATH=\$PATH:$HBASE_HOME/bin"
    echo ""
    echo -e "${YELLOW}快速启动:${NC}"
    echo "  $HBASE_HOME/bin/hbase shell"
}

stop_hbase() {
    print_header "停止 HBase"
    $HBASE_HOME/bin/stop-hbase.sh
    print_success "HBase 已停止"
}

start_shell() {
    print_header "启动 HBase Shell"
    $HBASE_HOME/bin/hbase shell
}

main() {
    local command=$1
    shift
    
    check_root
    check_os
    
    case $command in
        standalone)
            print_header "部署 HBase 单机模式"
            install_jdk
            download_hbase
            extract_and_install
            config_standalone_mode
            start_hbase
            
            echo ""
            show_status
            ;;
        pseudo)
            print_header "部署 HBase 伪分布式模式"
            install_jdk
            download_hbase
            extract_and_install
            config_pseudo_distributed_mode
            start_hbase
            
            echo ""
            show_status
            ;;
        stop)
            stop_hbase
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
