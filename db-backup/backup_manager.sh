#!/bin/bash
# 数据库备份管理脚本
# 统一管理所有数据库的增量和全量备份

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LOG_FILE="/var/log/db_backup_manager.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_info() {
    echo -e "\033[0;34m[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1\033[0m"
    log "INFO: $1"
}

log_success() {
    echo -e "\033[0;32m[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1\033[0m"
    log "SUCCESS: $1"
}

log_error() {
    echo -e "\033[0;31m[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1\033[0m"
    log "ERROR: $1"
}

# 执行MySQL备份
mysql_backup() {
    local action="$1"
    
    if [ -f "$SCRIPT_DIR/mysql/incremental.sh" ]; then
        log_info "执行 MySQL $action 备份..."
        "$SCRIPT_DIR/mysql/incremental.sh" "$action"
        if [ $? -eq 0 ]; then
            log_success "MySQL $action 备份完成"
        else
            log_error "MySQL $action 备份失败"
        fi
    else
        log_info "MySQL 备份脚本不存在，跳过"
    fi
}

# 执行PostgreSQL备份
postgresql_backup() {
    local action="$1"
    
    if [ -f "$SCRIPT_DIR/postgresql/incremental.sh" ]; then
        log_info "执行 PostgreSQL $action 备份..."
        "$SCRIPT_DIR/postgresql/incremental.sh" "$action"
        if [ $? -eq 0 ]; then
            log_success "PostgreSQL $action 备份完成"
        else
            log_error "PostgreSQL $action 备份失败"
        fi
    else
        log_info "PostgreSQL 备份脚本不存在，跳过"
    fi
}

# 执行MongoDB备份
mongodb_backup() {
    local action="$1"
    
    if [ -f "$SCRIPT_DIR/mongodb/incremental.sh" ]; then
        log_info "执行 MongoDB $action 备份..."
        "$SCRIPT_DIR/mongodb/incremental.sh" "$action"
        if [ $? -eq 0 ]; then
            log_success "MongoDB $action 备份完成"
        else
            log_error "MongoDB $action 备份失败"
        fi
    else
        log_info "MongoDB 备份脚本不存在，跳过"
    fi
}

# 执行Redis备份
redis_backup() {
    local action="$1"
    
    if [ -f "$SCRIPT_DIR/redis/incremental.sh" ]; then
        log_info "执行 Redis $action 备份..."
        "$SCRIPT_DIR/redis/incremental.sh" "$action"
        if [ $? -eq 0 ]; then
            log_success "Redis $action 备份完成"
        else
            log_error "Redis $action 备份失败"
        fi
    else
        log_info "Redis 备份脚本不存在，跳过"
    fi
}

# 执行MariaDB备份
mariadb_backup() {
    local action="$1"
    
    if [ -f "$SCRIPT_DIR/mariadb/full_backup.sh" ]; then
        log_info "执行 MariaDB $action 备份..."
        "$SCRIPT_DIR/mariadb/full_backup.sh" "$action"
        if [ $? -eq 0 ]; then
            log_success "MariaDB $action 备份完成"
        else
            log_error "MariaDB $action 备份失败"
        fi
    else
        log_info "MariaDB 备份脚本不存在，跳过"
    fi
}

# 执行SQLite备份
sqlite_backup() {
    local action="$1"
    
    if [ -f "$SCRIPT_DIR/sqlite/full_backup.sh" ]; then
        log_info "执行 SQLite $action 备份..."
        "$SCRIPT_DIR/sqlite/full_backup.sh" "$action"
        if [ $? -eq 0 ]; then
            log_success "SQLite $action 备份完成"
        else
            log_error "SQLite $action 备份失败"
        fi
    else
        log_info "SQLite 备份脚本不存在，跳过"
    fi
}

# 执行Elasticsearch备份
elasticsearch_backup() {
    local action="$1"
    
    if [ -f "$SCRIPT_DIR/elasticsearch/full_backup.sh" ]; then
        log_info "执行 Elasticsearch $action 备份..."
        "$SCRIPT_DIR/elasticsearch/full_backup.sh" "$action"
        if [ $? -eq 0 ]; then
            log_success "Elasticsearch $action 备份完成"
        else
            log_error "Elasticsearch $action 备份失败"
        fi
    else
        log_info "Elasticsearch 备份脚本不存在，跳过"
    fi
}

