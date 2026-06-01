#!/bin/bash
# 描述：部署 MongoDB 副本集集群

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

MONGODB_VERSION=${1:-6.0}
REPLICA_SET_NAME="rs0"
SHARD_SIZE=${2:-3}

install_mongodb() {
    print_step 1 4 "安装 MongoDB"
    
    local pkg_manager=$(get_pkg_manager)
    case $pkg_manager in
        dnf|yum)
            cat > /etc/yum.repos.d/mongodb.repo << 'EOF'
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOF
            yum install -y mongodb-org mongodb-org-server
            ;;
        apt)
            wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add -
            echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y mongodb-org mongodb-org-server
            ;;
    esac
    
    print_success "MongoDB 安装完成"
}

setup_replica_set() {
    print_step 2 4 "配置副本集节点"
    
    for i in $(seq 1 $SHARD_SIZE); do
        local port=$((27017 + i - 1))
        local dir="/opt/mongodb-rs/node-$i"
        
        mkdir -p "$dir"
        mkdir -p /var/log/mongodb-rs
        
        cat > "/opt/mongodb-rs/node-$i.conf" << EOF
systemLog:
  destination: file
  path: /var/log/mongodb-rs/mongod-$i.log
  logAppend: true
storage:
  dbPath: $dir
  journal:
    enabled: true
net:
  port: $port
  bindIp: 127.0.0.1
replication:
  replSetName: $REPLICA_SET_NAME
processManagement:
  fork: true
  pidFilePath: /var/run/mongodb-rs/mongod-$i.pid
EOF
        
        mkdir -p /var/run/mongodb-rs
    done
    
    chown -R mongod:mongod /opt/mongodb-rs
    chown -R mongod:mongod /var/log/mongodb-rs
    chown -R mongod:mongod /var/run/mongodb-rs
    
    print_success "副本集配置完成"
}

start_replica_set() {
    print_step 3 4 "启动副本集"
    
    for i in $(seq 1 $SHARD_SIZE); do
        local port=$((27017 + i - 1))
        mongod -f /opt/mongodb-rs/node-$i.conf
    done
    
    sleep 3
    
    print_success "副本集节点已启动"
}

init_replica_set() {
    print_step 4 4 "初始化副本集"
    
    local members=""
    for i in $(seq 1 $SHARD_SIZE); do
        local port=$((27017 + i - 1))
        if [ -n "$members" ]; then
            members="$members, {_id: $i, host: '127.0.0.1:$port'}"
        else
            members="{_id: $i, host: '127.0.0.1:$port'}"
        fi
    done
    
    mongosh --port 27017 << EOF
rs.initiate({
    _id: "$REPLICA_SET_NAME",
    members: [$members]
});
EOF
    
    sleep 2
    
    mongosh --port 27017 --eval "printjson(rs.status())"
    
    print_success "副本集初始化完成"
}

show_status() {
    print_header "MongoDB 副本集状态"
    
    echo -e "${YELLOW}副本集状态:${NC}"
    mongosh --port 27017 --quiet --eval "JSON.stringify(rs.status(), null, 2)"
    
    echo ""
    echo -e "${YELLOW}副本集配置:${NC}"
    mongosh --port 27017 --quiet --eval "JSON.stringify(rs.conf(), null, 2)"
    
    echo ""
    echo -e "${YELLOW}连接命令:${NC}"
    echo "  mongosh --port 27017"
    echo "  mongosh mongodb://127.0.0.1:27017,127.0.0.1:27018,127.0.0.1:27019/?replicaSet=$REPLICA_SET_NAME"
}

stop_cluster() {
    print_header "停止 MongoDB 副本集"
    
    for i in $(seq 1 $SHARD_SIZE); do
        mongod -f /opt/mongodb-rs/node-$i.conf --shutdown 2>/dev/null || true
    done
    
    print_success "副本集已停止"
}

test_replication() {
    print_header "测试副本集复制"
    
    echo -e "${YELLOW}插入测试数据:${NC}"
    mongosh --port 27017 << 'EOF'
use test_db;
db.test_collection.insertOne({name: "test", value: 123, timestamp: new Date()});
db.test_collection.find();
EOF
    
    sleep 2
    
    echo ""
    echo -e "${YELLOW}检查从节点复制:${NC}"
    mongosh --port 27018 --quiet --eval "
db.getMongo().setSlaveOk();
use test_db;
db.test_collection.find();
"
}

show_usage() {
    cat << EOF
${GREEN}MongoDB 副本集集群部署工具${NC}

${YELLOW}命令:${NC}
  install     - 安装并部署 MongoDB 副本集
  start       - 启动集群
  stop        - 停止集群
  status      - 查看集群状态
  test        - 测试复制功能

${YELLOW}集群架构:${NC}
  副本集名称: $REPLICA_SET_NAME
  节点数: $SHARD_SIZE
  端口: 27017-$((27017 + SHARD_SIZE - 1))

${YELLOW}示例:${NC}
  bash mongodb-cluster.sh install
  bash mongodb-cluster.sh status
  bash mongodb-cluster.sh test
  bash mongodb-cluster.sh stop
EOF
}

main() {
    local command=$1
    shift
    
    check_root
    
    case $command in
        install)
            print_header "部署 MongoDB 副本集集群"
            install_mongodb
            setup_replica_set
            start_replica_set
            init_replica_set
            
            echo ""
            show_status
            ;;
        start)
            print_header "启动 MongoDB 副本集"
            for i in $(seq 1 $SHARD_SIZE); do
                mongod -f /opt/mongodb-rs/node-$i.conf
            done
            print_success "副本集已启动"
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
