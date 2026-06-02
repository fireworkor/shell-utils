# Redis 缓存数据库

## 简介
Redis（Remote Dictionary Server）是一个开源的、基于内存的数据结构存储系统，可以用作数据库、缓存和消息中间件。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 6379 | Redis 服务 | 默认监听端口 |

### 主要组件

- **redis-server** - Redis 服务器
- **redis-cli** - 命令行客户端
- **redis-benchmark** - 性能测试工具
- **redis-sentinel** - 哨兵（高可用）
- **redis-cluster** - 集群管理

### 访问入口

- **本地连接**: `redis-cli`
- **远程连接**: `redis-cli -h <IP> -p 6379`
- **Web 管理**: RedisInsight、RedisDesktopManager

---

## 首次安装后必做设置

### 1. 设置访问密码
```bash
sudo vim /etc/redis/redis.conf
# requirepass yourStrongPassword
sudo systemctl restart redis
```

### 2. 启用持久化
默认已开启 RDB 持久化，建议同时启用 AOF：
```
appendonly yes
```

### 3. 配置最大内存
```
maxmemory 2gb
maxmemory-policy allkeys-lru
```

### 4. 限制远程访问
```bash
# 绑定特定 IP
bind 127.0.0.1 192.168.1.100
```

### 5. 配置防火墙
```bash
sudo firewall-cmd --permanent --add-port=6379/tcp
sudo firewall-cmd --reload
```

---

## 详细使用说明

### 常用命令

```bash
# 连接
redis-cli -a yourPassword

# 信息查看
INFO
INFO memory
DBSIZE

# 数据操作
SET key value
GET key
DEL key
EXPIRE key 60
KEYS pattern

# 性能测试
redis-benchmark -h 127.0.0.1 -p 6379 -n 10000
```

### 备份与恢复

```bash
# 自动备份（配置 save 规则）
# 手动备份
redis-cli BGSAVE

# 使用脚本
bash backup.sh all

# 恢复
sudo cp /var/backups/shell-utils/redis/data/redis_20250101.rdb /var/lib/redis/dump.rdb
sudo chown redis:redis /var/lib/redis/dump.rdb
sudo systemctl start redis
```

### 服务管理
```bash
sudo systemctl start redis
sudo systemctl stop redis
sudo systemctl restart redis
sudo systemctl enable redis
```

---

## 常见问题

### Q: 启动失败？
A: 查看 `/var/log/redis/redis.log`

### Q: 内存占用过高？
A: 配置 maxmemory 和淘汰策略

### Q: 性能调优？
A: 调整 tcp-keepalive、timeout 参数

---

## 后续改进方向

1. Redis Sentinel（高可用）
2. Redis Cluster（集群分片）
3. 监控告警（Redis Exporter + Grafana）
4. 慢查询日志
5. 大 Key 治理

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
