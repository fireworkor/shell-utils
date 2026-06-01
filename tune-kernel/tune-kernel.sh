#!/bin/bash
# 描述：内核调优

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

tune_kernel() {
    check_root
    check_os
    
    local mem_gb=$(free -g | awk 'NR==2 {print $2}')
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   内核调优（检测到内存: ${mem_gb}GB）${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    local profile=""
    if [ $mem_gb -lt 2 ]; then
        profile="small"
        tcp_mem_max="786432 1048576 1572864"
        tcp_rmem_max="4096 87380 4194304"
        tcp_wmem_max="4096 65536 4194304"
        file_max="65536"
        nofile_limit="65536"
    elif [ $mem_gb -lt 8 ]; then
        profile="medium"
        tcp_mem_max="3145728 4194304 6291456"
        tcp_rmem_max="4096 87380 67108864"
        tcp_wmem_max="4096 65536 67108864"
        file_max="4194304"
        nofile_limit="262144"
    else
        profile="large"
        tcp_mem_max="12582912 16777216 25165824"
        tcp_rmem_max="4096 87380 268435456"
        tcp_wmem_max="4096 65536 268435456"
        file_max="8388608"
        nofile_limit="524288"
    fi
    
    echo -e "${YELLOW}应用配置方案: ${profile}${NC}"
    
    cat > /etc/sysctl.d/99-tuning.conf << EOF
# 内核调优配置 - $profile 方案
# 内存: ${mem_gb}GB

net.core.rmem_max = $tcp_rmem_max
net.core.wmem_max = $tcp_wmem_max
net.ipv4.tcp_rmem = $tcp_rmem_max
net.ipv4.tcp_wmem = $tcp_wmem_max
net.ipv4.tcp_mem = $tcp_mem_max
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_tw_buckets = 262144
net.ipv4.ip_local_port_range = 10240 65535
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 8192
net.ipv4.tcp_max_syn_backlog = 8192

fs.file-max = $file_max
fs.inotify.max_user_watches = 524288
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 5
vm.overcommit_memory = 1
vm.max_map_count = 262144

kernel.shmmax = $((mem_gb * 1024 * 1024 * 1024 / 4))
kernel.shmall = $((mem_gb * 1024 * 1024 * 1024 / 4096))
kernel.sem = 250 64000 100 512
kernel.pid_max = 65536
EOF
    
    sysctl -p /etc/sysctl.d/99-tuning.conf > /dev/null 2>&1 || true
    
    cat > /etc/security/limits.d/99-tuning.conf << EOF
* soft nofile $nofile_limit
* hard nofile $nofile_limit
* soft nproc 65536
* hard nproc 65536
root soft nofile $nofile_limit
root hard nofile $nofile_limit
EOF
    
    ulimit -n $nofile_limit 2>/dev/null || true
    
    print_success "内核调优完成"
    echo ""
    echo -e "${YELLOW}建议重启系统使配置完全生效: reboot${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tune_kernel
fi
