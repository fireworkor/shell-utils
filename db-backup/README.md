# 数据库备份脚本

本目录包含多种数据库的备份和恢复脚本，支持增量备份和全量备份，并提供配置文件示例。

## 支持的数据库

| 数据库 | 增量备份 | 全量备份 | 恢复脚本 | 配置文件 |
|--------|----------|----------|----------|----------|
| MySQL | ✓ | ✓ | ✓ | ✓ |
| PostgreSQL | ✓ | ✓ | ✓ | ✓ |
| MongoDB | ✓ | ✓ | ✓ | ✓ |
| Redis | ✓ | ✓ | ✓ | ✓ |
| MariaDB | ✓ | ✓ | ✓ | ✓ |
| SQLite | ✓ | ✓ | ✓ | ✓ |
| Elasticsearch | ✓ | ✓ | ✓ | ✓ |
| InfluxDB | ✓ | ✓ | ✓ | ✓ |

## 目录结构

```
db-backup/
├── backup_manager.sh          # 统一备份管理脚本
├── README.md                  # 使用说明
├── mysql/
│   ├── incremental.sh         # MySQL 增量备份脚本
│   ├── full_backup.sh         # MySQL 全量备份脚本
│   ├── restore.sh             # MySQL 恢复脚本
│   └── config.conf.example    # MySQL 配置文件示例
├── postgresql/
│   ├── incremental.sh         # PostgreSQL 增量备份脚本
│   ├── full_backup.sh         # PostgreSQL 全量备份脚本
│   ├── restore.sh             # PostgreSQL 恢复脚本
│   └── config.conf.example    # PostgreSQL 配置文件示例
├── mongodb/
│   ├── incremental.sh         # MongoDB 增量备份脚本
│   ├── full_backup.sh         # MongoDB 全量备份脚本
│   ├── restore.sh             # MongoDB 恢复脚本
│   └── config.conf.example    # MongoDB 配置文件示例
├── redis/
│   ├── incremental.sh         # Redis 增量备份脚本
│   ├── full_backup.sh         # Redis 全量备份脚本
│   ├── restore.sh             # Redis 恢复脚本
│   └── config.conf.example    # Redis 配置文件示例
├── mariadb/
│   ├── full_backup.sh         # MariaDB 备份脚本
│   ├── restore.sh             # MariaDB 恢复脚本
│   └── config.conf.example    # MariaDB 配置文件示例
├── sqlite/
│   ├── full_backup.sh         # SQLite 备份脚本
│   ├── restore.sh             # SQLite 恢复脚本
│   └── config.conf.example    # SQLite 配置文件示例
├── elasticsearch/
│   ├── full_backup.sh         # Elasticsearch 备份脚本
│   ├── restore.sh             # Elasticsearch 恢复脚本
│   └── config.conf.example    # Elasticsearch 配置文件示例
└── influxdb/
    ├── full_backup.sh         # InfluxDB 备份脚本
    ├── restore.sh             # InfluxDB 恢复脚本
    └── config.conf.example    # InfluxDB 配置文件示例
```

## 配置文件使用方法

### 1. 复制配置文件

每个数据库目录下都提供了 `config.conf.example` 配置文件示例：

```bash
# MySQL
cd /workspace/db-backup/mysql
cp config.conf.example config.conf

# PostgreSQL
cd /workspace/db-backup/postgresql
cp config.conf.example config.conf

# MongoDB
cd /workspace/db-backup/mongodb
cp config.conf.example config.conf

# Redis
cd /workspace/db-backup/redis
cp config.conf.example config.conf

# MariaDB
cd /workspace/db-backup/mariadb
cp config.conf.example config.conf

# SQLite
cd /workspace/db-backup/sqlite
cp config.conf.example config.conf

# Elasticsearch
cd /workspace/db-backup/elasticsearch
cp config.conf.example config.conf

# InfluxDB
cd /workspace/db-backup/influxdb
cp config.conf.example config.conf
```

### 2. 编辑配置文件

使用文本编辑器修改配置文件，根据实际环境配置数据库连接信息：

```bash
# 使用 nano 编辑
nano config.conf

# 使用 vim 编辑
vim config.conf
```

### 3. 配置环境变量

可以通过环境变量覆盖配置文件中的设置：

