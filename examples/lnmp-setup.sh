#!/bin/bash

# =========================================
# 示例脚本 - LNMP 环境一键部署
# =========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/lib/common.sh" ]; then
    source "$SCRIPT_DIR/lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/lib/logging.sh" ]; then
    source "$SCRIPT_DIR/lib/logging.sh"
fi

echo "========================================"
echo "LNMP 环境一键部署"
echo "========================================"
echo ""

log_info "开始 LNMP 环境部署"

print_header "步骤 1/3 - 安装 Nginx"
bash "$SCRIPT_DIR/nginx/nginx.sh"
sleep 2

print_header "步骤 2/3 - 安装 MariaDB"
bash "$SCRIPT_DIR/mariadb/mariadb.sh"
sleep 2

print_header "步骤 3/3 - 安装 PHP"
bash "$SCRIPT_DIR/php/php.sh" 8.0

echo ""
echo "========================================"
echo "LNMP 环境部署完成！"
echo "========================================"
echo ""
echo "服务状态："
systemctl status nginx --no-pager | head -5
echo ""
systemctl status mariadb --no-pager | head -5
echo ""
echo "访问信息："
echo "  Web 根目录: /usr/share/nginx/html"
echo "  配置文件: /etc/nginx/conf.d/"
echo "  PHP-FPM: /etc/php-fpm.d/"
echo ""
echo "管理命令："
echo "  systemctl start nginx"
echo "  systemctl start mariadb"
echo "  systemctl start php-fpm"
echo ""
echo "测试命令："
echo "  echo '<?php phpinfo(); ?>' > /usr/share/nginx/html/info.php"
echo "  curl http://localhost/info.php"
