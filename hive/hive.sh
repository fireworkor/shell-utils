#!/bin/bash
# 描述：部署 Hive - 数据仓库工具

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

HIVE_VERSION=${1:-4.0.0-beta-1}
HIVE_HOME="/opt/hive"
HIVE_TAR="apache-hive-$HIVE_VERSION-bin.tar.gz"
HIVE_URL="https://dlcdn.apache.org/hive/hive-$HIVE_VERSION/$HIVE_TAR"

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

download_hive() {
    print_step 2 5 "下载 Hive $HIVE_VERSION"
    
    if [ -f "/tmp/$HIVE_TAR" ]; then
        print_info "使用已下载的文件"
    else
        download_with_retry "$HIVE_URL" "/tmp/$HIVE_TAR"
    fi
}

extract_and_install() {
    print_step 3 5 "解压并安装 Hive"
    
    tar xzf "/tmp/$HIVE_TAR" -C /opt
    rm -rf "$HIVE_HOME"
    ln -sf "/opt/apache-hive-$HIVE_VERSION-bin" "$HIVE_HOME"
    
    mkdir -p "$HIVE_HOME/logs"
    mkdir -p "$HIVE_HOME/warehouse"
    
    print_success "Hive 安装完成: $HIVE_HOME"
}

configure_hive() {
    print_step 4 5 "配置 Hive"
    
    local java_home=$(readlink -f $(which java) | sed 's:/bin/java::')
    
    cat > "$HIVE_HOME/conf/hive-env.sh" << EOF
export JAVA_HOME=$java_home
export HIVE_HOME=$HIVE_HOME
export HIVE_CONF_DIR=$HIVE_HOME/conf
export HIVE_AUX_JARS_PATH=$HIVE_HOME/lib
EOF
    
    cat > "$HIVE_HOME/conf/hive-site.xml" << 'EOF'
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:derby:;databaseName=/opt/hive/metastore_db;create=true</value>
    <description>JDBC connect string for a JDBC metastore</description>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>org.apache.derby.jdbc.EmbeddedDriver</value>
    <description>Driver class name for a JDBC metastore</description>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>APP</value>
    <description>Username to use against metastore database</description>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>mine</value>
    <description>password to use against metastore database</description>
  </property>
  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>/opt/hive/warehouse</value>
    <description>location of default database for the warehouse</description>
  </property>
  <property>
    <name>hive.exec.scratchdir</name>
    <value>/tmp/hive</value>
    <description>HDFS root scratch dir for Hive jobs</description>
  </property>
</configuration>
EOF
    
    cat > "$HIVE_HOME/conf/core-site.xml" << 'EOF'
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>hadoop.proxyuser.hive.hosts</name>
    <value>*</value>
  </property>
  <property>
    <name>hadoop.proxyuser.hive.groups</name>
    <value>*</value>
  </property>
</configuration>
EOF
    
    chmod 777 "$HIVE_HOME/warehouse"
    
    print_success "Hive 配置完成"
}

initialize_schema() {
    print_step 5 5 "初始化 Metastore 数据库"
    
    if [ ! -d "$HIVE_HOME/metastore_db" ]; then
        $HIVE_HOME/bin/schematool -dbType derby -initSchema
    else
        print_info "Metastore 已存在，跳过初始化"
    fi
    
    print_success "初始化完成"
}

show_usage() {
    cat << EOF
${GREEN}Hive 部署工具${NC}

${YELLOW}命令:${NC}
  install       - 安装并配置 Hive
  shell         - 启动 Hive Shell
  beeline       - 启动 Beeline 客户端
  status        - 查看状态
  metastore     - 启动 Metastore 服务
  hiveserver2   - 启动 HiveServer2 服务

${YELLOW}示例:${NC}
  $0 install
  $0 shell
  $0 beeline
  $0 status
  $0 metastore
  $0 hiveserver2
EOF
}

show_status() {
    print_header "Hive 状态"
    
    echo -e "${YELLOW}环境变量:${NC}"
    echo "  export HIVE_HOME=$HIVE_HOME"
    echo "  export PATH=\$PATH:$HIVE_HOME/bin"
    echo ""
    echo -e "${YELLOW}快速启动:${NC}"
    echo "  $HIVE_HOME/bin/hive"
    echo "  $HIVE_HOME/bin/beeline -u jdbc:hive2://"
    echo "  $HIVE_HOME/bin/hiveserver2"
}

start_metastore() {
    print_header "启动 Hive Metastore"
    $HIVE_HOME/bin/hive --service metastore > $HIVE_HOME/logs/metastore.log 2>&1 &
    print_success "Metastore 已启动，日志: $HIVE_HOME/logs/metastore.log"
}

start_hiveserver2() {
    print_header "启动 HiveServer2"
    $HIVE_HOME/bin/hive --service hiveserver2 > $HIVE_HOME/logs/hiveserver2.log 2>&1 &
    print_success "HiveServer2 已启动，日志: $HIVE_HOME/logs/hiveserver2.log"
    echo "  Web UI: http://localhost:10002"
}

start_shell() {
    print_header "启动 Hive Shell"
    $HIVE_HOME/bin/hive
}

start_beeline() {
    print_header "启动 Beeline 客户端"
    $HIVE_HOME/bin/beeline -u jdbc:hive2://
}

main() {
    local command=$1
    shift
    
    check_root
    check_os
    
    case $command in
        install)
            print_header "部署 Hive"
            install_jdk
            download_hive
            extract_and_install
            configure_hive
            initialize_schema
            
            echo ""
            show_status
            ;;
        shell)
            start_shell
            ;;
        beeline)
            start_beeline
            ;;
        metastore)
            start_metastore
            ;;
        hiveserver2)
            start_hiveserver2
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
