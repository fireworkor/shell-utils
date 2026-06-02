#!/bin/bash
# SQLite 安装脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="sqlite3"
SOFTWARE_NAME="sqlite"
DISPLAY_NAME="SQLite"

install() {
    echo "正在安装 SQLite..."
    
    # 检查系统
    if [ -f /etc/redhat-release ]; then
        sudo yum install -y sqlite sqlite-devel
    elif [ -f /etc/debian_version ]; then
        sudo apt update && sudo apt install -y sqlite3 libsqlite3-dev
    fi
    
    # 创建数据目录
    sudo mkdir -p /var/lib/sqlite
    sudo chmod 755 /var/lib/sqlite
    
    echo "SQLite 安装完成"
    sqlite3 --version
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install "$@"
fi
