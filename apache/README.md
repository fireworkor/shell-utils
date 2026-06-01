# Apache HTTP Server

## 简介
Apache HTTP Server 是最流行的 Web 服务器之一。

## 端口信息
- HTTP: 80
- HTTPS: 443

## 使用命令

```bash
# 基础安装
bash apache.sh

# 查看状态
systemctl status httpd (CentOS) 或 systemctl status apache2 (Ubuntu)

# 启动/停止/重启
systemctl start httpd
systemctl stop httpd
systemctl restart httpd

# 测试配置
apachectl configtest
```

## 配置文件位置
- 主配置: /etc/httpd/conf/httpd.conf (CentOS)
- 网站配置: /etc/httpd/conf.d/
- 文档根: /var/www/html/

## 健康检查
```bash
curl -I http://localhost/
apachectl status
```
