#!/bin/bash
# 合规性检查工具

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/logging.sh"

# 配置文件
COMPLIANCE_CONFIG="$SCRIPT_DIR/config/compliance-rules.conf"
COMPLIANCE_REPORT_DIR="$SCRIPT_DIR/logs/compliance"

# 合规框架
FRAMEWORKS=(
    "cis-benchmark:CIS Kubernetes Benchmark"
    "pci-dss:PCI DSS"
    "hipaa:HIPAA"
    "gdpr:GPDR"
    "soc2:SOC 2"
)

show_help() {
    cat << EOF
${GREEN}========================================${NC}
${GREEN}   合规性检查工具 v1.0${NC}
${GREEN}========================================${NC}

${YELLOW}使用方法：${NC}
  $0 <命令> [选项]

${YELLOW}检查命令：${NC}
  check [框架]      执行合规性检查
  list              列出合规框架
  rules             显示检查规则

${YELLOW}报告命令：${NC}
  report [框架]     生成合规报告
  diff [框架1] [框架2]  对比框架差异

${YELLOW}管理命令：${NC}
  add-rule          添加自定义规则
  export            导出配置
  import            导入配置

${YELLOW}支持的框架：${NC}
  cis-benchmark     CIS Kubernetes Benchmark
  pci-dss           PCI DSS
  hipaa             HIPAA
  gdpr              GPDR
  soc2              SOC 2

${YELLOW}示例：${NC}
  $0 check cis-benchmark
  $0 check all
  $0 report
  $0 list

EOF
}

# 初始化
init_compliance() {
    mkdir -p "$COMPLIANCE_REPORT_DIR" "$(dirname "$COMPLIANCE_CONFIG")"
    [ ! -f "$COMPLIANCE_CONFIG" ] && touch "$COMPLIANCE_CONFIG"
}

# 列出框架
list_frameworks() {
    print_header "支持的合规框架"
    
    echo ""
    echo -e "${YELLOW}框架 ID          名称${NC}"
    echo "----------------------------------------"
    
    for framework in "${FRAMEWORKS[@]}"; do
        IFS=':' read -r id name <<< "$framework"
        echo -e "$id          $name"
    done
}

# 显示检查规则
show_rules() {
    local framework=$1
    
    if [ -z "$framework" ]; then
        framework="cis-benchmark"
    fi
    
    clear
    print_header "检查规则: $framework"
    
    echo ""
    
    case $framework in
        cis-benchmark)
            echo "CIS Kubernetes Benchmark v1.6 检查项:"
            echo ""
            echo "1.1 API Server"
            echo "  ✓ 1.1.1 确保 API Server 使用强加密算法"
            echo "  ✓ 1.1.2 确保 API Server 使用强 TLS 加密"
            echo "  ✓ 1.1.3 确保禁用匿名认证"
            echo ""
            echo "1.2 Etcd"
            echo "  ✓ 1.2.1 确保 Etcd 使用强加密"
            echo "  ✓ 1.2.2 确保 Etcd 数据加密"
            echo ""
            echo "1.3 控制平面节点配置"
            echo "  ✓ 1.3.1 确保使用强加密算法"
            echo "  ✓ 1.3.2 确保禁用 SSH 密码认证"
            echo ""
            echo "2.1 RBAC"
            echo "  ✓ 2.1.1 确保使用 RBAC"
            echo "  ✓ 2.1.2 避免使用 system:masters 组"
            echo ""
            echo "3.1 容器配置"
            echo "  ✓ 3.1.1 确保不使用特权容器"
            echo "  ✓ 3.1.2 确保不使用 root 用户"
            echo "  ✓ 3.1.3 确保使用只读根文件系统"
            echo "  ✓ 3.1.4 确保禁止特权升级"
            echo ""
            echo "4.1 网络策略"
            echo "  ✓ 4.1.1 确保存在默认网络策略"
            echo ""
            echo "5.1 秘密管理"
            echo "  ✓ 5.1.1 确保使用外部秘密管理"
            ;;
        pci-dss)
            echo "PCI DSS 合规检查项:"
            echo ""
            echo "A. 数据保护"
            echo "  ✓ A.1 静态数据加密"
            echo "  ✓ A.2 传输中数据加密"
            echo ""
            echo "B. 访问控制"
            echo "  ✓ B.1 最小权限原则"
            echo "  ✓ B.2 强密码策略"
            echo "  ✓ B.3 多因素认证"
            echo ""
            echo "C. 审计日志"
            echo "  ✓ C.1 启用审计日志"
            echo "  ✓ C.2 保留日志足够时间"
            ;;
        hipaa)
            echo "HIPAA 合规检查项:"
            echo ""
            echo "1. 技术安全措施"
            echo "  ✓ 1.1 访问控制"
            echo "  ✓ 1.2 审计控制"
            echo "  ✓ 1.3 数据完整性"
            echo "  ✓ 1.4 传输安全"
            echo ""
            echo "2. 电子保护 PHI"
            echo "  ✓ 2.1 数据加密"
            echo "  ✓ 2.2 访问日志"
            ;;
        gdpr)
            echo "GDPR 合规检查项:"
            echo ""
            echo "1. 数据保护"
            echo "  ✓ 1.1 数据加密"
            echo "  ✓ 1.2 数据匿名化"
            echo "  ✓ 1.3 数据删除权"
            echo ""
            echo "2. 访问控制"
            echo "  ✓ 2.1 最小权限"
            echo "  ✓ 2.2 审计日志"
            ;;
        soc2)
            echo "SOC 2 合规检查项:"
            echo ""
            echo "1. 安全性"
            echo "  ✓ 1.1 访问控制"
            echo "  ✓ 1.2 加密"
            echo "  ✓ 1.3 防火墙"
            echo ""
            echo "2. 可用性"
            echo "  ✓ 2.1 备份"
            echo "  ✓ 2.2 灾难恢复"
            ;;
        *)
            print_error "未知框架: $framework"
            ;;
    esac
}

