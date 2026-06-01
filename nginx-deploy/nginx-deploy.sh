#!/bin/bash
# 描述：Nginx 示例网站一键部署脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

install_nginx() {
    print_step 1 5 "检查/安装 Nginx"
    
    if command -v nginx &>/dev/null; then
        print_info "Nginx 已安装: $(nginx -v 2>&1)"
    else
        local pkg_manager=$(get_pkg_manager)
        case $pkg_manager in
            dnf|yum)
                yum install -y nginx
                ;;
            apt)
                export DEBIAN_FRONTEND=noninteractive
                apt update
                apt install -y nginx
                ;;
        esac
    fi
    
    systemctl enable nginx
    systemctl start nginx
    
    print_success "Nginx 安装完成"
}

deploy_static_site() {
    local domain=$1
    local site_dir="/var/www/$domain"
    
    print_step 2 5 "部署静态网站"
    print_info "域名: $domain"
    print_info "目录: $site_dir"
    
    mkdir -p "$site_dir"
    
    cat > "$site_dir/index.html" << EOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$domain - 静态网站</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            padding: 3rem;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            text-align: center;
            max-width: 600px;
        }
        h1 { color: #333; margin-bottom: 1rem; font-size: 2.5rem; }
        p { color: #666; margin-bottom: 1rem; line-height: 1.8; }
        .badge {
            display: inline-block;
            padding: 0.5rem 1rem;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 50px;
            margin-top: 1rem;
        }
        .info { margin-top: 2rem; padding: 1rem; background: #f5f5f5; border-radius: 10px; }
        .info p { margin: 0.3rem 0; font-size: 0.9rem; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Welcome!</h1>
        <p>静态网站部署成功！</p>
        <span class="badge">Nginx + 静态页面</span>
        <div class="info">
            <p><strong>域名:</strong> $domain</p>
            <p><strong>服务器:</strong> $(hostname)</p>
            <p><strong>时间:</strong> $(date '+%Y-%m-%d %H:%M:%S')</p>
            <p><strong>IP地址:</strong> $(hostname -I | awk '{print $1}')</p>
        </div>
    </div>
</body>
</html>
EOF
    
    cat > "$site_dir/about.html" << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>关于我们</title>
    <style>
        body { font-family: sans-serif; background: #f5f5f5; padding: 2rem; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 2rem; border-radius: 10px; }
        h1 { color: #333; border-bottom: 2px solid #667eea; padding-bottom: 0.5rem; }
    </style>
</head>
<body>
    <div class="container">
        <h1>关于我们</h1>
        <p>这是一个由 Shell 脚本自动部署的静态网站。</p>
        <p>Powered by Nginx</p>
    </div>
</body>
</html>
EOF
    
    chown -R nginx:nginx "$site_dir"
    chmod -R 755 "$site_dir"
    
    print_success "静态网站部署完成"
}

deploy_php_site() {
    local domain=$1
    local site_dir="/var/www/$domain"
    
    print_step 2 5 "部署 PHP 网站"
    print_info "域名: $domain"
    print_info "目录: $site_dir"
    
    mkdir -p "$site_dir"
    
    cat > "$site_dir/index.php" << 'EOF'
<?php
phpinfo();
?>
EOF

    cat > "$site_dir/info.php" << 'EOF'
<?php
echo "<h1>PHP 网站部署成功！</h1>";
echo "<p>服务器时间: " . date('Y-m-d H:i:s') . "</p>";
echo "<p>PHP 版本: " . phpversion() . "</p>";
echo "<p>服务器主机名: " . gethostname() . "</p>";

phpinfo();
?>
EOF
    
    cat > "$site_dir/api.php" << 'EOF'
<?php
header('Content-Type: application/json');

$response = [
    'status' => 'success',
    'message' => 'API 工作正常',
    'timestamp' => time(),
    'server' => gethostname(),
    'php_version' => phpversion(),
    'request_uri' => $_SERVER['REQUEST_URI'] ?? ''
];

echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?>
EOF
    
    chown -R nginx:nginx "$site_dir"
    chmod -R 755 "$site_dir"
    
    print_success "PHP 网站部署完成"
}

deploy_nodejs_site() {
    local domain=$1
    local port=${2:-3000}
    local app_dir="/var/www/$domain"
    
    print_step 2 5 "部署 Node.js 应用"
    print_info "域名: $domain"
    print_info "目录: $app_dir"
    print_info "端口: $port"
    
    mkdir -p "$app_dir"
    
    cat > "$app_dir/package.json << 'EOF'
{
  "name": "nodejs-app",
  "version": "1.0.0",
  "description": "Node.js Application",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  }
}
EOF

    cat > "$app_dir/server.js << 'EOF'
const http = require('http');
const os = require('os');

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    
    const html = `
    <!DOCTYPE html>
    <html>
    <head>
        <title>Node.js 应用</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #f0f0f0; }
            .container { background: white; padding: 30px; border-radius: 10px; max-width: 600px; margin: 0 auto; }
            h1 { color: #333; }
            .info { background: #e8f5e9; padding: 15px; border-radius: 5px; margin-top: 20px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🎉 Node.js 应用部署成功!</h1>
            <p>服务器时间: ${new Date().toLocaleString('zh-CN')}</p>
            <p>主机名: ${os.hostname()}</p>
            <p>Node.js 版本: ${process.version}</p>
            <p>平台: ${os.platform()} ${os.arch()}</p>
            <p>总内存: ${(os.totalmem() / 1024 / 1024 / 1024).toFixed(2)} GB</p>
            <p>空闲内存: ${(os.freemem() / 1024 / 1024 / 1024).toFixed(2)} GB</p>
        </div>
    </body>
    </html>
    `;
    
    res.end(html);
});

server.listen(PORT, () => {
    console.log(`服务器运行在 http://localhost:${PORT}`);
});
EOF
    
    cd "$app_dir" && npm install
    
    chown -R nginx:nginx "$app_dir"
    
    print_success "Node.js 应用部署完成"
    print_info "运行命令: cd $app_dir && npm start"
}

config_nginx_vhost() {
    local domain=$1
    local type=$2
    local port=${3:-3000}
    local site_dir="/var/www/$domain"
    
    print_step 3 5 "配置 Nginx 虚拟主机"
    
    case $type in
        static)
            cat > "/etc/nginx/conf.d/$domain.conf" << EOF
server {
    listen 80;
    server_name $domain;
    
    root $site_dir;
    index index.html index.htm;
    
    charset utf-8;
    
    access_log /var/log/nginx/$domain.access.log;
    error_log /var/log/nginx/$domain.error.log;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 7d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
}
EOF
            ;;
        php)
            cat > "/etc/nginx/conf.d/$domain.conf" << EOF
server {
    listen 80;
    server_name $domain;
    
    root $site_dir;
    index index.php index.html index.htm;
    
    charset utf-8;
    
    access_log /var/log/nginx/$domain.access.log;
    error_log /var/log/nginx/$domain.error.log;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF
            ;;
        nodejs)
            cat > "/etc/nginx/conf.d/$domain.conf" << EOF
server {
    listen 80;
    server_name $domain;
    
    access_log /var/log/nginx/$domain.access.log;
    error_log /var/log/nginx/$domain.error.log;
    
    location / {
        proxy_pass http://127.0.0.1:$port;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
            ;;
    esac
    
    print_success "Nginx 虚拟主机配置完成"
}

test_and_reload() {
    print_step 4 5 "测试并重载 Nginx"
    
    nginx -t
    
    if [ $? -eq 0 ]; then
        systemctl reload nginx
        print_success "Nginx 配置重载成功"
    else
        print_error "Nginx 配置测试失败"
        exit 1
    fi
}

show_result() {
    local domain=$1
    local type=$2
    
    print_step 5 5 "部署完成"
    
    echo ""
    echo "=========================================="
    echo "   网站部署完成"
    echo "=========================================="
    echo ""
    echo -e "${GREEN}网站信息:${NC}"
    echo "  域名: $domain"
    echo "  类型: $type"
    echo "  目录: /var/www/$domain"
    echo ""
    echo -e "${GREEN}访问地址:${NC}"
    echo "  http://$domain"
    echo "  http://localhost"
    echo ""
    
    if [ "$type" = "php" ]; then
        echo -e "${GREEN}测试页面:${NC}"
        echo "  http://$domain/info.php"
        echo "  http://$domain/api.php"
    fi
    
    echo ""
    echo -e "${GREEN}常用命令:${NC}"
    echo "  查看日志: tail -f /var/log/nginx/$domain.access.log"
    echo "  编辑配置: vim /etc/nginx/conf.d/$domain.conf"
    echo "  重载配置: nginx -s reload"
    echo ""
}

show_usage() {
    cat << EOF
${GREEN}Nginx 网站一键部署工具${NC}

${YELLOW}用法:${NC}
  $0 <类型> <域名> [端口]

${YELLOW}网站类型:${NC}
  static   - 静态网站
  php      - PHP 网站
  nodejs   - Node.js 应用

${YELLOW}示例:${NC}
  # 部署静态网站
  $0 static www.example.com
  
  # 部署 PHP 网站
  $0 php php.example.com
  
  # 部署 Node.js 应用
  $0 nodejs node.example.com 3000

${YELLOW}其他命令:${NC}
  $0 list           - 列出已部署的网站
  $0 delete <域名>  - 删除网站
EOF
}

deploy_website() {
    local type=$1
    local domain=$2
    local port=${3:-3000}
    
    print_header "部署 $type 网站: $domain"
    
    install_nginx
    
    case $type in
        static)
            deploy_static_site "$domain"
            config_nginx_vhost "$domain" "static"
            ;;
        php)
            install_php
            deploy_php_site "$domain"
            config_nginx_vhost "$domain" "php"
            ;;
        nodejs)
            install_nodejs
            deploy_nodejs_site "$domain" "$port"
            config_nginx_vhost "$domain" "nodejs" "$port"
            ;;
        *)
            print_error "未知网站类型: $type"
            show_usage
            exit 1
            ;;
    esac
    
    test_and_reload
    show_result "$domain" "$type"
}

