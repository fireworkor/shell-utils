#!/bin/bash

# =========================================
# Docker 管理脚本
# 功能：安装、配置、镜像管理、容器管理、
#      监控、日志、清理、备份恢复等
# 需要：root 权限
# =========================================

set -o pipefail

# 加载依赖
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/../lib/logging.sh"

# 配置
readonly DOCKER_VERSION="${DOCKER_VERSION:-latest}"
readonly DOCKER_DATA_DIR="/var/lib/docker"
readonly DOCKER_CONFIG_DIR="/etc/docker"
readonly COMPOSE_VERSION="${COMPOSE_VERSION:-v2.17.2}"
readonly REGISTRY_MIRRORS=(
    "https://docker.mirrors.ustc.edu.cn"
    "https://hub-mirror.c.163.com"
    "https://mirror.baidubce.com"
)

# Docker 服务配置
DOCKER_OPTS="--storage-driveroverlay2 --log-driver=json-file --log-opt max-size=10m --log-opt max-file=3"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查 root 权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}错误：此脚本需要 root 权限${NC}"
        exit 1
    fi
}

# 检查 Docker 是否安装
check_docker_installed() {
    if command -v docker &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 获取 Docker 版本
get_docker_version() {
    if check_docker_installed; then
        docker version --format '{{.Server.Version}}' 2>/dev/null || echo "未知"
    else
        echo "未安装"
    fi
}

# 获取 Docker Compose 版本
get_compose_version() {
    if command -v docker-compose &>/dev/null; then
        docker-compose version --short 2>/dev/null || echo "未知"
    elif docker compose version &>/dev/null; then
        docker compose version --short 2>/dev/null || echo "未知"
    else
        echo "未安装"
    fi
}

# 安装 Docker (CentOS/RHEL)
install_docker_centos() {
    log_info "在 CentOS/RHEL 上安装 Docker..."

    local pkg_manager=$(get_pkg_manager)

    if [ "$pkg_manager" = "yum" ]; then
        yum install -y yum-utils device-mapper-persistent-data lvm2
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        
        if [ "$DOCKER_VERSION" = "latest" ]; then
            yum install -y docker-ce docker-ce-cli containerd.io
        else
            yum install -y docker-ce-"${DOCKER_VERSION}" docker-ce-cli-"${DOCKER_VERSION}" containerd.io
        fi
    elif [ "$pkg_manager" = "dnf" ]; then
        dnf install -y dnf-plugins-core
        dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        
        if [ "$DOCKER_VERSION" = "latest" ]; then
            dnf install -y docker-ce docker-ce-cli containerd.io
        else
            dnf install -y docker-ce-"${DOCKER_VERSION}" docker-ce-cli-"${DOCKER_VERSION}" containerd.io
        fi
    fi

    systemctl start docker
    systemctl enable docker

    log_info "Docker 安装完成"
}

# 安装 Docker (Ubuntu/Debian)
install_docker_ubuntu() {
    log_info "在 Ubuntu/Debian 上安装 Docker..."

    local os_name=$(grep -i "^NAME=" /etc/os-release | cut -d'"' -f2)
    local pkg_manager=$(get_pkg_manager)

    apt-get update -qq
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

    curl -fsSL https://download.docker.com/linux/${os_name,,}/gpg | apt-key add -
    
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/${os_name,,} $(lsb_release -cs) stable"

    apt-get update -qq

    if [ "$DOCKER_VERSION" = "latest" ]; then
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    else
        apt-get install -y docker-ce="${DOCKER_VERSION}" docker-ce-cli="${DOCKER_VERSION}" containerd.io docker-compose-plugin
    fi

    systemctl start docker
    systemctl enable docker

    log_info "Docker 安装完成"
}

# 配置 Docker 镜像加速
configure_mirror() {
    log_info "配置 Docker 镜像加速..."

    mkdir -p "$DOCKER_CONFIG_DIR"

    local mirror_json=$(cat <<EOF
{
  "registry-mirrors": [
$(printf '    "%s"\n' "${REGISTRY_MIRRORS[@]}" | sed 's/,$//')
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
)

    echo "$mirror_json" > "${DOCKER_CONFIG_DIR}/daemon.json"

    systemctl restart docker

    log_info "镜像加速配置完成"
}

# 安装 Docker Compose
install_docker_compose() {
    log_info "安装 Docker Compose..."

    if docker compose version &>/dev/null; then
        log_info "Docker Compose (V2) 已安装: $(docker compose version --short)"
        return 0
    fi

    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

    log_info "Docker Compose 安装完成: $(docker-compose --version)"
}

# 完整安装 Docker
install_docker() {
    check_root

    if check_docker_installed; then
        log_warn "Docker 已安装: $(get_docker_version)"
        read -p "是否重新安装? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            return 0
        fi
    fi

    local os_type=$(detect_os)

    case "$os_type" in
        "CentOS"|"RedHat"|"Fedora")
            install_docker_centos
            ;;
        "Ubuntu"|"Debian")
            install_docker_ubuntu
            ;;
        *)
            log_error "不支持的操作系统: $os_type"
            exit 1
            ;;
    esac

    configure_mirror
    install_docker_compose

    # 添加当前用户到 docker 组
    if [ -n "$SUDO_USER" ]; then
        usermod -aG docker "$SUDO_USER"
        log_info "用户 $SUDO_USER 已添加到 docker 组"
    fi

    # 验证安装
    log_info "验证 Docker 安装..."
    docker run --rm hello-world &>/dev/null && log_info "Docker 运行正常" || log_error "Docker 运行验证失败"

    show_docker_info
}

