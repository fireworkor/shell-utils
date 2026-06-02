#!/bin/bash
# Kafka Cluster 安装脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="kafka-cluster"
SOFTWARE_NAME="kafka-cluster"
DISPLAY_NAME="Kafka Cluster"

install() {
    echo "正在安装 Kafka Cluster..."
    echo "请手动安装 Kafka Cluster，或参考 README.md 中的说明"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install "$@"
fi
