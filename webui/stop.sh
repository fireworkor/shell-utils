#!/bin/bash
# 运维工具 Web UI 停止脚本

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LIB_DIR="$SCRIPT_DIR/../lib"

# 加载通用函数库
if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

print_header "停止 Web UI"

echo -e "${BLUE}⏹️ 停止运维工具管理平台...${NC}"

# 检查 pid 文件
if [ -f "$SCRIPT_DIR/pid.txt" ]; then
    pid=$(cat "$SCRIPT_DIR/pid.txt")
    
    # 检查进程是否存在
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        print_success "服务已停止"
    else
        print_warning "进程已不存在"
    fi
    
    rm -f "$SCRIPT_DIR/pid.txt"
else
    print_warning "未找到 pid 文件"
fi