# 显示 Docker 信息
show_docker_info() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}         Docker 信息${NC}"
    echo -e "${BLUE}========================================${NC}"

    echo -e "${GREEN}Docker 版本:${NC}         $(get_docker_version)"
    echo -e "${GREEN}Docker Compose 版本:${NC} $(get_compose_version)"
    echo -e "${GREEN}镜像数量:${NC}            $(docker images -q 2>/dev/null | wc -l)"
    echo -e "${GREEN}容器数量:${NC}            $(docker ps -aq 2>/dev/null | wc -l)"
    echo -e "${GREEN}运行中容器:${NC}          $(docker ps -q 2>/dev/null | wc -l)"
    echo -e "${GREEN}已停止容器:${NC}           $(docker ps -aq -f status=exited 2>/dev/null | wc -l)"
    echo -e "${GREEN}数据目录:${NC}            $DOCKER_DATA_DIR"
    echo -e "${GREEN}配置目录:${NC}            $DOCKER_CONFIG_DIR"
    echo -e "${GREEN}磁盘使用:${NC}            $(du -sh "$DOCKER_DATA_DIR" 2>/dev/null | cut -f1)"
    
    echo ""
}

# 镜像管理
pull_image() {
    local image=$1
    local tag="${2:-latest}"

    if [ -z "$image" ]; then
        log_error "请指定镜像名称"
        return 1
    fi

    log_info "拉取镜像: $image:$tag"
    
    if docker pull "$image:$tag"; then
        log_info "镜像拉取成功: $image:$tag"
    else
        log_error "镜像拉取失败: $image:$tag"
        return 1
    fi
}

list_images() {
    local format="${1:-table}"
    
    log_info "镜像列表:"
    
    case "$format" in
        table)
            docker images
            ;;
        json)
            docker images --format '{{json .}}' | jq '.'
            ;;
        name-only)
            docker images --format '{{.Repository}}:{{.Tag}}'
            ;;
    esac
}

