#!/bin/bash
# ClickHouse 安装脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="clickhouse"
SOFTWARE_NAME="clickhouse"
DISPLAY_NAME="ClickHouse"

install() {
    echo "正在安装 ClickHouse..."
    echo "请手动安装 ClickHouse，或参考 README.md 中的说明"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install "$@"
fi
