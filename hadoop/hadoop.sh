#!/bin/bash
# 描述：部署 Hadoop 集群 - 支持伪分布式和分布式模式

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

HADOOP_VERSION=${1:-3.3.6}
HADOOP_HOME="/opt/hadoop"
HADOOP_TAR="hadoop-$HADOOP_VERSION.tar.gz"
HADOOP_URL="https://dlcdn.apache.org/hadoop/common/hadoop-$HADOOP_VERSION/$HADOOP_TAR"

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

setup_ssh() {
    print_step 2 6 "配置 SSH 免密登录"
    
    if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
    fi
    
    if [ ! -f ~/.ssh/authorized_keys ]; then
        touch ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
    fi
    
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    ssh-keyscan localhost 2>/dev/null >> ~/.ssh/known_hosts
    ssh-keyscan 0.0.0.0 2>/dev/null >> ~/.ssh/known_hosts
    
    print_success "SSH 配置完成"
}

download_hadoop() {
    print_step 3 6 "下载 Hadoop $HADOOP_VERSION"
    
    if [ -f "/tmp/$HADOOP_TAR" ]; then
        print_info "使用已下载的文件"
    else
        download_with_retry "$HADOOP_URL" "/tmp/$HADOOP_TAR"
    fi
}

extract_and_install() {
    print_step 4 6 "解压并安装 Hadoop"
    
    tar xzf "/tmp/$HADOOP_TAR" -C /opt
    rm -rf "$HADOOP_HOME"
    ln -sf "/opt/hadoop-$HADOOP_VERSION" "$HADOOP_HOME"
    
    mkdir -p "$HADOOP_HOME/data/dfs/name"
    mkdir -p "$HADOOP_HOME/data/dfs/data"
    mkdir -p "$HADOOP_HOME/logs"
    
    print_success "Hadoop 安装完成: $HADOOP_HOME"
}

config_pseudo_distributed() {
    print_step 5 6 "配置伪分布式模式"
    
    local java_home=$(readlink -f $(which java) | sed 's:/bin/java::')
    
    cat > "$HADOOP_HOME/etc/hadoop/hadoop-env.sh" << EOF
export JAVA_HOME=$java_home
export HADOOP_HOME=$HADOOP_HOME
export HADOOP_LOG_DIR=$HADOOP_HOME/logs
EOF
    
    cat > "$HADOOP_HOME/etc/hadoop/core-site.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://localhost:9000</value>
  </property>
  <property>
    <name>hadoop.tmp.dir</name>
    <value>/opt/hadoop/data/tmp</value>
  </property>
</configuration>
EOF
    
    cat > "$HADOOP_HOME/etc/hadoop/hdfs-site.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>/opt/hadoop/data/dfs/name</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>/opt/hadoop/data/dfs/data</value>
  </property>
</configuration>
EOF
    
    cat > "$HADOOP_HOME/etc/hadoop/mapred-site.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
</configuration>
EOF
    
    cat > "$HADOOP_HOME/etc/hadoop/yarn-site.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
</configuration>
EOF
    
    echo "localhost" > "$HADOOP_HOME/etc/hadoop/workers"
    
    print_success "伪分布式配置完成"
}

format_and_start() {
    print_step 6 6 "格式化并启动 Hadoop"
    
    if [ ! -d "$HADOOP_HOME/data/dfs/name/current" ]; then
        $HADOOP_HOME/bin/hdfs namenode -format -force
    fi
    
    $HADOOP_HOME/sbin/start-dfs.sh
    $HADOOP_HOME/sbin/start-yarn.sh
    
    print_success "Hadoop 启动完成"
}

show_usage() {
    cat << EOF
${GREEN}Hadoop 部署工具${NC}

${YELLOW}命令:${NC}
  pseudo    - 伪分布式模式（单节点）
  cluster   - 分布式集群模式（需配置）
  stop      - 停止 Hadoop
  status    - 查看状态

${YELLOW}示例:${NC}
  $0 pseudo
  $0 stop
  $0 status
EOF
}

show_status() {
    print_header "Hadoop 状态"
    
    if command -v jps &>/dev/null; then
        echo -e "${YELLOW}Java 进程:${NC}"
        jps
    fi
    
    echo ""
    echo -e "${YELLOW}Web 界面:${NC}"
    echo "  NameNode: http://localhost:9870"
    echo "  ResourceManager: http://localhost:8088"
    echo "  DataNode: http://localhost:9864"
    echo ""
    echo -e "${YELLOW}环境变量:${NC}"
    echo "  export HADOOP_HOME=$HADOOP_HOME"
    echo "  export PATH=\$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin"
}

stop_hadoop() {
    print_header "停止 Hadoop"
    $HADOOP_HOME/sbin/stop-yarn.sh
    $HADOOP_HOME/sbin/stop-dfs.sh
    print_success "Hadoop 已停止"
}

main() {
    local command=$1
    shift
    
    check_root
    check_os
    
    case $command in
        pseudo)
            print_header "部署 Hadoop 伪分布式模式"
            install_jdk
            setup_ssh
            download_hadoop
            extract_and_install
            config_pseudo_distributed
            format_and_start
            
            echo ""
            show_status
            ;;
        stop)
            stop_hadoop
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
