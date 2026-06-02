#!/bin/bash
# Kafka 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="kafka"
SOFTWARE_NAME="kafka"
DISPLAY_NAME="Kafka"
SCRIPT_DIR_REF="$SCRIPT_DIR"

print_header "${DISPLAY_NAME} 信息"
echo ""

echo -e "${BLUE}基本信息${NC}"
echo "  软件名称: ${DISPLAY_NAME}"
echo "  包名: ${SOFTWARE_NAME}"
echo "  服务名: ${SERVICE_NAME}"
echo ""

echo -e "${BLUE}安装状态${NC}"
if command -v ${SERVICE_NAME} &>/dev/null; then
    echo -e "  状态: ${GREEN}已安装${NC}"
    version=$(${SERVICE_NAME} --version 2>&1 | head -1 || echo "未知")
    echo "  版本: $version"
    path=$(which ${SERVICE_NAME})
    echo "  路径: $path"
else
    echo -e "  状态: ${RED}未安装${NC}"
fi
echo ""

echo -e "${BLUE}服务状态${NC}"
if command -v systemctl &>/dev/null; then
    if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
        echo -e "  服务: ${GREEN}运行中${NC}"
        uptime=$(systemctl show "${SERVICE_NAME}" --property=ActiveEnterTimestamp 2>/dev/null | cut -d= -f2)
        echo "  启动时间: $uptime"
    else
        echo -e "  服务: ${RED}未运行${NC}"
    fi

    if systemctl is-enabled --quiet "${SERVICE_NAME}" 2>/dev/null; then
        echo "  开机启动: 是"
    else
        echo "  开机启动: 否"
    fi
else
    echo "  systemctl 不可用"
fi
echo ""

echo -e "${BLUE}端口信息${NC}"
bash "$SCRIPT_DIR_REF/port.sh" show 2>/dev/null
echo ""

echo -e "${BLUE}配置目录${NC}"
case "$SOFTWARE_NAME" in
    nginx)
        echo "  配置: /etc/nginx/"
        echo "  日志: /var/log/nginx/"
        ;;
    apache)
        echo "  配置: /etc/httpd/ 或 /etc/apache2/"
        echo "  日志: /var/log/httpd/ 或 /var/log/apache2/"
        ;;
    mysql|mariadb)
        echo "  配置: /etc/mysql/ 或 /etc/my.cnf"
        echo "  数据: /var/lib/mysql/"
        echo "  日志: /var/log/mysql/ 或 /var/log/mariadb/"
        ;;
    redis)
        echo "  配置: /etc/redis/"
        echo "  数据: /var/lib/redis/"
        echo "  日志: /var/log/redis/"
        ;;
    *)
        echo "  配置: /etc/${SERVICE_NAME}/"
        ;;
esac
echo ""

echo -e "${BLUE}备份列表${NC}"
bash "$SCRIPT_DIR_REF/backup.sh" list 2>/dev/null
