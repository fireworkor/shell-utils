#!/bin/bash

# =========================================
# 网络安全基线检查脚本
# 检查项：端口、协议、服务、防火墙等
# =========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPORT_FILE="network_security_report_$(date +%Y%m%d_%H%M%S).txt"

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
    echo "网络安全基线检查报告" >> "$REPORT_FILE"
    echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT_FILE"
    echo "主机名: $(hostname)" >> "$REPORT_FILE"
    echo "========================================" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

check_open_ports() {
    log_info "检查 1: 开放端口扫描"
    
    local open_ports=$(ss -tuln 2>/dev/null | grep -v "State" | awk '{print $5}' | grep -oP ':\K\d+$' | sort -n | uniq)
    
    if [ -z "$open_ports" ]; then
        log_warn "无法获取开放端口信息"
        return
    fi
    
    log_info "开放端口列表: $open_ports"
    
    local port_count=$(echo "$open_ports" | wc -l)
    log_info "总共开放 $port_count 个端口"
    
    if [ "$port_count" -lt 20 ]; then
        log_pass "开放端口数量正常: $port_count (符合要求)"
    else
        log_warn "开放端口数量较多: $port_count (建议检查)"
    fi
}

check_dangerous_ports() {
    log_info "检查 2: 危险端口检查"
    
    local dangerous_ports=(
        "21:FTP"
        "23:Telnet"
        "69:TFTP"
        "135:MSRPC"
        "139:NetBIOS"
        "445:SMB"
        "512:rexec"
        "513:rlogin"
        "514:rsh"
        "515:LPD"
        "1080:SOCKS"
        "1433:MSSQL"
        "1521:Oracle"
        "2049:NFS"
        "3306:MySQL"
        "3389:RDP"
        "5432:PostgreSQL"
        "5900:VNC"
        "6379:Redis"
        "27017:MongoDB"
    )
    
    local found_dangerous=false
    
    for entry in "${dangerous_ports[@]}"; do
        IFS=':' read -r port service <<< "$entry"
        
        if ss -tuln 2>/dev/null | grep -q ":$port "; then
            log_warn "发现 $service 端口 ($port) 开放 (建议确认业务需求)"
            found_dangerous=true
        fi
    done
    
    if [ "$found_dangerous" = false ]; then
        log_pass "未发现危险端口开放 (符合要求)"
    fi
}

check_firewall_rules() {
    log_info "检查 3: 防火墙规则"
    
    if command -v firewall-cmd &>/dev/null; then
        log_info "使用 firewalld"
        local rules=$(firewall-cmd --list-all 2>/dev/null)
        if [ -n "$rules" ]; then
            log_pass "firewalld 规则已配置"
            log_info "规则详情: $rules"
        else
            log_warn "firewalld 规则为空"
        fi
    elif command -v ufw &>/dev/null; then
        log_info "使用 ufw"
        local status=$(ufw status 2>/dev/null | head -1)
        if echo "$status" | grep -q "active"; then
            log_pass "ufw 防火墙已启用 (符合要求)"
        else
            log_warn "ufw 防火墙未启用 (建议启用)"
        fi
    elif [ -f /etc/iptables/rules.v4 ]; then
        log_info "使用 iptables"
        local rules_count=$(iptables -L -n 2>/dev/null | grep -c "Chain" || echo 0)
        log_pass "iptables 规则已配置 ($rules_count 条规则)"
    else
        log_warn "未检测到活动的防火墙"
    fi
}

check_network_interface() {
    log_info "检查 4: 网络接口配置"
    
    local interfaces=$(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep -v "^lo$")
    
    if [ -z "$interfaces" ]; then
        log_warn "无法获取网络接口信息"
        return
    fi
    
    log_info "活动网络接口: $interfaces"
    
    local public_iface=false
    for iface in $interfaces; do
        local flags=$(ip link show "$iface" 2>/dev/null)
        
        if echo "$flags" | grep -q "state UP"; then
            log_info "接口 $iface 状态: UP"
            
            local addr=$(ip addr show "$iface" 2>/dev/null | grep "inet " | awk '{print $2}')
            if [ -n "$addr" ]; then
                log_info "接口 $iface 地址: $addr"
                
                if echo "$addr" | grep -q "^10\." || echo "$addr" | grep -q "^172\." || echo "$addr" | grep -q "^192\.168\."; then
                    log_pass "接口 $iface 使用私有地址"
                fi
            fi
        fi
    done
}

