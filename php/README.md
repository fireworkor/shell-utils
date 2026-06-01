# PHP

## 简介
PHP 是一种流行的通用服务器端脚本语言。

## 使用命令

```bash
# 安装特定版本
bash php.sh 8.0
bash php.sh 8.1
bash php.sh 8.2

# 查看版本
php -v

# 查看已安装模块
php -m

# 配置检查
php -i | grep config
```

## 相关文件
- php.ini: /etc/php.ini 或 /etc/php/X.X/fpm/php.ini
- FPM 配置: /etc/php-fpm.conf

## 健康检查
```bash
systemctl status php-fpm
php -v
php -r 'phpinfo();'
```
