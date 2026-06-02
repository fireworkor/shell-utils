# MySQL 数据库

## 简介
MySQL 是一种关系型数据库管理系统，使用最常用的数据库管理语言 SQL（结构化查询语言）进行数据库管理。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 3306 | MySQL 服务 | 默认监听端口 |

### 主要组件

- **mysqld** - MySQL 服务器主进程
- **mysqld_safe** - 启动脚本
- **mysql** - 命令行客户端
- **mysqldump** - 备份工具
- **mysqladmin** - 管理工具
- **mysqlcheck** - 表检查和修复
- **mysql_secure_installation** - 安全配置向导

### 访问入口

- **本地连接**: `mysql -u root -p`
- **远程连接**: `mysql -h <IP> -u <user> -p`
- **Web 管理界面**: 可选 phpMyAdmin、Adminer
- **配置文件**: /etc/my.cnf

---

## 首次安装后必做设置

### 1. 运行安全配置向导
```bash
sudo mysql_secure_installation
```
建议设置：
- 设置 root 密码
- 移除匿名用户
- 禁止 root 远程登录
- 移除测试数据库
- 重新加载权限表

### 2. 创建管理员用户
```bash
mysql -u root -p
```
```sql
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'YourStrongPassword';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

### 3. 配置远程访问（可选）
```bash
sudo vim /etc/mysql/mysql.conf.d/mysqld.cnf
# 将 bind-address 改为 0.0.0.0 或注释掉
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

### 端口管理

```bash
bash port.sh show
bash port.sh change 3306 3307
sudo systemctl restart mysql
```

### 备份与恢复

```bash
bash backup.sh all
bash backup.sh data
mysqldump -u root -p mydb > mydb_$(date +%Y%m%d).sql
bash restore.sh /var/backups/shell-utils/mysql/backup_20250101.tar.gz
mysql -u root -p mydb < mydb_20250101.sql
```

### 服务管理

```bash
sudo systemctl start mysqld
sudo systemctl stop mysqld
sudo systemctl restart mysqld
sudo systemctl status mysqld
sudo systemctl enable mysqld
```

---

## 常见问题

### Q: 安装失败？
A: 可能需要先卸载旧版本。

### Q: 忘记 root 密码？
A: 参考官方文档重置密码流程。

### Q: 中文乱码？
A: 配置 `character-set-server=utf8mb4`

### Q: 远程连接失败？
A: 检查防火墙、bind-address、用户权限。

---

## 后续改进方向

1. 主从复制（读写分离）
2. 性能监控（Percona Monitoring）
3. 慢查询分析
4. 自动化备份
5. 高可用方案（MHA、Orchestrator）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
