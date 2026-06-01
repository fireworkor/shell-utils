# MySQL 数据库

## 简介
MySQL 是最流行的开源关系型数据库之一。

## 端口信息
- MySQL: 3306
- MySQL X Protocol: 33060

## 使用命令

```bash
# 安装 MySQL 8.0
bash mysql.sh

# 启动服务
systemctl start mysqld
systemctl enable mysqld

# 安全初始化（设置 root 密码）
mysql_secure_installation

# 登录
mysql -u root -p

# 查看版本
mysql --version
```

## 默认配置
- 数据目录: `/var/lib/mysql/`
- 配置目录: `/etc/my.cnf` 或 `/etc/mysql/`
- 日志文件: `/var/log/mysqld.log`
- Socket: `/var/lib/mysql/mysql.sock`

## 健康检查
```bash
mysqladmin -u root -p ping
mysql -u root -p -e "SELECT 1;"
systemctl status mysqld
```

## 备份

```bash
# 全量备份
mysqldump -u root -p --all-databases > /backup/all_databases_$(date +%Y%m%d).sql

# 单个数据库备份
mysqldump -u root -p database_name > /backup/database_$(date +%Y%m%d).sql

# 压缩备份
mysqldump -u root -p --all-databases | gzip > /backup/all_$(date +%Y%m%d).sql.gz
```

## 恢复

```bash
# 恢复全量备份
mysql -u root -p < /backup/all_databases_20240101.sql

# 解压恢复
gunzip < /backup/all_20240101.sql.gz | mysql -u root -p
```

## 集群
```bash
# 使用 mysql-cluster 脚本部署集群
bash ../mysql-cluster/mysql-cluster.sh install
```

## Web UI
无自带 Web UI，推荐使用 phpMyAdmin 或 MySQL Workbench。
