#!/bin/bash

# =========================================
# CentOS 8 内核调优脚本
# 根据内存大小自动优化内核参数
# 
# 使用方法：
#   curl ... | sudo bash -s -- tune_kernel
#   或
#   sudo ./tune-kernel.sh
# =========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 获取系统信息
get_system_info() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   CentOS 8 内核调优脚本${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${YELLOW}系统信息：${NC}"
    echo "  操作系统: $(cat /etc/centos-release | head -1)"
    echo "  内核版本: $(uname -r)"
    echo "  架构: $(uname -m)"
    echo "  运行时间: $(uptime -p)"
    echo ""
}

# 获取内存大小（单位：GB）
get_memory_gb() {
    local mem_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    local mem_gb=$((mem_kb / 1024 / 1024))
    echo $mem_gb
}

# 获取内存大小（单位：MB）
get_memory_mb() {
    local mem_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    local mem_mb=$((mem_kb / 1024))
    echo $mem_mb
}

# 根据内存大小确定配置类型
get_profile() {
    local mem_gb=$1
    
    if [ $mem_gb -lt 1 ]; then
        echo "tiny"
    elif [ $mem_gb -lt 2 ]; then
        echo "small"
    elif [ $mem_gb -lt 4 ]; then
        echo "medium"
    elif [ $mem_gb -lt 8 ]; then
        echo "large"
    elif [ $mem_gb -lt 16 ]; then
        echo "xlarge"
    elif [ $mem_gb -lt 32 ]; then
        echo "2xlarge"
    elif [ $mem_gb -lt 64 ]; then
        echo "4xlarge"
    else
        echo "8xlarge"
    fi
}

# 配置内核参数 - 小内存配置 ( < 2GB )
config_tiny() {
    echo -e "${YELLOW}应用小型服务器配置 (< 2GB)...${NC}"
    
    cat > /etc/sysctl.d/99-tuning.conf << 'EOF'
# CentOS 8 小型服务器内核调优配置
# 内存: < 2GB

# 网络参数
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_mem = 786432 1048576 1572864
net.ipv4.tcp_slow_start_after_idle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_tw_buckets = 262144
net.ipv4.ip_local_port_range = 10240 65535
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 1024

# 文件系统参数
fs.file-max = 65536
fs.inotify.max_user_watches = 524288
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 5
vm.overcommit_memory = 1
vm.max_map_count = 65530

# 内核参数
kernel.shmmax = 512000000
kernel.shmall = 2097152
kernel.sem = 250 32000 100 128
kernel.pid_max = 65536
EOF
}

# 配置内核参数 - 小型配置 ( 2-4GB )
config_small() {
    echo -e "${YELLOW}应用小型服务器配置 (2-4GB)...${NC}"
    
    cat > /etc/sysctl.d/99-tuning.conf << 'EOF'
# CentOS 8 小型服务器内核调优配置
# 内存: 2-4GB

# 网络参数
net.core.rmem_max = 4194304
net.core.wmem_max = 4194304
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 65536 4194304
net.ipv4.tcp_mem = 786432 1048576 1572864
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_tw_buckets = 262144
net.ipv4.ip_local_port_range = 10240 65535
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 2048
net.ipv4.tcp_max_syn_backlog = 2048

# 文件系统参数
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 5
vm.overcommit_memory = 1
vm.max_map_count = 65530

# 内核参数
kernel.shmmax = 2147483648
kernel.shmall = 2097152
kernel.sem = 250 32000 100 128
kernel.pid_max = 65536
EOF
}

# 配置内核参数 - 中型配置 ( 4-8GB )
config_medium() {
    echo -e "${YELLOW}应用中型服务器配置 (4-8GB)...${NC}"
    
    cat > /etc/sysctl.d/99-tuning.conf << 'EOF'
# CentOS 8 中型服务器内核调优配置
# 内存: 4-8GB

# 网络参数
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_mem = 1572864 2097152 3145728
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_tw_buckets = 262144
net.ipv4.ip_local_port_range = 10240 65535
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 4096
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 15

# 文件系统参数
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 5
vm.overcommit_memory = 1
vm.max_map_count = 262144

# 内核参数
kernel.shmmax = 4294967295
kernel.shmall = 2097152
kernel.sem = 250 64000 100 512
kernel.pid_max = 65536
EOF
}

