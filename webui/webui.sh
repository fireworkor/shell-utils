#!/bin/bash
# 运维工具 Web UI 管理脚本 - 改进版
# 支持: start, stop, restart, status, help, config

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LIB_DIR="$SCRIPT_DIR/../lib"
PID_FILE="$SCRIPT_DIR/pid.txt"
LOG_FILE="$SCRIPT_DIR/logs/webui.log"
APP_SCRIPT="$SCRIPT_DIR/app.py"
CONFIG_FILE="$SCRIPT_DIR/config.conf"

# 默认配置
PORT=5000
HOST=0.0.0.0

# 加载配置文件
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE" 2>/dev/null || true
    PORT=${PORT:-5000}
    HOST=${HOST:-0.0.0.0}
fi

# 支持命令行参数覆盖配置
# 使用方法: webui.sh start --port 8080 --host 127.0.0.1
while [[ $# -gt 0 ]]; do
    case $1 in
        --port)
            PORT="$2"
            shift 2
            ;;
        --host)
            HOST="$2"
            shift 2
            ;;
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

# 加载通用函数库
if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

# 颜色定义
RED=$(printf '\033[0;31m')
GREEN=$(printf '\033[0;32m')
YELLOW=$(printf '\033[1;33m')
BLUE=$(printf '\033[0;34m')
CYAN=$(printf '\033[0;36m')
NC=$(printf '\033[0m') # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# 打印头部
print_header() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}   运维工具 Web UI 管理${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# 检测进程是否正在运行（通过命令行特征而不是仅PID）
get_process_pid() {
    local pids
    if command -v pgrep &> /dev/null; then
        pids=$(pgrep -f "python3.*$APP_SCRIPT" 2>/dev/null)
    else
        pids=$(ps aux | grep "python3.*$APP_SCRIPT" | grep -v grep | awk '{print $2}')
    fi
    echo "$pids"
}

# 检查端口占用
check_port() {
    local port=$1
    if command -v ss &> /dev/null; then
        ss -tuln | grep -q ":$port "
    elif command -v netstat &> /dev/null; then
        netstat -tuln | grep -q ":$port "
    elif command -v lsof &> /dev/null; then
        lsof -i :$port &> /dev/null
    else
        return 1
    fi
    return $?
}

# 获取占用端口的进程
get_port_pid() {
    local port=$1
    if command -v lsof &> /dev/null; then
        lsof -t -i :$port 2>/dev/null
    elif command -v ss &> /dev/null; then
        ss -tulnp | grep ":$port " | awk '{print $6}' | cut -d',' -f2 | cut -d'=' -f2 2>/dev/null
    elif command -v netstat &> /dev/null; then
        netstat -tulnp | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 2>/dev/null
    fi
}

# 检查PID是否有效且属于我们的进程
is_valid_pid() {
    local pid=$1
    if [ -z "$pid" ]; then
        return 1
    fi
    
    if ! kill -0 $pid 2>/dev/null; then
        return 1
    fi
    
    # 检查进程命令行
    if command -v ps &> /dev/null; then
        local cmdline
        if [ -f "/proc/$pid/cmdline" ]; then
            cmdline=$(cat "/proc/$pid/cmdline" | tr '\0' ' ')
        else
            cmdline=$(ps -p $pid -o args= 2>/dev/null)
        fi
        if echo "$cmdline" | grep -q "$APP_SCRIPT"; then
            return 0
        fi
    fi
    
    return 1
}

# 获取有效PID
get_valid_pid() {
    local valid_pid=""
    local file_pid
    local process_pids
    
    # 先尝试从PID文件获取
    if [ -f "$PID_FILE" ]; then
        file_pid=$(cat "$PID_FILE" 2>/dev/null)
        if is_valid_pid "$file_pid"; then
            valid_pid="$file_pid"
        fi
    fi
    
    # 如果PID文件无效，尝试直接查找进程
    if [ -z "$valid_pid" ]; then
        process_pids=$(get_process_pid)
        for pid in $process_pids; do
            if is_valid_pid "$pid"; then
                valid_pid="$pid"
                break
            fi
        done
    fi
    
    echo "$valid_pid"
}

# 检查并安装基础命令
check_and_install_command() {
    local cmd=$1
    local package=$2
    if ! command -v "$cmd" &> /dev/null; then
        log_warning "安装 $cmd ($package)..."
        local pkg_manager=""
        if command -v dnf &> /dev/null; then
            pkg_manager="dnf"
        elif command -v yum &> /dev/null; then
            pkg_manager="yum"
        elif command -v apt &> /dev/null; then
            pkg_manager="apt"
        fi

        if [ -n "$pkg_manager" ]; then
            case $pkg_manager in
                dnf|yum)
                    $pkg_manager install -y "$package" >/dev/null 2>&1
                    ;;
                apt)
                    export DEBIAN_FRONTEND=noninteractive
                    $pkg_manager update -qq >/dev/null 2>&1
                    $pkg_manager install -y "$package" >/dev/null 2>&1
                    ;;
            esac
        fi
    fi
}