remove_image() {
    local image=$1
    local force="${2:-false}"

    if [ -z "$image" ]; then
        log_error "请指定镜像名称"
        return 1
    fi

    log_warn "删除镜像: $image"

    if [ "$force" = "true" ]; then
        docker rmi -f "$image" &>/dev/null
    else
        docker rmi "$image" &>/dev/null
    fi

    if [ $? -eq 0 ]; then
        log_info "镜像删除成功: $image"
    else
        log_error "镜像删除失败: $image"
        return 1
    fi
}

clean_images() {
    log_info "清理未使用的镜像..."

    local before=$(docker images -q 2>/dev/null | wc -l)
    
    docker image prune -f
    
    local after=$(docker images -q 2>/dev/null | wc -l)
    local cleaned=$((before - after))

    log_info "清理完成，删除了 $cleaned 个镜像"
}

# 容器管理
list_containers() {
    local all="${1:-false}"
    local format="${2:-table}"

    log_info "容器列表:"

    if [ "$all" = "true" ]; then
        case "$format" in
            table)
                docker ps -a
                ;;
            json)
                docker ps -a --format '{{json .}}' | jq '.'
                ;;
        esac
    else
        case "$format" in
            table)
                docker ps
                ;;
            json)
                docker ps --format '{{json .}}' | jq '.'
                ;;
        esac
    fi
}

start_container() {
    local container=$1

    if [ -z "$container" ]; then
        log_error "请指定容器名称或 ID"
        return 1
    fi

    log_info "启动容器: $container"

    if docker start "$container"; then
        log_info "容器启动成功: $container"
    else
        log_error "容器启动失败: $container"
        return 1
    fi
}

stop_container() {
    local container=$1
    local timeout="${2:-10}"

    if [ -z "$container" ]; then
        log_error "请指定容器名称或 ID"
        return 1
    fi

    log_warn "停止容器: $container"

    if docker stop -t "$timeout" "$container"; then
        log_info "容器停止成功: $container"
    else
        log_error "容器停止失败: $container"
        return 1
    fi
}

restart_container() {
    local container=$1

    if [ -z "$container" ]; then
        log_error "请指定容器名称或 ID"
        return 1
    fi

    log_info "重启容器: $container"

    if docker restart "$container"; then
        log_info "容器重启成功: $container"
    else
        log_error "容器重启失败: $container"
        return 1
    fi
}

remove_container() {
    local container=$1
    local force="${2:-false}"
    local remove_volumes="${3:-false}"

    if [ -z "$container" ]; then
        log_error "请指定容器名称或 ID"
        return 1
    fi

    log_warn "删除容器: $container"

    local cmd="docker rm"
    [ "$force" = "true" ] && cmd="$cmd -f"
    [ "$remove_volumes" = "true" ] && cmd="$cmd -v"

    if $cmd "$container" &>/dev/null; then
        log_info "容器删除成功: $container"
    else
        log_error "容器删除失败: $container"
        return 1
    fi
}

# 查看容器日志
logs_container() {
    local container=$1
    local lines="${2:-100}"
    local follow="${3:-false}"

    if [ -z "$container" ]; then
        log_error "请指定容器名称或 ID"
        return 1
    fi

    log_info "查看容器日志: $container"

    if [ "$follow" = "true" ]; then
        docker logs -f --tail "$lines" "$container"
    else
        docker logs --tail "$lines" "$container"
    fi
}

# 容器资源监控
monitor_container() {
    local container=$1

    if [ -z "$container" ]; then
        log_error "请指定容器名称或 ID"
        return 1
    fi

    echo -e "${BLUE}容器资源监控: $container${NC}"
    echo -e "${BLUE}========================================${NC}"

    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}" "$container"
}

