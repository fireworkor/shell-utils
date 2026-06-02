# SQLite 嵌入式数据库

## 简介
SQLite 是一个轻量级的嵌入式关系型数据库，零配置、无服务器、事务性 SQL 数据库引擎。

---

## 端口与组件

### 默认端口

SQLite 是嵌入式数据库，**不需要网络端口**，直接通过文件访问。

### 主要组件

- **sqlite3**: 命令行工具
- **libsqlite3**: C 语言库

### 访问入口

- **命令行**: `sqlite3 <database_file>`
- **编程接口**: C/C++, Python, PHP, Java 等

---

## 首次安装后必做设置

### 1. 安装 SQLite
```bash
cd sqlite
sudo bash install.sh
```

### 2. 验证安装
```bash
sqlite3 --version
```

### 3. 创建第一个数据库
```bash
sqlite3 /var/lib/sqlite/mydb.db
```

### 4. 基本操作
```sql
-- 创建表
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT
);

-- 插入数据
INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com');

-- 查询数据
SELECT * FROM users;

-- 退出
.quit
```

---

## 详细使用说明

### 常用命令

```bash
# 打开数据库
sqlite3 mydb.db

# 执行 SQL 文件
sqlite3 mydb.db < script.sql

# 导出数据库
sqlite3 mydb.db ".dump" > backup.sql

# 导入数据库
sqlite3 mydb.db < backup.sql
```

### SQL 操作

```sql
-- 创建表
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 插入数据
INSERT INTO users (name, email) VALUES 
    ('Bob', 'bob@example.com'),
    ('Charlie', 'charlie@example.com');

-- 查询
SELECT * FROM users WHERE name LIKE 'A%';
SELECT COUNT(*) FROM users;

-- 更新
UPDATE users SET email = 'new@example.com' WHERE id = 1;

-- 删除
DELETE FROM users WHERE id = 2;

-- 查看表结构
.schema users

-- 查看所有表
.tables

-- 退出
.quit
```

### 备份与恢复

```bash
# 备份所有数据库
bash backup.sh all

# 备份指定数据库
bash backup.sh /var/lib/sqlite/mydb.db

# 查看备份列表
bash backup.sh list

# 恢复备份
bash restore.sh mydb.db_20250101_120000.db
```

### 服务管理
SQLite 是嵌入式数据库，不需要启动/停止服务。

### 健康检查
```bash
bash healthcheck.sh
```

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 数据目录 | /var/lib/sqlite |
| 备份目录 | /var/backups/shell-utils/sqlite |

---

## 常见问题

### Q: 如何创建数据库？
A: `sqlite3 /path/to/database.db`，文件会自动创建。

### Q: 如何查看数据库文件大小？
A: `ls -lh /var/lib/sqlite/*.db`

### Q: 如何优化数据库？
A: 执行 `VACUUM;` 命令整理数据库文件。

### Q: 如何设置密码？
A: SQLite 本身不支持密码，可使用 SQLCipher 扩展。

---

## 后续改进方向

1. **SQLCipher**: 启用数据库加密
2. **FTS5**: 全文搜索扩展
3. **R-Tree**: 空间索引扩展
4. **备份策略**: 定时自动备份
5. **监控**: 数据库大小和性能监控

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
