#!/bin/bash
# SSH 远程执行库

# 全局变量
REMOTE_HOST=""
REMOTE_USER=""
REMOTE_PASSWORD=""
REMOTE_PORT=22
SSH_KEY_FILE=""

# 初始化远程连接配置
init_remote() {
    REMOTE_HOST="$1"
    REMOTE_USER="$2"
    REMOTE_PASSWORD="${3:-}"
    REMOTE_PORT="${4:-22}"
    SSH_KEY_FILE="${5:-}"
}

# 检查是否配置了远程连接
is_remote() {
    [ -n "$REMOTE_HOST" ]
}

# 获取 SSH 命令前缀
get_ssh_prefix() {
    local prefix=""
    
    if [ -n "$SSH_KEY_FILE" ]; then
        prefix="ssh -i $SSH_KEY_FILE -p $REMOTE_PORT $REMOTE_USER@$REMOTE_HOST"
    elif [ -n "$REMOTE_PASSWORD" ]; then
        prefix="sshpass -p '$REMOTE_PASSWORD' ssh -o StrictHostKeyChecking=no -p $REMOTE_PORT $REMOTE_USER@$REMOTE_HOST"
    else
        prefix="ssh -o StrictHostKeyChecking=no -p $REMOTE_PORT $REMOTE_USER@$REMOTE_HOST"
    fi
    
    echo "$prefix"
}

# 远程执行命令
remote_exec() {
    if ! is_remote; then
        "$@"
        return $?
    fi
    
    local cmd="$*"
    local ssh_prefix=$(get_ssh_prefix)
    
    if [ -n "$REMOTE_PASSWORD" ]; then
        sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "$cmd"
    elif [ -n "$SSH_KEY_FILE" ]; then
        ssh -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "$cmd"
    else
        ssh -o StrictHostKeyChecking=no -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "$cmd"
    fi
}

# 远程执行脚本
remote_exec_script() {
    local script_path="$1"
    shift
    
    if ! is_remote; then
        bash "$script_path" "$@"
        return $?
    fi
    
    # 将脚本复制到远程服务器并执行
    local remote_script="/tmp/$(basename "$script_path")"
    
    if [ -n "$REMOTE_PASSWORD" ]; then
        sshpass -p "$REMOTE_PASSWORD" scp -o StrictHostKeyChecking=no -P "$REMOTE_PORT" "$script_path" "$REMOTE_USER@$REMOTE_HOST:$remote_script"
        sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "chmod +x $remote_script && $remote_script $*"
    elif [ -n "$SSH_KEY_FILE" ]; then
        scp -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no -P "$REMOTE_PORT" "$script_path" "$REMOTE_USER@$REMOTE_HOST:$remote_script"
        ssh -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "chmod +x $remote_script && $remote_script $*"
    else
        scp -o StrictHostKeyChecking=no -P "$REMOTE_PORT" "$script_path" "$REMOTE_USER@$REMOTE_HOST:$remote_script"
        ssh -o StrictHostKeyChecking=no -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "chmod +x $remote_script && $remote_script $*"
    fi
}

# 远程复制文件
remote_copy() {
    local src="$1"
    local dst="$2"
    
    if ! is_remote; then
        cp "$src" "$dst"
        return $?
    fi
    
    if [ -n "$REMOTE_PASSWORD" ]; then
        sshpass -p "$REMOTE_PASSWORD" scp -o StrictHostKeyChecking=no -P "$REMOTE_PORT" "$src" "$REMOTE_USER@$REMOTE_HOST:$dst"
    elif [ -n "$SSH_KEY_FILE" ]; then
        scp -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no -P "$REMOTE_PORT" "$src" "$REMOTE_USER@$REMOTE_HOST:$dst"
    else
        scp -o StrictHostKeyChecking=no -P "$REMOTE_PORT" "$src" "$REMOTE_USER@$REMOTE_HOST:$dst"
    fi
}

# 远程创建目录
remote_mkdir() {
    local dir="$1"
    remote_exec "mkdir -p $dir"
}

# 远程检查文件是否存在
remote_file_exists() {
    local file="$1"
    remote_exec "[ -f $file ]"
}

# 远程检查目录是否存在
remote_dir_exists() {
    local dir="$1"
    remote_exec "[ -d $dir ]"
}

# 远程获取文件内容
remote_cat() {
    local file="$1"
    remote_exec "cat $file"
}

# 远程检查命令是否存在
remote_command_exists() {
    local cmd="$1"
    remote_exec "command -v $cmd" > /dev/null 2>&1
}

# 远程获取系统信息
remote_get_os() {
    remote_exec "cat /etc/os-release | grep -E '^(ID|VERSION_ID)=' | head -2"
}

# 远程安装软件（包管理器方式）
remote_install_package() {
    local pkg="$1"
    
    local os_info=$(remote_get_os)
    local os_id=$(echo "$os_info" | grep ID= | cut -d'=' -f2 | tr -d '"')
    local os_version=$(echo "$os_info" | grep VERSION_ID= | cut -d'=' -f2 | tr -d '"')
    
    case "$os_id" in
        centos|rhel|fedora)
            if [ "$os_version" = "8" ] || [ "$os_version" = "9" ]; then
                remote_exec "dnf install -y $pkg"
            else
                remote_exec "yum install -y $pkg"
            fi
            ;;
        ubuntu|debian)
            remote_exec "apt-get update && apt-get install -y $pkg"
            ;;
        *)
            echo "未知操作系统: $os_id"
            return 1
            ;;
    esac
}

# 测试远程连接
test_remote_connection() {
    if ! is_remote; then
        return 0
    fi
    
    echo "🔗 测试远程连接..."
    if remote_exec "echo '连接成功'"; then
        echo "✅ 远程连接测试成功"
        return 0
    else
        echo "❌ 远程连接失败"
        return 1
    fi
}