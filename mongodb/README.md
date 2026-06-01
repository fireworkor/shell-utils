# MongoDB 文档数据库

## 简介
MongoDB 是一个基于文档的 NoSQL 数据库，以 JSON 格式存储数据。

## 端口信息
- MongoDB: 27017
- MongoDB Web Interface: 28017

## 使用命令

```bash
# 安装 MongoDB
bash mongodb.sh

# 启动服务
systemctl start mongod
systemctl enable mongod

# 连接 MongoDB
mongosh

# 查看版本
mongod --version
```

## 默认配置
- 配置文件: `/etc/mongod.conf`
- 数据目录: `/var/lib/mongo/`
- 日志文件: `/var/log/mongodb/mongod.log`
- PID 文件: `/var/run/mongodb/mongod.pid`

## 健康检查

```bash
# 检查服务状态
systemctl status mongod

# 检查端口
netstat -tlnp | grep 27017

# 连接测试
mongosh --eval "db.adminCommand('ping')"

# 查看服务器状态
mongosh --eval "db.serverStatus()"
```

## 备份

```bash
# 全量备份
mongodump --out /backup/mongo_$(date +%Y%m%d)

# 压缩备份
mongodump --gzip --out /backup/mongo_$(date +%Y%m%d)

# 备份指定数据库
mongodump --db myapp --out /backup/myapp_$(date +%Y%m%d)

# 备份远程数据库
mongodump --host 192.168.1.100 --port 27017 --out /backup/remote_$(date +%Y%m%d)
```

## 恢复

```bash
# 恢复全量备份
mongorestore /backup/mongo_20240101

# 恢复压缩备份
mongorestore --gzip /backup/mongo_20240101

# 恢复指定数据库
mongorestore --db myapp /backup/myapp_20240101/myapp

# 删除目标数据库后恢复
mongorestore --drop /backup/mongo_20240101
```

## 集群
```bash
# 部署 MongoDB 集群
bash ../mongodb-cluster/mongodb-cluster.sh install
```

## 常用命令

```bash
# 查看数据库
show dbs

# 切换/创建数据库
use myapp

# 查看集合
show collections

# 插入文档
db.users.insertOne({name: "test", age: 25})

# 查询文档
db.users.find()

# 更新文档
db.users.updateOne({name: "test"}, {$set: {age: 30}})
```

## Web UI
推荐使用 MongoDB Compass。
