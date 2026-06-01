#!/bin/bash
# 自动化部署平台

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/logging.sh"

# 配置文件
DEPLOY_CONFIG="$SCRIPT_DIR/config/deployments.conf"
DEPLOY_LOG_DIR="$SCRIPT_DIR/logs/deployments"
TEMPLATE_DIR="$SCRIPT_DIR/templates"

# 初始化
init_deploy() {
    mkdir -p "$DEPLOY_LOG_DIR" "$TEMPLATE_DIR" "$(dirname "$DEPLOY_CONFIG")"
    [ ! -f "$DEPLOY_CONFIG" ] && touch "$DEPLOY_CONFIG"
}

show_help() {
    cat << EOF
${GREEN}========================================${NC}
${GREEN}   自动化部署平台 v1.0${NC}
${GREEN}========================================${NC}

${YELLOW}使用方法：${NC}
  $0 <命令> [选项]

${YELLOW}应用管理：${NC}
  list                列出已部署的应用
  deploy <应用>       部署应用
  scale <应用> <数量> 扩缩容
  rollback <应用>     回滚到上一版本
  status <应用>       查看应用状态
  delete <应用>       删除应用

${YELLOW}模板管理：${NC}
  templates           列出可用模板
  template create     创建自定义模板
  template apply      应用模板

${YELLOW}部署配置：${NC}
  config <应用>       配置应用参数
  env <应用>          查看环境变量

${YELLOW}示例：${NC}
  $0 list
  $0 deploy myapp --template nodejs
  $0 scale myapp 3
  $0 rollback myapp
  $0 status myapp

EOF
}

# 列出已部署应用
list_deployments() {
    init_deploy
    print_header "已部署的应用"
    
    if [ ! -s "$DEPLOY_CONFIG" ]; then
        print_info "暂无部署记录"
        return
    fi
    
    echo ""
    echo -e "${YELLOW}名称         类型         副本  状态     端口${NC}"
    echo "--------------------------------------------------------"
    
    while IFS='=' read -r line; do
        [ -z "$line" ] && continue
        [ "$line" = "#"* ] && continue
        
        IFS=':' read -r name type replicas port image namespace status <<< "$line"
        
        echo -e "$name         $type         $replicas  $status    $port"
    done < "$DEPLOY_CONFIG"
}

# 部署应用
deploy_app() {
    local app_name=$1
    shift
    local template="default"
    local namespace="default"
    local replicas=1
    local port=80
    local image=""
    local env_vars=""
    
    # 解析参数
    while [ $# -gt 0 ]; do
        case $1 in
            --template)
                template=$2
                shift 2
                ;;
            --namespace)
                namespace=$2
                shift 2
                ;;
            --replicas)
                replicas=$2
                shift 2
                ;;
            --port)
                port=$2
                shift 2
                ;;
            --image)
                image=$2
                shift 2
                ;;
            --env)
                env_vars=$2
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    if [ -z "$app_name" ]; then
        print_error "请指定应用名称"
        return 1
    fi
    
    init_deploy
    clear
    print_header "部署应用: $app_name"
    
    # 检查是否已存在
    if grep -q "^$app_name=" "$DEPLOY_CONFIG"; then
        print_warn "应用 $app_name 已存在，将执行更新"
    fi
    
    log_info "使用模板: $template"
    log_info "副本数: $replicas"
    log_info "端口: $port"
    log_info "命名空间: $namespace"
    
    # 选择镜像
    if [ -z "$image" ]; then
        image=$(select_image "$template")
    fi
    
    log_info "使用镜像: $image"
    
    # 检查 kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl 未安装"
        return 1
    fi
    
    # 创建部署
    log_info "创建 Kubernetes 部署..."
    
    kubectl create deployment "$app_name" \
        --image="$image" \
        --replicas="$replicas" \
        --namespace="$namespace" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # 创建服务
    log_info "创建服务..."
    kubectl expose deployment "$app_name" \
        --type=NodePort \
        --port="$port" \
        --namespace="$namespace" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # 等待就绪
    log_info "等待部署就绪..."
    kubectl rollout status deployment/"$app_name" -n "$namespace" --timeout=300s
    
    # 保存配置
    local timestamp=$(date +%s)
    echo "$app_name=$template:$replicas:$port:$image:$namespace:running:$timestamp" >> "$DEPLOY_CONFIG"
    
    # 记录日志
    local log_file="$DEPLOY_LOG_DIR/${app_name}_${timestamp}.log"
    echo "部署时间: $(date)" > "$log_file"
    echo "镜像: $image" >> "$log_file"
    echo "副本数: $replicas" >> "$log_file"
    echo "状态: 成功" >> "$log_file"
    
    # 获取访问地址
    local node_port=$(kubectl get svc "$app_name" -n "$namespace" -o jsonpath='{.spec.ports[0].nodePort}')
    
    print_success "应用 $app_name 部署成功！"
    echo ""
    echo "访问地址: http://<node-ip>:$node_port"
    echo "内部地址: http://$app_name.$namespace.svc.cluster.local:$port"
}

