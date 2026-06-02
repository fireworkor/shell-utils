#!/bin/bash
# Python 安装脚本
# 自动生成的标准化安装脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"
VERSION="${1:-}"

# 加载通用函数
if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

# 加载软件配置
if [ -f "$SCRIPT_DIR/config" ]; then
    source "$SCRIPT_DIR/config"
fi

SERVICE_NAME="python3"
SOFTWARE_NAME="python"
DISPLAY_NAME="Python"

# 调用原始安装脚本
install() {
    if [ -f "$SCRIPT_DIR/${SOFTWARE_NAME}.sh.original" ]; then
        bash "$SCRIPT_DIR/${SOFTWARE_NAME}.sh.original" "$VERSION"
    elif [ -f "$SCRIPT_DIR/${SOFTWARE_NAME}.sh" ]; then
        bash "$SCRIPT_DIR/${SOFTWARE_NAME}.sh" "$VERSION"
    else
        log_error "未找到 python 的原始安装脚本"
        return 1
    fi
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install "$@"
fi
