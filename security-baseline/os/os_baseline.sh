#!/bin/bash

# =========================================
# 操作系统安全基线检查脚本
# 检查项：用户和组、密码策略、文件权限、服务配置等
# =========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPORT_FILE="os_security_report_$(date +%Y%m%d_%H%M%S).txt"

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
    echo "操作系统安全基线检查报告" >> "$REPORT_FILE"
    echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT_FILE"
    echo "主机名: $(hostname)" >> "$REPORT_FILE"
    echo "操作系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)" >> "$REPORT_FILE"
    echo "内核版本: $(uname -r)" >> "$REPORT_FILE"
    echo "========================================" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

check_passwd_file() {
    log_info "检查 1: 密码文件权限"
    
    if [ -f /etc/passwd ]; then
        local perm=$(stat -c %a /etc/passwd)
        if [ "$perm" = "644" ] || [ "$perm" = "640" ]; then
            log_pass "/etc/passwd 权限为 $perm (符合要求)"
        else
            log_fail "/etc/passwd 权限为 $perm (应为 644 或 640)"
        fi
    fi
}

check_shadow_file() {
    log_info "检查 2: 阴影密码文件权限"
    
    if [ -f /etc/shadow ]; then
        local perm=$(stat -c %a /etc/shadow)
        local owner=$(stat -c %U /etc/shadow)
        if [ "$perm" = "0" ] || [ "$perm" = "400" ] || [ "$perm" = "600" ]; then
            log_pass "/etc/shadow 权限为 $perm, 所有者为 $owner (符合要求)"
        else
            log_fail "/etc/shadow 权限为 $perm (应为 0, 400 或 600)"
        fi
    fi
}

check_group_file() {
    log_info "检查 3: 组文件权限"
    
    if [ -f /etc/group ]; then
        local perm=$(stat -c %a /etc/group)
        if [ "$perm" = "644" ] || [ "$perm" = "640" ]; then
            log_pass "/etc/group 权限为 $perm (符合要求)"
        else
            log_fail "/etc/group 权限为 $perm (应为 644 或 640)"
        fi
    fi
}

check_root_uid() {
    log_info "检查 4: root 账户 UID 检查"
    
    local root_uid=$(grep "^root:" /etc/passwd | cut -d: -f3)
    if [ "$root_uid" = "0" ]; then
        log_pass "root 账户 UID 为 0 (符合要求)"
    else
        log_fail "root 账户 UID 为 $root_uid (应为 0)"
    fi
}

check_duplicate_uid() {
    log_info "检查 5: 重复 UID 检查"
    
    local dup_uids=$(cut -d: -f3 /etc/passwd | sort | uniq -d | head -10)
    if [ -z "$dup_uids" ]; then
        log_pass "没有发现重复 UID (符合要求)"
    else
        log_warn "发现重复 UID: $dup_uids"
    fi
}

check_empty_password() {
    log_info "检查 6: 空密码账户检查"
    
    local empty_pwd=$(awk -F: '($2 == "") {print $1}' /etc/shadow 2>/dev/null)
    if [ -z "$empty_pwd" ]; then
        log_pass "没有发现空密码账户 (符合要求)"
    else
        log_fail "发现空密码账户: $empty_pwd"
    fi
}

check_password_policy() {
    log_info "检查 7: 密码策略配置"
    
    if [ -f /etc/login.defs ]; then
        local min_len=$(grep "^PASS_MIN_LEN" /etc/login.defs | awk '{print $2}')
        if [ -n "$min_len" ] && [ "$min_len" -ge 8 ]; then
            log_pass "密码最小长度设置为 $min_len (符合要求)"
        else
            log_fail "密码最小长度设置为 $min_len (应至少为 8)"
        fi
        
        local max_days=$(grep "^PASS_MAX_DAYS" /etc/login.defs | awk '{print $2}')
        if [ -n "$max_days" ] && [ "$max_days" -le 90 ]; then
            log_pass "密码最大使用天数设置为 $max_days (符合要求)"
        else
            log_fail "密码最大使用天数设置为 $max_days (应不超过 90)"
        fi
    fi
}

