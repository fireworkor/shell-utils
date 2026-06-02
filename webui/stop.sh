#!/bin/bash
# 运维工具 Web UI 停止脚本 - 向后兼容
# 新脚本请使用 webui.sh

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [ -f "$SCRIPT_DIR/webui.sh" ]; then
    exec "$SCRIPT_DIR/webui.sh" stop
else
    echo "错误：找不到 webui.sh 脚本"
    exit 1
fi

