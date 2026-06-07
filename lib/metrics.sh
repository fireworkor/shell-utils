#!/bin/bash
# 性能监控模块
# 收集和报告系统性能指标

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 配置
METRICS_DIR="/var/lib/shell-utils/metrics"
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEM=85
ALERT_THRESHOLD_DISK=90

# 初始化
init_metrics() {
    mkdir -p "$METRICS_DIR" 2>/dev/null
    mkdir -p "$METRICS_DIR/history" 2>/dev/null
}

# 获取 CPU 使用率
get_cpu_usage() {
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    echo "$cpu_usage" | sed 's/^[[:space:]]*//'
}

# 获取内存使用率
get_mem_usage() {
    local mem_info
    mem_info=$(free | grep Mem)
    local total
    total=$(echo "$mem_info" | awk '{print $2}')
    local used
    used=$(echo "$mem_info" | awk '{print $3}')
    local percent=$((used * 100 / total))
    echo "$percent"
}

# 获取磁盘使用率
get_disk_usage() {
    local disk_usage
    disk_usage=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
    echo "$disk_usage"
}

# 获取负载平均值
get_load_average() {
    uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//'
}

# 获取进程数
get_process_count() {
    ps aux | wc -l
}

# 获取网络连接数
get_network_connections() {
    ss -s | grep -i "estab" | awk '{print $1}'
}

# 获取 TOP CPU 进程
get_top_cpu_processes() {
    ps aux --sort=-%cpu | head -6 | tail -5
}

# 获取 TOP 内存进程
get_top_mem_processes() {
    ps aux --sort=-%mem | head -6 | tail -5
}

# 获取磁盘 I/O
get_disk_io() {
    if command -v iostat &>/dev/null; then
        iostat -x 1 1 | tail -2
    else
        echo "iostat 未安装"
    fi
}

# 获取网络流量
get_network_traffic() {
    cat /proc/net/dev | grep -v "lo:" | tail -n +3 | while read line; do
        echo "$line" | awk '{print $1, $2, $10}'
    done
}

# 获取系统 uptime
get_uptime() {
    uptime -p 2>/dev/null || uptime
}

# 获取 CPU 信息
get_cpu_info() {
    grep -E "^model name|^cpu cores|^cpu MHz" /proc/cpuinfo | head -3
}

# 获取内存详情
get_mem_details() {
    free -h
}

# 获取磁盘详情
get_disk_details() {
    df -h | grep -E "^/dev|Filesystem"
}

# 获取服务状态
get_service_status() {
    local service="$1"
    if systemctl is-active "$service" &>/dev/null; then
        echo "running"
    elif systemctl is-enabled "$service" &>/dev/null; then
        echo "stopped"
    else
        echo "unknown"
    fi
}