check_sudo_config() {
    log_info "检查 8: sudo 配置检查"
    
    if [ -d /etc/sudoers.d ]; then
        local perm=$(stat -c %a /etc/sudoers.d)
        if [ "$perm" = "750" ] || [ "$perm" = "440" ]; then
            log_pass "/etc/sudoers.d 权限为 $perm (符合要求)"
        else
            log_fail "/etc/sudoers.d 权限为 $perm (应为 750 或 440)"
        fi
    fi
    
    if [ -f /etc/sudoers ]; then
        local perm=$(stat -c %a /etc/sudoers)
        if [ "$perm" = "440" ]; then
            log_pass "/etc/sudoers 权限为 $perm (符合要求)"
        else
            log_fail "/etc/sudoors 权限为 $perm (应为 440)"
        fi
    fi
}

check_ssh_config() {
    log_info "检查 9: SSH 安全配置"
    
    if [ -f /etc/ssh/sshd_config ]; then
        if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
            log_pass "SSH 禁止 root 登录 (符合要求)"
        else
            log_fail "SSH 允许 root 登录 (应禁止)"
        fi
        
        if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
            log_pass "SSH 禁用密码认证 (符合要求)"
        else
            log_warn "SSH 启用了密码认证 (建议禁用)"
        fi
        
        if grep -q "^Protocol 2" /etc/ssh/sshd_config || grep -q "^Protocol 2" /etc/ssh/sshd_config; then
            log_pass "SSH 使用协议版本 2 (符合要求)"
        else
            log_fail "SSH 未明确使用协议版本 2"
        fi
    fi
}

check_cron_access() {
    log_info "检查 10: Cron 服务访问控制"
    
    if [ -f /etc/cron.deny ]; then
        log_pass "/etc/cron.deny 存在 (符合要求)"
    else
        log_warn "/etc/cron.deny 不存在 (建议创建)"
    fi
    
    if [ -f /etc/at.deny ]; then
        log_pass "/etc/at.deny 存在 (符合要求)"
    else
        log_warn "/etc/at.deny 不存在 (建议创建)"
    fi
}

check_sysctl_config() {
    log_info "检查 11: 内核参数配置"
    
    if sysctl net.ipv4.ip_forward 2>/dev/null | grep -q "net.ipv4.ip_forward = 0"; then
        log_pass "IP 转发已禁用 (符合要求)"
    else
        log_warn "IP 转发未禁用或未配置"
    fi
    
    if sysctl net.ipv4.conf.all.accept_source_route 2>/dev/null | grep -q "net.ipv4.conf.all.accept_source_route = 0"; then
        log_pass "源路由已禁用 (符合要求)"
    else
        log_warn "源路由未禁用"
    fi
    
    if sysctl net.ipv4.icmp_echo_ignore_broadcasts 2>/dev/null | grep -q "net.ipv4.icmp_echo_ignore_broadcasts = 1"; then
        log_pass "ICMP 广播已忽略 (符合要求)"
    else
        log_warn "ICMP 广播未忽略"
    fi
    
    if sysctl net.ipv4.conf.all.rp_filter 2>/dev/null | grep -q "net.ipv4.conf.all.rp_filter = 1"; then
        log_pass "反向路径过滤已启用 (符合要求)"
    else
        log_warn "反向路径过滤未启用"
    fi
}

check_unused_services() {
    log_info "检查 12: 不必要服务检查"
    
    local services=("telnet" "rsh" "rlogin" "vsftpd" "xinetd" "cups" "avahi-daemon" "nfslock" "rpcbind" "ftp")
    
    for service in "${services[@]}"; do
        if systemctl list-unit-files | grep -q "^${service}"; then
            if systemctl is-active --quiet "$service" 2>/dev/null; then
                log_fail "服务 $service 正在运行 (应停止)"
            else
                log_pass "服务 $service 未运行"
            fi
        fi
    done
}

check_firewall() {
    log_info "检查 13: 防火墙状态"
    
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        log_pass "firewalld 正在运行 (符合要求)"
    elif systemctl is-active --quiet ufw 2>/dev/null; then
        log_pass "ufw 正在运行 (符合要求)"
    elif iptables -L -n 2>/dev/null | grep -q "Chain INPUT"; then
        log_pass "iptables 规则已配置 (符合要求)"
    else
        log_warn "未检测到活动的防火墙"
    fi
}

check_audit_service() {
    log_info "检查 14: 审计服务状态"
    
    if systemctl is-active --quiet auditd 2>/dev/null; then
        log_pass "auditd 审计服务正在运行 (符合要求)"
    else
        log_warn "auditd 审计服务未运行 (建议启用)"
    fi
}

