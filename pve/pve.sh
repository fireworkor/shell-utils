#!/bin/bash
# PVE (Proxmox Virtual Environment) 部署脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logging.sh"

# 配置文件
PVE_CONFIG="$SCRIPT_DIR/config/pve.conf"

show_help() {
    cat << EOF
${GREEN}========================================${NC}
${GREEN}   PVE 部署工具 v1.0${NC}
${GREEN}========================================${NC}

${YELLOW}使用方法：${NC}
  $0 <命令> [选项]

${YELLOW}配置命令：${NC}
  config              配置PVE连接信息
  list                列出当前配置

${YELLOW}VM管理（在PVE控制台操作）：${NC}
  create              显示VM创建说明
  start <ID>          显示VM启动说明
  stop <ID>           显示VM停止说明
  destroy <ID>        显示VM销毁说明
  status <ID>         显示VM状态查看说明

${YELLOW}部署命令：${NC}
  deploy <ID> <软件>...  在VM上部署软件
                        支持的软件: nginx, mysql, mariadb, php, redis, 
                        docker, nodejs, python, java, postgresql, 
                        mongodb, elasticsearch, kubernetes

${YELLOW}支持的操作系统：${NC}
  centos7, centos8, ubuntu2004, ubuntu2204, ubuntu2404

${YELLOW}示例：${NC}
  $0 config
  $0 deploy 100 nginx mysql
  $0 deploy 101 docker redis

EOF
}

# 初始化配置
init_pve_config() {
    mkdir -p "$(dirname "$PVE_CONFIG")" 2>/dev/null || true
}

# 配置PVE连接
config_pve() {
    clear
    print_header "配置PVE信息"
    
    echo ""
    echo "请输入PVE相关信息（用于记录，非必需）："
    echo ""
    
    read -p "PVE节点地址: " pve_host
    read -p "PVE用户 (默认: root): " pve_user
    read -p "PVE节点名称 (默认: pve): " pve_node
    echo ""
    read -p "VM名称 (可选): " vm_name
    read -p "VM ID (可选): " vm_id
    echo ""
    echo "请选择常用操作系统："
    echo "  1. CentOS 7"
    echo "  2. CentOS 8"
    echo "  3. Ubuntu 20.04"
    echo "  4. Ubuntu 22.04"
    echo "  5. Ubuntu 24.04"
    echo ""
    read -p "请选择 [1-5]: " os_choice
    
    local os_type="ubuntu2204"
    case $os_choice in
        1) os_type="centos7" ;;
        2) os_type="centos8" ;;
        3) os_type="ubuntu2004" ;;
        4) os_type="ubuntu2204" ;;
        5) os_type="ubuntu2404" ;;
    esac
    
    read -p "CPU核心数 (默认: 2): " vm_cpus
    read -p "内存大小 MB (默认: 2048): " vm_memory
    read -p "磁盘大小 GB (默认: 20): " vm_disk
    read -p "网络桥接 (默认: vmbr0): " vm_bridge
    
    # 保存配置
    cat > "$PVE_CONFIG" << EOF
pve_host="$pve_host"
pve_user="${pve_user:-root}"
pve_node="${pve_node:-pve}"
vm_name="$vm_name"
vm_id="$vm_id"
vm_os="$os_type"
vm_cpus="${vm_cpus:-2}"
vm_memory="${vm_memory:-2048}"
vm_disk="${vm_disk:-20}"
vm_bridge="${vm_bridge:-vmbr0}"
EOF
    
    print_success "PVE配置已保存到: $PVE_CONFIG"
}

# 列出当前配置
list_config() {
    print_header "当前PVE配置"
    if [ -f "$PVE_CONFIG" ]; then
        echo ""
        cat "$PVE_CONFIG"
        echo ""
    else
        print_info "没有保存的配置"
    fi
}

# 创建VM
create_vm() {
    print_header "创建VM"
    echo "注意：此脚本需要在PVE节点上运行，或者您需要先在PVE控制台中手动创建VM"
    echo ""
    echo "在PVE控制台中创建VM的步骤："
    echo "1. 登录PVE Web界面"
    echo "2. 点击 'Create CT' (容器) 或 'Create VM' (虚拟机)"
    echo "3. 选择操作系统模板（CentOS 7/8 或 Ubuntu）"
    echo "4. 配置资源（CPU、内存、磁盘）"
    echo "5. 配置网络，确保SSH可以访问"
    echo "6. 完成创建并启动"
    echo ""
    echo "VM创建完成后，请使用以下命令部署软件："
    echo "$0 deploy <VM_ID> <software1> <software2> ..."
    echo ""
    
    if [ -f "$PVE_CONFIG" ]; then
        echo "当前配置："
        cat "$PVE_CONFIG"
    fi
}