# 告警检查
check_alerts() {
    local alerts=()
    local cpu_usage
    local mem_usage
    local disk_usage
    
    # CPU 检查
    cpu_usage=$(get_cpu_usage | sed 's/%//')
    if [ "$cpu_usage" -ge "$ALERT_THRESHOLD_CPU" ]; then
        alerts+=("CPU 使用率过高: ${cpu_usage}%")
    fi
    
    # 内存检查
    mem_usage=$(get_mem_usage)
    if [ "$mem_usage" -ge "$ALERT_THRESHOLD_MEM" ]; then
        alerts+=("内存使用率过高: ${mem_usage}%")
    fi
    
    # 磁盘检查
    disk_usage=$(get_disk_usage)
    if [ "$disk_usage" -ge "$ALERT_THRESHOLD_DISK" ]; then
        alerts+=("磁盘使用率过高: ${disk_usage}%")
    fi
    
    # 输出告警
    if [ ${#alerts[@]} -gt 0 ]; then
        echo -e "${RED}⚠️  告警:${NC}"
        for alert in "${alerts[@]}"; do
            echo -e "  ${RED}• $alert${NC}"
        done
        return 1
    else
        return 0
    fi
}

# 性能报告
generate_report() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  系统性能监控报告${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    echo -e "${BLUE}【系统信息】${NC}"
    echo -e "运行时间: $(get_uptime)"
    echo -e "进程数: $(get_process_count)"
    echo -e "网络连接: $(get_network_connections) ESTABLISHED"
    echo ""
    
    echo -e "${BLUE}【CPU 信息】${NC}"
    get_cpu_info | sed 's/^/  /'
    echo -e "  CPU 使用率: $(get_cpu_usage)"
    echo -e "  负载平均值: $(get_load_average)"
    echo ""
    
    echo -e "${BLUE}【内存使用】${NC}"
    echo -e "  内存使用率: $(get_mem_usage)%"
    get_mem_details | grep -E "^Mem|^Swap" | sed 's/^/  /'
    echo ""
    
    echo -e "${BLUE}【磁盘使用】${NC}"
    echo -e "  根分区使用率: $(get_disk_usage)%"
    df -h / | tail -1 | awk '{printf "  可用空间: %s / %s\n", $4, $2}'
    echo ""
    
    echo -e "${BLUE}【Top 5 CPU 进程】${NC}"
    get_top_cpu_processes | awk '{printf "  %s %s%% %s\n", $11, $3, $6}' | head -5
    echo ""
    
    echo -e "${BLUE}【Top 5 内存进程】${NC}"
    get_top_mem_processes | awk '{printf "  %s %s%% %s\n", $11, $4, $6}' | head -5
    echo ""
    
    # 告警检查
    if ! check_alerts; then
        echo ""
    fi
    
    echo -e "${CYAN}========================================${NC}"
}

# 保存指标到文件
save_metrics() {
    local timestamp
    timestamp=$(date +%s)
    local metrics_file="$METRICS_DIR/history/metrics_$(date +%Y%m%d).log"
    
    {
        echo "[$timestamp]"
        echo "cpu=$(get_cpu_usage)"
        echo "mem=$(get_mem_usage)"
        echo "disk=$(get_disk_usage)"
        echo "load=$(get_load_average)"
        echo "processes=$(get_process_count)"
        echo "connections=$(get_network_connections)"
    } >> "$metrics_file"
}

# 生成趋势报告
generate_trend_report() {
    local days="${1:-7}"
    local today
    today=$(date +%Y%m%d)
    
    echo -e "${CYAN}性能趋势报告 (最近 $days 天)${NC}"
    echo ""
    
    for i in $(seq 0 $((days-1))); do
        local date
        date=$(date -d "$i days ago" +%Y%m%d)
        local file="$METRICS_DIR/history/metrics_${date}.log"
        
        if [ -f "$file" ]; then
            echo -e "${BLUE}$(date -d "$i days ago" '+%Y-%m-%d')${NC}"
            
            # 计算平均值
            local avg_cpu
            avg_cpu=$(grep "^cpu=" "$file" | sed 's/cpu=//' | awk '{sum+=$1} END {printf "%.1f", sum/NR}')
            local avg_mem
            avg_mem=$(grep "^mem=" "$file" | sed 's/mem=//' | awk '{sum+=$1} END {printf "%.1f", sum/NR}')
            local avg_disk
            avg_disk=$(grep "^disk=" "$file" | sed 's/disk=//' | awk '{sum+=$1} END {printf "%.1f", sum/NR}')
            
            echo -e "  CPU: ${avg_cpu}% | 内存: ${avg_mem}% | 磁盘: ${avg_disk}%"
        fi
    done
}

# 清理旧指标
cleanup_old_metrics() {
    local days="${1:-30}"
    find "$METRICS_DIR/history" -name "metrics_*.log" -mtime "+$days" -delete 2>/dev/null
    echo "已清理超过 $days 天的历史指标"
}

# 实时监控模式
realtime_monitor() {
    echo -e "${CYAN}实时性能监控 (Ctrl+C 退出)${NC}"
    echo ""
    
    while true; do
        clear
        echo -e "${CYAN}实时性能监控 - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
        echo -e "${CYAN}========================================${NC}"
        echo ""
        
        echo -e "${GREEN}CPU:${NC}   $(get_cpu_usage)"
        echo -e "${GREEN}内存:${NC}   $(get_mem_usage)%"
        echo -e "${GREEN}磁盘:${NC}   $(get_disk_usage)%"
        echo -e "${GREEN}负载:${NC}   $(get_load_average)"
        echo ""
        
        # 告警状态
        if check_alerts >/dev/null 2>&1; then
            echo -e "${GREEN}✓ 系统状态正常${NC}"
        fi
        echo ""
        
        sleep 2
    done
}

# 主函数
main() {
    local action="${1:-report}"
    
    init_metrics
    
    case "$action" in
        report)
            generate_report
            ;;
        save)
            save_metrics
            echo -e "${GREEN}✓ 指标已保存${NC}"
            ;;
        trend)
            generate_trend_report "${2:-7}"
            ;;
        alert)
            check_alerts
            ;;
        monitor)
            realtime_monitor
            ;;
        cleanup)
            cleanup_old_metrics "${2:-30}"
            ;;
        help|*)
            echo "用法: $0 {report|save|trend|alert|monitor|cleanup|help}"
            echo ""
            echo "命令:"
            echo "  report           - 生成性能报告"
            echo "  save             - 保存当前指标"
            echo "  trend [天数]     - 生成趋势报告 (默认7天)"
            echo "  alert            - 检查告警条件"
            echo "  monitor          - 实时监控模式"
            echo "  cleanup [天数]   - 清理旧指标 (默认30天)"
            echo "  help             - 显示帮助"
            ;;
    esac
}

# 如果直接运行
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
