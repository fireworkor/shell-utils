#!/bin/bash
# 描述：自动部署脚本 - 拉取最新代码并重启WebUI
# 用法：./deploy.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBUI_DIR="$SCRIPT_DIR/webui"
PID_FILE="$WEBUI_DIR/pid.txt"
LOG_FILE="$WEBUI_DIR/logs/deploy.log"

echo "========================================" | tee -a "$LOG_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始部署" | tee -a "$LOG_FILE"

# 1. 拉取最新代码
echo "[1/4] 拉取最新代码..." | tee -a "$LOG_FILE"
cd "$SCRIPT_DIR"
git pull origin master 2>&1 | tee -a "$LOG_FILE"
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ git pull 失败" | tee -a "$LOG_FILE"
    exit 1
fi
echo "✅ 代码更新成功" | tee -a "$LOG_FILE"

# 2. 安装Python依赖
echo "[2/4] 检查Python依赖..." | tee -a "$LOG_FILE"
if [ -f "$WEBUI_DIR/requirements.txt" ]; then
    python3 -m pip install -r "$WEBUI_DIR/requirements.txt" -q 2>&1 | tee -a "$LOG_FILE"
fi
echo "✅ 依赖检查完成" | tee -a "$LOG_FILE"

# 3. 停止旧服务
echo "[3/4] 停止旧WebUI服务..." | tee -a "$LOG_FILE"
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        kill -9 "$OLD_PID" 2>/dev/null
        echo "✅ 已停止旧进程 (PID: $OLD_PID)" | tee -a "$LOG_FILE"
    fi
    rm -f "$PID_FILE"
else
    echo "未找到运行中的服务" | tee -a "$LOG_FILE"
fi
sleep 2

# 4. 启动新服务
echo "[4/4] 启动WebUI服务..." | tee -a "$LOG_FILE"
cd "$WEBUI_DIR"
python3 app.py > "$WEBUI_DIR/logs/webui.log" 2>&1 &
echo $! > "$PID_FILE"
sleep 2

if kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    echo "✅ WebUI 启动成功 (PID: $(cat "$PID_FILE"))" | tee -a "$LOG_FILE"
    echo "📍 访问地址: http://localhost:5000" | tee -a "$LOG_FILE"
else
    echo "❌ WebUI 启动失败，请检查日志: $WEBUI_DIR/logs/webui.log" | tee -a "$LOG_FILE"
    exit 1
fi

echo "========================================" | tee -a "$LOG_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 部署完成" | tee -a "$LOG_FILE"