# 实时监控所有容器
monitor_all() {
    echo -e "${BLUE}实时容器监控 (Ctrl+C 退出)${NC}"
    echo -e "${BLUE}========================================${NC}"

    docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# 容器健康检查
healthcheck_container() {
    local container=$1

    if [ -z "$container" ]; then
        log_error "请指定容器名称或 ID"
        return 1
    fi

    local status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null)
    
    if [ -z "$status" ]; then
        status=$(docker inspect --format='{{.State.Status}}' "$container")
        echo -e "${GREEN}容器状态:${NC} $status"
    else
        echo -e "${GREEN}健康检查状态:${NC} $status"
    fi

    local running=$(docker inspect --format='{{.State.Running}}' "$container" 2>/dev/null)
    local started=$(docker inspect --format='{{.State.StartedAt}}' "$container" 2>/dev/null)
    local restart_count=$(docker inspect --format='{{.RestartCount}}' "$container" 2>/dev/null)

    echo -e "${GREEN}运行状态:${NC} $running"
    echo -e "${GREEN}启动时间:${NC} $started"
    echo -e "${GREEN}重启次数:${NC} $restart_count"
}

# 进入容器
exec_container() {
    local container=$1
    shift
    local cmd="${@:-bash}"

    if [ -z "$container" ]; then
        log_error "请指定容器名称或 ID"
        return 1
    fi

    log_info "进入容器: $container"

    docker exec -it "$container" $cmd
}

# 查看容器信息
inspect_container() {
    local container=$1
    local format="${2:-json}"

    if [ -z "$container" ]; then
        log_error "请指定容器名称或 ID"
        return 1
    fi

    case "$format" in
        json)
            docker inspect "$container" | jq '.'
            ;;
        yaml)
            docker inspect "$container" | docker-ps-to-k8s
            ;;
        *)
            docker inspect "$container"
            ;;
    esac
}

# 批量操作
batch_start() {
    local pattern=$1

    if [ -z "$pattern" ]; then
        log_error "请指定容器名称模式"
        return 1
    fi

    local containers=$(docker ps -aq -f name="$pattern" -f status=exited)

    if [ -z "$containers" ]; then
        log_warn "没有找到符合条件的已停止容器: $pattern"
        return 0
    fi

    log_info "启动匹配的容器..."
    echo "$containers" | xargs docker start

    log_info "批量启动完成"
}

batch_stop() {
    local pattern=$1

    if [ -z "$pattern" ]; then
        log_error "请指定容器名称模式"
        return 1
    fi

    local containers=$(docker ps -q -f name="$pattern")

    if [ -z "$containers" ]; then
        log_warn "没有找到符合条件的运行中容器: $pattern"
        return 0
    fi

    log_warn "停止匹配的容器..."
    echo "$containers" | xargs docker stop

    log_info "批量停止完成"
}

batch_remove() {
    local pattern=$1
    local force="${2:-false}"

    if [ -z "$pattern" ]; then
        log_error "请指定容器名称模式"
        return 1
    fi

    local containers=$(docker ps -aq -f name="$pattern")

    if [ -z "$containers" ]; then
        log_warn "没有找到符合条件的容器: $pattern"
        return 0
    fi

    log_warn "删除匹配的容器..."
    
    if [ "$force" = "true" ]; then
        echo "$containers" | xargs docker rm -f
    else
        echo "$containers" | xargs docker rm
    fi

    log_info "批量删除完成"
}

# Docker Compose 操作
compose_up() {
    local compose_file="${1:-docker-compose.yml}"
    local detach="${2:-true}"

    log_info "启动 Docker Compose: $compose_file"

    if [ ! -f "$compose_file" ]; then
        log_error "Compose 文件不存在: $compose_file"
        return 1
    fi

    cd "$(dirname "$compose_file")"

    if [ "$detach" = "true" ]; then
        docker-compose up -d
    else
        docker-compose up
    fi

    log_info "Docker Compose 启动完成"
}

compose_down() {
    local compose_file="${1:-docker-compose.yml}"
    local remove_volumes="${2:-false}"

    log_info "停止 Docker Compose: $compose_file"

    if [ ! -f "$compose_file" ]; then
        log_error "Compose 文件不存在: $compose_file"
        return 1
    fi

    cd "$(dirname "$compose_file")"

    if [ "$remove_volumes" = "true" ]; then
        docker-compose down -v
    else
        docker-compose down
    fi

    log_info "Docker Compose 停止完成"
}

