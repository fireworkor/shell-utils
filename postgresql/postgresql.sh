#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

install_postgresql() {
    check_root
    check_os

    local pkg_manager=$(get_pkg_manager)
    echo "使用包管理器: $pkg_manager"

    case $pkg_manager in
        apt)
            rm -f /etc/apt/sources.list.d/pgdg.list
            apt update
            apt install -y gnupg wget lsb-release ca-certificates

            mkdir -p /etc/apt/keyrings
            # 下载官方 GPG 密钥
            wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/keyrings/postgresql.gpg

            # 尝试国内镜像，如果失败则使用官方源
            local mirror_url="https://mirrors.aliyun.com/postgresql/repos/apt"
            local codename=$(lsb_release -cs)
            echo "deb [signed-by=/etc/apt/keyrings/postgresql.gpg] $mirror_url ${codename}-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list

            if ! apt update 2>&1 | grep -q "Release file"; then
                echo "国内镜像可用，继续安装"
            else
                echo "国内镜像失败，切换到官方源"
                rm -f /etc/apt/sources.list.d/pgdg.list
                echo "deb [signed-by=/etc/apt/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt ${codename}-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list
                apt update
            fi

            apt install -y postgresql-15
            ;;
        dnf|yum)
            echo "RHEL/CentOS 安装逻辑未实现"
            exit 1
            ;;
        *)
            print_error "不支持的包管理器"
            exit 1
            ;;
    esac

    systemctl start postgresql
    systemctl enable postgresql
    print_success "PostgreSQL 15 安装完成"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_postgresql
fi
