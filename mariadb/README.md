# MariaDB 数据库

## 简介
MariaDB 是 MySQL 的一个分支，由 MySQL 创始人主导开发，目标是完全兼容 MySQL。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 3306 | MariaDB 服务 | 与 MySQL 相同 |

### 主要组件

- **mariadbd** - MariaDB 服务器
- **mariadb** - 命令行客户端
- **mariadb-dump** - 备份工具
- **mariadb-admin** - 管理工具
- **mariadb-secure-installation** - 安全配置

### 访问入口

- **本地连接**: `mariadb -u root -p`
- **远程连接**: `mariadb -h <IP> -u <user> -p`
- **Web 管理**: phpMyAdmin、Adminer

---

## 首次安装后必做设置

### 1. 安全初始化
```bash
sudo mariadb-secure-installation
```

### 2. 设置 root 密码
```bash
sudo mariadb
```
```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'YourStrongPassword';
FLUSH PRIVILEGES;
```

### 3. 创建管理员用户
```sql
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'YourPassword';
GRANT ALL ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;
```

### 4. 配置防火墙
```bash
sudo firewall-cmd --permanent --add-port=3306/tcp
sudo firewall-cmd --reload
```

### 5. 立即备份
```bash
bash backup.sh all
```

---

## 详细使用说明

### 服务管理
```bash
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo systemctl status mariadb
```

### 备份与恢复
```bash
bash backup.sh all
bash backup.sh data
mariadb-dump -u root -p --all-databases > backup.sql
mariadb -u root -p < backup.sql
```

### 端口管理
```bash
bash port.sh show
bash port.sh change 3306 3307
```

---

## 常见问题

### Q: 与 MySQL 的区别？
A: 完全兼容 MySQL，但增加了新特性、性能优化。

### Q: 如何从 MySQL 迁移？
A: mysqldump 备份，mariadb 导入即可。

---

## 后续改进方向

1. Galera Cluster（多主集群）
2. ColumnStore（列式存储）
3. 性能监控
4. 自动化备份
5. 慢查询分析

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
