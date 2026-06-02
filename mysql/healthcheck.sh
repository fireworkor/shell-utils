#!/bin/bash
# MySQL 健康检查脚本
# 检查服务状态、端口、进程、资源使用等

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="mysqld"
SOFTWARE_NAME="mysql"
DISPLAY_NAME="MySQL"
SCRIPT_DIR_REF="$SCRIPT_DIR"

# 检查结果
RESULT_OK=0
RESULT_FAIL=0
ISSUES=()

# 检查服务状态
check_service() {
    echo -e "${BLUE}[1] 检查服务状态${NC}"

    if ! command -v systemctl &>/dev/null; then
        echo -e "${YELLOW}  ⚠ systemctl 不可用${NC}"
        return
    fi

    if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
        echo -e "${GREEN}  ✓ 服务 ${SERVICE_NAME} 正在运行${NC}"

        # 显示运行时间
        local uptime=$(systemctl show "${SERVICE_NAME}" --property=ActiveEnterTimestamp 2>/dev/null | cut -d= -f2)
        if [ -n "$uptime" ] && [ "$uptime" != "" ]; then
            echo "    启动时间: $uptime"
        fi
    else
        echo -e "${RED}  ✗ 服务 ${SERVICE_NAME} 未运行${NC}"
        ISSUES+=("服务未运行")
        RESULT_FAIL=$((RESULT_FAIL + 1))
    fi
}

# 检查端口监听
check_ports() {
    echo -e "${BLUE}[2] 检查端口监听${NC}"

    local ports=$(bash "$SCRIPT_DIR_REF/port.sh" show 2>/dev/null | grep "监听端口" | awk '{print $NF}' | tr ',' ' ')

    if [ -z "$ports" ]; then
        echo -e "${YELLOW}  ⚠ 未配置端口${NC}"
        return
    fi

    local port_ok=0
    for port in $ports; do
        if command -v ss &>/dev/null; then
            if ss -tuln | grep -q ":${port} "; then
                echo -e "${GREEN}  ✓ 端口 $port 正在监听${NC}"
                port_ok=$((port_ok + 1))
            else
                echo -e "${RED}  ✗ 端口 $port 未监听${NC}"
                ISSUES+=("端口 $port 未监听")
                RESULT_FAIL=$((RESULT_FAIL + 1))
            fi
        fi
    done

    if [ $port_ok -gt 0 ]; then
        RESULT_OK=$((RESULT_OK + 1))
    fi
}

# 检查进程
check_process() {
    echo -e "${BLUE}[3] 检查进程${NC}"

    if pgrep -x "${SERVICE_NAME}" &>/dev/null; then
        local pids=$(pgrep -x "${SERVICE_NAME}" | tr '\n' ' ')
        local count=$(echo "$pids" | wc -w)
        echo -e "${GREEN}  ✓ 进程运行中 (PID: $pids, 数量: $count)${NC}"
        RESULT_OK=$((RESULT_OK + 1))

        # 检查内存使用
        local mem=$(ps -o rss= -p $(echo $pids | awk '{print $1}') 2>/dev/null)
        if [ -n "$mem" ]; then
            local mem_mb=$((mem / 1024))
            echo "    内存使用: ${mem_mb}MB"
        fi
    else
        echo -e "${RED}  ✗ 未找到进程${NC}"
        ISSUES+=("进程未运行")
        RESULT_FAIL=$((RESULT_FAIL + 1))
    fi
}

# 检查配置
check_config() {
    echo -e "${BLUE}[4] 检查配置${NC}"

    case "$SOFTWARE_NAME" in
        nginx)
            if command -v nginx &>/dev/null; then
                if nginx -t &>/dev/null; then
                    echo -e "${GREEN}  ✓ Nginx 配置正确${NC}"
                    RESULT_OK=$((RESULT_OK + 1))
                else
                    echo -e "${RED}  ✗ Nginx 配置错误${NC}"
                    ISSUES+=("配置错误")
                    RESULT_FAIL=$((RESULT_FAIL + 1))
                fi
            fi
            ;;
        apache)
            if command -v apachectl &>/dev/null; then
                if apachectl configtest &>/dev/null; then
                    echo -e "${GREEN}  ✓ Apache 配置正确${NC}"
                    RESULT_OK=$((RESULT_OK + 1))
                else
                    echo -e "${RED}  ✗ Apache 配置错误${NC}"
                    ISSUES+=("配置错误")
                    RESULT_FAIL=$((RESULT_FAIL + 1))
                fi
            fi
            ;;
        *)
            echo "  - 跳过配置检查"
            ;;
    esac
}

# 检查磁盘空间
check_disk() {
    echo -e "${BLUE}[5] 检查磁盘空间${NC}"

    local usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$usage" -lt 80 ]; then
        echo -e "${GREEN}  ✓ 磁盘空间充足 (${usage}%)${NC}"
        RESULT_OK=$((RESULT_OK + 1))
    elif [ "$usage" -lt 90 ]; then
        echo -e "${YELLOW}  ⚠ 磁盘空间一般 (${usage}%)${NC}"
    else
        echo -e "${RED}  ✗ 磁盘空间不足 (${usage}%)${NC}"
        ISSUES+=("磁盘空间不足")
        RESULT_FAIL=$((RESULT_FAIL + 1))
    fi
}

# 输出总结
print_summary() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  ${DISPLAY_NAME} 健康检查总结${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "  通过项: ${GREEN}${RESULT_OK}${NC}"
    echo -e "  失败项: ${RED}${RESULT_FAIL}${NC}"

    if [ ${#ISSUES[@]} -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}问题列表:${NC}"
        for issue in "${ISSUES[@]}"; do
            echo "  - $issue"
        done
    fi

    echo ""
    if [ ${RESULT_FAIL} -eq 0 ]; then
        echo -e "${GREEN}✓ 健康检查通过${NC}"
        return 0
    else
        echo -e "${RED}✗ 健康检查发现问题${NC}"
        return 1
    fi
}

# 主函数
main() {
    print_header "${DISPLAY_NAME} 健康检查"
    echo ""

    check_service
    check_ports
    check_process
    check_config
    check_disk

    print_summary
}

main
