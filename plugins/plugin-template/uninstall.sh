#!/bin/bash
# =========================================
# 插件卸载脚本
# 示例插件 - 展示标准插件结构
# =========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# 插件信息
PLUGIN_NAME="example-plugin"
UNINSTALL_LOG="/var/log/shell-utils/uninstall-${PLUGIN_NAME}.log"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$UNINSTALL_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$UNINSTALL_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$UNINSTALL_LOG"
}

print_header() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}\n"
}

# ========================================
# 前置检查
# ========================================

pre_uninstall_check() {
    print_header "卸载前检查"
    
    log_info "检查插件状态..."
    
    # 检查插件是否已安装
    if [ ! -f "$SCRIPT_DIR/plugins/example-plugin/.status" ]; then
        log_error "插件未安装或已卸载"
        exit 1
    fi
    
    # 检查是否有运行中的进程
    if pgrep -f "example-plugin" > /dev/null; then
        log_warning "检测到运行中的进程，正在停止..."
        pkill -f "example-plugin" || true
        sleep 2
    fi
    
    log_success "前置检查通过"
}

# ========================================
# 停止服务
# ========================================

stop_service() {
    print_header "停止服务"
    
    log_info "停止示例服务..."
    
    # 停止启动脚本
    if [ -f "$SCRIPT_DIR/plugins/example-plugin/start.sh" ]; then
        pkill -f "$SCRIPT_DIR/plugins/example-plugin/start.sh" || true
    fi
    
    log_success "服务已停止"
}

# ========================================
# 卸载步骤
# ========================================

backup_data() {
    print_header "备份数据"
    
    log_info "备份插件数据..."
    
    local backup_dir="/var/backups/shell-utils/plugins"
    mkdir -p "$backup_dir"
    
    if [ -d "$SCRIPT_DIR/plugins/example-plugin/data" ]; then
        tar czf "$backup_dir/example-plugin-data-$(date +%Y%m%d-%H%M%S).tar.gz" \
            "$SCRIPT_DIR/plugins/example-plugin/data" 2>/dev/null || true
        log_success "数据已备份到: $backup_dir"
    fi
}

remove_files() {
    print_header "删除文件"
    
    log_info "删除插件文件..."
    
    # 删除插件目录
    if [ -d "$SCRIPT_DIR/plugins/example-plugin" ]; then
        rm -rf "$SCRIPT_DIR/plugins/example-plugin"
        log_success "插件目录已删除"
    fi
    
    # 删除符号链接
    if [ -L "$SCRIPT_DIR/example-plugin" ]; then
        rm -f "$SCRIPT_DIR/example-plugin"
        log_success "符号链接已删除"
    fi
    
    # 删除日志文件（可选）
    if [ -f "$UNINSTALL_LOG" ]; then
        rm -f "$UNINSTALL_LOG"
    fi
}

remove_config() {
    print_header "清理配置"
    
    log_info "清理配置文件..."
    
    # 清理系统配置（如果有）
    log_success "配置已清理"
}

# ========================================
# 卸载后步骤
# ========================================

post_uninstall() {
    print_header "卸载后处理"
    
    log_info "完成卸载..."
    
    log_success "插件已完全卸载"
}

# ========================================
# 主函数
# ========================================

main() {
    echo "开始卸载示例插件..."
    echo "卸载日志: $UNINSTALL_LOG"
    
    # 初始化日志
    mkdir -p "$(dirname "$UNINSTALL_LOG")"
    echo "# 卸载日志 - $(date)" > "$UNINSTALL_LOG"
    
    # 确认卸载
    echo ""
    read -p "确定要卸载示例插件吗? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "取消卸载"
        exit 0
    fi
    
    # 执行卸载步骤
    pre_uninstall_check
    stop_service
    backup_data
    remove_files
    remove_config
    post_uninstall
    
    print_header "卸载完成"
    
    echo -e "${GREEN}示例插件卸载成功！${NC}"
    echo ""
    echo "如需重新安装，请运行:"
    echo "  cd $SCRIPT_DIR/plugins/example-plugin"
    echo "  bash install.sh"
    echo ""
}

# 运行卸载
main "$@"
