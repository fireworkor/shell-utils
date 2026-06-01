#!/bin/bash

# =========================================
# 数据库安全基线检查脚本
# 支持: MySQL, PostgreSQL, MongoDB, Redis
# =========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DB_TYPE="${1:-all}"
REPORT_FILE="db_security_report_$(date +%Y%m%d_%H%M%S).txt"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
    echo "[INFO] $*" >> "$REPORT_FILE"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
    echo "[PASS] $*" >> "$REPORT_FILE"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $*"
    echo "[FAIL] $*" >> "$REPORT_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
    echo "[WARN] $*" >> "$REPORT_FILE"
}

init_report() {
    echo "========================================" > "$REPORT_FILE"
    echo "数据库安全基线检查报告" >> "$REPORT_FILE"
    echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT_FILE"
    echo "检查类型: $DB_TYPE" >> "$REPORT_FILE"
    echo "========================================" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

check_mysql() {
    echo -e "${BLUE}========== MySQL 安全检查 ==========${NC}" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
    
    if ! command -v mysql &>/dev/null; then
        log_warn "MySQL 未安装"
        return
    fi
    
    log_info "MySQL 版本: $(mysql --version 2>/dev/null)"
    
    log_info "检查 1: MySQL root 账户"
    local root_users=$(mysql -N -e "SELECT user,host FROM mysql.user WHERE user='root' AND host='%';" 2>/dev/null)
    if [ -z "$root_users" ]; then
        log_pass "MySQL root 不允许远程登录 (符合要求)"
    else
        log_fail "MySQL root 允许远程登录 (应限制)"
    fi
    
    log_info "检查 2: 匿名账户"
    local anon_users=$(mysql -N -e "SELECT user,host FROM mysql.user WHERE user='';" 2>/dev/null)
    if [ -z "$anon_users" ]; then
        log_pass "没有匿名账户 (符合要求)"
    else
        log_fail "发现匿名账户: $anon_users (应删除)"
    fi
    
    log_info "检查 3: 空密码账户"
    local empty_pwd=$(mysql -N -e "SELECT user,host FROM mysql.user WHERE authentication_string='' OR password='';" 2>/dev/null)
    if [ -z "$empty_pwd" ]; then
        log_pass "没有空密码账户 (符合要求)"
    else
        log_fail "发现空密码账户: $empty_pwd"
    fi
    
    log_info "检查 4: test 数据库"
    local test_db=$(mysql -N -e "SHOW DATABASES LIKE 'test';" 2>/dev/null)
    if [ -z "$test_db" ]; then
        log_pass "test 数据库不存在 (符合要求)"
    else
        log_warn "test 数据库存在 (建议删除)"
    fi
    
    log_info "检查 5: LOAD DATA 权限"
    local load_data_priv=$(mysql -N -e "SELECT user,host FROM mysql.user WHERE File_priv='Y';" 2>/dev/null)
    if [ -n "$load_data_priv" ]; then
        log_warn "以下用户有 FILE 权限: $load_data_priv (建议限制)"
    else
        log_pass "FILE 权限已正确配置"
    fi
    
    log_info "检查 6: SQL Mode"
    local sql_mode=$(mysql -N -e "SELECT @@sql_mode;" 2>/dev/null)
    if echo "$sql_mode" | grep -q "NO_AUTO_CREATE_USER"; then
        log_pass "SQL_MODE 包含 NO_AUTO_CREATE_USER (符合要求)"
    else
        log_warn "SQL_MODE 未包含 NO_AUTO_CREATE_USER"
    fi
    
    log_info "检查 7: 版本信息隐藏"
    local version=$(mysql -N -e "SHOW VARIABLES LIKE 'show_compatibility_56';" 2>/dev/null)
    if [ -n "$version" ]; then
        log_pass "MySQL 版本信息可配置"
    fi
    
    log_info "检查 8: 绑定地址"
    local bind_addr=$(mysql -N -e "SHOW VARIABLES LIKE 'bind_address';" 2>/dev/null | awk '{print $2}')
    if [ "$bind_addr" = "127.0.0.1" ] || [ "$bind_addr" = "::1" ] || [ -z "$bind_addr" ]; then
        log_pass "MySQL 绑定地址为本地 (符合要求)"
    else
        log_warn "MySQL 绑定地址为 $bind_addr (建议限制为 127.0.0.1)"
    fi
}

check_postgresql() {
    echo -e "${BLUE}========== PostgreSQL 安全检查 ==========${NC}" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
    
    if ! command -v psql &>/dev/null; then
        log_warn "PostgreSQL 未安装"
        return
    fi
    
    log_info "PostgreSQL 版本: $(psql --version 2>/dev/null)"
    
    log_info "检查 1: pg_hba.conf 配置"
    if [ -f /etc/postgresql/*/main/pg_hba.conf ] || [ -f /var/lib/pgsql/data/pg_hba.conf ]; then
        local pg_hba=$(find /etc/postgresql -name pg_hba.conf 2>/dev/null | head -1)
        if [ -z "$pg_hba" ]; then
            pg_hba=$(find /var/lib -name pg_hba.conf 2>/dev/null | head -1)
        fi
        
        if [ -n "$pg_hba" ]; then
            local trust_conns=$(grep -v "^#" "$pg_hba" | grep "trust" | grep -v "local")
            if [ -z "$trust_conns" ]; then
                log_pass "pg_hba.conf 没有 trust 认证方式 (符合要求)"
            else
                log_fail "发现 trust 认证配置: $trust_conns (应改为 md5 或 scram-sha-256)"
            fi
        fi
    fi
    
    log_info "检查 2: 超级用户检查"
    local superusers=$(psql -t -c "SELECT rolname FROM pg_roles WHERE rolsuper = true;" 2>/dev/null)
    local su_count=$(echo "$superusers" | wc -l)
    if [ "$su_count" -gt 1 ]; then
        log_warn "超级用户数量: $su_count (建议限制)"
    else
        log_pass "超级用户数量正常"
    fi
    
    log_info "检查 3: pg_execute_server_program"
    local dangerous_ext=$(psql -t -c "SELECT extname FROM pg_extension WHERE extname IN ('pg_execute_server_program', 'postgres_fdw', 'dblink');" 2>/dev/null)
    if [ -n "$dangerous_ext" ]; then
        log_warn "发现潜在危险扩展: $dangerous_ext (建议禁用)"
    else
        log_pass "没有发现危险扩展"
    fi
    
    log_info "检查 4: 密码强度"
    local password_enc=$(psql -t -c "SHOW password_encryption;" 2>/dev/null | tr -d ' ')
    if [ "$password_enc" = "scram-sha-256" ] || [ "$password_enc" = "md5" ]; then
        log_pass "密码加密方式为 $password_enc (符合要求)"
    else
        log_warn "密码加密方式为 $password_enc (建议使用 scram-sha-256)"
    fi
    
    log_info "检查 5: 日志记录"
    local logging=$(psql -t -c "SHOW logging_collector;" 2>/dev/null | tr -d ' ')
    if [ "$logging" = "on" ]; then
        log_pass "日志记录已启用 (符合要求)"
    else
        log_warn "日志记录未启用 (建议启用)"
    fi
}

check_mongodb() {
    echo -e "${BLUE}========== MongoDB 安全检查 ==========${NC}" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
    
    if ! command -v mongod &>/dev/null; then
        log_warn "MongoDB 未安装"
        return
    fi
    
    log_info "MongoDB 版本: $(mongod --version 2>/dev/null | head -1)"
    
    log_info "检查 1: 认证机制"
    if [ -f /etc/mongod.conf ]; then
        local auth=$(grep -A 5 "security:" /etc/mongod.conf | grep "authorization:")
        if echo "$auth" | grep -q "enabled"; then
            log_pass "MongoDB 认证已启用 (符合要求)"
        else
            log_fail "MongoDB 认证未启用 (必须启用)"
        fi
        
        log_info "检查 2: 绑定 IP"
        local bind_ip=$(grep "bindIp:" /etc/mongod.conf | awk '{print $2}')
        if echo "$bind_ip" | grep -q "127.0.0.1"; then
            log_pass "MongoDB 绑定到本地 (符合要求)"
        elif echo "$bind_ip" | grep -q "0.0.0.0"; then
            log_fail "MongoDB 绑定到所有地址 (应限制)"
        else
            log_warn "MongoDB 绑定地址为: $bind_ip"
        fi
        
        log_info "检查 3: 端口"
        local port=$(grep "^  port:" /etc/mongod.conf | awk '{print $2}')
        if [ "$port" != "27017" ]; then
            log_warn "MongoDB 使用非标准端口: $port"
        else
            log_pass "MongoDB 使用标准端口"
        fi
    fi
}

check_redis() {
    echo -e "${BLUE}========== Redis 安全检查 ==========${NC}" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
    
    if ! command -v redis-cli &>/dev/null; then
        log_warn "Redis 未安装"
        return
    fi
    
    log_info "Redis 版本: $(redis-cli --version 2>/dev/null)"
    
    log_info "检查 1: 绑定地址"
    if [ -f /etc/redis/redis.conf ] || [ -f /etc/redis.conf ]; then
        local redis_conf=$(find /etc -name redis.conf 2>/dev/null | head -1)
        if [ -z "$redis_conf" ]; then
            redis_conf=$(find / -name redis.conf 2>/dev/null | grep -v proc | head -1)
        fi
        
        if [ -n "$redis_conf" ]; then
            local bind_ip=$(grep "^bind " "$redis_conf" | awk '{print $2}')
            if echo "$bind_ip" | grep -q "127.0.0.1"; then
                log_pass "Redis 绑定到本地 (符合要求)"
            elif echo "$bind_ip" | grep -q "0.0.0.0"; then
                log_fail "Redis 绑定到所有地址 (应限制)"
            else
                log_warn "Redis 绑定地址为: $bind_ip"
            fi
            
            log_info "检查 2: 保护模式"
            local protected=$(grep "^protected-mode" "$redis_conf" | awk '{print $2}')
            if [ "$protected" = "yes" ]; then
                log_pass "Redis 保护模式已启用 (符合要求)"
            else
                log_fail "Redis 保护模式未启用 (应启用)"
            fi
            
            log_info "检查 3: 密码认证"
            local requirepass=$(grep "^requirepass" "$redis_conf")
            if [ -n "$requirepass" ]; then
                log_pass "Redis 密码认证已配置 (符合要求)"
            else
                log_fail "Redis 未配置密码 (必须配置)"
            fi
            
            log_info "检查 4: 危险命令"
            local dangerous_cmds=$(grep "^rename-command" "$redis_conf" | grep -E "FLUSHDB|FLUSHALL|CONFIG|SHUTDOWN|EVAL" | head -5)
            if [ -n "$dangerous_cmds" ]; then
                log_pass "危险命令已重命名 (符合要求)"
            else
                log_warn "危险命令未重命名 (建议重命名 FLUSHDB, FLUSHALL, CONFIG 等)"
            fi
        fi
    fi
}

show_summary() {
    echo ""
    echo "========================================"
    echo "数据库安全检查完成"
    echo "========================================"
    echo "报告已保存到: $REPORT_FILE"
    echo ""
    
    local pass_count=$(grep -c "^\[PASS\]" "$REPORT_FILE")
    local fail_count=$(grep -c "^\[FAIL\]" "$REPORT_FILE")
    local warn_count=$(grep -c "^\[WARN\]" "$REPORT_FILE")
    
    echo "通过: $pass_count"
    echo "失败: $fail_count"
    echo "警告: $warn_count"
    echo ""
}

main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}数据库安全基线检查${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    init_report
    
    case "$DB_TYPE" in
        mysql)
            check_mysql
            ;;
        postgresql)
            check_postgresql
            ;;
        mongodb)
            check_mongodb
            ;;
        redis)
            check_redis
            ;;
        all)
            check_mysql
            echo ""
            check_postgresql
            echo ""
            check_mongodb
            echo ""
            check_redis
            ;;
        *)
            echo "用法: $0 [mysql|postgresql|mongodb|redis|all]"
            exit 1
            ;;
    esac
    
    show_summary
}

main