check_promisc_mode() {
    log_info "检查 5: 网卡混杂模式"
    
    local promisc_ifaces=$(ip link show 2>/dev/null | grep -c "PROMISC" || echo 0)
    
    if [ "$promisc_ifaces" -eq 0 ]; then
        log_pass "没有网卡处于混杂模式 (符合要求)"
    else
        log_warn "发现 $promisc_ifaces 个网卡处于混杂模式 (建议检查)"
    fi
}

check_syn_cookies() {
    log_info "检查 6: SYN Cookies 配置"
    
    if sysctl net.ipv4.tcp_syncookies 2>/dev/null | grep -q "= 1"; then
        log_pass "SYN Cookies 已启用 (符合要求)"
    else
        log_fail "SYN Cookies 未启用 (应启用)"
    fi
}

check_ip_forwarding() {
    log_info "检查 7: IP 转发配置"
    
    if sysctl net.ipv4.ip_forward 2>/dev/null | grep -q "= 0"; then
        log_pass "IP 转发已禁用 (符合要求)"
    else
        log_warn "IP 转发未禁用 (如非路由需求建议禁用)"
    fi
}

check_source_route() {
    log_info "检查 8: 源路由配置"
    
    if sysctl net.ipv4.conf.all.accept_source_route 2>/dev/null | grep -q "= 0"; then
        log_pass "IPv4 源路由已禁用 (符合要求)"
    else
        log_fail "IPv4 源路由未禁用 (应禁用)"
    fi
    
    if sysctl net.ipv6.conf.all.accept_source_route 2>/dev/null | grep -q "= 0"; then
        log_pass "IPv6 源路由已禁用 (符合要求)"
    else
        log_fail "IPv6 源路由未禁用 (应禁用)"
    fi
}

check_icmp_broadcasts() {
    log_info "检查 9: ICMP 广播配置"
    
    if sysctl net.ipv4.icmp_echo_ignore_broadcasts 2>/dev/null | grep -q "= 1"; then
        log_pass "ICMP 广播已忽略 (符合要求)"
    else
        log_fail "ICMP 广播未忽略 (应启用)"
    fi
}

check_icmp_redirects() {
    log_info "检查 10: ICMP 重定向配置"
    
    if sysctl net.ipv4.conf.all.accept_redirects 2>/dev/null | grep -q "= 0"; then
        log_pass "ICMP 重定向已禁用 (符合要求)"
    else
        log_fail "ICMP 重定向未禁用 (应禁用)"
    fi
    
    if sysctl net.ipv4.conf.all.secure_redirects 2>/dev/null | grep -q "= 0"; then
        log_pass "安全重定向已禁用 (符合要求)"
    else
        log_fail "安全重定向未禁用 (应禁用)"
    fi
}

check_rp_filter() {
    log_info "检查 11: 反向路径过滤"
    
    if sysctl net.ipv4.conf.all.rp_filter 2>/dev/null | grep -q "= 1"; then
        log_pass "反向路径过滤已启用 (符合要求)"
    else
        log_warn "反向路径过滤未完全启用 (建议设置为 1)"
    fi
}

check_tcp_timestamps() {
    log_info "检查 12: TCP 时间戳"
    
    if sysctl net.ipv4.tcp_timestamps 2>/dev/null | grep -q "= 0"; then
        log_pass "TCP 时间戳已禁用 (符合要求)"
    else
        log_warn "TCP 时间戳未禁用 (建议禁用以减少信息泄露)"
    fi
}

check_tcp_syncookies() {
    log_info "检查 13: TCP SYN Cookie"
    
    if sysctl net.ipv4.tcp_syncookies 2>/dev/null | grep -q "= 1"; then
        log_pass "TCP SYN Cookie 已启用 (符合要求)"
    else
        log_fail "TCP SYN Cookie 未启用 (应启用防止 SYN 洪水攻击)"
    fi
}

