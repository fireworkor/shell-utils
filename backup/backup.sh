#!/bin/bash
# 描述：数据备份和恢复脚本 - 支持 MySQL、MongoDB、Redis 等数据库备份

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="/var/backups/shell-utils"
DATE=$(date +%Y%m%d_%H%M%S)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

mkdir -p "$BACKUP_DIR"

print_step() {
    echo -e "\n${YELLOW}[$1]${NC} $2"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

backup_mysql() {
    local db=${1:-"--all-databases"}
    local target_dir="$BACKUP_DIR/mysql"
    
    print_step "1/3" "准备备份目录"
    mkdir -p "$target_dir"
    
    print_step "2/3" "执行 MySQL 备份"
    if [ "$db" = "--all-databases" ]; then
        mysqldump -u root -p --single-transaction --routines --triggers --events "$db" | gzip > "$target_dir/all_databases_$DATE.sql.gz"
        print_success "MySQL 全量备份完成: $target_dir/all_databases_$DATE.sql.gz"
    else
        mysqldump -u root -p --single-transaction "$db" | gzip > "$target_dir/${db}_$DATE.sql.gz"
        print_success "MySQL 数据库 $db 备份完成: $target_dir/${db}_$DATE.sql.gz"
    fi
    
    print_step "3/3" "备份完成"
}

restore_mysql() {
    local backup_file=$1
    local db=${2:-""}
    
    print_step "1/2" "检查备份文件"
    if [ ! -f "$backup_file" ]; then
        print_error "备份文件不存在: $backup_file"
        return 1
    fi
    
    print_step "2/2" "恢复数据"
    if [[ "$backup_file" == *.gz ]]; then
        if [ -n "$db" ]; then
            gunzip < "$backup_file" | mysql -u root -p "$db"
        else
            gunzip < "$backup_file" | mysql -u root -p
        fi
    else
        if [ -n "$db" ]; then
            mysql -u root -p "$db" < "$backup_file"
        else
            mysql -u root -p < "$backup_file"
        fi
    fi
    
    print_success "MySQL 数据恢复完成"
}

backup_mongodb() {
    local db=${1:-""}
    local target_dir="$BACKUP_DIR/mongodb"
    
    print_step "1/3" "准备备份目录"
    mkdir -p "$target_dir"
    
    print_step "2/3" "执行 MongoDB 备份"
    if [ -n "$db" ]; then
        mongodump --db "$db" --archive="$target_dir/${db}_$DATE.archive" --gzip
        print_success "MongoDB 数据库 $db 备份完成: $target_dir/${db}_$DATE.archive"
    else
        mongodump --archive="$target_dir/all_databases_$DATE.archive" --gzip
        print_success "MongoDB 全量备份完成: $target_dir/all_databases_$DATE.archive"
    fi
    
    print_step "3/3" "备份完成"
}

restore_mongodb() {
    local backup_file=$1
    
    print_step "1/2" "检查备份文件"
    if [ ! -f "$backup_file" ]; then
        print_error "备份文件不存在: $backup_file"
        return 1
    fi
    
    print_step "2/2" "恢复数据"
    mongorestore --archive="$backup_file" --gzip --drop
    print_success "MongoDB 数据恢复完成"
}

backup_redis() {
    local target_dir="$BACKUP_DIR/redis"
    
    print_step "1/3" "准备备份目录"
    mkdir -p "$target_dir"
    
    print_step "2/3" "执行 Redis 备份"
    redis-cli BGSAVE
    sleep 2
    
    if [ -f /var/lib/redis/dump.rdb ]; then
        cp /var/lib/redis/dump.rdb "$target_dir/dump_$DATE.rdb"
        print_success "Redis RDB 备份完成: $target_dir/dump_$DATE.rdb"
    fi
    
    if [ -f /var/lib/redis/appendonly.aof ]; then
        cp /var/lib/redis/appendonly.aof "$target_dir/appendonly_$DATE.aof"
        print_success "Redis AOF 备份完成: $target_dir/appendonly_$DATE.aof"
    fi
    
    print_step "3/3" "备份完成"
}

restore_redis() {
    local rdb_file=$1
    
    print_step "1/2" "检查备份文件"
    if [ ! -f "$rdb_file" ]; then
        print_error "备份文件不存在: $rdb_file"
        return 1
    fi
    
    print_step "2/2" "恢复数据"
    systemctl stop redis 2>/dev/null || true
    cp "$rdb_file" /var/lib/redis/dump.rdb
    chown redis:redis /var/lib/redis/dump.rdb
    systemctl start redis 2>/dev/null || true
    print_success "Redis 数据恢复完成"
}

backup_configs() {
    local target_dir="$BACKUP_DIR/configs"
    
    print_step "1/3" "准备备份目录"
    mkdir -p "$target_dir"
    
    print_step "2/3" "备份配置文件"
    
    [ -f /etc/nginx/nginx.conf ] && cp /etc/nginx/nginx.conf "$target_dir/nginx.conf" && print_success "Nginx 配置已备份"
    [ -f /etc/my.cnf ] && cp /etc/my.cnf "$target_dir/my.cnf" && print_success "MySQL 配置已备份"
    [ -f /etc/redis/redis.conf ] && cp /etc/redis/redis.conf "$target_dir/redis.conf" && print_success "Redis 配置已备份"
    [ -f /etc/mongod.conf ] && cp /etc/mongod.conf "$target_dir/mongod.conf" && print_success "MongoDB 配置已备份"
    
    tar czf "$target_dir/configs_$DATE.tar.gz" -C /workspace shell-utils 2>/dev/null || true
    
    print_step "3/3" "配置备份完成"
}

backup_all() {
    echo "========================================"
    echo "   全量备份"
    echo "   $DATE"
    echo "========================================"
    
    print_step "1/4" "备份 MySQL"
    backup_mysql
    
    print_step "2/4" "备份 MongoDB"
    backup_mongodb
    
    print_step "3/4" "备份 Redis"
    backup_redis
    
    print_step "4/4" "备份配置文件"
    backup_configs
    
    echo ""
    echo "========================================"
    echo "   全量备份完成"
    echo "   备份目录: $BACKUP_DIR"
    echo "========================================"
    
    ls -lh "$BACKUP_DIR"/*/
}

list_backups() {
    echo -e "${YELLOW}可用备份:${NC}"
    echo ""
    
    for dir in "$BACKUP_DIR"/*; do
        if [ -d "$dir" ]; then
            name=$(basename "$dir")
            echo -e "${GREEN}$name${NC}:"
            ls -lh "$dir" 2>/dev/null | tail -n +2 | head -5
            echo ""
        fi
    done
}

show_usage() {
    cat << EOF
${GREEN}数据备份和恢复工具${NC}

${YELLOW}备份命令:${NC}
  $0 backup [软件] [选项]
    mysql [数据库名]     - 备份 MySQL（默认全量）
    mongodb [数据库名]  - 备份 MongoDB（默认全量）
    redis               - 备份 Redis
    configs             - 备份配置文件
    all                 - 全量备份

${YELLOW}恢复命令:${NC}
  $0 restore [软件] [备份文件] [数据库名]
    mysql <文件> [数据库名]
    mongodb <文件>
    redis <RDB文件>

${YELLOW}其他命令:${NC}
  list                 - 列出所有备份
  clean [天数]         - 清理旧备份（默认 7 天）

${YELLOW}示例:${NC}
  $0 backup all
  $0 backup mysql myapp
  $0 backup mongodb
  $0 backup redis
  $0 restore mysql /var/backups/shell-utils/mysql/all_databases_20240101.sql.gz
  $0 list
  $0 clean 30
EOF
}

main() {
    local command=$1
    shift
    
    case $command in
        backup)
            local target=$1
            shift
            case $target in
                mysql)
                    backup_mysql "$@"
                    ;;
                mongodb)
                    backup_mongodb "$@"
                    ;;
                redis)
                    backup_redis
                    ;;
                configs)
                    backup_configs
                    ;;
                all)
                    backup_all
                    ;;
                *)
                    print_error "未知备份目标: $target"
                    show_usage
                    ;;
            esac
            ;;
        restore)
            local target=$1
            shift
            case $target in
                mysql)
                    restore_mysql "$@"
                    ;;
                mongodb)
                    restore_mongodb "$1"
                    ;;
                redis)
                    restore_redis "$1"
                    ;;
                *)
                    print_error "未知恢复目标: $target"
                    show_usage
                    ;;
            esac
            ;;
        list)
            list_backups
            ;;
        clean)
            local days=${1:-7}
            print_step "1/1" "清理 $days 天前的备份"
            find "$BACKUP_DIR" -type f -mtime +$days -delete 2>/dev/null
            print_success "清理完成"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            show_usage
            ;;
    esac
}

main "$@"