```bash
# MySQL
export MYSQL_USER="myuser"
export MYSQL_PASSWORD="mypassword"
export MYSQL_HOST="192.168.1.100"

# PostgreSQL
export PG_USER="postgres"
export PG_HOST="192.168.1.101"

# MongoDB
export MONGO_USER="admin"
export MONGO_PASSWORD="secret"

# Redis
export REDIS_PASSWORD="redis_password"

# MariaDB
export MARIADB_USER="root"
export MARIADB_PASSWORD="password"

# SQLite
export SQLITE_DB_PATHS="/var/lib/sqlite /opt/data"

# Elasticsearch
export ES_USER="elastic"
export ES_PASSWORD="changeme"

# InfluxDB
export INFLUX_TOKEN="my_super_secret_token"
export INFLUX_ORG="my-org"
```

### 4. 加载配置文件执行脚本

```bash
# 方法1: 直接执行，脚本会自动读取环境变量
./full_backup.sh backup

# 方法2: 先加载配置文件再执行
source config.conf
./full_backup.sh backup

# 方法3: 使用 env 命令临时设置环境变量
MYSQL_USER=root MYSQL_PASSWORD=secret ./full_backup.sh backup
```

## 使用方法

### 1. 统一管理脚本

```bash
# 执行所有数据库的增量备份（每天执行）
./backup_manager.sh incremental

# 执行所有数据库的全量备份（每30天执行）
./backup_manager.sh full

# 清理所有数据库的旧备份
./backup_manager.sh cleanup

# 执行增量备份并清理旧备份
./backup_manager.sh all

# 列出所有数据库的备份
./backup_manager.sh list
```

### 2. 单个数据库备份

```bash
# MySQL
./mysql/incremental.sh incremental    # 增量备份
./mysql/full_backup.sh backup         # 全量备份

# PostgreSQL
./postgresql/incremental.sh incremental
./postgresql/full_backup.sh backup

# MongoDB
./mongodb/incremental.sh incremental
./mongodb/full_backup.sh backup

# Redis
./redis/incremental.sh incremental
./redis/full_backup.sh backup

# MariaDB
./mariadb/full_backup.sh full         # 全量备份
./mariadb/full_backup.sh incremental  # 增量备份
./mariadb/full_backup.sh physical     # 物理备份

# SQLite
./sqlite/full_backup.sh backup        # 全量备份
./sqlite/full_backup.sh incremental   # 增量备份

# Elasticsearch
./elasticsearch/full_backup.sh full
./elasticsearch/full_backup.sh incremental

# InfluxDB
./influxdb/full_backup.sh full
./influxdb/full_backup.sh incremental
```

## 环境变量配置

### MySQL
| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| MYSQL_USER | MySQL 用户名 | root |
| MYSQL_PASSWORD | MySQL 密码 | 空 |
| MYSQL_HOST | MySQL 主机 | localhost |
| MYSQL_PORT | MySQL 端口 | 3306 |
| BACKUP_ROOT | 备份根目录 | /var/backups/mysql |
| INCREMENTAL_RETENTION | 增量备份保留天数 | 7 |
| FULL_RETENTION | 全量备份保留天数 | 30 |

### PostgreSQL
| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| PG_USER | PostgreSQL 用户名 | postgres |
| PG_HOST | PostgreSQL 主机 | localhost |
| PG_PORT | PostgreSQL 端口 | 5432 |
| PG_DATABASE | PostgreSQL 数据库名 | postgres |
| BACKUP_ROOT | 备份根目录 | /var/backups/postgresql |

### MongoDB
| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| MONGO_HOST | MongoDB 主机 | localhost |
| MONGO_PORT | MongoDB 端口 | 27017 |
| MONGO_USER | MongoDB 用户名 | 空 |
| MONGO_PASSWORD | MongoDB 密码 | 空 |

### Redis
| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| REDIS_HOST | Redis 主机 | localhost |
| REDIS_PORT | Redis 端口 | 6379 |
| REDIS_PASSWORD | Redis 密码 | 空 |

### MariaDB
| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| MARIADB_USER | MariaDB 用户名 | root |
| MARIADB_PASSWORD | MariaDB 密码 | 空 |
| MARIADB_HOST | MariaDB 主机 | localhost |
| MARIADB_PORT | MariaDB 端口 | 3306 |

### SQLite
| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| SQLITE_DB_PATHS | SQLite 数据库文件路径 | /var/lib/sqlite |
| BACKUP_ROOT | 备份根目录 | /var/backups/sqlite |

