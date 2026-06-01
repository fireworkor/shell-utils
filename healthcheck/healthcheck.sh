#!/bin/bash
# 描述：软件健康检查脚本 - 支持所有软件的统一健康检查

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REDIS='\033[0;31m'
GREEN='\033[0;32m'

check_service() {
    local service=$1
    if systemctl is-active --quiet $service 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $service 运行正常"
        return 0
    else
        echo -e "${RED}✗${NC} $service 未运行"
        return 1
    fi
}

check_port() {
    local port=$1
    local name=$2
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        echo -e "${GREEN}✓${NC} $name (端口 $port) 监听正常"
        return 0
    else
        echo -e "${RED}✗${NC} $name (端口 $port) 未监听"
        return 1
    fi
}

check_process() {
    local process=$1
    local name=$2
    if pgrep -f "$process" >/dev/null; then
        echo -e "${GREEN}✓${NC} $name 进程运行正常"
        return 0
    else
        echo -e "${RED}✗${NC} $name 进程未运行"
        return 1
    fi
}

check_http() {
    local url=$1
    local name=$2
    if curl -sf "$url" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $name 可访问"
        return 0
    else
        echo -e "${RED}✗${NC} $name 无法访问"
        return 1
    fi
}

health_check_nginx() {
    echo -e "\n${YELLOW}=== Nginx 健康检查 ===${NC}"
    check_service nginx
    check_port 80 "HTTP"
    check_port 443 "HTTPS"
}

health_check_apache() {
    echo -e "\n${YELLOW}=== Apache 健康检查 ===${NC}"
    check_service httpd 2>/dev/null || check_service apache2 2>/dev/null
    check_port 80 "HTTP"
    check_port 443 "HTTPS"
}

health_check_mysql() {
    echo -e "\n${YELLOW}=== MySQL 健康检查 ===${NC}"
    check_service mysqld 2>/dev/null
    check_port 3306 "MySQL"
    
    if command -v mysql &>/dev/null; then
        if mysqladmin ping -u root -p 2>/dev/null | grep -q "alive"; then
            echo -e "${GREEN}✓${NC} MySQL 响应正常"
        else
            echo -e "${RED}✗${NC} MySQL 无响应"
        fi
    fi
}

health_check_mariadb() {
    echo -e "\n${YELLOW}=== MariaDB 健康检查 ===${NC}"
    check_service mariadb 2>/dev/null
    check_port 3306 "MariaDB"
}

health_check_redis() {
    echo -e "\n${YELLOW}=== Redis 健康检查 ===${NC}"
    check_service redis 2>/dev/null
    check_port 6379 "Redis"
    
    if command -v redis-cli &>/dev/null; then
        if redis-cli ping 2>/dev/null | grep -q "PONG"; then
            echo -e "${GREEN}✓${NC} Redis 响应正常"
        else
            echo -e "${RED}✗${NC} Redis 无响应"
        fi
    fi
}

health_check_mongodb() {
    echo -e "\n${YELLOW}=== MongoDB 健康检查 ===${NC}"
    check_service mongod 2>/dev/null
    check_port 27017 "MongoDB"
    
    if command -v mongosh &>/dev/null; then
        if mongosh --quiet --eval "db.adminCommand('ping')" 2>/dev/null | grep -q "ok"; then
            echo -e "${GREEN}✓${NC} MongoDB 响应正常"
        else
            echo -e "${RED}✗${NC} MongoDB 无响应"
        fi
    fi
}

health_check_postgresql() {
    echo -e "\n${YELLOW}=== PostgreSQL 健康检查 ===${NC}"
    check_service postgresql 2>/dev/null
    check_port 5432 "PostgreSQL"
}

health_check_php() {
    echo -e "\n${YELLOW}=== PHP-FPM 健康检查 ===${NC}"
    check_service php-fpm 2>/dev/null
    check_process php-fpm "PHP-FPM"
}

