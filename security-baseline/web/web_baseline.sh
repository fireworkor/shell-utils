#!/bin/bash

# =========================================
# Web 服务器安全基线检查脚本
# 支持: Nginx, Apache
# =========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

WEB_TYPE="${1:-all}"
REPORT_FILE="web_security_report_$(date +%Y%m%d_%H%M%S).txt"

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
    echo "Web 服务器安全基线检查报告" >> "$REPORT_FILE"
    echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT_FILE"
    echo "检查类型: $WEB_TYPE" >> "$REPORT_FILE"
    echo "========================================" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

check_nginx() {
    echo -e "${BLUE}========== Nginx 安全检查 ==========${NC}" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
    
    if ! command -v nginx &>/dev/null; then
        log_warn "Nginx 未安装"
        return
    fi
    
    log_info "Nginx 版本: $(nginx -v 2>&1)"
    
    local nginx_conf
    if [ -f /etc/nginx/nginx.conf ]; then
        nginx_conf="/etc/nginx/nginx.conf"
    elif [ -f /etc/nginx/conf/nginx.conf ]; then
        nginx_conf="/etc/nginx/conf/nginx.conf"
    fi
    
    if [ -n "$nginx_conf" ]; then
        log_info "Nginx 配置文件: $nginx_conf"
        
        log_info "检查 1: Nginx 版本隐藏"
        local server_tokens=$(grep -r "server_tokens" "$nginx_conf" 2>/dev/null | head -1)
        if echo "$server_tokens" | grep -q "off\|none"; then
            log_pass "Nginx 版本已隐藏 (符合要求)"
        else
            log_warn "Nginx 版本信息可能泄露 (建议设置 server_tokens off)"
        fi
        
        log_info "检查 2: X-Frame-Options 头"
        local x_frame=$(grep -r "X-Frame-Options" "$nginx_conf" 2>/dev/null)
        if [ -n "$x_frame" ]; then
            log_pass "X-Frame-Options 已配置 (符合要求)"
        else
            log_warn "X-Frame-Options 未配置 (建议添加)"
        fi
        
        log_info "检查 3: X-Content-Type-Options 头"
        local x_content=$(grep -r "X-Content-Type-Options" "$nginx_conf" 2>/dev/null)
        if [ -n "$x_content" ]; then
            log_pass "X-Content-Type-Options 已配置 (符合要求)"
        else
            log_warn "X-Content-Type-Options 未配置 (建议添加)"
        fi
        
        log_info "检查 4: X-XSS-Protection 头"
        local x_xss=$(grep -r "X-XSS-Protection" "$nginx_conf" 2>/dev/null)
        if [ -n "$x_xss" ]; then
            log_pass "X-XSS-Protection 已配置 (符合要求)"
        else
            log_warn "X-XSS-Protection 未配置 (建议添加)"
        fi
        
        log_info "检查 5: Content-Security-Policy 头"
        local csp=$(grep -r "Content-Security-Policy" "$nginx_conf" 2>/dev/null)
        if [ -n "$csp" ]; then
            log_pass "Content-Security-Policy 已配置 (符合要求)"
        else
            log_warn "Content-Security-Policy 未配置 (建议添加)"
        fi
        
        log_info "检查 6: 目录浏览"
        local autoindex=$(grep -r "autoindex" "$nginx_conf" 2>/dev/null)
        if echo "$autoindex" | grep -q "off"; then
            log_pass "目录浏览已禁用 (符合要求)"
        elif echo "$autoindex" | grep -q "on"; then
            log_fail "目录浏览已启用 (应禁用)"
        fi
        
        log_info "检查 7: TRACE 方法"
        local trace_method=$(grep -r "trace" "$nginx_conf" 2>/dev/null)
        if [ -z "$trace_method" ]; then
            log_pass "TRACE 方法未明确允许 (符合要求)"
        else
            log_fail "TRACE 方法被允许 (应禁用)"
        fi
        
        log_info "检查 8: SSL/TLS 配置"
        local ssl_protocols=$(grep -r "ssl_protocols" "$nginx_conf" 2>/dev/null | head -1)
        if echo "$ssl_protocols" | grep -q "TLSv1.3\|TLSv1.2"; then
            if echo "$ssl_protocols" | grep -qv "TLSv1.0\|TLSv1.1"; then
                log_pass "SSL/TLS 协议配置安全 (符合要求)"
            else
                log_fail "SSL/TLS 使用了不安全的协议版本 (应禁用 TLSv1.0 和 TLSv1.1)"
            fi
        else
            log_warn "SSL/TLS 协议配置未明确"
        fi
        
        log_info "检查 9: SSL 证书权限"
        local ssl_cert=$(grep -r "ssl_certificate" "$nginx_conf" 2>/dev/null | head -1 | awk '{print $2}' | tr -d ';')
        if [ -n "$ssl_cert" ] && [ -f "$ssl_cert" ]; then
            local cert_perm=$(stat -c %a "$ssl_cert")
            if [ "$cert_perm" = "644" ] || [ "$cert_perm" = "600" ]; then
                log_pass "SSL 证书权限为 $cert_perm (符合要求)"
            else
                log_warn "SSL 证书权限为 $cert_perm (建议设为 600)"
            fi
        fi
        
        log_info "检查 10: worker_processes"
        local worker_proc=$(grep -r "^worker_processes" "$nginx_conf" 2>/dev/null | head -1)
        if echo "$worker_proc" | grep -q "auto"; then
            log_pass "worker_processes 设置为 auto (符合要求)"
        else
            log_warn "worker_processes 未设置为 auto"
        fi
        
        log_info "检查 11: 连接数限制"
        local worker_conn=$(grep -r "worker_connections" "$nginx_conf" 2>/dev/null | head -1 | awk '{print $2}' | tr -d ';')
        if [ -n "$worker_conn" ] && [ "$worker_conn" -gt 1024 ]; then
            log_pass "worker_connections 设置为 $worker_conn (符合要求)"
        else
            log_warn "worker_connections 可能设置过低"
        fi
    else
        log_warn "未找到 Nginx 配置文件"
    fi
}