### Elasticsearch
| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| ES_HOST | Elasticsearch 主机 | localhost |
| ES_PORT | Elasticsearch 端口 | 9200 |
| ES_USER | Elasticsearch 用户名 | 空 |
| ES_PASSWORD | Elasticsearch 密码 | 空 |
| REPO_NAME | 快照仓库名称 | backup_repo |

### InfluxDB
| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| INFLUX_HOST | InfluxDB 主机 | localhost |
| INFLUX_PORT | InfluxDB 端口 | 8088 |
| INFLUX_TOKEN | 认证 Token | 空 |
| INFLUX_ORG | 组织名称 | 空 |
| INFLUX_VERSION | InfluxDB 版本 | 2 |

## 备份策略

### 增量备份
- **执行频率**: 每天执行
- **保留时间**: 7天
- **备份位置**: `/var/backups/{db_type}/incremental/`

### 全量备份
- **执行频率**: 每30天执行
- **保留时间**: 30天
- **备份位置**: `/var/backups/{db_type}/full/`

## 数据库配置要求

### MySQL
```ini
# my.cnf 配置示例
[mysqld]
log_bin = /var/log/mysql/mysql-bin.log
binlog_format = ROW
server_id = 1
innodb_flush_log_at_trx_commit = 1
sync_binlog = 1
```

### PostgreSQL
```ini
# postgresql.conf 配置示例
wal_level = replica
archive_mode = on
archive_command = 'cp %p /var/lib/postgresql/archive/%f'
max_wal_size = 1GB
min_wal_size = 80MB
```

### MongoDB
```yaml
# mongod.conf 配置示例
replication:
  replSetName: rs0
net:
  bindIp: 127.0.0.1
  port: 27017
security:
  authorization: enabled
```

### Redis
```ini
# redis.conf 配置示例
bind 127.0.0.1
port 6379
requirepass your_password_here
save 900 1
save 300 10
save 60 10000
dbfilename dump.rdb
dir /var/lib/redis
```

### MariaDB
```ini
# my.cnf 配置示例
[mysqld]
log_bin = /var/log/mariadb/mariadb-bin
binlog_format = ROW
server_id = 1
innodb_file_per_table = ON
```

### SQLite
```sql
-- SQLite 命令行配置
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
PRAGMA cache_size=10000;
PRAGMA foreign_keys=ON;
```

### Elasticsearch
```yaml
# elasticsearch.yml 配置示例
network.host: 127.0.0.1
http.port: 9200
path.repo: ["/var/backups/elasticsearch"]
cluster.name: my-cluster
discovery.type: single-node
```

### InfluxDB 2.x
```yaml
# config.yml 配置示例
reporting-disabled: false
bind-address: ":8086"
```

## Crontab 配置示例

```bash
# 每天凌晨2点执行增量备份
0 2 * * * /path/to/db-backup/backup_manager.sh incremental >> /var/log/db_backup.log 2>&1

# 每月1号凌晨3点执行全量备份
0 3 1 * * /path/to/db-backup/backup_manager.sh full >> /var/log/db_backup.log 2>&1

# 每天凌晨4点清理旧备份
0 4 * * * /path/to/db-backup/backup_manager.sh cleanup >> /var/log/db_backup.log 2>&1
```

## 数据恢复

### MySQL 恢复

```bash
./mysql/restore.sh full                    # 从全量备份恢复
./mysql/restore.sh incremental             # 从增量备份恢复
./mysql/restore.sh point '2024-01-15 10:30:00'
./mysql/restore.sh database backup.sql.gz mydb
./mysql/restore.sh list
```

### PostgreSQL 恢复

```bash
./postgresql/restore.sh full               # SQL格式恢复
./postgresql/restore.sh basebackup         # basebackup格式恢复
./postgresql/restore.sh incremental
./postgresql/restore.sh point '2024-01-15 10:30:00'
./postgresql/restore.sh list
```

### MongoDB 恢复

```bash
./mongodb/restore.sh full                  # archive格式恢复
./mongodb/restore.sh dump /path/to/dump    # dump目录恢复
./mongodb/restore.sh incremental
./mongodb/restore.sh database backup.archive.gz mydb
./mongodb/restore.sh collection /path/to/dump mydb.mycollection
./mongodb/restore.sh list
```

### Redis 恢复

```bash
./redis/restore.sh full
./redis/restore.sh incremental
./redis/restore.sh file /tmp/dump.rdb
./redis/restore.sh info                    # 查看Redis信息
./redis/restore.sh list
```

