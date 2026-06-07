#!/bin/bash

# =========================================
# 日常巡检脚本
# 综合健康检查、安全扫描、性能监控
# =========================================

# 设置错误处理，但不使用 set -e，因为我们需要更好的控制
set -o pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 设置脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPORT_DIR="daily_check_report_$(date +%Y%m%d)"
REPORT_FILE="$REPORT_DIR/report.txt"
EMAIL="${EMAIL:-}"

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

log_section() {
    echo "" | tee -a "$REPORT_FILE"
    echo -e "${CYAN}========================================${NC}" | tee -a "$REPORT_FILE"
    echo -e "${CYAN} $1${NC}" | tee -a "$REPORT_FILE"
    echo -e "${CYAN}========================================${NC}" | tee -a "$REPORT_FILE"
}

init_report() {
    mkdir -p "$REPORT_DIR"
    
    echo "========================================" > "$REPORT_FILE"
    echo "日常巡检报告" >> "$REPORT_FILE"
    echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT_FILE"
    echo "主机名: $(hostname)" >> "$REPORT_FILE"
    echo "操作系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)" >> "$REPORT_FILE"
    echo "内核版本: $(uname -r)" >> "$REPORT_FILE"
    echo "========================================" >> "$REPORT_FILE"
}

check_system_info() {
    log_section "系统信息"
    
    log_info "主机名: $(hostname)"
    log_info "IP 地址: $(hostname -I | awk '{print $1}')"
    log_info "运行时间: $(uptime -p)"
    log_info "系统负载: $(uptime | awk '{print $10 $11 $12}')"
    
    local cpu_cores mem_total disk_total
    cpu_cores=$(nproc)
    mem_total=$(free -h | grep Mem | awk '{print $2}')
    disk_total=$(df -h / | grep / | awk '{print $2}')
    
    log_info "CPU 核心: $cpu_cores"
    log_info "内存总量: $mem_total"
    log_info "磁盘总量: $disk_total"
    
    log_pass "系统信息检查完成"
}

check_cpu_usage() {
    log_section "CPU 使用情况"
    
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    cpu_usage=$(printf "%.1f" "$cpu_usage")
    
    log_info "CPU 使用率: ${cpu_usage}%"
    
    if (( $(echo "$cpu_usage < 80" | bc -l) )); then
        log_pass "CPU 使用正常"
    elif (( $(echo "$cpu_usage < 95" | bc -l) )); then
        log_warn "CPU 使用较高"
    else
        log_fail "CPU 使用过高"
    fi
    
    log_info "CPU 详情:"
    top -bn1 | grep "Cpu(s)" | head -3 | while read line; do
        log_info "  $line"
        echo "  $line" >> "$REPORT_FILE"
    done
}

check_memory_usage() {
    log_section "内存使用情况"
    
    local mem_info mem_total mem_used mem_usage
    mem_info=$(free -m | grep Mem)
    mem_total=$(echo "$mem_info" | awk '{print $2}')
    mem_used=$(echo "$mem_info" | awk '{print $3}')
    mem_usage=$(echo "scale=2; $mem_used / $mem_total * 100" | bc)
    
    log_info "内存总量: ${mem_total}MB"
    log_info "已使用: ${mem_used}MB (${mem_usage}%)"
    
    if (( $(echo "$mem_usage < 80" | bc -l) )); then
        log_pass "内存使用正常"
    elif (( $(echo "$mem_usage < 90" | bc -l) )); then
        log_warn "内存使用较高"
    else
        log_fail "内存使用过高"
    fi
    
    log_info "Swap 使用: $(free -m | grep Swap | awk '{print $3 "/" $2}')MB"
}

