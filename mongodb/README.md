# MongoDB NoSQL 数据库

## 简介
MongoDB 是一个基于分布式文件存储的数据库，由 C++ 语言编写，旨在为 WEB 应用提供可扩展的高性能数据存储解决方案。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 27017 | MongoDB | 默认服务端口 |

### 主要组件

- **mongod** - 数据库主进程
- **mongos** - 分片路由器
- **mongosh** - 命令行客户端
- **mongodump** - 备份工具
- **mongorestore** - 恢复工具

### 访问入口

- **本地连接**: `mongosh`
- **远程连接**: `mongosh mongodb://<IP>:27017`
- **Web 管理**: MongoDB Compass、Studio 3T

---

## 首次安装后必做设置

### 1. 验证安装
```bash
mongod --version
sudo systemctl status mongod
```

### 2. 启用认证
```yaml
# /etc/mongod.conf
security:
  authorization: enabled
```

### 3. 创建管理员用户
```bash
mongosh
```
```javascript
use admin
db.createUser({
  user: "admin",
  pwd: "YourStrongPassword",
  roles: [{ role: "userAdminAnyDatabase", db: "admin" }]
})
```

### 4. 配置远程访问
```yaml
net:
  port: 27017
  bindIp: 0.0.0.0
```

### 5. 重启服务
```bash
sudo systemctl restart mongod
```

### 6. 配置防火墙
```bash
sudo firewall-cmd --permanent --add-port=27017/tcp
sudo firewall-cmd --reload
```

---

## 详细使用说明

### 基本命令
```javascript
use mydb
db.users.insertOne({ name: "Alice", age: 30 })
db.users.find()
db.users.find({ age: { $gt: 25 } })
db.users.updateOne({ name: "Alice" }, { $set: { age: 31 } })
db.users.deleteOne({ name: "Alice" })
db.users.createIndex({ name: 1 })
```

### 备份与恢复
```bash
bash backup.sh all
mongodump --db mydb --out /backup/
mongorestore --db mydb /backup/mydb/
```

### 服务管理
```bash
sudo systemctl start mongod
sudo systemctl stop mongod
sudo systemctl restart mongod
sudo systemctl enable mongod
```

---

## 常见问题

### Q: 连接被拒绝？
A: 检查 bindIp、防火墙、是否启用认证

### Q: 性能问题？
A: 创建合适的索引

### Q: 数据量过大？
A: 启用分片集群

---

## 后续改进方向

1. 副本集（高可用）
2. 分片集群（水平扩展）
3. 监控（MongoDB Atlas）
4. 备份策略
5. 安全加固（TLS/SSL）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
