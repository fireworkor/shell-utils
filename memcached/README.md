# Memcached 缓存系统

## 简介
Memcached 是一个高性能的分布式内存对象缓存系统，用于动态 Web 应用以减轻数据库负载。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 11211 | Memcached | 默认服务端口 |

### 主要组件

- **memcached** - 主进程
- **memcached-tool** - 统计工具
- **libmemcached** - C 客户端库

### 访问入口

- **命令行**: `memcached -h`
- **telnet**: `telnet 127.0.0.1 11211`
- **stats**: `echo "stats" | nc 127.0.0.1 11211`

---

## 首次安装后必做设置

### 1. 启动参数优化
```
# /etc/memcached.conf
-m 1024    # 最大内存
-c 1024    # 最大连接
-p 11211
-l 127.0.0.1
-d
```

### 2. 启动服务
```bash
sudo systemctl start memcached
sudo systemctl enable memcached
```

### 3. 测试
```bash
echo "stats" | nc 127.0.0.1 11211
```

---

## 常用命令

```bash
set key 0 60 5
hello
get key
delete key
stats
stats items
stats slabs
```

---

## 后续改进方向

1. 集群部署
2. 持久化（Couchbase）
3. 监控（Memcached Exporter）
4. 安全（SASL 认证）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
