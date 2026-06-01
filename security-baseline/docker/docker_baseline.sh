#!/bin/bash

# =========================================
# Docker 安全基线检查脚本
# 基于 CIS Docker Benchmark
# =========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPORT_FILE="docker_security_report_$(date +%Y%m%d_%H%M%S).txt"

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
    echo "Docker 安全基线检查报告 (CIS Docker Benchmark)" >> "$REPORT_FILE"
    echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT_FILE"
    echo "Docker 版本: $(docker --version 2>/dev/null)" >> "$REPORT_FILE"
    echo "========================================" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

check_docker_installed() {
    log_info "检查 1: Docker 安装检查"
    
    if command -v docker &>/dev/null; then
        log_pass "Docker 已安装"
        return 0
    else
        log_fail "Docker 未安装"
        return 1
    fi
}

check_docker_service() {
    log_info "检查 2: Docker 服务状态"
    
    if systemctl is-active --quiet docker 2>/dev/null; then
        log_pass "Docker 服务正在运行 (符合要求)"
    else
        log_fail "Docker 服务未运行 (应启动)"
    fi
}

check_docker_socket() {
    log_info "检查 3: Docker Socket 权限"
    
    if [ -S /var/run/docker.sock ]; then
        local perm=$(stat -c %a /var/run/docker.sock)
        local owner=$(stat -c %U /var/run/docker.sock)
        
        if [ "$perm" = "660" ] || [ "$perm" = "640" ]; then
            log_pass "Docker Socket 权限为 $perm (符合要求)"
        else
            log_fail "Docker Socket 权限为 $perm (应为 660 或 640)"
        fi
        
        if [ "$owner" = "root" ]; then
            log_pass "Docker Socket 所有者为 root (符合要求)"
        else
            log_warn "Docker Socket 所有者为 $owner (建议为 root)"
        fi
    else
        log_fail "Docker Socket 不存在"
    fi
}

check_daemon_json() {
    log_info "检查 4: Docker daemon.json 配置"
    
    if [ -f /etc/docker/daemon.json ]; then
        log_pass "/etc/docker/daemon.json 存在 (符合要求)"
        
        if grep -q "\"icc\": false" /etc/docker/daemon.json; then
            log_pass "容器间通信已禁用 (符合要求)"
        else
            log_warn "容器间通信未禁用 (建议设置 icc: false)"
        fi
        
        if grep -q "\"userns-remap\":" /etc/docker/daemon.json; then
            log_pass "用户命名空间重映射已配置 (符合要求)"
        else
            log_warn "用户命名空间重映射未配置 (建议启用)"
        fi
        
        if grep -q "\"log-driver\":" /etc/docker/daemon.json; then
            log_pass "日志驱动已配置 (符合要求)"
        else
            log_warn "日志驱动未配置 (建议配置)"
        fi
        
        if grep -q "\"live-restore\": true" /etc/docker/daemon.json; then
            log_pass "实时恢复已启用 (符合要求)"
        else
            log_warn "实时恢复未启用 (建议启用)"
        fi
    else
        log_warn "/etc/docker/daemon.json 不存在 (建议创建)"
    fi
}

check_container_user() {
    log_info "检查 5: 容器用户检查"
    
    local privileged=$(docker ps --format '{{.Names}}' --filter "status=running" --exec-uglify 2>/dev/null | while read container; do
        docker inspect --format '{{.HostConfig.Privileged}}' "$container" 2>/dev/null
    done | grep -c "true" || echo "0")
    
    if [ "$privileged" -eq 0 ]; then
        log_pass "没有特权容器运行 (符合要求)"
    else
        log_fail "发现 $privileged 个特权容器 (应避免使用)"
    fi
    
    local cap_add=$(docker ps --format '{{.Names}}' --filter "status=running" 2>/dev/null | while read container; do
        docker inspect --format '{{.HostConfig.CapAdd}}' "$container" 2>/dev/null
    done | grep -v "\[" | grep -v "^$" | wc -l)
    
    if [ "$cap_add" -eq 0 ]; then
        log_pass "没有容器添加额外 capabilities (符合要求)"
    else
        log_warn "发现 $cap_add 个容器添加了额外 capabilities (建议检查)"
    fi
}

check_container_network() {
    log_info "检查 6: 容器网络配置"
    
    local host_net=$(docker ps --format '{{.Names}}' --filter "status=running" --network host 2>/dev/null | wc -l)
    
    if [ "$host_net" -eq 0 ]; then
        log_pass "没有容器使用 host 网络模式 (符合要求)"
    else
        log_warn "发现 $host_net 个容器使用 host 网络模式 (建议避免)"
    fi
}

check_container_ports() {
    log_info "检查 7: 容器端口映射"
    
    local exposed_ports=$(docker ps --format '{{.Ports}}' --filter "status=running" 2>/dev/null | grep -v "^$" | wc -l)
    
    if [ "$exposed_ports" -gt 0 ]; then
        log_warn "发现 $exposed_ports 个容器暴露端口 (请确认必要性)"
    else
        log_pass "没有容器暴露端口 (符合要求)"
    fi
}