# 执行检查
check_compliance() {
    local framework=$1
    
    if [ -z "$framework" ]; then
        framework="cis-benchmark"
    fi
    
    if [ "$framework" = "all" ]; then
        for fw in "${FRAMEWORKS[@]}"; do
            IFS=':' read -r id name <<< "$fw"
            check_compliance "$id"
        done
        return
    fi
    
    clear
    print_header "合规性检查: $framework"
    
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local report_file="$COMPLIANCE_REPORT_DIR/${framework}_$(date +%Y%m%d_%H%M%S).json"
    
    echo ""
    echo "检查时间: $timestamp"
    echo ""
    
    # 检查 kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl 未安装"
        return 1
    fi
    
    local passed=0
    local failed=0
    local warnings=0
    
    # JSON 报告头
    echo "{" > "$report_file"
    echo "  \"framework\": \"$framework\"," >> "$report_file"
    echo "  \"timestamp\": \"$timestamp\"," >> "$report_file"
    echo "  \"results\": [" >> "$report_file"
    
    local first=true
    
    case $framework in
        cis-benchmark)
            echo -e "${YELLOW}1. API Server 安全检查${NC}"
            echo "----------------------------------------"
            
            # 检查 API Server 配置
            local api_secure=$(kubectl get pod -n kube-system -l component=kube-apiserver -o jsonpath='{.items[0].spec.containers[0].command}' 2>/dev/null | grep -c "anonymous-auth=false" || echo 0)
            if [ "$api_secure" -gt 0 ]; then
                echo -e "  ${GREEN}✓${NC} 匿名认证已禁用"
                ((passed++))
            else
                echo -e "  ${RED}✗${NC} 匿名认证未禁用"
                ((failed++))
                [ -n "$first" ] && first=false || echo "," >> "$report_file"
                echo "    {\"check\": \"anonymous-auth\", \"status\": \"FAIL\", \"message\": \"Anonymous authentication is enabled\"}" >> "$report_file"
            fi
            
            # 检查 TLS 加密
            local tls_version=$(kubectl get pod -n kube-system -l component=kube-apiserver -o jsonpath='{.items[0].spec.containers[0].command}' 2>/dev/null | grep -o "tls-min-version-version-[A-Z]*" || echo "UNKNOWN")
            echo -e "  TLS 版本: $tls_version"
            
            echo ""
            echo -e "${YELLOW}2. Etcd 安全检查${NC}"
            echo "----------------------------------------"
            
            # 检查 Etcd 加密
            local etcd_encrypted=$(kubectl get pod -n kube-system -l component=etcd -o jsonpath='{.items[0].spec.containers[0].command}' 2>/dev/null | grep -c "encryption" || echo 0)
            if [ "$etcd_encrypted" -gt 0 ]; then
                echo -e "  ${GREEN}✓${NC} Etcd 数据已加密"
                ((passed++))
            else
                echo -e "  ${YELLOW}⚠${NC} Etcd 数据加密未配置"
                ((warnings++))
            fi
            
            echo ""
            echo -e "${YELLOW}3. RBAC 检查${NC}"
            echo "----------------------------------------"
            
            # 检查 ClusterRoleBindings
            local cluster_admin=$(kubectl get clusterrolebinding -o json 2>/dev/null | jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .subjects[].name' | wc -l)
            if [ "$cluster_admin" -le 2 ]; then
                echo -e "  ${GREEN}✓${NC} Cluster-admin 权限已最小化"
                ((passed++))
            else
                echo -e "  ${YELLOW}⚠${NC} Cluster-admin 权限过多"
                ((warnings++))
            fi
            
            echo ""
            echo -e "${YELLOW}4. 容器安全检查${NC}"
            echo "----------------------------------------"
            
            # 检查特权容器
            local privileged_pods=$(kubectl get pods --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.spec.containers[].securityContext.privileged==true) | .metadata.namespace + "/" + .metadata.name' | wc -l)
            if [ "$privileged_pods" -eq 0 ]; then
                echo -e "  ${GREEN}✓${NC} 无特权容器"
                ((passed++))
            else
                echo -e "  ${RED}✗${NC} 发现 $privileged_pods 个特权容器"
                ((failed++))
            fi
            
            # 检查 root 用户
            local root_pods=$(kubectl get pods --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.spec.containers[].securityContext.runAsNonRoot!=true and .spec.containers[].securityContext.runAsUser==0) | .metadata.namespace + "/" + .metadata.name' | wc -l)
            if [ "$root_pods" -eq 0 ]; then
                echo -e "  ${GREEN}✓${NC} 无 root 用户容器"
                ((passed++))
            else
                echo -e "  ${RED}✗${NC} 发现 $root_pods 个 root 用户容器"
                ((failed++))
            fi
            
            echo ""
            echo -e "${YELLOW}5. 网络策略检查${NC}"
            echo "----------------------------------------"
            
            # 检查默认拒绝策略
            local default_deny=$(kubectl get networkpolicies --all-namespaces -o json 2>/dev/null | jq -r '.items[].spec.podSelector.matchLabels | to_entries | .[].value' | grep -c "default-deny" || echo 0)
            if [ "$default_deny" -gt 0 ]; then
                echo -e "  ${GREEN}✓${NC} 存在默认拒绝网络策略"
                ((passed++))
            else
                echo -e "  ${YELLOW}⚠${NC} 建议添加默认拒绝策略"
                ((warnings++))
            fi
            
            echo ""
            echo -e "${YELLOW}6. 安全上下文检查${NC}"
            echo "----------------------------------------"
            
            # 检查只读根文件系统
            local readonly_pods=$(kubectl get pods --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.spec.containers[].securityContext.readOnlyRootFilesystem==true) | .metadata.namespace + "/" + .metadata.name' | wc -l)
            echo "  使用只读根文件系统的 Pod: $readonly_pods"
            
            # 检查资源限制
            local no_limits=$(kubectl get deployments --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.spec.template.spec.containers[].resources.limits==null) | .metadata.namespace + "/" + .metadata.name' | wc -l)
            if [ "$no_limits" -eq 0 ]; then
                echo -e "  ${GREEN}✓${NC} 所有部署都配置了资源限制"
                ((passed++))
            else
                echo -e "  ${YELLOW}⚠${NC} $no_limits 个部署缺少资源限制"
                ((warnings++))
            fi
            ;;
            
        *)
            print_error "未知框架: $framework"
            return 1
            ;;
    esac
    
    # JSON 报告尾
    echo "" >> "$report_file"
    echo "  ]," >> "$report_file"
    echo "  \"summary\": {" >> "$report_file"
    echo "    \"passed\": $passed," >> "$report_file"
    echo "    \"failed\": $failed," >> "$report_file"
    echo "    \"warnings\": $warnings" >> "$report_file"
    echo "  }" >> "$report_file"
    echo "}" >> "$report_file"
    
    echo ""
    echo "==========================================="
    echo -e "检查完成: ${GREEN}通过 $passed${NC} | ${RED}失败 $failed${NC} | ${YELLOW}警告 $warnings${NC}"
    echo "==========================================="
    echo ""
    
    local compliance_rate=0
    if [ $((passed + failed + warnings)) -gt 0 ]; then
        compliance_rate=$((passed * 100 / (passed + failed + warnings)))
    fi
    
    echo -e "合规率: ${compliance_rate}%"
    
    if [ "$failed" -gt 0 ]; then
        echo ""
        echo -e "${RED}⚠️  发现 $failed 项不合规，请尽快修复${NC}"
    fi
    
    echo ""
    echo "报告已保存: $report_file"
}

