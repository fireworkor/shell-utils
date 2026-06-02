# Elasticsearch 搜索引擎

## 简介
Elasticsearch 是一个分布式、RESTful 风格的搜索和数据分析引擎。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 9200 | HTTP API | RESTful 接口 |
| 9300 | 节点通信 | 集群内部 |

### 主要组件

- **elasticsearch** - 主服务
- **kibana** - 可视化
- **logstash** - 日志处理
- **beats** - 轻量数据收集

### 访问入口

- **HTTP API**: `http://<IP>:9200`
- **Web UI**: Kibana
- **健康检查**: `curl http://<IP>:9200/_cluster/health`

---

## 首次安装后必做设置

### 1. 配置 elasticsearch.yml
```yaml
cluster.name: my-cluster
node.name: node-1
network.host: 0.0.0.0
http.port: 9200
discovery.seed_hosts: ["127.0.0.1"]
cluster.initial_master_nodes: ["node-1"]
```

### 2. 配置 JVM
```
-Xms2g
-Xmx2g
```

### 3. 启动
```bash
sudo systemctl start elasticsearch
sudo systemctl enable elasticsearch
```

### 4. 验证
```bash
curl http://127.0.0.1:9200
```

### 5. 防火墙
```bash
sudo firewall-cmd --permanent --add-port=9200/tcp
sudo firewall-cmd --permanent --add-port=9300/tcp
sudo firewall-cmd --reload
```

---

## 详细使用说明

### 基本操作
```bash
# 创建索引
curl -X PUT http://127.0.0.1:9200/myindex

# 添加文档
curl -X POST http://127.0.0.1:9200/myindex/_doc/1 -H "Content-Type: application/json" -d '{"title": "Hello"}'

# 搜索
curl -X GET http://127.0.0.1:9200/myindex/_search

# 集群健康
curl http://127.0.0.1:9200/_cluster/health?pretty
```

### 备份恢复
```bash
curl -X PUT "http://127.0.0.1:9200/_snapshot/my_backup" -H "Content-Type: application/json" -d '{"type": "fs", "settings": {"location": "/backup/es"}}'
curl -X PUT "http://127.0.0.1:9200/_snapshot/my_backup/snapshot_1?wait_for_completion=true"
curl -X POST "http://127.0.0.1:9200/_snapshot/my_backup/snapshot_1/_restore"
```

---

## 常见问题

### Q: 启动失败？
A: 查看 /var/log/elasticsearch/

### Q: 内存不足？
A: 调整 -Xmx（不超过物理内存 50%）

---

## 后续改进方向

1. 集群部署（3 节点以上）
2. Kibana 集成
3. X-Pack 安全
4. ILM 策略
5. 监控（Metricbeat + Kibana）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
