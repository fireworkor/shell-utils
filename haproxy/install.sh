#!/bin/bash
# HAProxy 安装脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="haproxy"
SOFTWARE_NAME="haproxy"
DISPLAY_NAME="HAProxy"

install() {
    echo "正在安装 HAProxy..."
    echo "请手动安装 HAProxy，或参考 README.md 中的说明"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install "$@"
fi
