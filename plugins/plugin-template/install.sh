#!/bin/bash
# =========================================
# 插件安装脚本
# 示例插件 - 展示标准插件结构
# =========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/logging.sh"

# 插件信息
PLUGIN_NAME="example-plugin"
PLUGIN_VERSION="1.0.0"
INSTALL_LOG="/var/log/shell-utils/install-${PLUGIN_NAME}.log"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$INSTALL_LOG"
}

print_header() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}\n"
}

# ========================================
# 前置检查
# ========================================

pre_install_check() {
    print_header "前置检查"
    
    log_info "检查系统要求..."
    
    # 检查是否为 root 用户
    if [ "$EUID" -ne 0 ]; then
        log_error "此脚本需要 root 权限运行"
        exit 1
    fi
    
    # 检查操作系统
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
        log_info "检测到操作系统: $OS $VER"
    else
        log_error "无法检测操作系统"
        exit 1
    fi
    
    # 检查磁盘空间
    AVAILABLE_SPACE=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
    REQUIRED_SPACE=1  # GB
    
    if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
        log_error "磁盘空间不足，需要至少 ${REQUIRED_SPACE}G，可用: ${AVAILABLE_SPACE}G"
        exit 1
    fi
    
    log_success "前置检查通过"
}

# ========================================
# 安装步骤
# ========================================

create_directories() {
    print_header "创建目录"
    
    log_info "创建插件目录..."
    
    mkdir -p "$SCRIPT_DIR/plugins/example-plugin/data"
    mkdir -p "$SCRIPT_DIR/plugins/example-plugin/logs"
    mkdir -p "$SCRIPT_DIR/plugins/example-plugin/config"
    mkdir -p "$SCRIPT_DIR/plugins/example-plugin/cache"
    
    log_success "目录创建完成"
}

install_files() {
    print_header "安装文件"
    
    log_info "安装插件文件..."
    
    # 创建示例配置文件
    cat > "$SCRIPT_DIR/plugins/example-plugin/config/plugin.conf" <<EOF
# 示例插件配置
plugin_name=$PLUGIN_NAME
plugin_version=$PLUGIN_VERSION
enabled=true
log_level=INFO
data_dir=\${SCRIPT_DIR}/plugins/example-plugin/data
EOF
    
    # 创建示例数据文件
    cat > "$SCRIPT_DIR/plugins/example-plugin/data/sample.txt" <<EOF
示例数据文件
创建时间: $(date)
EOF
    
    log_success "文件安装完成"
}

configure_plugin() {
    print_header "配置插件"
    
    log_info "配置插件参数..."
    
    # 读取配置文件
    source "$SCRIPT_DIR/plugins/example-plugin/config/plugin.conf"
    
    log_success "插件配置完成"
}

start_service() {
    print_header "启动服务"
    
    log_info "启动示例服务..."
    
    # 创建启动脚本
    cat > "$SCRIPT_DIR/plugins/example-plugin/start.sh" <<EOF
#!/bin/bash
echo "示例服务已启动"
echo "PID: \$\$"
while true; do
    sleep 60
done
EOF
    
    chmod +x "$SCRIPT_DIR/plugins/example-plugin/start.sh"
    
    log_success "服务启动完成"
}

# ========================================
# 安装后步骤
# ========================================

post_install() {
    print_header "安装后处理"
    
    log_info "注册插件..."
    
    # 创建插件状态文件
    cat > "$SCRIPT_DIR/plugins/example-plugin/.status" <<EOF
status=installed
installed=$(date)
version=$PLUGIN_VERSION
EOF
    
    # 创建符号链接
    ln -sf "$SCRIPT_DIR/plugins/example-plugin" "$SCRIPT_DIR/example-plugin" 2>/dev/null || true
    
    log_success "插件注册完成"
}

# ========================================
# 主函数
# ========================================

main() {
    echo "开始安装示例插件 v${PLUGIN_VERSION}..."
    echo "安装日志: $INSTALL_LOG"
    
    # 初始化日志
    mkdir -p "$(dirname "$INSTALL_LOG")"
    echo "# 安装日志 - $(date)" > "$INSTALL_LOG"
    
    # 执行安装步骤
    pre_install_check
    create_directories
    install_files
    configure_plugin
    start_service
    post_install
    
    print_header "安装完成"
    
    echo -e "${GREEN}示例插件安装成功！${NC}"
    echo ""
    echo "插件路径: $SCRIPT_DIR/plugins/example-plugin"
    echo "配置文件: $SCRIPT_DIR/plugins/example-plugin/config/plugin.conf"
    echo "日志文件: $INSTALL_LOG"
    echo ""
    echo "使用方法:"
    echo "  查看状态: $SCRIPT_DIR/plugins/example-plugin/info.sh"
    echo "  卸载插件: $SCRIPT_DIR/plugins/example-plugin/uninstall.sh"
    echo ""
}

# 运行安装
main "$@"