install_system_package() {
    local package=$1
    log_warning "安装系统依赖 $package..."
    local pkg_manager=""
    if command -v dnf &> /dev/null; then
        pkg_manager="dnf"
    elif command -v yum &> /dev/null; then
        pkg_manager="yum"
    elif command -v apt &> /dev/null; then
        pkg_manager="apt"
    fi

    if [ -n "$pkg_manager" ]; then
        case $pkg_manager in
            dnf|yum)
                $pkg_manager install -y "$package" >/dev/null 2>&1
                ;;
            apt)
                export DEBIAN_FRONTEND=noninteractive
                $pkg_manager update -qq >/dev/null 2>&1
                $pkg_manager install -y "$package" >/dev/null 2>&1
                ;;
        esac
    fi
}

# 安装依赖
install_dependencies() {
    log_info "检查依赖..."

    # 检查基础命令
    check_and_install_command python3 python3
    check_and_install_command python3-pip python3-pip
    check_and_install_command curl curl
    check_and_install_command kill procps
    check_and_install_command mkdir coreutils

    # PostgreSQL 系统依赖（psycopg2 需要）
    if command -v apt &> /dev/null; then
        install_system_package "libpq-dev"
        install_system_package "python3-dev"
        install_system_package "build-essential"
    elif command -v dnf &> /dev/null || command -v yum &> /dev/null; then
        install_system_package "postgresql-devel"
        install_system_package "python3-devel"
    fi

    # 检查并安装 Python3-pip
    if ! python3 -m pip --version &> /dev/null; then
        log_warning "安装 python3-pip..."
        if command -v apt &> /dev/null; then
            export DEBIAN_FRONTEND=noninteractive
            apt update -qq >/dev/null 2>&1
            apt install -y python3-pip >/dev/null 2>&1
        elif command -v dnf &> /dev/null; then
            dnf install -y python3-pip >/dev/null 2>&1
        elif command -v yum &> /dev/null; then
            yum install -y python3-pip >/dev/null 2>&1
        fi

        # 如果系统包管理器不行，尝试通过get-pip.py安装
        if ! python3 -m pip --version &> /dev/null; then
            log_warning "尝试通过 get-pip.py 安装..."
            curl -sSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
            python3 /tmp/get-pip.py >/dev/null 2>&1
            rm -f /tmp/get-pip.py
        fi
    fi

    # 使用 requirements.txt 安装所有 Python 依赖
    if [ -f "$SCRIPT_DIR/requirements.txt" ]; then
        log_warning "安装 Python 依赖包..."
        python3 -m pip install --upgrade pip -q >/dev/null 2>&1
        python3 -m pip install -r "$SCRIPT_DIR/requirements.txt" -q >/dev/null 2>&1

        # 检查 psycopg2 是否安装成功
        if ! python3 -c "import psycopg2" &> /dev/null; then
            log_warning "psycopg2-binary 安装失败，尝试备用方案..."
            # 优先使用系统包
            if command -v apt &> /dev/null; then
                install_system_package "python3-psycopg2"
            elif command -v dnf &> /dev/null || command -v yum &> /dev/null; then
                install_system_package "python3-psycopg2"
            fi
            # 再尝试 pip 安装
            python3 -m pip install psycopg2-binary -q >/dev/null 2>&1
        fi
    else
        # 退回到逐包安装
        log_warning "未找到 requirements.txt，使用逐包安装..."
        for pkg in "flask" "flask-socketio" "python-socketio" "eventlet" "psutil" "flasgger" "psycopg2-binary"; do
            if ! python3 -c "import $pkg" &> /dev/null; then
                log_warning "安装 $pkg..."
                python3 -m pip install "$pkg" -q >/dev/null 2>&1
            fi
        done
    fi
}