health_check_docker() {
    echo -e "\n${YELLOW}=== Docker 健康检查 ===${NC}"
    check_service docker 2>/dev/null
    if command -v docker &>/dev/null; then
        if docker info >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Docker 运行正常"
            echo -e "${YELLOW}Docker 信息:${NC}"
            docker info --format '{{.ServerVersion}}' 2>/dev/null | xargs echo "  版本:"
        else
            echo -e "${RED}✗${NC} Docker 无响应"
        fi
    fi
}

health_check_hadoop() {
    echo -e "\n${YELLOW}=== Hadoop 健康检查 ===${NC}"
    check_process namenode "NameNode"
    check_process datanode "DataNode"
    check_process resourcemanager "ResourceManager"
    check_process nodemanager "NodeManager"
    
    check_http "http://localhost:9870" "NameNode Web UI"
    check_http "http://localhost:8088" "ResourceManager Web UI"
}

health_check_spark() {
    echo -e "\n${YELLOW}=== Spark 健康检查 ===${NC}"
    check_process Master "Spark Master"
    check_process Worker "Spark Worker"
    check_http "http://localhost:8080" "Spark Master Web UI"
}

health_check_flink() {
    echo -e "\n${YELLOW}=== Flink 健康检查 ===${NC}"
    check_process java "Flink JobManager"
    check_http "http://localhost:8081" "Flink Web UI"
}

health_check_hbase() {
    echo -e "\n${YELLOW}=== HBase 健康检查 ===${NC}"
    check_process HMaster "HBase Master"
    check_process HRegionServer "HBase RegionServer"
    check_http "http://localhost:16010" "HBase Master Web UI"
}

health_check_all() {
    echo "========================================"
    echo "   系统健康检查报告"
    echo "   $(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================"
    
    health_check_nginx
    health_check_apache
    health_check_mysql
    health_check_mariadb
    health_check_redis
    health_check_mongodb
    health_check_postgresql
    health_check_php
    health_check_docker
    health_check_hadoop
    health_check_spark
    health_check_flink
    health_check_hbase
    
    echo ""
    echo "========================================"
    echo "   检查完成"
    echo "========================================"
}

show_usage() {
    cat << EOF
${GREEN}健康检查工具${NC}

${YELLOW}用法:${NC}
  $0 [选项]

${YELLOW}选项:${NC}
  all           - 检查所有软件
  nginx         - 检查 Nginx
  mysql         - 检查 MySQL
  mariadb       - 检查 MariaDB
  redis         - 检查 Redis
  mongodb       - 检查 MongoDB
  postgresql    - 检查 PostgreSQL
  docker        - 检查 Docker
  hadoop        - 检查 Hadoop
  spark         - 检查 Spark
  flink         - 检查 Flink
  hbase         - 检查 HBase

${YELLOW}示例:${NC}
  $0 all
  $0 nginx mysql redis
  $0 hadoop
EOF
}

main() {
    if [ $# -eq 0 ]; then
        health_check_all
        return
    fi
    
    for arg in "$@"; do
        case $arg in
            all)
                health_check_all
                ;;
            nginx)
                health_check_nginx
                ;;
            apache)
                health_check_apache
                ;;
            mysql)
                health_check_mysql
                ;;
            mariadb)
                health_check_mariadb
                ;;
            redis)
                health_check_redis
                ;;
            mongodb)
                health_check_mongodb
                ;;
            postgresql)
                health_check_postgresql
                ;;
            php)
                health_check_php
                ;;
            docker)
                health_check_docker
                ;;
            hadoop)
                health_check_hadoop
                ;;
            spark)
                health_check_spark
                ;;
            flink)
                health_check_flink
                ;;
            hbase)
                health_check_hbase
                ;;
            help|--help|-h)
                show_usage
                ;;
            *)
                echo -e "${RED}未知选项: $arg${NC}"
                ;;
        esac
    done
}

main "$@"
