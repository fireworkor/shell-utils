#!/bin/bash
# 描述：安装 SQLite 数据库

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_sqlite() {
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 SQLite...${NC}"
    
    case $pkg_manager in
        dnf|yum)
            yum install -y sqlite sqlite-devel
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y sqlite3 libsqlite3-dev
            ;;
    esac
    
    print_success "SQLite 安装完成"
    echo ""
    echo "SQLite 版本: $(sqlite3 --version)"
    echo "使用示例："
    echo "  sqlite3 test.db"
    echo "  .databases"
    echo "  CREATE TABLE test (id INT);"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_sqlite
fi