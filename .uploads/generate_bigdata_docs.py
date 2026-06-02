#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
大数据组件 README.md 文档生成器
"""

import os

WORKSPACE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

DOCS = {}

DOCS["hadoop"] = """# Hadoop 大数据框架

## 简介
Hadoop 是一个分布式计算平台，用于处理大规模数据的分布式存储和处理。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 8088 | ResourceManager | YARN 资源管理 |
| 9000 | NameNode | HDFS 主节点 |
| 50070 | NameNode Web | HDFS Web UI |
| 50075 | DataNode Web | DataNode Web UI |
| 8042 | NodeManager | NodeManager Web |

### 主要组件

- **HDFS**: 分布式文件系统
  - NameNode: 元数据管理
  - DataNode: 数据存储
  - SecondaryNameNode: 辅助管理

- **YARN**: 资源管理
  - ResourceManager: 资源调度
  - NodeManager: 节点管理

- **MapReduce**: 分布式计算框架

### 访问入口

- **HDFS Web UI**: `http://<NameNode>:50070`
- **YARN Web UI**: `http://<ResourceManager>:8088`
- **命令行**: `hadoop fs`, `hdfs dfs`, `yarn`

---

## 首次安装后必做设置

### 1. 配置环境变量
```bash
echo 'export HADOOP_HOME=/opt/hadoop' >> ~/.bashrc
echo 'export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin' >> ~/.bashrc
source ~/.bashrc
```

### 2. 配置 Java 环境
```bash
echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> ~/.bashrc
source ~/.bashrc
```

### 3. 修改配置文件
```bash
cd /opt/hadoop/etc/hadoop

# 修改 hadoop-env.sh
echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> hadoop-env.sh

# 修改 core-site.xml
cat > core-site.xml << 'EOF'
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
EOF

# 修改 hdfs-site.xml
cat > hdfs-site.xml << 'EOF'
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
</configuration>
EOF
```

### 4. 格式化 HDFS
```bash
hdfs namenode -format
```

### 5. 启动 Hadoop
```bash
# 启动 HDFS
start-dfs.sh

# 启动 YARN
start-yarn.sh

# 查看状态
jps
```

---

## 详细使用说明

### HDFS 命令
```bash
# 创建目录
hdfs dfs -mkdir /user
hdfs dfs -mkdir /user/$USER

# 上传文件
hdfs dfs -put localfile.txt /user/$USER/

# 列出文件
hdfs dfs -ls /user/$USER/

# 下载文件
hdfs dfs -get /user/$USER/file.txt .

# 删除文件
hdfs dfs -rm /user/$USER/file.txt
```

### YARN 命令
```bash
# 运行 MapReduce 作业
yarn jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples*.jar pi 2 5

# 查看应用
yarn application -list

# 查看日志
yarn logs -applicationId <app_id>
```

### 服务管理
```bash
# 启动
start-dfs.sh
start-yarn.sh

# 停止
stop-yarn.sh
stop-dfs.sh

# 一键启停
start-all.sh
stop-all.sh
```

### 健康检查
```bash
bash healthcheck.sh
```

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 安装目录 | /opt/hadoop |
| 配置目录 | /opt/hadoop/etc/hadoop |
| 日志目录 | /var/log/hadoop |
| 数据目录 | /var/lib/hadoop |

---

## 常见问题

### Q: NameNode 无法启动？
A: 检查 Java 环境、端口是否被占用、权限是否正确。

### Q: DataNode 无法启动？
A: 删除 dfs/data/current/VERSION 文件，重新格式化。

### Q: 权限问题？
A: 使用 `hdfs dfs -chown` 和 `hdfs dfs -chmod` 设置权限。

---

## 后续改进方向

1. **集群部署**：配置多节点集群
2. **高可用**：配置 NameNode HA
3. **联邦 HDFS**：扩展命名空间
4. **监控**：集成 Prometheus + Grafana
5. **安全**：启用 Kerberos 认证

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
"""

DOCS["spark"] = """# Spark 分布式计算框架

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
spark-submit --class org.apache.spark.examples.SparkPi \
    $SPARK_HOME/examples/jars/spark-examples*.jar 10
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
"""

DOCS["hive"] = """# Hive 数据仓库

