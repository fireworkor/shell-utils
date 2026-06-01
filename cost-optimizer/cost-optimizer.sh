#!/bin/bash
# 云成本优化工具

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/logging.sh"

# 配置文件
COST_CONFIG="$SCRIPT_DIR/config/cost-rules.conf"
COST_REPORT_DIR="$SCRIPT_DIR/logs/cost-reports"

show_help() {
    cat << EOF
${GREEN}========================================${NC}
${GREEN}   云成本优化工具 v1.0${NC}
${GREEN}========================================${NC}

${YELLOW}使用方法：${NC}
  $0 <命令> [选项]

${YELLOW}成本分析：${NC}
  analyze              分析当前资源使用
  report               生成成本报告
  trends               查看成本趋势

${YELLOW}资源优化：${NC}
  right-size           右尺寸建议
  idle-resources       列出闲置资源
  old-snapshots        列出旧快照
  reserved-instances    预留实例建议

${YELLOW}成本控制：${NC}
  set-budget <金额>    设置预算
  alerts               配置告警
  schedule <操作>      定时启停

${YELLOW}优化执行：${NC}
  optimize             执行优化建议
  simulate            模拟优化效果

${YELLOW}示例：${NC}
  $0 analyze
  $0 report
  $0 right-size
  $0 idle-resources
  $0 set-budget 1000
  $0 optimize

EOF
}

# 初始化
init_cost() {
    mkdir -p "$COST_REPORT_DIR" "$(dirname "$COST_CONFIG")"
    [ ! -f "$COST_CONFIG" ] && touch "$COST_CONFIG"
}

# 成本分析
analyze_cost() {
    init_cost
    clear
    print_header "成本分析报告"
    
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local report_file="$COST_REPORT_DIR/analysis_$(date +%Y%m%d_%H%M%S).txt"
    
    echo "分析时间: $timestamp" > "$report_file"
    echo "" >> "$report_file"
    
    # 检查 kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl 未安装"
        return 1
    fi
    
    echo "======================================" >> "$report_file"
    echo "Kubernetes 资源分析" >> "$report_file"
    echo "======================================" >> "$report_file"
    echo "" >> "$report_file"
    
    # 获取所有命名空间
    echo "命名空间资源使用:" >> "$report_file"
    kubectl top nodes 2>/dev/null | tee -a "$report_file" || echo "metrics-server 未安装" >> "$report_file"
    echo "" >> "$report_file"
    
    # Pod 资源使用
    echo "Pod 资源使用 (Top 10):" >> "$report_file"
    kubectl top pods --all-namespaces 2>/dev/null | head -20 | tee -a "$report_file" || echo "无法获取 Pod 资源" >> "$report_file"
    echo "" >> "$report_file"
    
    # 资源配置
    echo "资源配置检查:" >> "$report_file"
    kubectl get deployments --all-namespaces -o json | jq -r '.items[] | select(.spec.template.spec.containers[].resources.requests==null) | .metadata.namespace + "/" + .metadata.name' 2>/dev/null | while read line; do
        echo "  ⚠️  $line - 缺少资源限制" >> "$report_file"
    done
    
    # PVC 使用
    echo "" >> "$report_file"
    echo "持久卷使用:" >> "$report_file"
    kubectl get pvc --all-namespaces -o wide 2>/dev/null | tee -a "$report_file"
    echo "" >> "$report_file"
    
    # 闲置资源检测
    echo "======================================" >> "$report_file"
    echo "闲置资源检测" >> "$report_file"
    echo "======================================" >> "$report_file"
    echo "" >> "$report_file"
    
    echo "无流量服务:" >> "$report_file"
    kubectl get svc --all-namespaces | grep -v "ClusterIP" | grep -v "LoadBalancer" | grep -v "NODE" | while read line; do
        echo "  $line" >> "$report_file"
    done
    
    # 闲置 PVC
    echo "" >> "$report_file"
    echo "未绑定的 PVC:" >> "$report_file"
    kubectl get pvc --all-namespaces | grep -v "Bound" | tee -a "$report_file"
    
    print_success "分析完成，报告已保存到: $report_file"
    
    # 成本估算
    echo ""
    print_header "成本估算"
    
    echo ""
    echo -e "${YELLOW}计算资源成本 (按月估算):${NC}"
    echo "----------------------------------------"
    
    # 获取节点信息
    local node_count=$(kubectl get nodes --no-headers | wc -l)
    local total_cpu=$(kubectl get nodes -o jsonpath='{.items[*].status.capacity.cpu}' | tr ' ' '\n' | paste -sd+ | bc 2>/dev/null || echo 0)
    local total_mem=$(kubectl get nodes -o jsonpath='{.items[*].status.capacity.memory}' | awk '{gsub(/Ki/, "", $1); print $1/1024/1024}' | paste -sd+ | bc 2>/dev/null || echo 0)
    
    # 估算成本 (假设 1 CPU 核 = $50/月, 1 GB 内存 = $10/月)
    local cpu_cost=$((total_cpu * 50))
    local mem_cost=$((total_mem * 10))
    local total_cost=$((cpu_cost + mem_cost))
    
    echo "节点数: $node_count"
    echo "CPU 核数: $total_cpu"
    echo "内存: ${total_mem}GB"
    echo "CPU 成本: \$$cpu_cost/月"
    echo "内存成本: \$$mem_cost/月"
    echo "估算总成本: \$$total_cost/月"
    
    # 保存估算
    echo "" >> "$report_file"
    echo "成本估算: \$$total_cost/月" >> "$report_file"
}

