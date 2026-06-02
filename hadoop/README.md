# Hadoop 大数据框架

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
