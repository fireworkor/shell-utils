# Spark 分布式计算框架

## 简介
Apache Spark 是一个快速通用的大规模数据处理引擎，支持批处理、流处理、机器学习等。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 7077 | Spark Master | 主节点通信 |
| 8080 | Spark Web UI | Master Web UI |
| 4040 | Application UI | 应用运行时 UI |
| 6066 | REST API | REST 提交接口 |

### 主要组件

- **Spark Core**: 核心引擎
- **Spark SQL**: SQL 查询接口
- **Spark Streaming**: 流处理
- **MLlib**: 机器学习库
- **GraphX**: 图计算

### 访问入口

- **Spark UI**: `http://<Master>:8080`
- **应用 UI**: `http://<Driver>:4040`
- **命令行**: `spark-shell`, `pyspark`, `spark-submit`

---

## 首次安装后必做设置

### 1. 配置环境变量
```bash
echo 'export SPARK_HOME=/opt/spark' >> ~/.bashrc
echo 'export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin' >> ~/.bashrc
source ~/.bashrc
```

### 2. 配置 Spark
```bash
cd /opt/spark/conf
cp spark-env.sh.template spark-env.sh
echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> spark-env.sh
echo "export SPARK_MASTER_HOST=localhost" >> spark-env.sh
```

### 3. 启动 Spark
```bash
# 启动 Master
start-master.sh

# 启动 Worker
start-worker.sh spark://localhost:7077
```

### 4. 验证
```bash
# 查看 UI
echo "Spark UI: http://localhost:8080"

# 运行示例
spark-submit --class org.apache.spark.examples.SparkPi     $SPARK_HOME/examples/jars/spark-examples*.jar 10
```

---

## 详细使用说明

### Spark Shell
```bash
# Scala Shell
spark-shell

# Python Shell
pyspark

# R Shell
sparkR
```

### 提交作业
```bash
# 本地模式
spark-submit --master local[4] myapp.py

# Standalone 模式
spark-submit --master spark://localhost:7077 myapp.py

# YARN 模式
spark-submit --master yarn myapp.py
```

### 服务管理
```bash
# 启动 Master
start-master.sh

# 启动 Worker
start-worker.sh spark://localhost:7077

# 停止
stop-master.sh
stop-worker.sh
```

### 健康检查
```bash
bash healthcheck.sh
```

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 安装目录 | /opt/spark |
| 配置目录 | /opt/spark/conf |
| 日志目录 | /var/log/spark |

---

## 常见问题

### Q: Worker 无法连接 Master？
A: 检查防火墙、Master 地址是否正确。

### Q: 内存不足？
A: 配置 spark.executor.memory 和 spark.driver.memory。

### Q: YARN 模式报错？
A: 确保 HADOOP_HOME 配置正确。

---

## 后续改进方向

1. **集群部署**：配置多节点集群
2. **资源管理**：集成 YARN 或 Mesos
3. **监控**：集成 Prometheus + Grafana
4. **优化**：调整 Spark 参数
5. **安全**：启用 Kerberos

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