compose_restart() {
    local compose_file="${1:-docker-compose.yml}"

    log_info "重启 Docker Compose: $compose_file"

    if [ ! -f "$compose_file" ]; then
        log_error "Compose 文件不存在: $compose_file"
        return 1
    fi

    cd "$(dirname "$compose_file")"
    docker-compose restart

    log_info "Docker Compose 重启完成"
}

compose_logs() {
    local compose_file="${1:-docker-compose.yml}"
    local service="${2:-}"
    local lines="${3:-100}"
    local follow="${4:-false}"

    if [ ! -f "$compose_file" ]; then
        log_error "Compose 文件不存在: $compose_file"
        return 1
    fi

    cd "$(dirname "$compose_file")"

    if [ -n "$service" ]; then
        if [ "$follow" = "true" ]; then
            docker-compose logs -f --tail "$lines" "$service"
        else
            docker-compose logs --tail "$lines" "$service"
        fi
    else
        if [ "$follow" = "true" ]; then
            docker-compose logs -f --tail "$lines"
        else
            docker-compose logs --tail "$lines"
        fi
    fi
}

compose_ps() {
    local compose_file="${1:-docker-compose.yml}"

    if [ ! -f "$compose_file" ]; then
        log_error "Compose 文件不存在: $compose_file"
        return 1
    fi

    cd "$(dirname "$compose_file")"
    docker-compose ps
}

# 清理操作
clean_all() {
    log_warn "清理所有未使用的 Docker 资源..."

    log_info "清理已停止的容器..."
    docker container prune -f

    log_info "清理未使用的镜像..."
    docker image prune -f

    log_info "清理构建缓存..."
    docker builder prune -f

    log_info "清理未使用的网络..."
    docker network prune -f

    log_info "清理完成"

    show_cleanup_stats
}

clean_containers() {
    log_warn "清理已停止的容器..."

    local before=$(docker ps -aq -f status=exited | wc -l)
    
    docker container prune -f

    local after=$(docker ps -aq -f status=exited | wc -l)
    local cleaned=$((before - after))

    log_info "清理完成，删除了 $cleaned 个已停止的容器"
}

clean_volumes() {
    log_warn "清理未使用的卷..."

    local volumes=$(docker volume ls -qf dangling=true)
    
    if [ -n "$volumes" ]; then
        echo "$volumes" | xargs docker volume rm
        log_info "删除了 $(echo "$volumes" | wc -l) 个未使用的卷"
    else
        log_info "没有未使用的卷"
    fi
}

# 清理统计
show_cleanup_stats() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}         Docker 清理统计${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    echo -e "${GREEN}镜像数量:${NC}     $(docker images -q | wc -l)"
    echo -e "${GREEN}容器数量:${NC}     $(docker ps -aq | wc -l)"
    echo -e "${GREEN}运行中:${NC}       $(docker ps -q | wc -l)"
    echo -e "${GREEN}卷数量:${NC}       $(docker volume ls | tail -n +2 | wc -l)"
    echo -e "${GREEN}网络数量:${NC}     $(docker network ls | tail -n +2 | wc -l)"
    echo -e "${GREEN}磁盘使用:${NC}     $(du -sh "$DOCKER_DATA_DIR" 2>/dev/null | cut -f1)"
}

# 备份操作
backup_container() {
    local container=$1
    local backup_dir="${2:-/tmp/docker-backups}"
    local timestamp=$(date +%Y%m%d_%H%M%S)

    if [ -z "$container" ]; then
        log_error "请指定容器名称或 ID"
        return 1
    fi

    log_info "备份容器: $container"

    mkdir -p "$backup_dir"

    local backup_file="${backup_dir}/${container}_${timestamp}.tar"

    docker export "$container" -o "$backup_file"

    if [ $? -eq 0 ]; then
        log_info "容器备份成功: $backup_file"
        
        local size=$(du -h "$backup_file" | cut -f1)
        log_info "备份文件大小: $size"
        
        echo "$backup_file" >> "${backup_dir}/backup_list.txt"
    else
        log_error "容器备份失败: $container"
        return 1
    fi
}

