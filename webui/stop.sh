#!/bin/bash
# 运维工具 Web UI 停止脚本

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

echo "⏹️ 停止运维工具管理平台..."

# 检查 pid 文件
if [ -f "$SCRIPT_DIR/pid.txt" ]; then
    pid=$(cat "$SCRIPT_DIR/pid.txt")
    
    # 检查进程是否存在
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid"
        echo "✅ 服务已停止"
    else
        echo "⚠️ 进程已不存在"
    fi
    
    rm -f "$SCRIPT_DIR/pid.txt"
else
    echo "⚠️ 未找到 pid 文件"
fi