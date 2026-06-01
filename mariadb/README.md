# MariaDB 数据库

## 简介
MariaDB 是 MySQL 的开源分支，完全兼容的关系型数据库。

## 端口信息
- MariaDB: 3306

## 使用命令

```bash
# 安装
bash mariadb.sh

# 启动服务
systemctl start mariadb
systemctl enable mariadb

# 连接
mysql -u root -p

# 安全配置
mysql_secure_installation
```

## 健康检查
```bash
mysqladmin -u root -p ping
systemctl status mariadb
```

## 备份恢复
```bash
mysqldump -u root -p --all-databases > backup.sql
mysql -u root -p < backup.sql
```
