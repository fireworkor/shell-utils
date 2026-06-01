#!/bin/bash
# 多云管理工具

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/logging.sh"

# 配置文件
CONFIG_FILE="$SCRIPT_DIR/config/cloud-accounts.conf"

show_help() {
    cat << EOF
${GREEN}========================================${NC}
${GREEN}   多云管理工具 v1.0${NC}
${GREEN}========================================${NC}

${YELLOW}使用方法：${NC}
  $0 <命令> [选项]

${YELLOW}云账户管理：${NC}
  list              列出已配置的云账户
  add               添加云账户
  remove <名称>     删除云账户
  set-default <名称> 设置默认账户

${YELLOW}AWS 操作：${NC}
  aws <账户> s3 list              列出 S3 桶
  aws <账户> ec2 list            列出 EC2 实例
  aws <账户> ec2 start <id>     启动实例
  aws <账户> ec2 stop <id>      停止实例
  aws <账户> costs              查看费用

${YELLOW}阿里云操作：${NC}
  aliyun <账户> ecs list         列出 ECS 实例
  aliyun <账户> ecs start <id>   启动实例
  aliyun <账户> ecs stop <id>    停止实例
  aliyun <账户> costs            查看费用

${YELLOW}腾讯云操作：${NC}
  tencent <账户> cvm list        列出 CVM 实例
  tencent <账户> cvm start <id>  启动实例
  tencent <账户> cvm stop <id>   停止实例
  tencent <账户> costs           查看费用

${YELLOW}通用操作：${NC}
  all costs            查看所有账户费用
  all instances        列出所有实例
  sync                同步配置

${YELLOW}示例：${NC}
  $0 list
  $0 add aws
  $0 aws my-aws ec2 list
  $0 all costs

EOF
}

# 创建配置目录
init_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    if [ ! -f "$CONFIG_FILE" ]; then
        touch "$CONFIG_FILE"
    fi
}

# 列出账户
list_accounts() {
    init_config
    print_header "已配置的云账户"
    
    if [ ! -s "$CONFIG_FILE" ]; then
        print_info "暂无配置账户"
        return
    fi
    
    echo ""
    echo -e "${YELLOW}名称         类型     默认${NC}"
    echo "----------------------------------------"
    
    local default_account=$(get_config "default_account")
    
    while IFS='=' read -r name type credentials; do
        [ -z "$name" ] && continue
        [ "$name" = "#"* ] && continue
        
        local is_default=""
        if [ "$name" = "$default_account" ]; then
            is_default="${GREEN}✓${NC}"
        fi
        
        echo -e "$name         $type     $is_default"
    done < "$CONFIG_FILE"
}

# 添加账户
add_account() {
    local type=$1
    
    if [ -z "$type" ]; then
        echo "请选择云服务商:"
        echo "1. AWS"
        echo "2. 阿里云"
        echo "3. 腾讯云"
        read -p "请输入选项: " choice
        
        case $choice in
            1) type="aws" ;;
            2) type="aliyun" ;;
            3) type="tencent" ;;
            *) print_error "无效选项"; return 1 ;;
        esac
    fi
    
    clear
    print_header "添加 $type 账户"
    
    read -p "账户名称: " name
    read -p "Access Key ID: " access_key
    read -s -p "Access Key Secret: " secret
    echo ""
    read -p "默认区域 (默认: us-east-1): " region
    region=${region:-us-east-1}
    
    # 保存配置
    echo "$name=$type:$access_key:$secret:$region" >> "$CONFIG_FILE"
    
    print_success "账户 $name 添加成功"
}

# 删除账户
remove_account() {
    local name=$1
    
    if [ -z "$name" ]; then
        print_error "请指定账户名称"
        return 1
    fi
    
    if grep -q "^$name=" "$CONFIG_FILE"; then
        sed -i "/^$name=/d" "$CONFIG_FILE"
        print_success "账户 $name 已删除"
    else
        print_error "账户 $name 不存在"
    fi
}

# 设置默认账户
set_default() {
    local name=$1
    
    if [ -z "$name" ]; then
        print_error "请指定账户名称"
        return 1
    fi
    
    set_config "default_account" "$name"
    print_success "默认账户已设置为: $name"
}

