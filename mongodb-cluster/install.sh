#!/bin/bash
# MongoDB Cluster 安装脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="mongodb-cluster"
SOFTWARE_NAME="mongodb-cluster"
DISPLAY_NAME="MongoDB Cluster"

install() {
    echo "正在安装 MongoDB Cluster..."
    echo "请手动安装 MongoDB Cluster，或参考 README.md 中的说明"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install "$@"
fi