## 简介
Apache Hive 是建立在 Hadoop 之上的数据仓库工具，提供类 SQL 查询语言。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 10000 | HiveServer2 | Thrift 服务端口 |
| 10002 | Hive Metastore | 元数据服务 |

### 主要组件

- **HiveServer2**: 提供 JDBC/ODBC 接口
- **Hive Metastore**: 管理元数据
- **CLI**: 命令行接口
- **WebHCat**: REST API

### 访问入口

- **CLI**: `hive`
- **Beeline**: `beeline -u jdbc:hive2://localhost:10000`
- **JDBC URL**: `jdbc:hive2://<host>:10000/default`

---

## 首次安装后必做设置

### 1. 配置环境变量
```bash
echo 'export HIVE_HOME=/opt/hive' >> ~/.bashrc
echo 'export PATH=$PATH:$HIVE_HOME/bin' >> ~/.bashrc
source ~/.bashrc
```

### 2. 配置 Hive
```bash
cd /opt/hive/conf

# 修改 hive-env.sh
cp hive-env.sh.template hive-env.sh
echo "export HADOOP_HOME=/opt/hadoop" >> hive-env.sh

# 创建 hive-site.xml
cat > hive-site.xml << 'EOF'
<configuration>
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:derby:;databaseName=/var/lib/hive/metastore_db;create=true</value>
    </property>
    <property>
        <name>datanucleus.schema.autoCreateAll</name>
        <value>true</value>
    </property>
    <property>
        <name>hive.metastore.warehouse.dir</name>
        <value>/user/hive/warehouse</value>
    </property>
</configuration>
EOF
```

### 3. 创建目录
```bash
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -chmod 777 /user/hive/warehouse
hdfs dfs -mkdir -p /tmp/hive
hdfs dfs -chmod 777 /tmp/hive
```

### 4. 初始化元数据
```bash
schematool -dbType derby -initSchema
```

### 5. 启动服务
```bash
# 启动 HiveServer2
hive --service hiveserver2 &

# 启动 Metastore
hive --service metastore &
```

---

## 详细使用说明

### Hive CLI
```bash
# 进入 CLI
hive

# 创建数据库
CREATE DATABASE IF NOT EXISTS mydb;

# 使用数据库
USE mydb;

# 创建表
CREATE TABLE users (
    id INT,
    name STRING,
    age INT
) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';

# 加载数据
LOAD DATA LOCAL INPATH '/path/to/data.txt' INTO TABLE users;

# 查询
SELECT * FROM users WHERE age > 25;
```

### Beeline
```bash
beeline -u jdbc:hive2://localhost:10000
```

### 服务管理
```bash
# 启动 HiveServer2
nohup hive --service hiveserver2 > /var/log/hive/hiveserver2.log 2>&1 &

# 启动 Metastore
nohup hive --service metastore > /var/log/hive/metastore.log 2>&1 &
```

### 备份与恢复
```bash
bash backup.sh all
bash restore.sh /var/backups/shell-utils/hive/backup_20250101.tar.gz
```

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 安装目录 | /opt/hive |
| 配置目录 | /opt/hive/conf |
| 日志目录 | /var/log/hive |
| 数据目录 | /var/lib/hive |
| HDFS 仓库 | /user/hive/warehouse |

---

## 常见问题

### Q: 元数据初始化失败？
A: 删除 metastore_db 目录，重新初始化。

### Q: HiveServer2 无法启动？
A: 检查端口是否被占用，查看日志文件。

### Q: 权限问题？
A: 确保 HDFS 目录权限正确。

---

## 后续改进方向

1. **元数据存储**：配置 MySQL/PostgreSQL 存储元数据
2. **性能优化**：启用 Tez 或 Spark 执行引擎
3. **安全**：启用 Kerberos 认证
4. **监控**：集成 Prometheus + Grafana

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
"""

DOCS["hbase"] = """# HBase 分布式数据库

