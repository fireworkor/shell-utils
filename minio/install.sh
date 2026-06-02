#!/bin/bash
# MinIO 安装脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="minio"
SOFTWARE_NAME="minio"
DISPLAY_NAME="MinIO"

install() {
    echo "正在安装 MinIO..."
    echo "请手动安装 MinIO，或参考 README.md 中的说明"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install "$@"
fi
