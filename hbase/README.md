# HBase 分布式数据库

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
