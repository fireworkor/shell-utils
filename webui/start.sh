#!/bin/bash
# 运维工具 Web UI 启动脚本

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

echo "🚀 启动运维工具管理平台..."

# 检查 Python 是否安装
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 未安装，请先安装 Python3"
    exit 1
fi

# 检查 Flask 是否安装
if ! python3 -c "import flask" &> /dev/null; then
    echo "📦 安装 Flask 依赖..."
    pip3 install flask flask-socketio
fi

# 创建日志目录
mkdir -p "$SCRIPT_DIR/logs"

# 启动服务
echo "🌐 启动 Web 服务..."
cd "$SCRIPT_DIR"
python3 app.py > "$SCRIPT_DIR/logs/webui.log" 2>&1 &
echo $! > "$SCRIPT_DIR/pid.txt"

echo "✅ 服务已启动"
echo "📍 访问地址: http://localhost:5000"
echo "📝 日志文件: $SCRIPT_DIR/logs/webui.log"