# 配置内核参数 - 大型配置 ( 8-16GB )
config_large() {
    echo -e "${YELLOW}应用大型服务器配置 (8-16GB)...${NC}"
    
    cat > /etc/sysctl.d/99-tuning.conf << 'EOF'
# CentOS 8 大型服务器内核调优配置
# 内存: 8-16GB

# 网络参数
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mem = 3145728 4194304 6291456
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_max_orphans = 524288
net.ipv4.tcp_max_tw_buckets = 524288
net.ipv4.ip_local_port_range = 10240 65535
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 8192
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_sack = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1

# 文件系统参数
fs.file-max = 4194304
fs.inotify.max_user_watches = 524288
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 5
vm.overcommit_memory = 1
vm.max_map_count = 262144
vm.zone_reclaim_mode = 0
vm.numa_zonelist_order = node
vm.block_dump = 0
vm.oom_dump_tasks = 1

# 内核参数
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
kernel.sem = 250 64000 100 512
kernel.pid_max = 65536
kernel.threads-max = 65536
EOF
}

# 配置内核参数 - 超大型配置 ( 16-32GB )
config_xlarge() {
    echo -e "${YELLOW}应用超大型服务器配置 (16-32GB)...${NC}"
    
    cat > /etc/sysctl.d/99-tuning.conf << 'EOF'
# CentOS 8 超大型服务器内核调优配置
# 内存: 16-32GB

# 网络参数
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.tcp_mem = 6291456 8388608 12582912
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_max_orphans = 1048576
net.ipv4.tcp_max_tw_buckets = 1048576
net.ipv4.ip_local_port_range = 10240 65535
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 16384
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_sack = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_congestion_control = cubic

# 文件系统参数
fs.file-max = 4194304
fs.inotify.max_user_watches = 524288
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 5
vm.overcommit_memory = 1
vm.max_map_count = 524288
vm.zone_reclaim_mode = 0
vm.numa_zonelist_order = node
vm.block_dump = 0
vm.oom_dump_tasks = 1
vm.stat_interval = 10

# 内核参数
kernel.shmmax = 137438953472
kernel.shmall = 4294967296
kernel.sem = 250 128000 100 1024
kernel.pid_max = 65536
kernel.threads-max = 131072
EOF
}

# 配置内核参数 - 2倍超大型配置 ( 32-64GB )
config_2xlarge() {
    echo -e "${YELLOW}应用 2xlarge 服务器配置 (32-64GB)...${NC}"
    
    cat > /etc/sysctl.d/99-tuning.conf << 'EOF'
# CentOS 8 2xlarge 服务器内核调优配置
# 内存: 32-64GB

# 网络参数
net.core.rmem_max = 268435456
net.core.wmem_max = 268435456
net.ipv4.tcp_rmem = 4096 87380 268435456
net.ipv4.tcp_wmem = 4096 65536 268435456
net.ipv4.tcp_mem = 12582912 16777216 25165824
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_max_orphans = 2097152
net.ipv4.tcp_max_tw_buckets = 2097152
net.ipv4.ip_local_port_range = 10240 65535
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 32768
net.ipv4.tcp_max_syn_backlog = 32768
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_sack = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_congestion_control = cubic
net.ipv4.tcp_syncookies = 1

# 文件系统参数
fs.file-max = 8388608
fs.inotify.max_user_watches = 524288
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 5
vm.overcommit_memory = 1
vm.max_map_count = 1048576
vm.zone_reclaim_mode = 0
vm.numa_zonelist_order = node
vm.block_dump = 0
vm.oom_dump_tasks = 1
vm.stat_interval = 10
vm.dirty_writeback_centisecs = 500
vm.dirty_expire_centisecs = 30000

# 内核参数
kernel.shmmax = 274877906944
kernel.shmall = 8589934592
kernel.sem = 250 256000 100 2048
kernel.pid_max = 65536
kernel.threads-max = 262144
EOF
}