# 部署软件到VM
deploy_to_vm() {
    local vm_id="$1"
    shift
    local software_list="$@"
    
    if [ -z "$vm_id" ]; then
        print_error "请提供VM ID"
        show_help
        exit 1
    fi
    
    print_header "部署软件到VM ID: $vm_id"
    
    echo "请输入VM的IP地址（可在PVE控制台中查看）："
    read -p "VM IP: " vm_ip
    
    if [ -z "$vm_ip" ]; then
        print_error "VM IP地址不能为空"
        return 1
    fi
    
    log_info "VM的IP地址: $vm_ip"
    echo ""
    
    # 等待SSH可用
    log_info "等待SSH服务可用..."
    local ssh_available=0
    for i in 1 2 3 4 5 6 7 8 9 10; do
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes root@$vm_ip "echo test" 2>/dev/null; then
            ssh_available=1
            log_success "SSH连接成功"
            break
        fi
        echo -n "."
        sleep 10
    done
    
    if [ $ssh_available -eq 0 ]; then
        print_error "无法连接到VM的SSH服务"
        echo "请确保："
        echo "1. VM已启动"
        echo "2. IP地址正确"
        echo "3. 防火墙允许SSH连接"
        echo "4. 使用root用户或有sudo权限的用户"
        return 1
    fi
    
    echo ""
    if [ -z "$software_list" ]; then
        print_info "没有指定要部署的软件"
        echo "支持的软件: nginx, mysql, mariadb, php, redis, docker, nodejs, python, java, postgresql, mongodb, elasticsearch, kubernetes"
        return 0
    fi
    
    log_info "将在VM上部署软件: $software_list"
    echo ""
    
    local success=0
    
    for software in $software_list; do
        echo "=========================================="
        echo "正在部署: $software"
        echo "=========================================="
        
        case $software in
            nginx)
                ssh -o StrictHostKeyChecking=no root@$vm_ip << 'ENDSSH'
apt-get update && apt-get install -y nginx
systemctl start nginx
systemctl enable nginx
echo "Nginx安装成功"
ENDSSH
                if [ $? -eq 0 ]; then
                    success=$((success + 1))
                    print_success "$software 部署成功"
                fi
                ;;
            mysql)
                ssh -o StrictHostKeyChecking=no root@$vm_ip << 'ENDSSH'
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
systemctl start mysql
systemctl enable mysql
echo "MySQL安装成功"
ENDSSH
                if [ $? -eq 0 ]; then
                    success=$((success + 1))
                    print_success "$software 部署成功"
                fi
                ;;
            mariadb)
                ssh -o StrictHostKeyChecking=no root@$vm_ip << 'ENDSSH'
apt-get update && apt-get install -y mariadb-server
systemctl start mariadb
systemctl enable mariadb
echo "MariaDB安装成功"
ENDSSH
                if [ $? -eq 0 ]; then
                    success=$((success + 1))
                    print_success "$software 部署成功"
                fi
                ;;
            php)
                ssh -o StrictHostKeyChecking=no root@$vm_ip << 'ENDSSH'
apt-get update && apt-get install -y php-fpm php-mysql php-cli
echo "PHP安装成功"
ENDSSH
                if [ $? -eq 0 ]; then
                    success=$((success + 1))
                    print_success "$software 部署成功"
                fi
                ;;
            redis)
                ssh -o StrictHostKeyChecking=no root@$vm_ip << 'ENDSSH'
apt-get update && apt-get install -y redis-server
systemctl start redis
systemctl enable redis
echo "Redis安装成功"
ENDSSH
                if [ $? -eq 0 ]; then
                    success=$((success + 1))
                    print_success "$software 部署成功"
                fi
                ;;
            docker)
                ssh -o StrictHostKeyChecking=no root@$vm_ip << 'ENDSSH'
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
systemctl start docker
systemctl enable docker
echo "Docker安装成功"
ENDSSH
                if [ $? -eq 0 ]; then
                    success=$((success + 1))
                    print_success "$software 部署成功"
                fi
                ;;
            nodejs)
                ssh -o StrictHostKeyChecking=no root@$vm_ip << 'ENDSSH'
apt-get update && apt-get install -y nodejs npm
echo "Node.js安装成功"
ENDSSH
                if [ $? -eq 0 ]; then
                    success=$((success + 1))
                    print_success "$software 部署成功"
                fi
                ;;
            python)
                ssh -o StrictHostKeyChecking=no root@$vm_ip << 'ENDSSH'
