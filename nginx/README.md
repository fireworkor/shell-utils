# Nginx Web 服务器

## 简介
Nginx 是一个高性能的 HTTP 和反向代理服务器。

## 端口信息
- HTTP: 80
- HTTPS: 443

## 使用命令

```bash
# 基础安装
bash nginx.sh

# 查看状态
systemctl status nginx

# 启动/停止/重启
systemctl start nginx
systemctl stop nginx
systemctl restart nginx

# 测试配置
nginx -t

# 查看版本
nginx -v
```

## 配置文件位置
- 主配置: `/etc/nginx/nginx.conf`
- 网站配置: `/etc/nginx/conf.d/`
- 默认站点: `/usr/share/nginx/html/`
- 配置示例: `configs/` 目录

## 常用配置示例

提供多种常用配置示例，位于 `configs/` 目录：

| 配置文件 | 用途 |
|---------|------|
| `static-site.conf` | 静态网站配置 |
| `reverse-proxy.conf` | 反向代理配置 |
| `load-balancer.conf` | 负载均衡配置 |
| `ssl-site.conf` | HTTPS + SSL配置 |
| `php-fastcgi.conf` | PHP-FPM配置 |
| `wordpress.conf` | WordPress配置 |
| `nodejs-proxy.conf` | Node.js反向代理 |
| `cache.conf` | 静态资源缓存配置 |
| `rate-limit.conf` | 限流配置 |
| `security.conf` | 安全加固配置 |

### 使用示例

```bash
# 复制配置示例到配置目录
cp configs/ssl-site.conf /etc/nginx/conf.d/

# 修改配置
vim /etc/nginx/conf.d/ssl-site.conf

# 测试并重载
nginx -t && systemctl reload nginx
```

## 健康检查
```bash
curl -I http://localhost/health
```

## 备份
```bash
cp -r /etc/nginx /var/backups/nginx.backup.$(date +%Y%m%d)
```

## Web UI
无自带 Web UI，使用系统工具或第三方工具监控。