check_ip_spoofing() {
    log_info "检查 14: IP 欺骗防护"
    
    if [ -f /etc/host.conf ]; then
        local nospoof=$(grep "nospoof" /etc/host.conf 2>/dev/null)
        if [ -n "$nospoof" ]; then
            log_pass "IP 欺骗防护已启用 (符合要求)"
        else
            log_warn "IP 欺骗防护未启用 (建议在 /etc/host.conf 添加 nospoof on)"
        fi
    else
        log_warn "/etc/host.conf 不存在 (建议创建并添加 nospoof on)"
    fi
}

check_dns_config() {
    log_info "检查 15: DNS 配置"
    
    if [ -f /etc/resolv.conf ]; then
        local nameservers=$(grep "^nameserver" /etc/resolv.conf | awk '{print $2}')
        if [ -n "$nameservers" ]; then
            log_pass "DNS 服务器已配置: $nameservers"
            
            local ns_count=$(echo "$nameservers" | wc -l)
            if [ "$ns_count" -ge 2 ]; then
                log_pass "配置了 $ns_count 个 DNS 服务器 (符合要求)"
            else
                log_warn "只配置了 $ns_count 个 DNS 服务器 (建议至少配置 2 个)"
            fi
        fi
    fi
    
    if [ -f /etc/nsswitch.conf ]; then
        local hosts_line=$(grep "^hosts:" /etc/nsswitch.conf)
        if echo "$hosts_line" | grep -q "dns"; then
            log_pass "DNS 解析已配置"
        else
            log_warn "DNS 解析未在 nsswitch.conf 中配置"
        fi
    fi
}

check_arp_garp() {
    log_info "检查 16: ARP GARP 防护"
    
    if sysctl net.ipv4.conf.all.arp_announce 2>/dev/null | grep -q "= 2"; then
        log_pass "ARP 公告已限制 (符合要求)"
    else
        log_warn "ARP 公告未限制 (建议设置为 2)"
    fi
    
    if sysctl net.ipv4.conf.all.arp_ignore 2>/dev/null | grep -q "= 1"; then
        log_pass "ARP 忽略已配置 (符合要求)"
    else
        log_warn "ARP 忽略未配置 (建议设置为 1)"
    fi
}

check_network_utils() {
    log_info "检查 17: 网络工具检查"
    
    local dangerous_tools=("nc" "netcat" "ncat" "socat")
    
    for tool in "${dangerous_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            log_warn "发现网络工具: $tool (建议确认是否必需)"
        fi
    done
}

check_listening_services() {
    log_info "检查 18: 监听服务统计"
    
    local tcp_listening=$(ss -tln 2>/dev/null | grep -v "State" | wc -l)
    local udp_listening=$(ss -uln 2>/dev/null | grep -v "State" | wc -l)
    
    log_info "TCP 监听: $tcp_listening"
    log_info "UDP 监听: $udp_listening"
    
    if [ "$tcp_listening" -lt 30 ]; then
        log_pass "TCP 监听服务数量正常: $tcp_listening"
    else
        log_warn "TCP 监听服务数量较多: $tcp_listening (建议检查)"
    fi
}

show_summary() {
    echo ""
    echo "========================================"
    echo "网络安全检查完成"
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
        echo -e "${RED}发现 $fail_count 项网络安全问题，请及时修复${NC}"
    fi
    
    if [ "$warn_count" -gt 0 ]; then
        echo -e "${YELLOW}发现 $warn_count 项安全警告，建议关注${NC}"
    fi
}

main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}网络安全基线检查${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    init_report
    
    check_open_ports
    check_dangerous_ports
    check_firewall_rules
    check_network_interface
    check_promisc_mode
    check_syn_cookies
    check_ip_forwarding
    check_source_route
    check_icmp_broadcasts
    check_icmp_redirects
    check_rp_filter
    check_tcp_timestamps
    check_tcp_syncookies
    check_ip_spoofing
    check_dns_config
    check_arp_garp
    check_network_utils
    check_listening_services
    
    show_summary
}

main
