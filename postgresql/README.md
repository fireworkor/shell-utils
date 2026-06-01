# PostgreSQL 数据库

## 简介
PostgreSQL 是强大的开源对象-关系型数据库系统。

## 端口信息
- PostgreSQL: 5432

## 使用命令

```bash
# 安装
bash postgresql.sh

# 启动服务
systemctl start postgresql
systemctl enable postgresql

# 切换到 postgres 用户
su - postgres

# 连接
psql

# 创建数据库
createdb mydb
createuser myuser
```

## 配置文件
- 数据目录: /var/lib/postgresql
- 配置目录: /etc/postgresql

## 健康检查
```bash
systemctl status postgresql
psql -c "SELECT version();"
pg_isready
```