# 选择镜像
select_image() {
    local template=$1
    
    local images=()
    
    case $template in
        nodejs|node)
            images=("nginx:latest" "node:18-alpine" "node:20-alpine")
            ;;
        python)
            images=("python:3.11-alpine" "python:3.10-slim")
            ;;
        java)
            images=("openjdk:17-slim" "openjdk:11-slim" "eclipse-temurin:17-alpine")
            ;;
        golang|go)
            images=("golang:1.21-alpine" "golang:1.20-alpine")
            ;;
        nginx)
            images=("nginx:latest" "nginx:alpine")
            ;;
        mysql)
            images=("mysql:8.0" "mysql:5.7")
            ;;
        postgres|postgresql)
            images=("postgres:15" "postgres:14")
            ;;
        redis)
            images=("redis:7-alpine" "redis:6-alpine")
            ;;
        mongo|mongodb)
            images=("mongo:6" "mongo:5")
            ;;
        default|*)
            images=("nginx:latest" "alpine:latest")
            ;;
    esac
    
    echo "选择镜像:"
    local i=1
    for img in "${images[@]}"; do
        echo "  $i. $img"
        ((i++))
    done
    
    read -p "选择镜像 [1]: " choice
    choice=${choice:-1}
    
    echo "${images[$((choice-1))]}"
}

# 扩缩容
scale_app() {
    local app_name=$1
    local replicas=$2
    
    if [ -z "$app_name" ] || [ -z "$replicas" ]; then
        print_error "请指定应用名称和副本数"
        return 1
    fi
    
    clear
    print_header "扩缩容: $app_name -> $replicas 副本"
    
    local namespace="default"
    local line=$(grep "^$app_name=" "$DEPLOY_CONFIG" 2>/dev/null | head -1)
    if [ -n "$line" ]; then
        IFS=':' read -r name type old_replicas port image namespace status timestamp <<< "$line"
    fi
    
    kubectl scale deployment "$app_name" --replicas="$replicas" -n "$namespace"
    
    # 更新配置
    if [ -n "$line" ]; then
        sed -i "s/^$app_name=.*/$app_name=$type:$replicas:$port:$image:$namespace:$status:$timestamp/" "$DEPLOY_CONFIG"
    fi
    
    print_success "已缩放到 $replicas 副本"
}

# 回滚
rollback_app() {
    local app_name=$1
    
    if [ -z "$app_name" ]; then
        print_error "请指定应用名称"
        return 1
    fi
    
    clear
    print_header "回滚应用: $app_name"
    
    local namespace="default"
    local line=$(grep "^$app_name=" "$DEPLOY_CONFIG" 2>/dev/null | head -1)
    if [ -n "$line" ]; then
        IFS=':' read -r name type replicas port image namespace status timestamp <<< "$line"
    fi
    
    log_info "查看部署历史..."
    kubectl rollout history deployment/"$app_name" -n "$namespace"
    
    echo ""
    read -p "输入要回滚到的版本 (留空回滚到上一版本): " revision
    
    if [ -z "$revision" ]; then
        log_info "回滚到上一版本..."
        kubectl rollout undo deployment/"$app_name" -n "$namespace"
    else
        log_info "回滚到版本 $revision..."
        kubectl rollout undo deployment/"$app_name" -n "$namespace" --to-revision="$revision"
    fi
    
    kubectl rollout status deployment/"$app_name" -n "$namespace" --timeout=300s
    
    print_success "回滚完成"
}

