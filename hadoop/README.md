# Hadoop 分布式存储和计算框架

## 简介
Hadoop 是一个分布式系统基础架构，用于大规模数据的存储和处理。

## 端口信息
- NameNode Web UI: 9870
- DataNode: 9864
- ResourceManager: 8088
- NodeManager: 8042
- Secondary NameNode: 9868

## 使用命令

```bash
# 部署伪分布式模式
bash hadoop.sh pseudo

# 停止 Hadoop
bash hadoop.sh stop

# 查看状态
bash hadoop.sh status

# 启动 HDFS 和 YARN
start-dfs.sh
start-yarn.sh
```

## 环境变量
```bash
export HADOOP_HOME=/opt/hadoop
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
```

## 默认配置
- Hadoop 配置目录: `$HADOOP_HOME/etc/hadoop/`
- HDFS 数据目录: `/opt/hadoop/data/dfs/`
- YARN 日志目录: `$HADOOP_HOME/logs/`

## 健康检查

```bash
# 检查 Java 进程
jps

# 预期看到以下进程:
# NameNode
# DataNode
# ResourceManager
# NodeManager
# Jps

# 检查 HDFS 状态
hdfs dfsadmin -report

# 检查 YARN 节点
yarn node -list

# 检查 NameNode 状态
hdfs haadmin -getServiceState nn1
```

## 备份

```bash
# 备份 HDFS 配置
cp -r /opt/hadoop/etc/hadoop /backup/hadoop_config_$(date +%Y%m%d)

# 备份 NameNode 元数据
# 需要先停止集群
hdfs dfsadmin -safemode enter
hdfs dfsadmin -saveNamespace
cp -r /opt/hadoop/data/dfs/name /backup/namenode_$(date +%Y%m%d)
hdfs dfsadmin -safemode leave

# 导出 HDFS 文件到本地
hdfs dfs -get /user/hadoop/data /backup/hdfs_data_$(date +%Y%m%d)
```

## 恢复

```bash
# 恢复 NameNode 元数据
# 停止集群
stop-dfs.sh

# 恢复元数据
cp -r /backup/namenode_20240101/* /opt/hadoop/data/dfs/name/
chown -R hadoop:hadoop /opt/hadoop/data/dfs/name

# 格式化并重启
hdfs namenode -format
start-dfs.sh
```

## Web UI
- NameNode: http://localhost:9870
- ResourceManager: http://localhost:8088
- DataNode: http://localhost:9864

## HDFS 常用命令

```bash
# 查看文件
hdfs dfs -ls /

# 创建目录
hdfs dfs -mkdir -p /user/hadoop

# 上传文件
hdfs dfs -put localfile /hdfs/path/

# 下载文件
hdfs dfs -get /hdfs/path/file localfile

# 查看文件内容
hdfs dfs -cat /path/to/file

# 删除文件
hdfs dfs -rm /path/to/file
```

## YARN 常用命令

```bash
# 查看队列
yarn queue -status default

# 查看应用
yarn application -list

# 查看应用日志
yarn logs -applicationId <app-id>

# 杀掉应用
yarn application -kill <app-id>
```