check_world_writable() {
    log_info "检查 15: 全局可写文件检查"
    
    local ww_files=$(df --local | awk 'NR>1 {print $6}' | xargs -I {} find {} -xdev -type f -perm -0002 2>/dev/null | head -10)
    if [ -z "$ww_files" ]; then
        log_pass "没有发现全局可写文件 (符合要求)"
    else
        log_warn "发现全局可写文件: $ww_files"
    fi
}

check_suid_files() {
    log_info "检查 16: SUID 文件检查"
    
    local suid_count=$(df --local | awk 'NR>1 {print $6}' | xargs -I {} find {} -xdev -type f -perm -4000 2>/dev/null | wc -l)
    if [ "$suid_count" -lt 20 ]; then
        log_pass "SUID 文件数量为 $suid_count (正常)"
    else
        log_warn "SUID 文件数量为 $suid_count (可能过多)"
    fi
}

check_netrc_files() {
    log_info "检查 17: .netrc 文件检查"
    
    local netrc_files=$(find /home -name ".netrc" -type f 2>/dev/null | head -10)
    if [ -z "$netrc_files" ]; then
        log_pass "没有发现 .netrc 文件 (符合要求)"
    else
        log_warn "发现 .netrc 文件: $netrc_files (建议删除密码)"
    fi
}

check_rhost_files() {
    log_info "检查 18: .rhost 文件检查"
    
    local rhost_files=$(find /home -name ".rhosts" -type f 2>/dev/null)
    if [ -z "$rhost_files" ]; then
        log_pass "没有发现 .rhosts 文件 (符合要求)"
    else
        log_fail "发现 .rhosts 文件: $rhost_files (应删除)"
    fi
}

check_tmp_partition() {
    log_info "检查 19: /tmp 分区配置"
    
    local tmp_opts=$(mount | grep " /tmp " | grep -o "nosuid\|noexec\|nodev")
    if [ -n "$tmp_opts" ]; then
        log_pass "/tmp 分区已配置安全选项: $tmp_opts (符合要求)"
    else
        log_warn "/tmp 分区未配置安全选项 (建议添加 nosuid,noexec,nodev)"
    fi
}

check_log_permissions() {
    log_info "检查 20: 日志文件权限"
    
    local log_dir="/var/log"
    if [ -d "$log_dir" ]; then
        local perm=$(stat -c %a "$log_dir")
        if [ "$perm" = "755" ] || [ "$perm" = "750" ]; then
            log_pass "/var/log 权限为 $perm (符合要求)"
        else
            log_warn "/var/log 权限为 $perm (应检查)"
        fi
    fi
}

check_host_conf() {
    log_info "检查 21: hosts.allow 和 hosts.deny 配置"
    
    if [ -f /etc/hosts.allow ]; then
        log_pass "/etc/hosts.allow 存在 (符合要求)"
    else
        log_warn "/etc/hosts.allow 不存在 (建议创建)"
    fi
    
    if [ -f /etc/hosts.deny ]; then
        log_pass "/etc/hosts.deny 存在 (符合要求)"
    else
        log_warn "/etc/hosts.deny 不存在 (建议创建)"
    fi
}

show_summary() {
    echo ""
    echo "========================================"
    echo "检查完成"
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
    
    if [ "$fail_count" -gt 0 ]; then
        echo -e "${RED}发现 $fail_count 项安全问题，请及时修复${NC}"
    fi
    
    if [ "$warn_count" -gt 0 ]; then
        echo -e "${YELLOW}发现 $warn_count 项安全警告，建议关注${NC}"
    fi
    
    if [ "$fail_count" -eq 0 ] && [ "$warn_count" -eq 0 ]; then
        echo -e "${GREEN}恭喜！未发现安全问题${NC}"
    fi
}

main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}操作系统安全基线检查${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    init_report
    
    check_passwd_file
    check_shadow_file
    check_group_file
    check_root_uid
    check_duplicate_uid
    check_empty_password
    check_password_policy
    check_sudo_config
    check_ssh_config
    check_cron_access
    check_sysctl_config
    check_unused_services
    check_firewall
    check_audit_service
    check_world_writable
    check_suid_files
    check_netrc_files
    check_rhost_files
    check_tmp_partition
    check_log_permissions
    check_host_conf
    
    show_summary
}

main
