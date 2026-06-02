#!/bin/bash
# InfluxDB 安装脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="influxdb"
SOFTWARE_NAME="influxdb"
DISPLAY_NAME="InfluxDB"

install() {
    echo "正在安装 InfluxDB..."
    echo "请手动安装 InfluxDB，或参考 README.md 中的说明"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install "$@"
fi
