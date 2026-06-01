#!/bin/bash
# 运维工具 Web UI 启动脚本

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LIB_DIR="$SCRIPT_DIR/../lib"

# 加载通用函数库
if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

print_header "启动 Web UI"

echo -e "${BLUE}🚀 启动运维工具管理平台...${NC}"

# 检测操作系统
detect_os

# 检查并安装基础命令
check_and_install_command() {
    local cmd=$1
    local package=$2
    if ! command -v $cmd &> /dev/null; then
        echo -e "${YELLOW}📦 安装 $cmd...${NC}"
        pkg_manager=$(get_pkg_manager)
        case $pkg_manager in
            dnf|yum)
                $pkg_manager install -y $package
                ;;
            apt)
                export DEBIAN_FRONTEND=noninteractive
                apt update
                apt install -y $package
                ;;
        esac
    fi
}

# 检查并安装所有需要的命令
check_and_install_command python3 python3
check_and_install_command curl curl
check_and_install_command kill procps
check_and_install_command sleep coreutils
check_and_install_command mkdir coreutils
check_and_install_command rm coreutils
check_and_install_command cat coreutils

# 检查并安装 Python3-pip
if ! python3 -m pip --version &> /dev/null; then
    echo -e "${YELLOW}📦 安装 python3-pip...${NC}"
    pkg_manager=$(get_pkg_manager)
    case $pkg_manager in
        dnf|yum)
            $pkg_manager install -y python3-pip
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y python3-pip
            ;;
    esac
    # 如果系统包管理器不行，尝试通过get-pip.py安装
    if ! python3 -m pip --version &> /dev/null; then
        echo -e "${YELLOW}尝试通过 get-pip.py 安装...${NC}"
        curl -sSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
        python3 /tmp/get-pip.py
        rm -f /tmp/get-pip.py
    fi
    print_success "pip 模块安装完成"
fi

# 检查并安装 Flask
if ! python3 -c "import flask" &> /dev/null; then
    echo -e "${YELLOW}📦 安装 Flask 依赖...${NC}"
    python3 -m pip install flask flask-socketio
    print_success "Flask 依赖安装完成"
fi

# 创建日志目录
mkdir -p "$SCRIPT_DIR/logs"

# 停止已存在的服务
if [ -f "$SCRIPT_DIR/pid.txt" ]; then
    old_pid=$(cat "$SCRIPT_DIR/pid.txt")
    if kill -0 $old_pid 2>/dev/null; then
        echo -e "${YELLOW}停止已存在的服务...${NC}"
        kill $old_pid 2>/dev/null
        sleep 1
    fi
    rm -f "$SCRIPT_DIR/pid.txt"
fi

# 启动服务
echo -e "${BLUE}🌐 启动 Web 服务...${NC}"
cd "$SCRIPT_DIR"
python3 app.py > "$SCRIPT_DIR/logs/webui.log" 2>&1 &
echo $! > "$SCRIPT_DIR/pid.txt"

print_success "服务已启动"
echo ""
echo -e "${CYAN}📍 访问地址: http://localhost:5000${NC}"
echo -e "${CYAN}📝 日志文件: $SCRIPT_DIR/logs/webui.log${NC}"