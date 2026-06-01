# Redis 缓存数据库

## 简介
Redis 是一个开源的内存数据结构存储系统，可用作数据库、缓存和消息队列。

## 端口信息
- Redis: 6379
- Redis Sentinel: 26379 (集群模式)

## 使用命令

```bash
# 安装 Redis
bash redis.sh

# 启动服务
systemctl start redis
systemctl enable redis

# 连接 Redis
redis-cli

# 查看版本
redis-server --version
```

## 默认配置
- 配置文件: `/etc/redis/redis.conf`
- 数据目录: `/var/lib/redis/`
- 日志文件: `/var/log/redis/redis.log`
- PID 文件: `/var/run/redis/redis.pid`

## 健康检查

```bash
# 基本检查
redis-cli ping

# 详细状态
redis-cli info

# 检查服务器
redis-cli info server

# 检查内存使用
redis-cli info memory

# 检查连接数
redis-cli info clients
```

## 备份

```bash
# RDB 持久化备份（自动）
# 配置文件中设置 save 规则

# 手动 BGSAVE
redis-cli BGSAVE

# 复制备份
cp /var/lib/redis/dump.rdb /backup/dump_$(date +%Y%m%d).rdb

# AOF 备份
cp /var/lib/redis/appendonly.aof /backup/appendonly_$(date +%Y%m%d).aof
```

## 恢复

```bash
# 停止 Redis
systemctl stop redis

# 恢复 RDB 文件
cp /backup/dump_20240101.rdb /var/lib/redis/dump.rdb

# 设置权限
chown redis:redis /var/lib/redis/dump.rdb

# 启动 Redis
systemctl start redis
```

## 集群
```bash
# 部署 Redis 集群
bash ../redis-cluster/redis-cluster.sh install
```

## 常用命令

```bash
# 设置键值
SET key value

# 获取值
GET key

# 查看所有键
KEYS *

# 查看信息
INFO

# 清空所有数据
FLUSHALL
```

## Web UI
推荐使用 RedisInsight 或 phpRedisAdmin。
