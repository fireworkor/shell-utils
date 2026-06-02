#!/bin/bash
# PostgreSQL Cluster 安装脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="postgresql-cluster"
SOFTWARE_NAME="postgresql-cluster"
DISPLAY_NAME="PostgreSQL Cluster"

install() {
    echo "正在安装 PostgreSQL Cluster..."
    echo "请手动安装 PostgreSQL Cluster，或参考 README.md 中的说明"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install "$@"
fi
