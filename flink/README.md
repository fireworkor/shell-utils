# Flink 流处理框架

## 简介
Apache Flink 是一个分布式流处理框架，支持实时流处理和批处理。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 8081 | JobManager | Web UI |
| 6123 | JobManager RPC | 内部通信 |
| 6124 | TaskManager RPC | 任务通信 |
| 8080 | TaskManager | Web UI |

### 主要组件

- **JobManager**: 协调作业执行
- **TaskManager**: 执行任务
- **Flink CLI**: 命令行接口
- **Flink Dashboard**: Web 管理界面

### 访问入口

- **Web UI**: `http://<JobManager>:8081`
- **CLI**: `flink run`, `flink list`
- **REST API**: `http://<JobManager>:8081/jobmanager/rest`

---

## 首次安装后必做设置

### 1. 配置环境变量
```bash
echo 'export FLINK_HOME=/opt/flink' >> ~/.bashrc
echo 'export PATH=$PATH:$FLINK_HOME/bin' >> ~/.bashrc
source ~/.bashrc
```

### 2. 配置 Flink
```bash
cd /opt/flink/conf

# 修改 flink-conf.yaml
cat > flink-conf.yaml << 'EOF'
jobmanager.rpc.address: localhost
jobmanager.memory.process.size: 1600m
taskmanager.memory.process.size: 1728m
taskmanager.numberOfTaskSlots: 2
parallelism.default: 2
EOF
```

### 3. 启动 Flink
```bash
# 启动集群
start-cluster.sh

# 查看状态
echo "Flink UI: http://localhost:8081"
```

### 4. 运行示例
```bash
# 运行 WordCount 示例
flink run $FLINK_HOME/examples/streaming/WordCount.jar
```

---

## 详细使用说明

### 提交作业
```bash
# 运行作业
flink run myjob.jar

# 运行带参数的作业
flink run myjob.jar --input /data/input --output /data/output

# 列出运行中的作业
flink list

# 取消作业
flink cancel <job_id>
```

### 流处理示例
```bash
# 启动本地流处理
flink run -m local $FLINK_HOME/examples/streaming/SocketWindowWordCount.jar --port 9999

# 发送数据
nc -lk 9999
```

### 服务管理
```bash
# 启动集群
start-cluster.sh

# 停止集群
stop-cluster.sh

# 启动单个组件
jobmanager.sh start
taskmanager.sh start
```

### 健康检查
```bash
bash healthcheck.sh
```

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 安装目录 | /opt/flink |
| 配置目录 | /opt/flink/conf |
| 日志目录 | /var/log/flink |

---

## 常见问题

### Q: JobManager 无法启动？
A: 检查内存配置和端口占用。

### Q: TaskManager 无法连接？
A: 检查网络和防火墙设置。

### Q: 作业失败？
A: 查看 Web UI 中的日志和异常信息。

---

## 后续改进方向

1. **集群部署**：配置多节点集群
2. **高可用**：配置 JobManager HA
3. **资源管理**：集成 YARN 或 Kubernetes
4. **监控**：集成 Prometheus + Grafana
5. **状态管理**：配置 Checkpoint 和 Savepoint

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