check_disk_usage() {
    log_section "磁盘使用情况"
    
    local critical=false
    
    df -h | grep -v "tmpfs" | grep -v "loop" | while read line; do
        local mount=$(echo "$line" | awk '{print $6}')
        local usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        
        log_info "$mount: $usage%"
        
        if (( usage >= 95 )); then
            log_fail "$mount 磁盘空间不足 (${usage}%)"
            critical=true
        elif (( usage >= 85 )); then
            log_warn "$mount 磁盘空间较高 (${usage}%)"
        else
            log_pass "$mount 磁盘空间正常"
        fi
    done
    
    if [ "$critical" = true ]; then
        log_fail "发现磁盘空间严重不足"
    fi
}

check_network_status() {
    log_section "网络状态"
    
    local interfaces
    interfaces=$(ip link show | grep "state UP" | awk -F': ' '{print $2}')
    
    for iface in $interfaces; do
        if [ "$iface" != "lo" ]; then
            local ip=$(ip addr show "$iface" | grep "inet " | awk '{print $2}')
            log_info "$iface: $ip"
        fi
    done
    
    log_info "网络连接测试..."
    
    if ping -c 1 8.8.8.8 &>/dev/null; then
        log_pass "外网连接正常"
    else
        log_fail "外网连接失败"
    fi
    
    if ping -c 1 127.0.0.1 &>/dev/null; then
        log_pass "本地回环正常"
    else
        log_fail "本地回环失败"
    fi
}

check_service_status() {
    log_section "服务状态"
    
    local services=("nginx" "mysql" "redis" "docker" "sshd" "firewalld")
    local failed_services=()
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            log_pass "$service 服务运行正常"
        elif systemctl list-unit-files | grep -q "$service"; then
            log_warn "$service 服务未运行"
            failed_services+=("$service")
        fi
    done
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        log_fail "以下服务未运行: ${failed_services[*]}"
    fi
}

check_running_processes() {
    log_section "运行进程"
    
    local process_count
    process_count=$(ps aux | wc -l)
    log_info "进程总数: $process_count"
    
    log_info "占用资源最高的进程:"
    ps aux --sort=-%mem | head -6 | while read line; do
        echo "$line" | awk '{print "  " $11 " - CPU:" $3 "% MEM:" $4 "%"}'
        echo "$line" | awk '{print "  " $11 " - CPU:" $3 "% MEM:" $4 "%"}' >> "$REPORT_FILE"
    done
}

check_logs() {
    log_section "日志检查"
    
    local error_count=0
    
    if [ -f /var/log/messages ]; then
        error_count=$(grep -i "error" /var/log/messages | tail -100 | wc -l)
        if [ "$error_count" -gt 10 ]; then
            log_warn "发现 $error_count 条错误日志"
        else
            log_pass "系统日志正常"
        fi
    fi
    
    if [ -f /var/log/syslog ]; then
        error_count=$(grep -i "error" /var/log/syslog | tail -100 | wc -l)
        if [ "$error_count" -gt 10 ]; then
            log_warn "发现 $error_count 条错误日志"
        else
            log_pass "系统日志正常"
        fi
    fi
    
    log_info "最近的系统日志:"
    tail -5 /var/log/messages 2>/dev/null || tail -5 /var/log/syslog 2>/dev/null || echo "无法读取日志"
}

check_security() {
    log_section "安全检查"
    
    local failed_count=0
    
    if [ -f "$SCRIPT_DIR/security-baseline/os/os_baseline.sh" ]; then
        bash "$SCRIPT_DIR/security-baseline/os/os_baseline.sh" > "$REPORT_DIR/security_check.log"
        
        local fail_count=$(grep -c "^\[FAIL\]" "$REPORT_DIR/security_check.log")
        local warn_count=$(grep -c "^\[WARN\]" "$REPORT_DIR/security_check.log")
        
        if [ "$fail_count" -gt 0 ]; then
            log_fail "发现 $fail_count 项安全问题"
            failed_count=$((failed_count + fail_count))
        fi
        
        if [ "$warn_count" -gt 0 ]; then
            log_warn "发现 $warn_count 项安全警告"
        fi
        
        if [ "$fail_count" -eq 0 ] && [ "$warn_count" -eq 0 ]; then
            log_pass "安全检查通过"
        fi
    else
        log_warn "安全基线脚本未找到"
    fi
    
    if [ "$failed_count" -gt 0 ]; then
        log_fail "安全检查未通过"
    fi
}