# 配置内核参数 - 4倍超大型配置 ( 64-128GB )
config_4xlarge() {
    echo -e "${YELLOW}应用 4xlarge 服务器配置 (64-128GB)...${NC}"
    
    cat > /etc/sysctl.d/99-tuning.conf << 'EOF'
# CentOS 8 4xlarge 服务器内核调优配置
# 内存: 64-128GB

# 网络参数
net.core.rmem_max = 536870912
net.core.wmem_max = 536870912
net.ipv4.tcp_rmem = 4096 87380 536870912
net.ipv4.tcp_wmem = 4096 65536 536870912
net.ipv4.tcp_mem = 25165824 33554432 50331648
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_max_orphans = 4194304
net.ipv4.tcp_max_tw_buckets = 4194304
net.ipv4.ip_local_port_range = 10240 65535
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 65536
net.ipv4.tcp_max_syn_backlog = 65536
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_sack = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_congestion_control = cubic
net.ipv4.tcp_syncookies = 1

# 文件系统参数
fs.file-max = 16777216
fs.inotify.max_user_watches = 524288
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 5
vm.overcommit_memory = 1
vm.max_map_count = 2097152
vm.zone_reclaim_mode = 0
vm.numa_zonelist_order = node
vm.block_dump = 0
vm.oom_dump_tasks = 1
vm.stat_interval = 10
vm.dirty_writeback_centisecs = 500
vm.dirty_expire_centisecs = 30000

# 内核参数
kernel.shmmax = 549755813888
kernel.shmall = 17179869184
kernel.sem = 250 512000 100 4096
kernel.pid_max = 65536
kernel.threads-max = 524288
EOF
}

# 配置内核参数 - 8倍超大型配置 ( > 128GB )
config_8xlarge() {
    echo -e "${YELLOW}应用 8xlarge 服务器配置 (> 128GB)...${NC}"
    
    cat > /etc/sysctl.d/99-tuning.conf << 'EOF'
# CentOS 8 8xlarge 服务器内核调优配置
# 内存: > 128GB

# 网络参数
net.core.rmem_max = 1073741824
net.core.wmem_max = 1073741824
net.ipv4.tcp_rmem = 4096 87380 1073741824
net.ipv4.tcp_wmem = 4096 65536 1073741824
net.ipv4.tcp_mem = 50331648 67108864 100663296
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_max_orphans = 8388608
net.ipv4.tcp_max_tw_buckets = 8388608
net.ipv4.ip_local_port_range = 10240 65535
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 131072
net.ipv4.tcp_max_syn_backlog = 131072
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_sack = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_congestion_control = cubic
net.ipv4.tcp_syncookies = 1
net.core.default_qdisc = fq

# 文件系统参数
fs.file-max = 33554432
fs.inotify.max_user_watches = 524288
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 5
vm.overcommit_memory = 1
vm.max_map_count = 4194304
vm.zone_reclaim_mode = 0
vm.numa_zonelist_order = node
vm.block_dump = 0
vm.oom_dump_tasks = 1
vm.stat_interval = 10
vm.dirty_writeback_centisecs = 500
vm.dirty_expire_centisecs = 30000

# 内核参数
kernel.shmmax = 1099511627776
kernel.shmall = 34359738368
kernel.sem = 250 1024000 100 8192
kernel.pid_max = 65536
kernel.threads-max = 1048576
EOF
}

# 配置 limits.conf
config_limits() {
    local mem_gb=$1
    local nofile_limit=$((mem_gb * 65536))
    if [ $nofile_limit -gt 65536 ]; then
        nofile_limit=65536
    fi
    
    echo -e "${YELLOW}配置系统限制...${NC}"
    
    cat > /etc/security/limits.d/99-tuning.conf << EOF
# CentOS 8 系统限制配置
# 根据内存自动调整

* soft nofile $nofile_limit
* hard nofile $nofile_limit
* soft nproc 65536
* hard nproc 65536
* soft core unlimited
* hard core unlimited
* soft memlock unlimited
* hard memlock unlimited

root soft nofile $nofile_limit
root hard nofile $nofile_limit
root soft nproc 65536
root hard nproc 65536

# 对于 MySQL/MariaDB
mysql soft nofile 65536
mysql hard nofile 65536
mysql soft nproc 65536
mysql hard nproc 65536

# 对于 PostgreSQL
postgres soft nofile 65536
postgres hard nofile 65536
postgres soft nproc 65536
postgres hard nproc 65536

# 对于 Nginx
nginx soft nofile 65536
nginx hard nofile 65536
nginx soft nproc 65536
nginx hard nproc 65536
EOF
}