restore_container() {
    local backup_file=$1
    local new_name="${2:-}"

    if [ -z "$backup_file" ]; then
        log_error "请指定备份文件"
        return 1
    fi

    if [ ! -f "$backup_file" ]; then
        log_error "备份文件不存在: $backup_file"
        return 1
    fi

    log_info "恢复容器: $backup_file"

    if [ -n "$new_name" ]; then
        docker import "$backup_file" "$new_name"
    else
        docker import "$backup_file"
    fi

    if [ $? -eq 0 ]; then
        log_info "容器恢复成功"
    else
        log_error "容器恢复失败"
        return 1
    fi
}

# 备份所有镜像
backup_all_images() {
    local backup_dir="${1:-/tmp/docker-backups}"
    local timestamp=$(date +%Y%m%d_%H%M%S)

    log_info "备份所有镜像..."

    mkdir -p "$backup_dir"

    local backup_file="${backup_dir}/images_${timestamp}.tar"

    docker save -o "$backup_file" $(docker images -q)

    if [ $? -eq 0 ]; then
        log_info "镜像备份成功: $backup_file"
        
        local size=$(du -h "$backup_file" | cut -f1)
        log_info "备份文件大小: $size"
    else
        log_error "镜像备份失败"
        return 1
    fi
}

restore_all_images() {
    local backup_file=$1

    if [ -z "$backup_file" ]; then
        log_error "请指定备份文件"
        return 1
    fi

    if [ ! -f "$backup_file" ]; then
        log_error "备份文件不存在: $backup_file"
        return 1
    fi

    log_info "恢复镜像: $backup_file"

    docker load -i "$backup_file"

    if [ $? -eq 0 ]; then
        log_info "镜像恢复成功"
    else
        log_error "镜像恢复失败"
        return 1
    fi
}

# Docker 系统信息
show_system_info() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}         Docker 系统信息${NC}"
    echo -e "${BLUE}========================================${NC}"

    docker system info
}

show_disk_usage() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}         Docker 磁盘使用${NC}"
    echo -e "${BLUE}========================================${NC}"

    docker system df

    echo ""
    echo -e "${BLUE}详细磁盘使用:${NC}"
    docker system df -v
}

# 卸载 Docker
uninstall_docker() {
    log_warn "即将卸载 Docker..."

    read -p "确认卸载? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        log_info "取消卸载"
        return 0
    fi

    log_info "停止 Docker 服务..."
    systemctl stop docker
    systemctl disable docker

    local os_type=$(detect_os)

    case "$os_type" in
        "CentOS"|"RedHat"|"Fedora")
            yum remove -y docker-ce docker-ce-cli containerd.io
            ;;
        "Ubuntu"|"Debian")
            apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
    esac

    log_warn "删除 Docker 数据..."
    rm -rf "$DOCKER_DATA_DIR"
    rm -rf "$DOCKER_CONFIG_DIR"
    rm -f /usr/local/bin/docker-compose

    log_info "Docker 卸载完成"
}