apt-get update && apt-get install -y python3 python3-pip
echo "Python安装成功"
ENDSSH
                if [ $? -eq 0 ]; then
                    success=$((success + 1))
                    print_success "$software 部署成功"
                fi
                ;;
            java)
                ssh -o StrictHostKeyChecking=no root@$vm_ip << 'ENDSSH'
apt-get update && apt-get install -y openjdk-11-jdk
echo "Java安装成功"
ENDSSH
                if [ $? -eq 0 ]; then
                    success=$((success + 1))
                    print_success "$software 部署成功"
                fi
                ;;
            postgresql)
                ssh -o StrictHostKeyChecking=no root@$vm_ip << 'ENDSSH'
apt-get update && apt-get install -y postgresql postgresql-contrib
systemctl start postgresql
systemctl enable postgresql
echo "PostgreSQL安装成功"
ENDSSH
                if [ $? -eq 0 ]; then
                    success=$((success + 1))
                    print_success "$software 部署成功"
                fi
                ;;
            mongodb)
                ssh -o StrictHostKeyChecking=no root@$vm_ip << 'ENDSSH'
apt-get update && apt-get install -y mongodb || true
systemctl start mongodb || true
systemctl enable mongodb || true
echo "MongoDB安装完成"
ENDSSH
                if [ $? -eq 0 ]; then
                    success=$((success + 1))
                    print_success "$software 部署成功"
                fi
                ;;
            elasticsearch)
                ssh -o StrictHostKeyChecking=no root@$vm_ip << 'ENDSSH'
apt-get update && apt-get install -y apt-transport-https
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic.list
apt-get update
apt-get install -y elasticsearch
systemctl start elasticsearch
systemctl enable elasticsearch
echo "Elasticsearch安装成功"
ENDSSH
                if [ $? -eq 0 ]; then
                    success=$((success + 1))
                    print_success "$software 部署成功"
                fi
                ;;
            kubernetes)
                ssh -o StrictHostKeyChecking=no root@$vm_ip << 'ENDSSH'
apt-get update && apt-get install -y curl
curl -sfL https://get.k3s.io | sh -
echo "Kubernetes (k3s)安装成功"
ENDSSH
                if [ $? -eq 0 ]; then
                    success=$((success + 1))
                    print_success "$software 部署成功"
                fi
                ;;
            *)
                print_warning "未知软件: $software"
                echo "支持的软件: nginx, mysql, mariadb, php, redis, docker, nodejs, python, java, postgresql, mongodb, elasticsearch, kubernetes"
                continue
                ;;
        esac
        echo ""
    done
    
    echo "=========================================="
    print_success "部署完成！成功部署: $success 个软件"
    echo "VM IP: $vm_ip"
    echo "您现在可以通过 SSH 连接到VM: ssh root@$vm_ip"
    echo "=========================================="
}

# 启动VM
start_vm() {
    local vm_id="$1"
    print_header "启动VM: $vm_id"
    echo "请在PVE控制台中启动VM ID: $vm_id"
    echo ""
    echo "或者，在PVE节点上运行："
    echo "pvesh start /nodes/[节点名]/lxc/$vm_id/status/start"
}

# 停止VM
stop_vm() {
    local vm_id="$1"
    print_header "停止VM: $vm_id"
    echo "请在PVE控制台中停止VM ID: $vm_id"
    echo ""
    echo "或者，在PVE节点上运行："
    echo "pvesh stop /nodes/[节点名]/lxc/$vm_id/status/stop"
}

# 销毁VM
destroy_vm() {
    local vm_id="$1"
    print_header "销毁VM: $vm_id"
    echo "请在PVE控制台中销毁VM ID: $vm_id"
    echo ""
    echo "警告：此操作不可逆！"
    echo ""
    echo "或者，在PVE节点上运行："
    echo "pvesh destroy /nodes/[节点名]/lxc/$vm_id"
}

# 查看VM状态
status_vm() {
    local vm_id="$1"
    print_header "VM状态: $vm_id"
    echo "请在PVE控制台中查看VM ID: $vm_id 的状态"
    echo ""
    echo "或者，在PVE节点上运行："
    echo "pvesh get /nodes/[节点名]/lxc/$vm_id/status/current"
}

# 主函数
main() {
    init_pve_config
    
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    local command="$1"
    shift
    
    case $command in
        help|--help|-h)
            show_help
            ;;
        config)
            config_pve
            ;;
        list)
            list_config
            ;;
        create)
            create_vm
            ;;
        deploy)
            deploy_to_vm "$@"
            ;;
        start)
            start_vm "$1"
            ;;
        stop)
            stop_vm "$1"
            ;;
        destroy)
            destroy_vm "$1"
            ;;
        status)
            status_vm "$1"
            ;;
        *)
            print_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