# 配置网络优化
config_network_tuning() {
    echo -e "${YELLOW}配置网络优化...${NC}"
    
    # 备份原始配置
    if [ ! -f /etc/sysctl.d/99-network.conf ]; then
        cp /etc/sysctl.d/50-default.conf /etc/sysctl.d/99-network.conf 2>/dev/null || true
    fi
    
    # 添加额外网络优化
    cat >> /etc/sysctl.d/99-tuning.conf << 'EOF'

# 网络连接优化
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 1
net.ipv4.conf.default.secure_redirects = 1
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.default.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.default.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.log_martians = 0
net.ipv4.conf.default.log_martians = 0
net.ipv4.neigh.default.gc_thresh1 = 4096
net.ipv4.neigh.default.gc_thresh2 = 8192
net.ipv4.neigh.default.gc_thresh3 = 16384
net.ipv6.neigh.default.gc_thresh1 = 4096
net.ipv6.neigh.default.gc_thresh2 = 8192
net.ipv6.neigh.default.gc_thresh3 = 16384
EOF
}

# 应用配置
apply_config() {
    echo -e "${YELLOW}应用内核参数...${NC}"
    sysctl -p /etc/sysctl.d/99-tuning.conf > /dev/null 2>&1 || true
    
    echo -e "${YELLOW}应用系统限制...${NC}"
    ulimit -n 65536 2>/dev/null || true
    
    echo -e "${GREEN}✓ 内核调优完成${NC}"
}

# 验证配置
verify_config() {
    echo ""
    echo -e "${BLUE}验证配置：${NC}"
    echo "  网络连接数上限: $(cat /proc/sys/net/core/somaxconn)"
    echo "  文件描述符上限: $(ulimit -n)"
    echo "  最大内存映射: $(cat /proc/sys/vm/max_map_count)"
    echo "  Swappiness: $(cat /proc/sys/vm/swappiness)"
}

# 优化建议
show_recommendations() {
    local mem_gb=$1
    local profile=$2
    
    echo ""
    echo -e "${BLUE}优化建议：${NC}"
    echo "  检测到内存: ${mem_gb}GB"
    echo "  配置方案: ${profile}"
    echo ""
    echo "  建议后续操作:"
    echo "    1. 重启系统使配置完全生效: reboot"
    echo "    2. 检查应用性能: top, htop, vmstat 1"
    echo "    3. 检查网络性能: netstat -s, ss -s"
    echo "    4. 监控磁盘 I/O: iostat -x 1"
    echo ""
    echo "  配置说明:"
    echo "    - 网络参数已优化高并发连接"
    echo "    - 文件描述符已根据内存扩展"
    echo "    - Swappiness 设置为 10，减少交换分区使用"
    echo "    - TCP 连接参数已优化"
    echo ""
}

# 主函数
main() {
    # 检查 root 权限
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}错误：请使用 root 用户运行此脚本${NC}"
        echo "使用方法: sudo $0"
        exit 1
    fi
    
    get_system_info
    
    local mem_gb=$(get_memory_gb)
    local mem_mb=$(get_memory_mb)
    local profile=$(get_profile $mem_gb)
    
    echo -e "${YELLOW}内存信息：${NC}"
    echo "  总内存: ${mem_gb}GB (${mem_mb}MB)"
    echo "  配置方案: ${profile}"
    echo ""
    
    echo -e "${BLUE}开始优化...${NC}"
    echo ""
    
    # 根据内存大小应用配置
    case $profile in
        tiny)
            config_tiny
            ;;
        small)
            config_small
            ;;
        medium)
            config_medium
            ;;
        large)
            config_large
            ;;
        xlarge)
            config_xlarge
            ;;
        2xlarge)
            config_2xlarge
            ;;
        4xlarge)
            config_4xlarge
            ;;
        8xlarge)
            config_8xlarge
            ;;
    esac
    
    config_limits $mem_gb
    config_network_tuning
    apply_config
    verify_config
    show_recommendations $mem_gb $profile
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   内核调优完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}注意：建议重启系统使配置完全生效${NC}"
}

main "$@"
