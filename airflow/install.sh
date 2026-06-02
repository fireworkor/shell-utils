#!/bin/bash
# Airflow 安装脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="airflow"
SOFTWARE_NAME="airflow"
DISPLAY_NAME="Airflow"

install() {
    echo "正在安装 Airflow..."
    echo "请手动安装 Airflow，或参考 README.md 中的说明"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install "$@"
fi