# 获取账户信息
get_account() {
    local name=$1
    grep "^$name=" "$CONFIG_FILE" | head -1
}

# AWS 操作
aws_operation() {
    local account=$1
    shift
    local service=$1
    shift
    local action=$1
    shift
    
    init_config
    
    # 如果没有指定账户，使用默认账户
    if [ -z "$account" ]; then
        account=$(get_config "default_account")
    fi
    
    local account_info=$(get_account "$account")
    if [ -z "$account_info" ]; then
        print_error "账户 $account 不存在"
        return 1
    fi
    
    IFS=':' read -r name type access_key secret region <<< "$account_info"
    
    export AWS_ACCESS_KEY_ID="$access_key"
    export AWS_SECRET_ACCESS_KEY="$secret"
    export AWS_DEFAULT_REGION="$region"
    
    case "$service" in
        s3)
            case "$action" in
                list)
                    log_info "列出 S3 桶..."
                    if command -v aws &> /dev/null; then
                        aws s3 ls
                    else
                        print_error "AWS CLI 未安装"
                        echo "安装命令: pip3 install awscli"
                    fi
                    ;;
                *) print_error "未知 S3 操作: $action" ;;
            esac
            ;;
        ec2)
            case "$action" in
                list)
                    log_info "列出 EC2 实例..."
                    if command -v aws &> /dev/null; then
                        aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,PublicIpAddress,Tags[?Key==`Name`]|[0].Value]' --output table
                    else
                        print_error "AWS CLI 未安装"
                    fi
                    ;;
                start|stop)
                    local instance_id=$1
                    if [ -z "$instance_id" ]; then
                        print_error "请指定实例 ID"
                        return 1
                    fi
                    log_info "$action 实例 $instance_id..."
                    aws ec2 "$action-instances" --instance-ids "$instance_id"
                    ;;
                *) print_error "未知 EC2 操作: $action" ;;
            esac
            ;;
        costs)
            log_info "获取 AWS 费用报告..."
            if command -v aws &> /dev/null; then
                aws ce get-cost-and-usage --time-period Start=$(date -d '30 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) --granularity MONTHLY --metrics BlendedCost
            else
                print_error "AWS CLI 未安装"
            fi
            ;;
        *) print_error "未知 AWS 服务: $service" ;;
    esac
}

# 阿里云操作
aliyun_operation() {
    local account=$1
    shift
    local service=$1
    shift
    local action=$1
    shift
    
    init_config
    
    if [ -z "$account" ]; then
        account=$(get_config "default_account")
    fi
    
    local account_info=$(get_account "$account")
    if [ -z "$account_info" ]; then
        print_error "账户 $account 不存在"
        return 1
    fi
    
    IFS=':' read -r name type access_key secret region <<< "$account_info"
    
    export ALIBABA_CLOUD_ACCESS_KEY_ID="$access_key"
    export ALIBABA_CLOUD_ACCESS_KEY_SECRET="$secret"
    export ALIBABA_CLOUD_REGION="$region"
    
    case "$service" in
        ecs)
            case "$action" in
                list)
                    log_info "列出 ECS 实例..."
                    if command -v aliyun &> /dev/null; then
                        aliyun ecs DescribeInstances
                    else
                        print_error "阿里云 CLI 未安装"
                        echo "安装命令: pip3 install aliyun-python-sdk-core"
                    fi
                    ;;
                start|stop|restart)
                    local instance_id=$1
                    if [ -z "$instance_id" ]; then
                        print_error "请指定实例 ID"
                        return 1
                    fi
                    log_info "$action 实例 $instance_id..."
                    aliyun ecs "$action"Instances --InstanceId "$instance_id"
                    ;;
                *) print_error "未知 ECS 操作: $action" ;;
            esac
            ;;
        costs)
            log_info "获取阿里云费用报告..."
            if command -v aliyun &> /dev/null; then
                aliyun bssapi QueryBillOverview
            else
                print_error "阿里云 CLI 未安装"
            fi
            ;;
        *) print_error "未知阿里云服务: $service" ;;
    esac
}

