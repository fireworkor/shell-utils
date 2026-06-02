#!/bin/bash
# RabbitMQ Cluster 安装脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="rabbitmq-cluster"
SOFTWARE_NAME="rabbitmq-cluster"
DISPLAY_NAME="RabbitMQ Cluster"

install() {
    echo "正在安装 RabbitMQ Cluster..."
    echo "请手动安装 RabbitMQ Cluster，或参考 README.md 中的说明"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install "$@"
fi