# 显示帮助信息
show_help() {
    cat <<EOF
${GREEN}Docker 管理脚本${NC}

${YELLOW}使用方法:${NC} $0 <命令> [参数]

${BLUE}安装与配置:${NC}
  install              安装 Docker
  configure-mirror     配置镜像加速
  install-compose      安装 Docker Compose
  uninstall            卸载 Docker

${BLUE}信息查看:${NC}
  info                 显示 Docker 信息
  version              显示版本信息
  system-info          显示系统信息
  disk-usage           显示磁盘使用
  stats                实时资源监控

${BLUE}镜像管理:${NC}
  pull <镜像> [标签]    拉取镜像
  images               列出镜像
  rmi <镜像>           删除镜像
  clean-images         清理未使用镜像

${BLUE}容器管理:${NC}
  ps [all]             列出容器
  start <容器>         启动容器
  stop <容器> [超时]    停止容器
  restart <容器>       重启容器
  rm <容器> [-f]       删除容器
  logs <容器> [行数]   查看日志
  exec <容器> [命令]   进入容器
  inspect <容器>       查看容器详情
  health <容器>        健康检查
  monitor <容器>        监控容器资源

${BLUE}批量操作:${NC}
  batch-start <模式>   批量启动容器
  batch-stop <模式>    批量停止容器
  batch-rm <模式> [-f] 批量删除容器

${BLUE}Docker Compose:${NC}
  compose-up [文件]     启动 Compose
  compose-down [文件]   停止 Compose
  compose-restart [文件] 重启 Compose
  compose-logs [文件] [服务] [行数]  查看日志
  compose-ps [文件]     查看 Compose 状态

${BLUE}清理操作:${NC}
  clean                清理所有未使用资源
  clean-containers     清理已停止容器
  clean-volumes        清理未使用卷
  clean-all            完整清理

${BLUE}备份恢复:${NC}
  backup <容器> [目录]  备份容器
  restore <文件> [名称] 恢复容器
  backup-images [目录]  备份所有镜像
  restore-images <文件> 恢复镜像

${BLUE}示例:${NC}
  $0 install
  $0 pull nginx:latest
  $0 images
  $0 start myapp
  $0 logs myapp 200
  $0 exec myapp bash
  $0 clean
  $0 backup myapp /backups

EOF
}

# 主函数
main() {
    local command=${1:-help}
    shift || true

    case "$command" in
        install)
            install_docker
            ;;
        configure-mirror)
            check_root
            configure_mirror
            ;;
        install-compose)
            check_root
            install_docker_compose
            ;;
        uninstall)
            check_root
            uninstall_docker
            ;;
        info)
            show_docker_info
            ;;
        version)
            echo "Docker: $(get_docker_version)"
            echo "Docker Compose: $(get_compose_version)"
            ;;
        system-info)
            show_system_info
            ;;
        disk-usage)
            show_disk_usage
            ;;
        stats)
            monitor_all
            ;;
        pull)
            pull_image "$@"
            ;;
        images)
            list_images "$@"
            ;;
        rmi)
            remove_image "$@"
            ;;
        clean-images)
            clean_images
            ;;
        ps)
            list_containers "$@"
            ;;
        start)
            start_container "$@"
            ;;
        stop)
            stop_container "$@"
            ;;
        restart)
            restart_container "$@"
            ;;
        rm)
            remove_container "$@"
            ;;
        logs)
            logs_container "$@"
            ;;
        exec)
            exec_container "$@"
            ;;
        inspect)
            inspect_container "$@"
            ;;
        health)
            healthcheck_container "$@"
            ;;
        monitor)
            monitor_container "$@"
            ;;
        batch-start)
            batch_start "$@"
            ;;
        batch-stop)
            batch_stop "$@"
            ;;
        batch-rm)
            batch_remove "$@"
            ;;
        compose-up)
            compose_up "$@"
            ;;
        compose-down)
            compose_down "$@"
            ;;
        compose-restart)
            compose_restart "$@"
            ;;
        compose-logs)
            compose_logs "$@"
            ;;
        compose-ps)
            compose_ps "$@"
            ;;
        clean)
            clean_all
            ;;
        clean-containers)
            clean_containers
            ;;
        clean-volumes)
            clean_volumes
            ;;
        clean-all)
            clean_all
            ;;
        backup)
            backup_container "$@"
            ;;
        restore)
            restore_container "$@"
            ;;
        backup-images)
            backup_all_images "$@"
            ;;
        restore-images)
            restore_all_images "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