# 生成报告
generate_report() {
    local framework=$1
    
    if [ -z "$framework" ]; then
        framework="cis-benchmark"
    fi
    
    init_compliance
    
    local report_file="$COMPLIANCE_REPORT_DIR/compliance_report_${framework}_$(date +%Y%m%d).html"
    
    clear
    print_header "生成合规报告: $framework"
    
    # 执行检查并生成报告
    check_compliance "$framework" | tee >(tail -20 > /dev/null)
    
    # 转换为 HTML 报告
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>合规报告 - $framework - $(date)</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .summary { background: #f0f0f0; padding: 15px; border-radius: 5px; }
        .passed { color: green; }
        .failed { color: red; }
        .warnings { color: orange; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
    </style>
</head>
<body>
    <h1>合规性报告</h1>
    <div class="summary">
        <p><strong>框架:</strong> $framework</p>
        <p><strong>生成时间:</strong> $(date)</p>
        <p><strong>合规率:</strong> <span class="passed">$compliance_rate%</span></p>
    </div>
    <h2>检查详情</h2>
    <p>完整报告请查看 JSON 文件</p>
</body>
</html>
EOF
    
    print_success "HTML 报告已生成: $report_file"
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
        check)
            check_compliance "$@"
            ;;
        list)
            list_frameworks
            ;;
        rules)
            show_rules "$@"
            ;;
        report)
            generate_report "$@"
            ;;
        diff)
            echo "对比框架功能开发中..."
            ;;
        add-rule)
            echo "添加自定义规则功能开发中..."
            ;;
        export)
            echo "导出配置功能开发中..."
            ;;
        import)
            echo "导入配置功能开发中..."
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