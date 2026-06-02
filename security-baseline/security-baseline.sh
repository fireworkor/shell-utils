#!/bin/bash

# =========================================
# 安全基线统一管理脚本
# 一键执行所有安全检查
# =========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPORT_DIR="security_reports_$(date +%Y%m%d)"
EMAIL="${EMAIL:-}"
DB_TYPE="${DB_TYPE:-}"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

show_help() {
    cat <<EOF
${GREEN}安全基线检查工具${NC}

${YELLOW}使用方法:${NC} $0 [选项] <检查类型...>

${BLUE}检查类型:${NC}
  all           - 执行所有安全检查
  os            - 操作系统安全检查
  database      - 数据库安全检查
  web           - Web 服务器安全检查
  docker        - Docker 安全检查
  network       - 网络安全检查
  
${BLUE}选项:${NC}
  --report-dir  - 指定报告输出目录
  --email       - 发送报告到指定邮箱
  --db-type     - 指定数据库类型 (mysql/postgresql/mongodb)
  --help        - 显示帮助信息

${BLUE}示例:${NC}
  $0 all                  # 执行所有检查
  $0 os database          # 执行系统和数据库检查
  $0 --report-dir ./reports all  # 指定报告目录
  $0 --db-type mysql database  # 指定数据库类型检查

EOF
}

create_report_dir() {
    if [ ! -d "$REPORT_DIR" ]; then
        mkdir -p "$REPORT_DIR"
        log_info "创建报告目录: $REPORT_DIR"
    fi
}

run_os_check() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}执行操作系统安全检查${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if [ -f "os/os_baseline.sh" ]; then
        bash "os/os_baseline.sh" | tee "$REPORT_DIR/os_check.log"
        log_success "操作系统安全检查完成"
    else
        log_error "操作系统检查脚本不存在"
    fi
}

run_database_check() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}执行数据库安全检查${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if [ -f "database/db_baseline.sh" ]; then
        bash "database/db_baseline.sh" "$DB_TYPE" | tee "$REPORT_DIR/database_check.log"
        log_success "数据库安全检查完成"
    else
        log_error "数据库检查脚本不存在"
    fi
}

run_web_check() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}执行 Web 服务器安全检查${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if [ -f "web/web_baseline.sh" ]; then
        bash "web/web_baseline.sh" | tee "$REPORT_DIR/web_check.log"
        log_success "Web 服务器安全检查完成"
    else
        log_error "Web 服务器检查脚本不存在"
    fi
}

run_docker_check() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}执行 Docker 安全检查${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if [ -f "docker/docker_baseline.sh" ]; then
        bash "docker/docker_baseline.sh" | tee "$REPORT_DIR/docker_check.log"
        log_success "Docker 安全检查完成"
    else
        log_error "Docker 检查脚本不存在"
    fi
}

run_network_check() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}执行网络安全检查${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if [ -f "network/network_baseline.sh" ]; then
        bash "network/network_baseline.sh" | tee "$REPORT_DIR/network_check.log"
        log_success "网络安全检查完成"
    else
        log_error "网络检查脚本不存在"
    fi
}