check_rootless() {
    log_info "检查 8: Rootless 模式"
    
    if grep -q "rootless" /etc/docker/daemon.json 2>/dev/null; then
        log_pass "Docker 使用 rootless 模式 (符合要求)"
    else
        log_warn "Docker 未使用 rootless 模式 (建议启用)"
    fi
}

check_content_trust() {
    log_info "检查 9: Docker Content Trust"
    
    if [ "${DOCKER_CONTENT_TRUST:-0}" = "1" ]; then
        log_pass "Docker Content Trust 已启用 (符合要求)"
    else
        log_warn "Docker Content Trust 未启用 (建议启用)"
    fi
}

check_registry() {
    log_info "检查 10: 镜像仓库配置"
    
    if [ -f /etc/docker/daemon.json ]; then
        local registries=$(grep -o '"registry-mirrors"' /etc/docker/daemon.json)
        if [ -n "$registries" ]; then
            log_pass "镜像加速器已配置 (符合要求)"
        else
            log_warn "镜像加速器未配置 (建议配置)"
        fi
    fi
}

check_log_files() {
    log_info "检查 11: Docker 日志文件大小"
    
    if [ -f /etc/docker/daemon.json ]; then
        if grep -q '"log-opts"' /etc/docker/daemon.json; then
            local max_size=$(grep "max-size" /etc/docker/daemon.json | grep -o '[0-9]*m' | head -1)
            local max_file=$(grep "max-file" /etc/docker/daemon.json | grep -o '[0-9]*' | head -1)
            
            if [ -n "$max_size" ]; then
                log_pass "日志文件大小限制为 $max_size (符合要求)"
            else
                log_warn "日志文件大小未限制 (建议设置)"
            fi
            
            if [ -n "$max_file" ]; then
                log_pass "日志文件数量限制为 $max_file (符合要求)"
            else
                log_warn "日志文件数量未限制 (建议设置)"
            fi
        else
            log_warn "日志选项未配置 (建议配置 log-opts)"
        fi
    fi
}

check_aufs() {
    log_info "检查 12: 存储驱动"
    
    local storage_driver=$(docker info --format '{{.Driver}}' 2>/dev/null)
    
    case "$storage_driver" in
        overlay2)
            log_pass "使用 overlay2 存储驱动 (符合要求)"
            ;;
        devicemapper)
            log_warn "使用 devicemapper 存储驱动 (建议使用 overlay2)"
            ;;
        aufs)
            log_fail "使用 aufs 存储驱动 (应使用 overlay2)"
            ;;
        *)
            log_warn "使用 $storage_driver 存储驱动"
            ;;
    esac
}

check_cgroup() {
    log_info "检查 13: Cgroup 版本"
    
    if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
        log_pass "使用 cgroup v2 (符合要求)"
    else
        log_warn "使用 cgroup v1 (建议迁移到 v2)"
    fi
}

check_ulimits() {
    log_info "检查 14: 默认 ulimits"
    
    if [ -f /etc/docker/daemon.json ]; then
        if grep -q '"default-ulimit"' /etc/docker/daemon.json; then
            log_pass "默认 ulimits 已配置 (符合要求)"
        else
            log_warn "默认 ulimits 未配置 (建议配置)"
        fi
    fi
}

check_distroless() {
    log_info "检查 15: Distroless 镜像使用"
    
    local distroless_count=$(docker images --format '{{.Repository}}' 2>/dev/null | grep -c "distroless\|scratch" || echo "0")
    
    if [ "$distroless_count" -gt 0 ]; then
        log_pass "使用 $distroless_count 个 Distroless 镜像 (符合要求)"
    else
        log_warn "未使用 Distroless 镜像 (建议使用 scratch 或 distroless)"
    fi
}

check_security_options() {
    log_info "检查 16: 容器安全选项"
    
    local no_seccomp=$(docker ps --format '{{.Names}}' --filter "status=running" 2>/dev/null | while read container; do
        docker inspect --format '{{.HostConfig.SecurityOpt}}' "$container" 2>/dev/null
    done | grep -c "seccomp=unconfined" || echo "0")
    
    if [ "$no_seccomp" -eq 0 ]; then
        log_pass "没有容器禁用 seccomp (符合要求)"
    else
        log_warn "发现 $no_seccomp 个容器禁用 seccomp (建议启用)"
    fi
    
    local no_apparmor=$(docker ps --format '{{.Names}}' --filter "status=running" 2>/dev/null | while read container; do
        docker inspect --format '{{.HostConfig.AppArmorProfile}}' "$container" 2>/dev/null
    done | grep -c "<no value>" || echo "0")
    
    if [ "$no_apparmor" -eq 0 ]; then
        log_pass "所有容器都有 AppArmor 配置 (符合要求)"
    else
        log_warn "发现 $no_apparmor 个容器没有 AppArmor 配置"
    fi
}

show_summary() {
    echo ""
    echo "========================================"
    echo "Docker 安全检查完成"
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
}

main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Docker 安全基线检查 (CIS Docker Benchmark)${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    init_report
    
    if ! check_docker_installed; then
        exit 1
    fi
    
    check_docker_service
    check_docker_socket
    check_daemon_json
    check_container_user
    check_container_network
    check_container_ports
    check_rootless
    check_content_trust
    check_registry
    check_log_files
    check_aufs
    check_cgroup
    check_ulimits
    check_distroless
    check_security_options
    
    show_summary
}

main
