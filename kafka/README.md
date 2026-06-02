# Kafka 消息系统

## 简介
Apache Kafka 是一个分布式流处理平台，最初由 LinkedIn 开发。Kafka 是一种高吞吐量的分布式发布订阅消息系统。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 9092 | Kafka Broker | 主服务端口 |
| 2181 | ZooKeeper | 依赖组件 |

### 主要组件

- **kafka-server-start.sh** - 启动 Broker
- **kafka-topics.sh** - Topic 管理
- **kafka-console-producer.sh** - 生产消息
- **kafka-console-consumer.sh** - 消费消息

---

## 首次安装后必做设置

### 1. 配置 server.properties
```bash
sudo vim /opt/kafka/config/server.properties
broker.id=0
listeners=PLAINTEXT://:9092
advertised.listeners=PLAINTEXT://<IP>:9092
log.dirs=/var/lib/kafka/data
```

### 2. 启动服务
```bash
sudo systemctl start kafka
sudo systemctl enable kafka
```

### 3. 创建 Topic
```bash
/opt/kafka/bin/kafka-topics.sh --create     --bootstrap-server localhost:9092     --topic mytopic     --partitions 3     --replication-factor 1
```

### 4. 测试
```bash
# 生产
/opt/kafka/bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic mytopic
# 消费
/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic mytopic --from-beginning
```

---

## 详细使用说明

### Topic 管理
```bash
/opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092
/opt/kafka/bin/kafka-topics.sh --describe --bootstrap-server localhost:9092
/opt/kafka/bin/kafka-topics.sh --delete --bootstrap-server localhost:9092 --topic mytopic
```

### 消费者组
```bash
/opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list
/opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group mygroup
```

---

## 后续改进方向

1. 集群部署（多 Broker）
2. KRaft 模式（替代 ZooKeeper）
3. 监控（JMX Exporter + Prometheus）
4. 安全（SASL/SSL）
5. 流处理（Kafka Streams）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