generate_summary() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}安全基线检查汇总${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    local total_pass=0
    local total_fail=0
    local total_warn=0
    
    for log_file in "$REPORT_DIR"/*.log; do
        if [ -f "$log_file" ]; then
            local filename=$(basename "$log_file" .log)
            local pass=$(grep -c "^\[PASS\]" "$log_file" 2>/dev/null || echo 0)
            local fail=$(grep -c "^\[FAIL\]" "$log_file" 2>/dev/null || echo 0)
            local warn=$(grep -c "^\[WARN\]" "$log_file" 2>/dev/null || echo 0)
            
            echo -e "${YELLOW}$filename:${NC}"
            echo "  通过: $pass"
            echo "  失败: $fail"
            echo "  警告: $warn"
            echo ""
            
            total_pass=$((total_pass + pass))
            total_fail=$((total_fail + fail))
            total_warn=$((total_warn + warn))
        fi
    done
    
    echo -e "${BLUE}总计:${NC}"
    echo "  通过: $total_pass"
    echo "  失败: $total_fail"
    echo "  警告: $total_warn"
    echo ""
    
    if [ "$total_fail" -gt 0 ]; then
        echo -e "${RED}⚠ 发现 $total_fail 项安全问题，请优先修复！${NC}"
    fi
    
    if [ "$total_warn" -gt 0 ]; then
        echo -e "${YELLOW}⚠ 发现 $total_warn 项安全警告，建议关注${NC}"
    fi
    
    if [ "$total_fail" -eq 0 ] && [ "$total_warn" -eq 0 ]; then
        echo -e "${GREEN}✓ 恭喜！未发现安全问题${NC}"
    fi
    
    echo ""
    echo "报告目录: $REPORT_DIR"
    echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
}

send_email_report() {
    if [ -z "$EMAIL" ]; then
        log_info "未配置邮箱，跳过邮件发送"
        return
    fi
    
    log_info "发送报告到: $EMAIL"
    
    local subject="安全基线检查报告 - $(hostname) - $(date '+%Y-%m-%d')"
    local body=$(cat <<EOF
安全基线检查报告

主机: $(hostname)
时间: $(date '+%Y-%m-%d %H:%M:%S')

检查类型: $CHECK_TYPES

报告详情请查看附件。

---
此邮件由安全基线检查工具自动发送
EOF
)
    
    if command -v mutt &>/dev/null; then
        echo "$body" | mutt -s "$subject" -a "$REPORT_DIR"/* "$EMAIL" 2>/dev/null || true
        log_success "报告已发送"
    elif command -v mail &>/dev/null; then
        echo "$body" | mail -s "$subject" -A "$REPORT_DIR" "$EMAIL" 2>/dev/null || true
        log_success "报告已发送"
    else
        log_error "未找到邮件客户端 (mutt 或 mail)"
        log_info "请手动发送报告: $REPORT_DIR"
    fi
}

main() {
    local args=("$@")
    local check_types=()
    
    # 解析参数
    for ((i=0; i<${#args[@]}; i++)); do
        case "${args[$i]}" in
            --help|-h)
                show_help
                exit 0
                ;;
            --report-dir)
                i=$((i+1))
                if [ $i -lt ${#args[@]} ]; then
                    REPORT_DIR="${args[$i]}"
                fi
                ;;
            --email)
                i=$((i+1))
                if [ $i -lt ${#args[@]} ]; then
                    EMAIL="${args[$i]}"
                fi
                ;;
            --db-type)
                i=$((i+1))
                if [ $i -lt ${#args[@]} ]; then
                    DB_TYPE="${args[$i]}"
                fi
                ;;
            all|os|database|web|docker|network)
                check_types+=("${args[$i]}")
                ;;
            *)
                log_error "未知选项: ${args[$i]}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 如果没有指定检查类型，默认执行所有检查
    if [ ${#check_types[@]} -eq 0 ]; then
        check_types=("all")
    fi
    
    CHECK_TYPES="${check_types[*]}"
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}安全基线检查工具${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    log_info "检查类型: ${CHECK_TYPES:-all}"
    log_info "报告目录: $REPORT_DIR"
    echo ""
    
    create_report_dir
    
    cd "$(dirname "$0")" || exit 1
    
    # 执行检查
    for type in "${check_types[@]}"; do
        case "$type" in
            all)
                run_os_check
                run_database_check
                run_web_check
                run_docker_check
                run_network_check
                ;;
            os)
                run_os_check
                ;;
            database)
                run_database_check
                ;;
            web)
                run_web_check
                ;;
            docker)
                run_docker_check
                ;;
            network)
                run_network_check
                ;;
        esac
    done
    
    generate_summary
    
    if [ -n "$EMAIL" ]; then
        send_email_report
    fi
    
    echo ""
    log_success "所有安全检查完成！"
}

main "$@"
