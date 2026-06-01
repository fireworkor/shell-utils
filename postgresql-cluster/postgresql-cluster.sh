#!/bin/bash
# 描述：部署 PostgreSQL 主从集群

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

PG_VERSION=${1:-16}
MASTER_PORT=${2:-5432}
REPLICA_PORT=${3:-5433}
BASE_DATA_DIR="/opt/postgres-cluster"

install_postgres() {
    print_step 1 4 "安装 PostgreSQL"

    local pkg_manager=$(get_pkg_manager)
    case $pkg_manager in
        dnf|yum)
            dnf install -y postgresql$PG_VERSION-server postgresql$PG_VERSION-contrib
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y postgresql-$PG_VERSION
            ;;
    esac

    print_success "PostgreSQL 安装完成"
}

configure_master() {
    print_step 2 4 "配置主节点"

    mkdir -p "$BASE_DATA_DIR/master"
    chown -R postgres:postgres "$BASE_DATA_DIR"

    su - postgres -c "/usr/pgsql-$PG_VERSION/bin/initdb -D $BASE_DATA_DIR/master" 2>/dev/null || true

    cat > "$BASE_DATA_DIR/master/postgresql.conf" << EOF
listen_addresses = '*'
port = $MASTER_PORT
wal_level = replica
max_wal_senders = 3
wal_keep_size = 64MB
EOF

    cat > "$BASE_DATA_DIR/master/pg_hba.conf" << EOF
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust
EOF

    chown -R postgres:postgres "$BASE_DATA_DIR/master"
    print_success "主节点配置完成 (端口: $MASTER_PORT)"
}

configure_replica() {
    print_step 3 4 "配置从节点"

    mkdir -p "$BASE_DATA_DIR/replica"

    su - postgres -c "pg_basebackup -h 127.0.0.1 -p $MASTER_PORT -D $BASE_DATA_DIR/replica -U postgres -P -Xs -Fp" 2>/dev/null || true

    cat > "$BASE_DATA_DIR/replica/postgresql.conf" << EOF
listen_addresses = '*'
port = $REPLICA_PORT
wal_level = replica
max_wal_senders = 3
hot_standby = on
EOF

    cat > "$BASE_DATA_DIR/replica/standby.signal" << EOF
standby_mode = on
primary_conninfo = 'host=127.0.0.1 port=$MASTER_PORT user=postgres'
EOF

    chown -R postgres:postgres "$BASE_DATA_DIR/replica"
    print_success "从节点配置完成 (端口: $REPLICA_PORT)"
}

start_cluster() {
    print_step 4 4 "启动集群"

    su - postgres -c "/usr/pgsql-$PG_VERSION/bin/pg_ctl -D $BASE_DATA_DIR/master start" 2>&1
    sleep 2
    su - postgres -c "/usr/pgsql-$PG_VERSION/bin/pg_ctl -D $BASE_DATA_DIR/replica start" 2>&1
    sleep 2

    print_success "PostgreSQL 主从集群启动完成"
}

show_status() {
    print_header "PostgreSQL 主从集群状态"

    echo -e "${YELLOW}主节点 (端口 $MASTER_PORT):${NC}"
    su - postgres -c "psql -p $MASTER_PORT -c 'SELECT usename, application_name, state, sent_lsn, flush_lsn, write_lsn, sync_state FROM pg_stat_replication;'" 2>&1 || true

    echo -e "\n${YELLOW}从节点 (端口 $REPLICA_PORT):${NC}"
    su - postgres -c "psql -p $REPLICA_PORT -c 'SELECT pg_is_in_recovery();'" 2>&1 || true

    echo -e "\n${YELLOW}连接命令:${NC}"
    echo "  主节点: psql -h 127.0.0.1 -p $MASTER_PORT -U postgres"
    echo "  从节点: psql -h 127.0.0.1 -p $REPLICA_PORT -U postgres"
}

stop_cluster() {
    print_header "停止集群"
    su - postgres -c "/usr/pgsql-$PG_VERSION/bin/pg_ctl -D $BASE_DATA_DIR/replica stop" 2>/dev/null || true
    su - postgres -c "/usr/pgsql-$PG_VERSION/bin/pg_ctl -D $BASE_DATA_DIR/master stop" 2>/dev/null || true
    print_success "PostgreSQL 主从集群已停止"
}

show_usage() {
    cat << EOF
${GREEN}PostgreSQL 主从集群部署工具${NC}

${YELLOW}命令:${NC}
  install          - 安装并部署主从集群
  start            - 启动集群
  stop             - 停止集群
  status           - 查看集群状态

${YELLOW}架构:${NC}
  主节点: $MASTER_PORT
  从节点: $REPLICA_PORT

${YELLOW}示例:${NC}
  $0 install
  $0 status
  $0 stop
EOF
}

main() {
    local command=$1
    shift

    check_root

    case $command in
        install)
            print_header "部署 PostgreSQL 主从集群"
            install_postgres
            configure_master
            configure_replica
            start_cluster
            show_status
            ;;
        start)
            start_cluster
            ;;
        stop)
            stop_cluster
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
