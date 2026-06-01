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
