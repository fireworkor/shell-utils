# Hive 数据仓库

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