# 生成报告
generate_report() {
    init_cost
    clear
    print_header "成本报告"
    
    local period=${1:-30}  # 默认 30 天
    local report_file="$COST_REPORT_DIR/report_$(date +%Y%m%d).txt"
    
    echo "成本报告 - $(date)" > "$report_file"
    echo "周期: 最近 $period 天" >> "$report_file"
    echo "" >> "$report_file"
    
    # 调用成本分析
    analyze_cost >> "$report_file" 2>&1
    
    # 生成建议
    echo "" >> "$report_file"
    echo "======================================" >> "$report_file"
    echo "优化建议" >> "$report_file"
    echo "======================================" >> "$report_file"
    echo "" >> "$report_file"
    
    generate_suggestions >> "$report_file"
    
    print_success "报告已生成: $report_file"
    
    # 显示报告
    cat "$report_file"
}

# 生成优化建议
generate_suggestions() {
    echo "🔍 优化建议:"
    echo ""
    
    # 检查无资源限制的部署
    local no_limits=$(kubectl get deployments --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.spec.template.spec.containers[].resources.limits==null) | .metadata.namespace + "/" + .metadata.name' | wc -l)
    
    if [ "$no_limits" -gt 0 ]; then
        echo "1. ⚠️  发现 $no_limits 个部署缺少资源限制"
        echo "   建议: 添加 CPU 和内存限制，避免资源争用"
        echo ""
    fi
    
    # 检查闲置 PVC
    local unbound_pvc=$(kubectl get pvc --all-namespaces 2>/dev/null | grep -v "Bound" | wc -l)
    
    if [ "$unbound_pvc" -gt 0 ]; then
        echo "2. ⚠️  发现 $unbound_pvc 个未绑定的 PVC"
        echo "   建议: 删除未使用的 PVC，避免存储费用"
        echo ""
    fi
    
    # 检查大规模部署
    local large_deployments=$(kubectl get deployments --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.spec.replicas >= 5) | .metadata.namespace + "/" + .metadata.name + " (replicas: " + (.spec.replicas | tostring) + ")"' | wc -l)
    
    if [ "$large_deployments" -gt 0 ]; then
        echo "3. 📊  发现 $large_deployments 个大规模部署"
        echo "   建议: 考虑使用 HPA 自动扩缩容"
        echo ""
    fi
    
    # 检查旧镜像
    echo "4. 📦 镜像优化建议:"
    echo "   - 使用多阶段构建减小镜像大小"
    echo "   - 使用轻量级基础镜像 (alpine, distroless)"
    echo "   - 定期清理未使用的镜像"
    echo ""
    
    # 成本节约估算
    echo "5. 💰 预估节约成本:"
    echo "   - 优化资源限制: 预计节约 10-20%"
    echo "   - 使用 Spot 实例: 预计节约 60-70%"
    echo "   - 自动扩缩容: 预计节约 20-30%"
    echo ""
}

# 右尺寸建议
right_size_suggestions() {
    clear
    print_header "右尺寸建议"
    
    echo ""
    echo "正在分析资源使用情况..."
    echo ""
    
    # 获取 Pod 资源配置
    kubectl get pods --all-namespaces -o json 2>/dev/null | jq -r '
        .items[] | 
        select(.spec.containers[].resources.requests!=null) | 
        .metadata.namespace + "/" + .metadata.name + " (" + .spec.containers[0].resources.requests.cpu + " CPU, " + .spec.containers[0].resources.requests.memory + " MEM)"
    ' 2>/dev/null | while read pod; do
        echo "  $pod"
    done
    
    echo ""
    echo "建议优化:"
    echo "  1. 根据实际使用情况调整资源请求"
    echo "  2. 使用 VPA (Vertical Pod Autoscaler) 自动调整"
    echo "  3. 监控实际 CPU/内存使用率"
}

