#!/bin/bash
# Spark 版本管理脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

show_current_version() {
    if [ -f "/opt/spark/VERSION" ]; then
        echo "${GREEN}当前版本:${NC} $(cat /opt/spark/VERSION)"
    elif [ -d "/opt/spark" ]; then
        echo "${YELLOW}版本信息未配置${NC}"
    else
        echo "${YELLOW}软件未安装${NC}"
    fi
}

case "${1:-show}" in
    show|status)
        show_current_version
        ;;
    *)
        show_current_version
        echo "用法: $0 {show}"
        ;;
esac