# 启动服务
start() {
    print_header
    log_info "启动 Web UI 服务..."
    
    # 检查是否已在运行
    local current_pid
    current_pid=$(get_valid_pid)
    if [ -n "$current_pid" ]; then
        log_warning "服务已在运行 (PID: $current_pid)，正在停止..."
        stop
        sleep 2
    fi
    
    # 检查端口是否被占用（包括其他进程）
    if check_port "$PORT"; then
        local port_pid
        port_pid=$(get_port_pid "$PORT")
        if [ -n "$port_pid" ]; then
            log_warning "端口 $PORT 已被占用 (PID: $port_pid)，正在停止..."
            # 尝试停止占用端口的进程
            if kill -0 "$port_pid" 2>/dev/null; then
                kill "$port_pid" 2>/dev/null
                sleep 2
                # 如果还在运行，强制杀死
                if kill -0 "$port_pid" 2>/dev/null; then
                    log_warning "进程未响应，强制停止..."
                    kill -9 "$port_pid" 2>/dev/null
                    sleep 1
                fi
            fi
        fi
    fi
    
    # 安装依赖
    install_dependencies
    
    # 创建日志目录
    mkdir -p "$SCRIPT_DIR/logs"
    
    # 启动服务
    log_info "启动 Web 服务..."
    cd "$SCRIPT_DIR"
    
    # 删除旧的PID文件
    rm -f "$PID_FILE"
    
    # 重定向输出并启动
    nohup python3 app.py > "$LOG_FILE" 2>&1 &
    local new_pid=$!
    
    # 等待并验证启动
    local max_wait=30
    local waited=0
    local started=0
    local port_pid
    
    while [ $waited -lt $max_wait ]; do
        if is_valid_pid "$new_pid"; then
            # 检查端口是否监听
            if check_port "$PORT"; then
                # 验证端口和进程匹配
                port_pid=$(get_port_pid "$PORT")
                if [ -z "$port_pid" ] || [ "$port_pid" = "$new_pid" ] || echo "$port_pid" | grep -q "$new_pid"; then
                    started=1
                    break
                fi
            fi
        fi
        sleep 1
        waited=$((waited + 1))
        echo -n "."
    done
    echo ""
    
    if [ $started -eq 1 ]; then
        echo "$new_pid" > "$PID_FILE"
        log_success "服务启动成功"
        echo ""
        echo -e "${CYAN}📍 访问地址: http://localhost:$PORT${NC}"
        echo -e "${CYAN}📝 日志文件: $LOG_FILE${NC}"
        echo -e "${CYAN}🔢 进程 PID: $new_pid${NC}"
        return 0
    else
        log_error "服务启动失败，请检查日志: $LOG_FILE"
        tail -20 "$LOG_FILE" 2>/dev/null || true
        return 1
    fi
}

