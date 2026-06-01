#!/bin/bash
# 描述：部署 Redis 集群 - 支持主从复制和哨兵模式

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

REDIS_VERSION=${1:-7.2}
REDIS_HOME="/opt/redis"
REDIS_PORT=${2:-6379}
REDIS_CLUSTER_SIZE=${3:-3}

install_redis() {
    print_step 1 4 "安装 Redis"
    
    local pkg_manager=$(get_pkg_manager)
    case $pkg_manager in
        dnf|yum)
            yum install -y epel-release
            yum install -y redis
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y redis-server
            ;;
    esac
    
    print_success "Redis 安装完成"
}

setup_pseudo_cluster() {
    print_step 2 4 "配置伪集群（3 主 3 从）"
    
    local base_port=7000
    
    for i in {1..6}; do
        local port=$((base_port + i - 1))
        local dir="/opt/redis-cluster/node-$port"
        
        mkdir -p "$dir"
        
        cat > "$dir/redis.conf" << EOF
port $port
cluster-enabled yes
cluster-config-file nodes-$port.conf
cluster-node-timeout 5000
appendonly yes
daemonize yes
pidfile /var/run/redis-cluster-$port.pid
dir $dir
logfile $dir/redis.log
protected-mode no
bind 127.0.0.1
EOF
    done
    
    print_success "集群配置完成"
}

start_cluster() {
    print_step 3 4 "启动 Redis 集群"
    
    local base_port=7000
    
    for i in {1..6}; do
        local port=$((base_port + i - 1))
        redis-server /opt/redis-cluster/node-$port/redis.conf
    done
    
    sleep 2
    
    redis-cli --cluster create \
        127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 \
        127.0.0.1:7004 127.0.0.1:7005 127.0.0.1:7006 \
        --cluster-replicas 1
    
    print_success "集群启动完成"
}

show_status() {
    print_step 4 4 "集群状态"
    
    echo ""
    echo -e "${YELLOW}Redis 集群节点:${NC}"
    redis-cli -p 7001 cluster nodes
    
    echo ""
    echo -e "${YELLOW}集群信息:${NC}"
    redis-cli -p 7001 cluster info
    
    echo ""
    echo -e "${YELLOW}测试集群:${NC}"
    redis-cli -p 7001 cluster slots
    
    echo ""
    echo -e "${YELLOW}连接命令:${NC}"
    echo "  redis-cli -p 7001"
    echo "  redis-cli -c -p 7001  # 集群模式"
}

stop_cluster() {
    print_header "停止 Redis 集群"
    
    local base_port=7000
    for i in {1..6}; do
        local port=$((base_port + i - 1))
        redis-cli -p $port shutdown 2>/dev/null || true
    done
    
    print_success "集群已停止"
}

show_usage() {
    cat << EOF
${GREEN}Redis 集群部署工具${NC}

${YELLOW}命令:${NC}
  install     - 安装并部署 Redis 集群
  start       - 启动集群
  stop        - 停止集群
  status      - 查看集群状态
  test        - 测试集群功能

${YELLOW}集群架构:${NC}
  3 主节点 + 3 从节点
  端口: 7001-7006

${YELLOW}示例:${NC}
  bash redis-cluster.sh install
  bash redis-cluster.sh status
  bash redis-cluster.sh stop
EOF
}

main() {
    local command=$1
    shift
    
    check_root
    
    case $command in
        install)
            print_header "部署 Redis 集群"
            install_redis
            setup_pseudo_cluster
            start_cluster
            show_status
            ;;
        start)
            print_header "启动 Redis 集群"
            for i in {1..6}; do
                local port=$((6999 + i))
                redis-server /opt/redis-cluster/node-$port/redis.conf
            done
            print_success "集群已启动"
            ;;
        stop)
            stop_cluster
            ;;
        status)
            print_header "Redis 集群状态"
            redis-cli -p 7001 cluster nodes
            echo ""
            redis-cli -p 7001 cluster info
            ;;
        test)
            print_header "测试 Redis 集群"
            redis-cli -c -p 7001 set test "hello"
            redis-cli -c -p 7001 get test
            redis-cli -p 7001 cluster slots
            ;;
        *)
            show_usage
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