# 查看状态
status_app() {
    local app_name=$1
    
    if [ -z "$app_name" ]; then
        print_error "请指定应用名称"
        return 1
    fi
    
    clear
    print_header "应用状态: $app_name"
    
    local namespace="default"
    local line=$(grep "^$app_name=" "$DEPLOY_CONFIG" 2>/dev/null | head -1)
    if [ -n "$line" ]; then
        IFS=':' read -r name type replicas port image namespace status timestamp <<< "$line"
    fi
    
    echo ""
    echo -e "${YELLOW}部署信息:${NC}"
    kubectl get deployment "$app_name" -n "$namespace" -o wide
    
    echo ""
    echo -e "${YELLOW}Pod 信息:${NC}"
    kubectl get pods -l "app=$app_name" -n "$namespace" -o wide
    
    echo ""
    echo -e "${YELLOW}服务信息:${NC}"
    kubectl get svc "$app_name" -n "$namespace"
    
    echo ""
    echo -e "${YELLOW}资源使用:${NC}"
    kubectl top pods -l "app=$app_name" -n "$namespace" 2>/dev/null || echo "metrics-server 未安装"
    
    echo ""
    echo -e "${YELLOW}最近日志:${NC}"
    kubectl logs deployment/"$app_name" -n "$namespace" --tail=10
}

# 删除应用
delete_app() {
    local app_name=$1
    
    if [ -z "$app_name" ]; then
        print_error "请指定应用名称"
        return 1
    fi
    
    local namespace="default"
    local line=$(grep "^$app_name=" "$DEPLOY_CONFIG" 2>/dev/null | head -1)
    if [ -n "$line" ]; then
        IFS=':' read -r name type replicas port image namespace status timestamp <<< "$line"
    fi
    
    if confirm "确定要删除应用 $app_name 吗？"; then
        kubectl delete deployment "$app_name" -n "$namespace"
        kubectl delete svc "$app_name" -n "$namespace"
        
        # 移除配置
        sed -i "/^$app_name=/d" "$DEPLOY_CONFIG"
        
        print_success "应用 $app_name 已删除"
    else
        print_info "取消删除"
    fi
}

# 列出模板
list_templates() {
    print_header "可用部署模板"
    
    echo ""
    echo -e "${YELLOW}模板名称        说明${NC}"
    echo "-----------------------------------"
    echo -e "nodejs           Node.js 应用"
    echo -e "python           Python 应用"
    echo -e "java             Java 应用"
    echo -e "golang           Go 应用"
    echo -e "nginx            Nginx 静态网站"
    echo -e "mysql            MySQL 数据库"
    echo -e "postgresql       PostgreSQL 数据库"
    echo -e "redis            Redis 缓存"
    echo -e "mongodb          MongoDB 数据库"
    echo -e "custom           自定义模板"
}

# 查看环境变量
show_env() {
    local app_name=$1
    
    if [ -z "$app_name" ]; then
        print_error "请指定应用名称"
        return 1
    fi
    
    clear
    print_header "环境变量: $app_name"
    
    local namespace="default"
    
    echo ""
    kubectl get deployment "$app_name" -n "$namespace" -o jsonpath='{.spec.template.spec.containers[0].env}' | jq '.' 2>/dev/null || \
    kubectl get deployment "$app_name" -n "$namespace" -o jsonpath='{.spec.template.spec.containers[0].envFrom}' | jq '.' 2>/dev/null || \
    echo "无环境变量配置"
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
        list)
            list_deployments
            ;;
        deploy)
            deploy_app "$@"
            ;;
        scale)
            scale_app "$1" "$2"
            ;;
        rollback)
            rollback_app "$1"
            ;;
        status)
            status_app "$1"
            ;;
        delete|remove)
            delete_app "$1"
            ;;
        templates)
            list_templates
            ;;
        env)
            show_env "$1"
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