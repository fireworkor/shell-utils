# PostgreSQL 数据库

## 简介
PostgreSQL 是一个功能强大的开源对象关系型数据库系统，使用并扩展了 SQL 语言。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 5432 | PostgreSQL | 默认监听端口 |

### 主要组件

- **postgres** - 服务器主进程
- **psql** - 命令行客户端
- **pg_dump** - 备份工具
- **pg_restore** - 恢复工具
- **pg_ctl** - 服务控制
- **createdb/dropdb** - 数据库管理

### 访问入口

- **本地连接**: `psql -U postgres`
- **远程连接**: `psql -h <IP> -U <user> -d <db>`
- **Web 管理**: pgAdmin、Adminer

---

## 首次安装后必做设置

### 1. 切换到 postgres 用户
```bash
sudo -u postgres psql
```

### 2. 设置密码
```sql
\password postgres
```

### 3. 创建数据库和用户
```sql
CREATE USER myuser WITH PASSWORD 'mypassword';
CREATE DATABASE mydb OWNER myuser;
GRANT ALL PRIVILEGES ON DATABASE mydb TO myuser;
```

### 4. 配置远程访问
```bash
sudo vim /etc/postgresql/14/main/postgresql.conf
# listen_addresses = '*'
sudo vim /etc/postgresql/14/main/pg_hba.conf
# host    all    all    0.0.0.0/0    md5
```

### 5. 重启服务
```bash
sudo systemctl restart postgresql
```

### 6. 配置防火墙
```bash
sudo firewall-cmd --permanent --add-port=5432/tcp
sudo firewall-cmd --reload
```

---

## 详细使用说明

### 常用命令
```bash
psql -U postgres
\l
\c mydb
\dt
\d tablename
\i /path/to/file.sql
```

### 备份与恢复
```bash
bash backup.sh all
pg_dump -U postgres mydb > mydb.sql
pg_dumpall -U postgres > all.sql
psql -U postgres -d mydb < mydb.sql
```

### 服务管理
```bash
sudo systemctl start postgresql
sudo systemctl stop postgresql
sudo systemctl restart postgresql
sudo systemctl status postgresql
```

---

## 常见问题

### Q: 远程连接失败？
A: 检查 pg_hba.conf、listen_addresses

### Q: 性能问题？
A: 调整 postgresql.conf 参数

### Q: 主从复制？
A: 配置流复制

---

## 后续改进方向

1. 流复制（主从热备）
2. PostgreSQL Cluster（Patroni）
3. 逻辑复制
4. 分区表
5. pgBouncer（连接池）
6. 监控（pg_stat_statements）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
