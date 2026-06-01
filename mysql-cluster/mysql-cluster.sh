#!/bin/bash
# 描述：部署 MySQL 主从复制集群

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

MYSQL_VERSION=${1:-8.0}
MYSQL_PORT_MASTER=${2:-3306}
MYSQL_PORT_SLAVE=${3:-3307}

install_mysql() {
    print_step 1 4 "安装 MySQL"
    
    local pkg_manager=$(get_pkg_manager)
    case $pkg_manager in
        dnf|yum)
            yum install -y mysql mysql-server
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y mysql-server mysql-client
            ;;
    esac
    
    print_success "MySQL 安装完成"
}

setup_master() {
    print_step 2 4 "配置主节点"
    
    mkdir -p /opt/mysql-master/data
    mkdir -p /var/log/mysql-master
    
    cat > /opt/mysql-master/my.cnf << EOF
[mysqld]
server-id=1
port=$MYSQL_PORT_MASTER
datadir=/opt/mysql-master/data
log-bin=/var/log/mysql-master/mysql-bin
binlog-format=ROW
sync-binlog=1
innodb_flush_log_at_trx_commit=1
socket=/tmp/mysql-master.sock
pid-file=/tmp/mysql-master.pid
log-error=/var/log/mysql-master/error.log
EOF
    
    chown -R mysql:mysql /opt/mysql-master
    chown -R mysql:mysql /var/log/mysql-master
    
    mysqld --initialize-insecure --user=mysql --datadir=/opt/mysql-master/data
    mysqld --defaults-file=/opt/mysql-master/my.cnf --user=mysql &
    
    sleep 5
    
    print_success "主节点配置完成"
}

setup_slave() {
    print_step 3 4 "配置从节点"
    
    mkdir -p /opt/mysql-slave/data
    mkdir -p /var/log/mysql-slave
    
    cat > /opt/mysql-slave/my.cnf << EOF
[mysqld]
server-id=2
port=$MYSQL_PORT_SLAVE
datadir=/opt/mysql-slave/data
relay-log=/var/log/mysql-slave/relay-log
read-only=1
socket=/tmp/mysql-slave.sock
pid-file=/tmp/mysql-slave.pid
log-error=/var/log/mysql-slave/error.log
EOF
    
    chown -R mysql:mysql /opt/mysql-slave
    chown -R mysql:mysql /var/log/mysql-slave
    
    mysqld --initialize-insecure --user=mysql --datadir=/opt/mysql-slave/data
    mysqld --defaults-file=/opt/mysql-slave/my.cnf --user=mysql &
    
    sleep 5
    
    print_success "从节点配置完成"
}

configure_replication() {
    print_step 4 4 "配置主从复制"
    
    mysql -u root --socket=/tmp/mysql-master.sock << 'EOF'
CREATE USER 'repl_user'@'%' IDENTIFIED BY 'repl_password';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';
FLUSH PRIVILEGES;
SHOW MASTER STATUS;
EOF
    
    mysql -u root --socket=/tmp/mysql-slave.sock << 'EOF'
CHANGE MASTER TO
    MASTER_HOST='127.0.0.1',
    MASTER_PORT=3306,
    MASTER_USER='repl_user',
    MASTER_PASSWORD='repl_password',
    MASTER_LOG_FILE='mysql-bin.000001',
    MASTER_LOG_POS=155;
START SLAVE;
SHOW SLAVE STATUS\G;
EOF
    
    print_success "主从复制配置完成"
}

show_status() {
    print_header "MySQL 主从集群状态"
    
    echo -e "${YELLOW}主节点状态:${NC}"
    mysql -u root --socket=/tmp/mysql-master.sock -e "SHOW MASTER STATUS\G"
    
    echo ""
    echo -e "${YELLOW}从节点状态:${NC}"
    mysql -u root --socket=/tmp/mysql-slave.sock -e "SHOW SLAVE STATUS\G"
    
    echo ""
    echo -e "${YELLOW}连接命令:${NC}"
    echo "  主节点: mysql -u root --socket=/tmp/mysql-master.sock"
    echo "  从节点: mysql -u root --socket=/tmp/mysql-slave.sock"
}

stop_cluster() {
    print_header "停止 MySQL 集群"
    
    mysqladmin -u root --socket=/tmp/mysql-master.sock shutdown
    mysqladmin -u root --socket=/tmp/mysql-slave.sock shutdown
    
    print_success "集群已停止"
}

test_replication() {
    print_header "测试主从复制"
    
    echo -e "${YELLOW}在主节点创建测试数据:${NC}"
    mysql -u root --socket=/tmp/mysql-master.sock << 'EOF'
CREATE DATABASE IF NOT EXISTS test_db;
USE test_db;
CREATE TABLE IF NOT EXISTS test_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO test_table (name) VALUES ('test_master');
SELECT * FROM test_table;
EOF
    
    sleep 2
    
    echo ""
    echo -e "${YELLOW}检查从节点数据:${NC}"
    mysql -u root --socket=/tmp/mysql-slave.sock << 'EOF'
USE test_db;
SELECT * FROM test_table;
EOF
}

show_usage() {
    cat << EOF
${GREEN}MySQL 主从集群部署工具${NC}

${YELLOW}命令:${NC}
  install     - 安装并部署 MySQL 主从集群
  start       - 启动集群
  stop        - 停止集群
  status      - 查看集群状态
  test        - 测试主从复制

${YELLOW}集群架构:${NC}
  主节点: 端口 $MYSQL_PORT_MASTER
  从节点: 端口 $MYSQL_PORT_SLAVE

${YELLOW}示例:${NC}
  bash mysql-cluster.sh install
  bash mysql-cluster.sh status
  bash mysql-cluster.sh test
  bash mysql-cluster.sh stop
EOF
}

main() {
    local command=$1
    shift
    
    check_root
    
    case $command in
        install)
            print_header "部署 MySQL 主从集群"
            install_mysql
            setup_master
            setup_slave
            configure_replication
            
            echo ""
            show_status
            ;;
        start)
            print_header "启动 MySQL 集群"
            mysqld --defaults-file=/opt/mysql-master/my.cnf --user=mysql &
            mysqld --defaults-file=/opt/mysql-slave/my.cnf --user=mysql &
            print_success "集群已启动"
            ;;
        stop)
            stop_cluster
            ;;
        status)
            show_status
            ;;
        test)
            test_replication
            ;;
        *)
            show_usage
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