# 停止服务
stop() {
    print_header
    log_info "停止 Web UI 服务..."
    
    local current_pid
    current_pid=$(get_valid_pid)
    
    if [ -z "$current_pid" ]; then
        log_warning "服务未运行"
        rm -f "$PID_FILE"
        return 0
    fi
    
    
    log_info "正在停止进程 (PID: $current_pid)..."
    
    # 尝试优雅停止
    kill "$current_pid" 2>/dev/null
    
    # 等待进程退出
    local max_wait=10
    local waited=0
    while [ $waited -lt $max_wait ]; do
        if ! is_valid_pid "$current_pid"; then
            break
        fi
        sleep 1
        waited=$((waited + 1))
        echo -n "."
    done
    echo ""
    
    # 如果还在运行，强制杀死
    if is_valid_pid "$current_pid"; then
        log_warning "进程未响应，强制停止..."
        kill -9 "$current_pid" 2>/dev/null
        sleep 2
    fi
    
    # 清理PID文件
    rm -f "$PID_FILE"
    
    # 最终检查
    if ! is_valid_pid "$current_pid"; then
        log_success "服务已停止"
        return 0
    else
        log_error "无法停止服务"
        return 1
    fi
}

# 重启服务
restart() {
    log_info "重启 Web UI 服务..."
    stop
    sleep 2
    start
}

# 显示状态
status() {
    print_header
    
    local current_pid
    current_pid=$(get_valid_pid)
    
    if [ -n "$current_pid" ]; then
        log_success "服务正在运行"
        echo -e "${CYAN}🔢 进程 PID: $current_pid${NC}"
        if [ -f "/proc/$current_pid/status" ]; then
            local mem
            mem=$(grep VmRSS "/proc/$current_pid/status" | awk '{print $2 " " $3}')
            echo -e "${CYAN}💾 内存使用: $mem${NC}"
        fi
        echo -e "${CYAN}📍 访问地址: http://localhost:$PORT${NC}"
        echo -e "${CYAN}📝 日志文件: $LOG_FILE${NC}"
        
        if [ -f "$PID_FILE" ]; then
            local file_pid
            file_pid=$(cat "$PID_FILE")
            if [ "$file_pid" != "$current_pid" ]; then
                log_warning "PID 文件内容 ($file_pid) 与实际运行 PID ($current_pid) 不一致"
            fi
        fi
        return 0
    else
        log_warning "服务未运行"
        return 1
    fi
}

# 显示帮助
show_help() {
    print_header
    echo "用法: $0 [命令]"
    echo ""
    echo "命令列表:"
    echo "  start    - 启动 Web UI 服务"
    echo "  stop     - 停止 Web UI 服务"
    echo "  restart  - 重启 Web UI 服务"
    echo "  status   - 显示服务状态"
    echo "  help     - 显示此帮助信息"
  echo "  config   - 显示/编辑 WebUI 配置"
    echo ""
}

# 主逻辑

# 显示配置
show_config() {
    print_header
    echo -e "${CYAN}WebUI 当前配置${NC}"
    echo ""
    echo -e "${YELLOW}配置文件:${NC} $CONFIG_FILE"
    echo -e "${YELLOW}监听端口:${NC} $PORT"
    echo -e "${YELLOW}监听地址:${NC} $HOST"
    echo ""
    
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}配置文件内容:${NC}"
        sed 's/^/  /' "$CONFIG_FILE"
    else
        echo -e "${YELLOW}配置文件不存在，使用默认值${NC}"
    fi
    
    echo ""
}

# 编辑配置
edit_config() {
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}正在打开配置文件: $CONFIG_FILE${NC}"
        if command -v nano &> /dev/null; then
            nano "$CONFIG_FILE"
        elif command -v vim &> /dev/null; then
            vim "$CONFIG_FILE"
        elif command -v vi &> /dev/null; then
            vi "$CONFIG_FILE"
        else
            echo "$CONFIG_FILE"
            cat "$CONFIG_FILE"
        fi
        
        echo -e "${YELLOW}配置文件已修改，请重启 WebUI 使配置生效${NC}"
    else
        echo -e "${RED}配置文件不存在，无法编辑${NC}"
    fi
}
case "${1:-help}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    help)
        ;;
    config)
        case "${2:-show}" in
            show)
                show_config
                ;;
            edit)
                edit_config
                ;;
            *)
                echo -e "${RED}未知配置命令: $2${NC}"
                show_config
                exit 1
                ;;
        esac
        show_help
        ;;
    *)
        echo -e "${RED}未知命令: $1${NC}"
        show_help
        exit 1
        ;;
esac