## 简介
Apache HBase 是一个分布式、面向列的开源数据库，构建在 HDFS 之上。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 16000 | HMaster | 主节点端口 |
| 16010 | HMaster Web | 主节点 Web UI |
| 16020 | HRegionServer | 区域服务器端口 |
| 16030 | HRegionServer Web | 区域服务器 Web UI |
| 2181 | ZooKeeper | 依赖组件 |

### 主要组件

- **HMaster**: 管理集群
- **HRegionServer**: 存储和服务数据
- **ZooKeeper**: 协调服务
- **HBase Shell**: 命令行接口

### 访问入口

- **Web UI**: `http://<HMaster>:16010`
- **Shell**: `hbase shell`
- **Java API**: HBase Java Client

---

## 首次安装后必做设置

### 1. 配置环境变量
```bash
echo 'export HBASE_HOME=/opt/hbase' >> ~/.bashrc
echo 'export PATH=$PATH:$HBASE_HOME/bin' >> ~/.bashrc
source ~/.bashrc
```

### 2. 配置 HBase
```bash
cd /opt/hbase/conf

# 修改 hbase-env.sh
echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> hbase-env.sh
echo "export HBASE_MANAGES_ZK=false" >> hbase-env.sh

# 修改 hbase-site.xml
cat > hbase-site.xml << 'EOF'
<configuration>
    <property>
        <name>hbase.rootdir</name>
        <value>hdfs://localhost:9000/hbase</value>
    </property>
    <property>
        <name>hbase.cluster.distributed</name>
        <value>true</value>
    </property>
    <property>
        <name>hbase.zookeeper.quorum</name>
        <value>localhost</value>
    </property>
</configuration>
EOF
```

### 3. 启动服务
```bash
# 启动 HBase
start-hbase.sh

# 启动 Thrift 服务（可选）
hbase thrift start &
```

### 4. 验证
```bash
hbase shell
status
```

---

## 详细使用说明

### HBase Shell
```bash
# 进入 Shell
hbase shell

# 创建表
create 'users', 'info', 'address'

# 插入数据
put 'users', 'user1', 'info:name', 'Alice'
put 'users', 'user1', 'info:age', '30'

# 查询
get 'users', 'user1'

# 扫描
scan 'users'

# 删除表
disable 'users'
drop 'users'
```

### 服务管理
```bash
# 启动
start-hbase.sh

# 停止
stop-hbase.sh
```

### 健康检查
```bash
bash healthcheck.sh
```

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 安装目录 | /opt/hbase |
| 配置目录 | /opt/hbase/conf |
| 日志目录 | /var/log/hbase |
| HDFS 数据 | /hbase |

---

## 常见问题

### Q: HMaster 无法启动？
A: 检查 ZooKeeper 是否正常运行，查看日志。

### Q: 数据写入失败？
A: 检查 HDFS 可用空间和权限。

### Q: RegionServer 宕机？
A: 检查资源使用情况，重启服务。

---

## 后续改进方向

1. **集群部署**：配置多节点集群
2. **高可用**：配置 HMaster HA
3. **备份恢复**：使用 HBase 快照
4. **监控**：集成 Prometheus + Grafana
5. **安全**：启用 Kerberos 认证

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
"""

DOCS["flink"] = """# Flink 流处理框架

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
"""


def main():
    print("=" * 50)
    print("  生成大数据组件文档")
    print("=" * 50)
    print()

    count = 0
    for software, content in DOCS.items():
        target_dir = os.path.join(WORKSPACE_DIR, software)
        readme_path = os.path.join(target_dir, "README.md")

        if not os.path.isdir(target_dir):
            continue

        try:
            with open(readme_path, "w", encoding="utf-8") as f:
                f.write(content)
            lines = content.count("\n")
            print(f"  ✓ {software}/README.md ({lines} 行)")
            count += 1
        except Exception as e:
            print(f"  ✗ {software}/README.md 错误: {e}")

    print()
    print("=" * 50)
    print(f"  文档生成完成，共 {count} 个文件")
    print("=" * 50)


if __name__ == "__main__":
    main()
