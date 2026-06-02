# Apache HTTP 服务器

## 简介
Apache HTTP Server 是 Apache 软件基金会的一个开放源码的网页服务器，是最流行的 Web 服务器软件之一。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 80 | HTTP | 提供 HTTP 访问 |
| 443 | HTTPS | 提供 HTTPS 访问 |

### 主要组件

- **httpd** - Apache 主进程
- **apache2** - Debian/Ubuntu 命名
- **apachectl** - 控制脚本
- **htpasswd** - 密码文件管理
- **ab** - 压力测试工具
- **rotatelogs** - 日志轮转

### 访问入口

- **HTTP**: `http://<服务器IP>/`
- **HTTPS**: `https://<服务器IP>/`
- **测试页**: "It works!"

---

## 首次安装后必做设置

### 1. 验证安装
```bash
httpd -v
apachectl configtest
```

### 2. 配置防火墙
```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### 3. 设置主机名
```bash
sudo vim /etc/httpd/conf/httpd.conf
# ServerName www.example.com:80
```

### 4. 创建虚拟主机
参见 Apache 虚拟主机配置示例。

### 5. 设置权限
```bash
sudo chown -R apache:apache /var/www/example.com
```

---

## 详细使用说明

### 服务管理
```bash
sudo systemctl start httpd    # CentOS
sudo systemctl start apache2  # Ubuntu
sudo systemctl enable httpd
```

### 常用模块
```bash
sudo a2enmod ssl rewrite headers
sudo a2dismod autoindex
```

### 备份与恢复
```bash
bash backup.sh all
bash restore.sh /var/backups/shell-utils/apache/backup_20250101.tar.gz
```

---

## 常见问题

### Q: 403 Forbidden？
A: 检查目录权限和 Require 指令

### Q: 加载 PHP？
A: 安装 libapache2-mod-php

### Q: 性能调优？
A: 调整 MaxRequestWorkers

---

## 后续改进方向

1. HTTPS 配置（Let's Encrypt）
2. mod_rewrite（URL 重写）
3. 访问控制（IP 白名单）
4. 日志分析（AWStats）
5. WAF 集成（ModSecurity）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