# 闲置资源
idle_resources() {
    clear
    print_header "闲置资源检测"
    
    echo ""
    echo -e "${YELLOW}闲置的 Deployments:${NC}"
    kubectl get deployments --all-namespaces -o json 2>/dev/null | jq -r '
        .items[] | 
        select(.spec.replicas > 0) | 
        .metadata.namespace + "/" + .metadata.name + " (replicas: " + (.spec.replicas | tostring) + ")"
    ' | while read deploy; do
        # 检查是否有 Pod 运行
        local name=$(echo "$deploy" | awk -F'/' '{print $2}')
        local ns=$(echo "$deploy" | awk -F'/' '{print $1}')
        local ready=$(kubectl get deployment "$name" -n "$ns" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
        
        if [ -z "$ready" ] || [ "$ready" = "0" ]; then
            echo "  ⚠️  $deploy - 无就绪 Pod"
        fi
    done
    
    echo ""
    echo -e "${YELLOW}未绑定的 PVC:${NC}"
    kubectl get pvc --all-namespaces 2>/dev/null | grep -v "Bound" || echo "  无"
    
    echo ""
    echo -e "${YELLOW}无 Selector 的 Service:${NC}"
    kubectl get svc --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.spec.selector==null) | .metadata.namespace + "/" + .metadata.name' || echo "  无"
}

# 设置预算
set_budget() {
    local budget=$1
    
    if [ -z "$budget" ]; then
        print_error "请指定预算金额"
        return 1
    fi
    
    init_cost
    set_config "monthly_budget" "$budget"
    print_success "月度预算已设置为: \$$budget"
    
    # 计算告警阈值
    local warning=$((budget * 80 / 100))
    local critical=$((budget * 90 / 100))
    
    set_config "alert_warning" "$warning"
    set_config "alert_critical" "$critical"
    
    echo ""
    echo "告警阈值:"
    echo "  警告: \$$warning (80%)"
    echo "  严重: \$$critical (90%)"
}

# 定时启停
schedule_control() {
    local action=$1
    local schedule=$2
    
    if [ -z "$action" ]; then
        print_error "请指定操作 (start/stop/schedule)"
        return 1
    fi
    
    init_cost
    
    case $action in
        start)
            echo "启动非关键应用..."
            kubectl get deployments --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.metadata.annotations.scheduler=="non-critical") | "kubectl scale deployment " + .metadata.name + " -n " + .metadata.namespace + " --replicas=1"' | bash
            print_success "已启动非关键应用"
            ;;
        stop)
            echo "停止非关键应用..."
            kubectl get deployments --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.metadata.annotations.scheduler=="non-critical") | "kubectl scale deployment " + .metadata.name + " -n " + .metadata.namespace + " --replicas=0"' | bash
            print_success "已停止非关键应用"
            ;;
        schedule)
            echo "设置定时任务..."
            read -p "输入 Cron 表达式 (例如: 0 18 * * 1-5 表示工作日 18:00 停止): " cron_expr
            read -p "操作 (start/stop): " schedule_action
            
            echo "$cron_expr kubectl $0 schedule-control $schedule_action" >> "$COST_CONFIG"
            print_success "定时任务已添加: $cron_expr"
            ;;
        *)
            print_error "未知操作: $action"
            ;;
    esac
}

# 执行优化
execute_optimize() {
    clear
    print_header "执行优化"
    
    echo ""
    echo "⚠️  以下操作将对集群进行更改:"
    echo ""
    echo "1. 删除未绑定的 PVC"
    echo "2. 缩小过度配置的部署"
    echo "3. 清理未使用的镜像"
    echo ""
    
    if ! confirm "确定继续?"; then
        print_info "优化已取消"
        return
    fi
    
    local changes=0
    
    # 删除未绑定的 PVC
    echo ""
    echo "1. 删除未绑定的 PVC..."
    local unbound_pvcs=$(kubectl get pvc --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.status.phase!="Bound") | .metadata.namespace + "/" + .metadata.name')
    
    if [ -n "$unbound_pvcs" ]; then
        echo "$unbound_pvcs" | while read pvc; do
            kubectl delete pvc "$pvc" 2>/dev/null && echo "  ✓ 已删除: $pvc" && ((changes++))
        done
    else
        echo "  无未绑定的 PVC"
    fi
    
    echo ""
    echo "优化完成，共执行 $changes 项更改"
    
    if [ "$changes" -gt 0 ]; then
        print_success "优化已完成!"
    fi
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    local command=$1
    shift
    
    case $command in
        analyze)
            analyze_cost
            ;;
        report)
            generate_report "$@"
            ;;
        trends)
            echo "查看成本趋势..."
            # TODO: 实现趋势分析
            print_info "功能开发中"
            ;;
        right-size)
            right_size_suggestions
            ;;
        idle-resources)
            idle_resources
            ;;
        old-snapshots)
            echo "检查旧快照..."
            # TODO: 实现快照检查
            print_info "功能开发中"
            ;;
        reserved-instances)
            echo "预留实例建议..."
            # TODO: 实现 RI 建议
            print_info "功能开发中"
            ;;
        set-budget)
            set_budget "$1"
            ;;
        alerts)
            echo "配置告警..."
            # TODO: 实现告警配置
            print_info "功能开发中"
            ;;
        schedule)
            schedule_control "$@"
            ;;
        optimize)
            execute_optimize
            ;;
        simulate)
            echo "模拟优化效果..."
            generate_suggestions
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"