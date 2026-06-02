# PHP 编程语言

## 简介
PHP（PHP: Hypertext Preprocessor）即"超文本预处理器"，是在服务器端执行的脚本语言，尤其适用于 Web 开发并能嵌入 HTML 中。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 9000 | PHP-FPM | FastCGI 进程管理器 |

### 主要组件

- **php** - PHP CLI
- **php-fpm** - FastCGI 进程管理器
- **php-cgi** - CGI 接口
- **phpize** - 扩展编译工具
- **php-config** - 配置查询工具
- **pecl** - 扩展包管理器
- **composer** - 依赖管理工具

### 访问入口

- **命令行**: `php -v`
- **Web 访问**: 通过 Nginx/Apache + PHP-FPM
- **测试页面**: 创建 phpinfo 验证

---

## 首次安装后必做设置

### 1. 验证安装
```bash
php -v
php -m
```

### 2. 配置 PHP-FPM
```bash
sudo vim /etc/php/8.0/fpm/pool.d/www.conf
# 修改监听
listen = /run/php/php8.0-fpm.sock
```

### 3. 安装常用扩展
```bash
sudo apt install php-curl php-gd php-mbstring php-xml php-zip php-mysql
```

### 4. 安装 Composer
```bash
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
```

### 5. 配置 Nginx 集成
参见 nginx/README.md 的 PHP-FPM 配置示例。

---

## 详细使用说明

### 版本管理
```bash
bash version.sh show
bash version.sh switch 7.4
```

### 端口管理
```bash
bash port.sh show
bash port.sh change 9000 9001
```

### 备份与恢复
```bash
bash backup.sh all
bash restore.sh /var/backups/shell-utils/php/backup_20250101.tar.gz
```

### 服务管理
```bash
sudo systemctl start php8.0-fpm
sudo systemctl enable php8.0-fpm
```

---

## 常见问题

### Q: PHP-FPM 无法启动？
A: 查看 `/var/log/php-fpm/` 日志

### Q: 502 Bad Gateway？
A: 检查 Nginx 配置和 PHP-FPM 监听

### Q: 扩展缺失？
A: `apt search php-` 查找

---

## 后续改进方向

1. OPcache 优化
2. Xdebug 集成
3. PHPUnit 测试
4. 性能监控（Tideways、Blackfire）
5. 安全加固

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