check_apache() {
    echo -e "${BLUE}========== Apache 安全检查 ==========${NC}" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
    
    if ! command -v apache2 &>/dev/null && ! command -v httpd &>/dev/null; then
        log_warn "Apache 未安装"
        return
    fi
    
    local apache_cmd
    if command -v apache2 &>/dev/null; then
        apache_cmd="apache2"
        log_info "Apache 版本: $(apache2 -v 2>&1 | head -1)"
    else
        apache_cmd="httpd"
        log_info "Apache 版本: $(httpd -v 2>&1 | head -1)"
    fi
    
    local apache_conf
    if [ -f /etc/apache2/apache2.conf ]; then
        apache_conf="/etc/apache2/apache2.conf"
    elif [ -f /etc/httpd/conf/httpd.conf ]; then
        apache_conf="/etc/httpd/conf/httpd.conf"
    fi
    
    if [ -n "$apache_conf" ]; then
        log_info "Apache 配置文件: $apache_conf"
        
        log_info "检查 1: ServerTokens"
        local server_tokens=$(grep -i "ServerTokens" "$apache_conf" 2>/dev/null | grep -v "^#")
        if echo "$server_tokens" | grep -qi "Prod"; then
            log_pass "ServerTokens 设置为 Prod (符合要求)"
        else
            log_fail "ServerTokens 未设置为 Prod (应设置为 Prod)"
        fi
        
        log_info "检查 2: ServerSignature"
        local server_sig=$(grep -i "ServerSignature" "$apache_conf" 2>/dev/null | grep -v "^#")
        if echo "$server_sig" | grep -qi "Off\|False"; then
            log_pass "ServerSignature 已关闭 (符合要求)"
        else
            log_fail "ServerSignature 未关闭 (应设置为 Off)"
        fi
        
        log_info "检查 3: TraceEnable"
        local trace_enable=$(grep -i "TraceEnable" "$apache_conf" 2>/dev/null | grep -v "^#")
        if echo "$trace_enable" | grep -qi "Off"; then
            log_pass "TRACE 已禁用 (符合要求)"
        else
            log_fail "TRACE 未禁用 (应设置为 Off)"
        fi
        
        log_info "检查 4: 目录浏览"
        local options_indexes=$(grep -r "Options.*Indexes" "$apache_conf" 2>/dev/null | grep -v "^#")
        if [ -z "$options_indexes" ]; then
            log_pass "目录浏览未启用 (符合要求)"
        else
            log_fail "目录浏览已启用 (应移除 Indexes)"
        fi
        
        log_info "检查 5: .htaccess 支持"
        local allow_override=$(grep -ri "AllowOverride" "$apache_conf" 2>/dev/null | grep -v "^#" | head -5)
        if echo "$allow_override" | grep -q "None"; then
            log_pass "AllowOverride 设置为 None (符合要求)"
        else
            log_warn "AllowOverride 未设置为 None"
        fi
        
        log_info "检查 6: SSL 协议"
        local ssl_protocol=$(grep -ri "SSLProtocol" "$apache_conf" 2>/dev/null | grep -v "^#" | head -1)
        if echo "$ssl_protocol" | grep -q "TLSv1.2\|TLSv1.3"; then
            if echo "$ssl_protocol" | grep -qv "SSLv2\|SSLv3\|TLSv1.0\|TLSv1.1"; then
                log_pass "SSL 协议配置安全 (符合要求)"
            else
                log_fail "SSL 使用了不安全的协议版本"
            fi
        fi
        
        log_info "检查 7: X-Frame-Options"
        local x_frame=$(grep -ri "X-Frame-Options" "$apache_conf" 2>/dev/null)
        if [ -n "$x_frame" ]; then
            log_pass "X-Frame-Options 已配置 (符合要求)"
        else
            log_warn "X-Frame-Options 未配置 (建议添加)"
        fi
        
        log_info "检查 8: X-Content-Type-Options"
        local x_content=$(grep -ri "X-Content-Type-Options" "$apache_conf" 2>/dev/null)
        if [ -n "$x_content" ]; then
            log_pass "X-Content-Type-Options 已配置 (符合要求)"
        else
            log_warn "X-Content-Type-Options 未配置 (建议添加)"
        fi
        
        log_info "检查 9: X-XSS-Protection"
        local x_xss=$(grep -ri "X-XSS-Protection" "$apache_conf" 2>/dev/null)
        if [ -n "$x_xss" ]; then
            log_pass "X-XSS-Protection 已配置 (符合要求)"
        else
            log_warn "X-XSS-Protection 未配置 (建议添加)"
        fi
        
        log_info "检查 10: 默认账户"
        local user=$(grep -i "^User" "$apache_conf" 2>/dev/null | grep -v "^#" | awk '{print $2}')
        local group=$(grep -i "^Group" "$apache_conf" 2>/dev/null | grep -v "^#" | awk '{print $2}')
        if [ "$user" != "root" ] && [ "$group" != "root" ]; then
            log_pass "Apache 不以 root 运行 (符合要求)"
        else
            log_fail "Apache 以 root 运行 (应创建专用用户)"
        fi
    else
        log_warn "未找到 Apache 配置文件"
    fi
}

show_summary() {
    echo ""
    echo "========================================"
    echo "Web 服务器安全检查完成"
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
    echo -e "${BLUE}Web 服务器安全基线检查${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    init_report
    
    case "$WEB_TYPE" in
        nginx)
            check_nginx
            ;;
        apache)
            check_apache
            ;;
        all)
            check_nginx
            echo ""
            check_apache
            ;;
        *)
            echo "用法: $0 [nginx|apache|all]"
            exit 1
            ;;
    esac
    
    show_summary
}

main