# 执行InfluxDB备份
influxdb_backup() {
    local action="$1"
    
    if [ -f "$SCRIPT_DIR/influxdb/full_backup.sh" ]; then
        log_info "执行 InfluxDB $action 备份..."
        "$SCRIPT_DIR/influxdb/full_backup.sh" "$action"
        if [ $? -eq 0 ]; then
            log_success "InfluxDB $action 备份完成"
        else
            log_error "InfluxDB $action 备份失败"
        fi
    else
        log_info "InfluxDB 备份脚本不存在，跳过"
    fi
}

# 执行所有数据库的增量备份
do_all_incremental() {
    log_info "开始执行所有数据库的增量备份..."
    
    mysql_backup "incremental"
    postgresql_backup "incremental"
    mongodb_backup "incremental"
    redis_backup "incremental"
    mariadb_backup "incremental"
    sqlite_backup "incremental"
    elasticsearch_backup "incremental"
    influxdb_backup "incremental"
    
    log_success "所有数据库增量备份任务完成"
}

# 执行所有数据库的全量备份
do_all_full() {
    log_info "开始执行所有数据库的全量备份..."
    
    mysql_backup "full"
    postgresql_backup "full"
    mongodb_backup "full"
    redis_backup "full"
    mariadb_backup "full"
    sqlite_backup "full"
    elasticsearch_backup "full"
    influxdb_backup "full"
    
    log_success "所有数据库全量备份任务完成"
}

# 清理所有数据库的旧备份
do_all_cleanup() {
    log_info "开始清理所有数据库的旧备份..."
    
    mysql_backup "cleanup"
    postgresql_backup "cleanup"
    mongodb_backup "cleanup"
    redis_backup "cleanup"
    mariadb_backup "cleanup"
    sqlite_backup "cleanup"
    elasticsearch_backup "cleanup"
    influxdb_backup "cleanup"
    
    log_success "所有数据库旧备份清理完成"
}

# 列出所有数据库的备份
list_all_backups() {
    echo "========================================"
    echo "          数据库备份列表"
    echo "========================================"
    
    mysql_backup "list"
    echo ""
    postgresql_backup "list"
    echo ""
    mongodb_backup "list"
    echo ""
    redis_backup "list"
    echo ""
    mariadb_backup "list"
    echo ""
    sqlite_backup "list"
    echo ""
    elasticsearch_backup "list"
    echo ""
    influxdb_backup "list"
    
    echo "========================================"
}

# 显示帮助信息
show_help() {
    echo "数据库备份管理脚本"
    echo "用法: $0 {incremental|full|cleanup|all|list}"
    echo ""
    echo "选项:"
    echo "  incremental   - 执行所有数据库的增量备份（每天执行）"
    echo "  full          - 执行所有数据库的全量备份（每30天执行）"
    echo "  cleanup       - 清理所有数据库的旧备份"
    echo "  all           - 执行增量备份并清理旧备份"
    echo "  list          - 列出所有数据库的备份"
    echo ""
    echo "支持的数据库:"
    echo "  MySQL, PostgreSQL, MongoDB, Redis"
    echo "  MariaDB, SQLite, Elasticsearch, InfluxDB"
    echo ""
    echo "配置环境变量:"
    echo "  MySQL: MYSQL_USER, MYSQL_PASSWORD, MYSQL_HOST, MYSQL_PORT"
    echo "  PostgreSQL: PG_USER, PG_HOST, PG_PORT, PG_DATABASE"
    echo "  MongoDB: MONGO_HOST, MONGO_PORT, MONGO_USER, MONGO_PASSWORD"
    echo "  Redis: REDIS_HOST, REDIS_PORT, REDIS_PASSWORD"
    echo "  MariaDB: MARIADB_USER, MARIADB_PASSWORD, MARIADB_HOST, MARIADB_PORT"
    echo "  SQLite: SQLITE_DB_PATHS (数据库文件路径，多个用空格分隔)"
    echo "  Elasticsearch: ES_HOST, ES_PORT, ES_USER, ES_PASSWORD"
    echo "  InfluxDB: INFLUX_HOST, INFLUX_PORT, INFLUX_TOKEN, INFLUX_ORG"
}

# 主函数
main() {
    mkdir -p /var/log
    
    case "$1" in
        incremental)
            do_all_incremental
            ;;
        full)
            do_all_full
            ;;
        cleanup)
            do_all_cleanup
            ;;
        all)
            do_all_incremental
            do_all_cleanup
            ;;
        list)
            list_all_backups
            ;;
        *)
            show_help
            ;;
    esac
}

main "$@"