install_php() {
    print_info "安装 PHP-FPM"
    
    local pkg_manager=$(get_pkg_manager)
    case $pkg_manager in
        dnf|yum)
            yum install -y php-fpm php-mysql php-gd php-mbstring
            ;;
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt update
            apt install -y php-fpm php-mysql php-gd php-mbstring
            ;;
    esac
    
    systemctl enable php-fpm
    systemctl start php-fpm
}

install_nodejs() {
    print_info "安装 Node.js"
    
    if ! command -v node &>/dev/null; then
        curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
        local pkg_manager=$(get_pkg_manager)
        case $pkg_manager in
            dnf|yum)
                yum install -y nodejs
                ;;
            apt)
                curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
                apt install -y nodejs
                ;;
        esac
    fi
}

list_sites() {
    print_header "已部署的网站"
    
    echo -e "${YELLOW}域名                  类型    目录${NC}"
    echo "----------------------------------------"
    
    for conf in /etc/nginx/conf.d/*.conf; do
        if [ -f "$conf" ]; then
            domain=$(basename "$conf" .conf)
            root=$(grep -E "^\s*root" "$conf" | head -1 | awk '{print $2}' | tr ';' ' ' | tr -d ' ')
            type="unknown"
            
            if grep -q "\.php" "$conf"; then
                type="PHP"
            elif grep -q "proxy_pass" "$conf"; then
                type="Node.js"
            else
                type="静态"
            fi
            
            printf "%-22s %-8s %s\n" "$domain" "$type" "$root"
        fi
    done
}

delete_site() {
    local domain=$1
    
    print_header "删除网站: $domain"
    
    rm -f "/etc/nginx/conf.d/$domain.conf"
    rm -rf "/var/www/$domain"
    
    nginx -t && systemctl reload nginx
    
    print_success "网站已删除"
}

main() {
    local command=$1
    shift
    
    case $command in
        static|php|nodejs)
            deploy_website "$command" "$@"
            ;;
        list)
            list_sites
            ;;
        delete)
            delete_site "$1"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            show_usage
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
