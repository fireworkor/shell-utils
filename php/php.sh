#!/bin/bash
# 描述：安装 PHP（支持多版本）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

install_php() {
    local version=${1:-7.4}
    check_root
    check_os
    local pkg_manager=$(get_pkg_manager)
    
    echo -e "${BLUE}正在安装 PHP $version...${NC}"
    
    case $pkg_manager in
        dnf)
            yum install -y epel-release
            yum install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
            yum module reset php -y
            yum module enable php:remi-${version} -y
            yum install -y php php-fpm php-mysql php-pdo php-mbstring \
                php-xml php-gd php-curl php-zip php-intl php-bcmath
            ;;
        yum)
            yum install -y epel-release
            yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm
            yum module reset php -y
            yum module enable php:remi-${version} -y
            yum install -y php php-fpm php-mysql php-pdo php-mbstring \
                php-xml php-gd php-curl php-zip php-intl php-bcmath
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y software-properties-common
            add-apt-repository -y ppa:ondrej/php
            apt update
            apt install -y php${version} php${version}-fpm php${version}-mysql php${version}-mbstring \
                php${version}-xml php${version}-gd php${version}-curl php${version}-zip php${version}-intl php${version}-bcmath
            ;;
    esac
    
    start_service php-fpm
    
    print_success "PHP $version 安装完成"
    echo ""
    echo "PHP 版本: $(php -v | head -1)"
    echo "配置目录: /etc/php.ini (CentOS) 或 /etc/php/${version}/fpm/php.ini (Ubuntu)"
}

# 直接运行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_php "$@"
fi
