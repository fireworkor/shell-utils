#!/bin/bash
# 清理工具 安装脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"
VERSION="${1:-}"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

if [ -f "$SCRIPT_DIR/config" ]; then
    source "$SCRIPT_DIR/config"
fi

SERVICE_NAME="cleanup"
SOFTWARE_NAME="cleanup"
DISPLAY_NAME="清理工具"

RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
NC='\\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

install() {
    log_info "正在安装 ${DISPLAY_NAME}..."
    
    if [ -f "$SCRIPT_DIR/${SOFTWARE_NAME}.sh.original" ]; then
        bash "$SCRIPT_DIR/${SOFTWARE_NAME}.sh.original" "$VERSION"
    elif [ -f "$SCRIPT_DIR/${SOFTWARE_NAME}.sh" ]; then
        bash "$SCRIPT_DIR/${SOFTWARE_NAME}.sh" "$VERSION"
    else
        log_warn "未找到 ${SOFTWARE_NAME} 的原始安装脚本"
        log_info "请参考 README.md 手动安装"
        return 0
    fi
    
    if [ $? -eq 0 ]; then
        log_success "${DISPLAY_NAME} 安装完成"
        return 0
    else
        log_error "${DISPLAY_NAME} 安装失败"
        return 1
    fi
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install "$@"
fi