### MariaDB 恢复

```bash
./mariadb/restore.sh full
./mariadb/restore.sh incremental
./mariadb/restore.sh physical              # 从物理备份恢复
./mariadb/restore.sh database backup.sql.gz mydb
./mariadb/restore.sh list
```

### SQLite 恢复

```bash
./sqlite/restore.sh restore
./sqlite/restore.sh restore backup.tar.gz /var/lib/sqlite
./sqlite/restore.sh database backup.tar.gz mydb.db /path/to/mydb.db
./sqlite/restore.sh list
```

### Elasticsearch 恢复

```bash
./elasticsearch/restore.sh restore snapshot_name
./elasticsearch/restore.sh indices snapshot_name myindex
./elasticsearch/restore.sh list
./elasticsearch/restore.sh verify snapshot_name
./elasticsearch/restore.sh info snapshot_name
```

### InfluxDB 恢复

```bash
./influxdb/restore.sh restore
./influxdb/restore.sh bucket backup.tar.gz mybucket
./influxdb/restore.sh list
./influxdb/restore.sh verify backup.tar.gz
```

## 恢复注意事项

1. **恢复前备份** - 在执行恢复操作前，建议先备份当前数据
2. **服务停止** - 大多数恢复操作需要停止数据库服务
3. **权限要求** - 恢复脚本需要数据库管理员权限
4. **时间点恢复** - 需要有完整的增量备份链
5. **数据一致性** - 建议在恢复期间停止所有写操作

## 日志管理

### 备份日志位置

| 数据库 | 日志路径 |
|--------|----------|
| MySQL | /var/log/mysql_backup.log |
| PostgreSQL | /var/log/postgresql_backup.log |
| MongoDB | /var/log/mongodb_backup.log |
| Redis | /var/log/redis_backup.log |
| MariaDB | /var/log/mariadb_backup.log |
| SQLite | /var/log/sqlite_backup.log |
| Elasticsearch | /var/log/elasticsearch_backup.log |
| InfluxDB | /var/log/influxdb_backup.log |

### 日志轮转配置示例

```bash
# /etc/logrotate.d/db_backup
/var/log/mysql_backup.log
/var/log/postgresql_backup.log
/var/log/mongodb_backup.log
/var/log/redis_backup.log
/var/log/mariadb_backup.log
/var/log/sqlite_backup.log
/var/log/elasticsearch_backup.log
/var/log/influxdb_backup.log {
    daily
    rotate 30
    compress
    missingok
    notifempty
    create 0640 root root
}
```

## 安全建议

1. **配置文件权限** - 确保配置文件权限为 `600`，只允许所有者读取
   ```bash
   chmod 600 config.conf
   ```

2. **密码管理** - 不要在配置文件中明文存储密码，使用环境变量或密钥管理服务

3. **备份文件权限** - 备份目录权限设置为 `700`
   ```bash
   chmod 700 /var/backups/mysql
   ```

4. **加密备份** - 对敏感数据的备份文件进行加密存储

5. **异地备份** - 将备份文件复制到异地存储或云存储

## 故障排除

### 常见问题

1. **备份失败**
   - 检查数据库连接参数是否正确
   - 确保数据库服务正在运行
   - 检查备份目录是否有写入权限

2. **增量备份失败**
   - MySQL/MariaDB: 确保已启用二进制日志
   - PostgreSQL: 确保 WAL 级别配置正确
   - MongoDB: 确保已配置副本集

3. **恢复失败**
   - 检查备份文件是否损坏
   - 确保目标数据库版本与备份版本兼容
   - 检查磁盘空间是否充足

4. **权限问题**
   - 使用 `sudo` 或以数据库管理员身份运行脚本
   - 检查目录和文件权限

### 测试命令

```bash
# 测试 MySQL 连接
mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h$MYSQL_HOST -e "SELECT VERSION();"

# 测试 PostgreSQL 连接
psql -U $PG_USER -h $PG_HOST -d $PG_DATABASE -c "SELECT version();"

# 测试 MongoDB 连接
mongosh --host $MONGO_HOST --port $MONGO_PORT --eval "db.version();"

# 测试 Redis 连接
redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD PING

# 测试 Elasticsearch 连接
curl -s http://$ES_HOST:$ES_PORT/_cluster/health | python3 -m json.tool

# 测试 InfluxDB 连接
influx ping --host http://$INFLUX_HOST:$INFLUX_PORT --token $INFLUX_TOKEN
```