check_cron_jobs() {
    log_section "定时任务检查"
    
    local cron_count
    cron_count=$(crontab -l 2>/dev/null | grep -v "^#" | grep -v "^$" | wc -l)
    log_info "定时任务数量: $cron_count"
    
    if [ "$cron_count" -gt 0 ]; then
        log_info "定时任务列表:"
        crontab -l 2>/dev/null | grep -v "^#" | grep -v "^$" | while read line; do
            log_info "  $line"
        done
        log_pass "定时任务检查完成"
    else
        log_warn "没有配置定时任务"
    fi
}

check_backup_status() {
    log_section "备份状态"
    
    local backup_dir="/var/backups"
    local recent_backup
    recent_backup=$(find "$backup_dir" -type f -name "*.tar.gz" -mtime -7 2>/dev/null | head -1)
    
    if [ -n "$recent_backup" ]; then
        log_pass "最近一周有备份: $(basename "$recent_backup")"
    else
        log_warn "最近一周没有备份"
    fi
}

generate_summary() {
    log_section "检查总结"
    
    local pass_count fail_count warn_count
    pass_count=$(grep -c "^\[PASS\]" "$REPORT_FILE")
    fail_count=$(grep -c "^\[FAIL\]" "$REPORT_FILE")
    warn_count=$(grep -c "^\[WARN\]" "$REPORT_FILE")
    
    echo "" | tee -a "$REPORT_FILE"
    echo "检查结果汇总:" | tee -a "$REPORT_FILE"
    echo "  通过: $pass_count" | tee -a "$REPORT_FILE"
    echo "  失败: $fail_count" | tee -a "$REPORT_FILE"
    echo "  警告: $warn_count" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
    
    if [ "$fail_count" -gt 0 ]; then
        echo -e "${RED}⚠ 发现 $fail_count 项问题，请及时处理${NC}" | tee -a "$REPORT_FILE"
    fi
    
    if [ "$warn_count" -gt 0 ]; then
        echo -e "${YELLOW}⚠ 发现 $warn_count 项警告，建议关注${NC}" | tee -a "$REPORT_FILE"
    fi
    
    if [ "$fail_count" -eq 0 ] && [ "$warn_count" -eq 0 ]; then
        echo -e "${GREEN}✓ 所有检查通过！${NC}" | tee -a "$REPORT_FILE"
    fi
    
    echo "" | tee -a "$REPORT_FILE"
    echo "报告位置: $REPORT_FILE" | tee -a "$REPORT_FILE"
    echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$REPORT_FILE"
}

send_email() {
    if [ -z "$EMAIL" ]; then
        log_info "未配置邮箱，跳过邮件发送"
        return
    fi
    
    log_info "发送报告到: $EMAIL"
    
    local subject body
    subject="日常巡检报告 - $(hostname) - $(date '+%Y-%m-%d')"
    body="日常巡检报告已完成，请查看附件。"
    
    if command -v mutt &>/dev/null; then
        echo "$body" | mutt -s "$subject" -a "$REPORT_FILE" "$EMAIL"
        log_success "报告已发送"
    elif command -v mail &>/dev/null; then
        echo "$body" | mail -s "$subject" -A "$REPORT_FILE" "$EMAIL"
        log_success "报告已发送"
    else
        log_warn "未找到邮件客户端，报告已保存到 $REPORT_FILE"
    fi
}

main() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}      日常巡检脚本${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    init_report
    
    check_system_info
    check_cpu_usage
    check_memory_usage
    check_disk_usage
    check_network_status
    check_service_status
    check_running_processes
    check_logs
    check_security
    check_cron_jobs
    check_backup_status
    
    generate_summary
    
    if [ -n "$EMAIL" ]; then
        send_email
    fi
    
    echo ""
    echo -e "${GREEN}巡检完成！报告已保存到: $REPORT_FILE${NC}"
}

main "$@"