# 腾讯云操作
tencent_operation() {
    local account=$1
    shift
    local service=$1
    shift
    local action=$1
    shift
    
    init_config
    
    if [ -z "$account" ]; then
        account=$(get_config "default_account")
    fi
    
    local account_info=$(get_account "$account")
    if [ -z "$account_info" ]; then
        print_error "账户 $account 不存在"
        return 1
    fi
    
    IFS=':' read -r name type access_key secret region <<< "$account_info"
    
    export TENCENTCLOUD_SECRET_ID="$access_key"
    export TENCENTCLOUD_SECRET_KEY="$secret"
    export TENCENTCLOUD_REGION="$region"
    
    case "$service" in
        cvm)
            case "$action" in
                list)
                    log_info "列出 CVM 实例..."
                    if command -v tccli &> /dev/null; then
                        tccli cvm DescribeInstances
                    else
                        print_error "腾讯云 CLI 未安装"
                        echo "安装命令: pip3 install tencentcloud-sdk-python"
                    fi
                    ;;
                start|stop)
                    local instance_id=$1
                    if [ -z "$instance_id" ]; then
                        print_error "请指定实例 ID"
                        return 1
                    fi
                    log_info "$action 实例 $instance_id..."
                    tccli cvm "$action"Instances --InstanceIds "[\"$instance_id\"]"
                    ;;
                *) print_error "未知 CVM 操作: $action" ;;
            esac
            ;;
        costs)
            log_info "获取腾讯云费用报告..."
            if command -v tccli &> /dev/null; then
                tccli billing QueryBillSummary
            else
                print_error "腾讯云 CLI 未安装"
            fi
            ;;
        *) print_error "未知腾讯云服务: $service" ;;
    esac
}

# 列出所有实例
list_all_instances() {
    init_config
    
    print_header "所有云账户实例"
    
    if [ ! -s "$CONFIG_FILE" ]; then
        print_info "暂无配置账户"
        return
    fi
    
    while IFS='=' read -r line; do
        [ -z "$line" ] && continue
        [ "$line" = "#"* ] && continue
        
        IFS=':' read -r name type access_key secret region <<< "$line"
        
        echo ""
        echo -e "${YELLOW}账户: $name ($type)${NC}"
        echo "----------------------------------------"
        
        case "$type" in
            aws)
                if command -v aws &> /dev/null; then
                    aws_operation "$name" ec2 list 2>/dev/null || echo "无法获取实例列表"
                fi
                ;;
            aliyun)
                if command -v aliyun &> /dev/null; then
                    aliyun_operation "$name" ecs list 2>/dev/null || echo "无法获取实例列表"
                fi
                ;;
            tencent)
                if command -v tccli &> /dev/null; then
                    tencent_operation "$name" cvm list 2>/dev/null || echo "无法获取实例列表"
                fi
                ;;
        esac
    done < "$CONFIG_FILE"
}

# 费用汇总
show_all_costs() {
    init_config
    
    print_header "所有云账户费用"
    
    if [ ! -s "$CONFIG_FILE" ]; then
        print_info "暂无配置账户"
        return
    fi
    
    echo ""
    
    while IFS='=' read -r line; do
        [ -z "$line" ] && continue
        [ "$line" = "#"* ] && continue
        
        IFS=':' read -r name type access_key secret region <<< "$line"
        
        echo -e "${YELLOW}账户: $name ($type)${NC}"
        echo "----------------------------------------"
        
        case "$type" in
            aws)
                aws_operation "$name" costs 2>/dev/null || echo "无法获取费用"
                ;;
            aliyun)
                aliyun_operation "$name" costs 2>/dev/null || echo "无法获取费用"
                ;;
            tencent)
                tencent_operation "$name" costs 2>/dev/null || echo "无法获取费用"
                ;;
        esac
        
        echo ""
    done < "$CONFIG_FILE"
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
            list_accounts
            ;;
        add)
            add_account "$@"
            ;;
        remove)
            remove_account "$1"
            ;;
        set-default)
            set_default "$1"
            ;;
        aws)
            aws_operation "$@"
            ;;
        aliyun)
            aliyun_operation "$@"
            ;;
        tencent)
            tencent_operation "$@"
            ;;
        all)
            case $1 in
                costs)
                    show_all_costs
                    ;;
                instances)
                    list_all_instances
                    ;;
                *)
                    print_error "未知操作: all $1"
                    ;;
            esac
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