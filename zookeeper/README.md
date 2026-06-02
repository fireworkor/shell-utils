# ZooKeeper 协调服务

## 简介
Apache ZooKeeper 是一个为分布式应用提供一致性服务的开源组件。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 2181 | 客户端连接 | 默认服务端口 |
| 2888 | Follower 连接 | 集群内部 |
| 3888 | 选举 | 集群选举 |

### 主要组件

- **zkServer.sh** - 启动脚本
- **zkCli.sh** - 命令行客户端
- **zkCleanup.sh** - 清理工具

---

## 首次安装后必做设置

### 1. 配置 zoo.cfg
```properties
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/var/lib/zookeeper
clientPort=2181
maxClientCnxns=60
```

### 2. 创建 myid
```bash
echo "1" | sudo tee /var/lib/zookeeper/myid
```

### 3. 启动
```bash
sudo systemctl start zookeeper
sudo systemctl enable zookeeper
```

### 4. 测试
```bash
echo "ruok" | nc 127.0.0.1 2181
# imok
```

---

## 常用命令

```bash
zkCli.sh -server 127.0.0.1:2181
ls /
create /mynode "data"
get /mynode
set /mynode "new data"
delete /mynode
```

---

## 后续改进方向

1. 集群部署（3/5 节点）
2. 监控（Four Letter Words + Prometheus）
3. 配置管理（Exhibitor）
4. 高可用（Observer 节点）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
