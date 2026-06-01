# Docker Compose Templates

本仓库包含大量常用软件的 Docker Compose 配置模板，涵盖 Web 应用、数据库、监控、消息队列、大数据等多种场景。

## 目录结构

```
docker-compose-templates/
├── web-servers/              # Web 服务器和应用框架
├── databases/                # 数据库和数据存储
├── cache-queue/              # 缓存和消息队列
├── dev-tools/                # 开发和 CI/CD 工具
├── monitoring/               # 监控和日志系统
├── big-data/                 # 大数据和分析平台
├── message-queue/            # 消息队列
├── search/                   # 搜索引擎
├── file-storage/             # 文件存储
├── cms/                      # 内容管理系统
├── blog/                     # 博客系统
├── ecommerce/                # 电商平台
├── chat/                     # 聊天和即时通讯
├── git/                      # Git 和代码管理
├── container-registry/       # 容器镜像仓库
├── ci-cd/                    # CI/CD 工具链
├── security/                 # 安全工具
├── automation/               # 自动化工具
├── media/                    # 媒体处理
├── education/                # 教育平台
├── collaboration/            # 协作工具
├── productivity/             # 生产力工具
├── home-automation/          # 家庭自动化
├── backup/                   # 备份和恢复
└── networking/               # 网络和代理
```

## 完整配置列表

### Web 服务器和应用框架 (10个)
| 配置文件 | 描述 | 主要组件 |
|---------|------|---------|
| [`nginx-php-mysql.yml`](./web-servers/nginx-php-mysql.yml) | Nginx + PHP + MySQL + phpMyAdmin 完整 LNMP 栈 | Nginx, PHP, MySQL, phpMyAdmin |
| [`apache-php.yml`](./web-servers/apache-php.yml) | Apache + PHP + MariaDB 经典组合 | Apache, PHP, MariaDB |
| [`nodejs-mongodb.yml`](./web-servers/nodejs-mongodb.yml) | Node.js + MongoDB + Mongo Express | Node.js, MongoDB, Mongo Express |
| [`django-postgres.yml`](./web-servers/django-postgres.yml) | Django + PostgreSQL + pgAdmin | Django, PostgreSQL, pgAdmin |
| [`rails-redis.yml`](./web-servers/rails-redis.yml) | Ruby on Rails + Redis + PostgreSQL | Rails, PostgreSQL, Redis |
| [`flask-redis.yml`](./web-servers/flask-redis.yml) | Flask + Redis 轻量级应用 | Flask, Redis |
| [`vuejs-nginx.yml`](./web-servers/vuejs-nginx.yml) | Vue.js + Nginx 前端应用 | Vue.js, Nginx |
| [`react-express-mysql.yml`](./web-servers/react-express-mysql.yml) | React + Express + MySQL 全栈应用 | React, Express, MySQL |
| [`laravel.yml`](./web-servers/laravel.yml) | Laravel + Nginx + MySQL + Redis | Laravel, Nginx, MySQL, Redis |
| [`springboot-postgres.yml`](./web-servers/springboot-postgres.yml) | Spring Boot + PostgreSQL | Spring Boot, PostgreSQL |
| [`go-gin-redis.yml`](./web-servers/go-gin-redis.yml) | Go + Gin + Redis + PostgreSQL | Go, Gin, Redis, PostgreSQL |

### 数据库和数据存储 (7个)
| 配置文件 | 描述 | 主要组件 |
|---------|------|---------|
| [`mysql-master-slave.yml`](./databases/mysql-master-slave.yml) | MySQL 主从复制架构 | MySQL Master, MySQL Slave |
| [`postgresql-pgpool.yml`](./databases/postgresql-pgpool.yml) | PostgreSQL + Pgpool-II 集群 | PostgreSQL, Pgpool-II |
| [`mongodb-replica.yml`](./databases/mongodb-replica.yml) | MongoDB 三节点副本集 | MongoDB x3, Mongo Express |
| [`redis-cluster.yml`](./databases/redis-cluster.yml) | Redis 6 节点集群 | Redis Cluster (6 nodes) |
| [`mariadb-galera.yml`](./databases/mariadb-galera.yml) | MariaDB Galera 集群 + MaxScale | MariaDB Galera, MaxScale |
| [`cockroachdb.yml`](./databases/cockroachdb.yml) | CockroachDB 分布式数据库 | CockroachDB (3 nodes) |
| [`etcd-cluster.yml`](./databases/etcd-cluster.yml) | etcd 三节点高可用集群 | etcd (3 nodes) |

### 缓存和消息队列 (3个)
| 配置文件 | 描述 | 主要组件 |
|---------|------|---------|
| [`redis-sentinel.yml`](./cache-queue/redis-sentinel.yml) | Redis + Sentinel 高可用 | Redis Master, 2 Slaves, 3 Sentinels |
| [`kafka-cluster.yml`](./cache-queue/kafka-cluster.yml) | Kafka + Zookeeper 集群 | Zookeeper x3, Kafka x3, Kafka UI |
| [`rabbitmq-cluster.yml`](./cache-queue/rabbitmq-cluster.yml) | RabbitMQ 集群 + HAProxy | RabbitMQ x3, HAProxy |

### 开发和 CI/CD 工具 (3个)
| 配置文件 | 描述 | 主要组件 |
|---------|------|---------|
| [`sonarqube.yml`](./dev-tools/sonarqube.yml) | SonarQube 代码质量分析 | SonarQube, PostgreSQL |
| [`gitlab.yml`](./dev-tools/gitlab.yml) | GitLab 自托管 Git 平台 | GitLab CE |
| [`jenkins.yml`](./dev-tools/jenkins.yml) | Jenkins 持续集成 | Jenkins (with Docker support) |

### 监控和日志系统 (3个)
| 配置文件 | 描述 | 主要组件 |
|---------|------|---------|
| [`prometheus-grafana.yml`](./monitoring/prometheus-grafana.yml) | Prometheus + Grafana 监控栈 | Prometheus, Grafana, Node Exporter, Alertmanager |
| [`elk.yml`](./monitoring/elk.yml) | ELK 日志分析平台 | Elasticsearch, Logstash, Kibana, Filebeat |
| [`loki.yml`](./monitoring/loki.yml) | Loki + Promtail + Grafana | Loki, Promtail, Grafana |

### 大数据和分析平台 (2个)
| 配置文件 | 描述 | 主要组件 |
|---------|------|---------|
| [`hadoop.yml`](./big-data/hadoop.yml) | Hadoop HDFS + YARN | NameNode, DataNodes x3, ResourceManager, NodeManager |
| [`spark.yml`](./big-data/spark.yml) | Spark Standalone 集群 | Spark Master, Spark Workers x2 |

### 内容管理和应用 (1个)
| 配置文件 | 描述 | 主要组件 |
|---------|------|---------|
| [`wordpress.yml`](./cms/wordpress.yml) | WordPress 内容管理系统 | WordPress, MySQL |

### 搜索引擎 (1个)
| 配置文件 | 描述 | 主要组件 |
|---------|------|---------|
| [`elasticsearch.yml`](./search/elasticsearch.yml) | Elasticsearch + Kibana | Elasticsearch, Kibana |

### 文件存储 (1个)
| 配置文件 | 描述 | 主要组件 |
|---------|------|---------|
| [`minio.yml`](./file-storage/minio.yml) | MinIO 对象存储 | MinIO, MinIO Client |

### 聊天和即时通讯 (1个)
| 配置文件 | 描述 | 主要组件 |
|---------|------|---------|
| [`mattermost.yml`](./chat/mattermost.yml) | Mattermost 团队协作平台 | Mattermost, PostgreSQL |

### 容器镜像仓库 (1个)
| 配置文件 | 描述 | 主要组件 |
|---------|------|---------|
| [`registry.yml`](./container-registry/registry.yml) | Docker Registry + UI | Docker Registry, Registry UI |

### 备份和恢复 (1个)
| 配置文件 | 描述 | 主要组件 |
|---------|------|---------|
| [`backup-manager.yml`](./backup/backup-manager.yml) | Docker 卷备份管理 | Docker Volume Backup |

### 网络和代理 (1个)
| 配置文件 | 描述 | 主要组件 |
|---------|------|---------|
| [`traefik.yml`](./networking/traefik.yml) | Traefik 反向代理和负载均衡 | Traefik, Whoami |

## 快速开始

### 1. 选择配置
根据需要选择对应的 `docker-compose.yml` 文件。

### 2. 准备环境
确保已安装：
- Docker
- Docker Compose

### 3. 启动服务
```bash
# 进入对应目录
cd docker-compose-templates/web-servers/

# 启动服务
docker-compose -f nginx-php-mysql.yml up -d

# 查看日志
docker-compose -f nginx-php-mysql.yml logs -f

# 停止服务
docker-compose -f nginx-php-mysql.yml down

# 停止并删除数据
docker-compose -f nginx-php-mysql.yml down -v
```

## 常见问题

### 端口冲突
如果遇到端口冲突，可以修改 docker-compose.yml 中的端口映射：
```yaml
ports:
  - "8080:80"  # 外部端口:内部端口
```

### 数据持久化
所有配置都已配置 Docker Volumes，数据会自动持久化。如需备份，直接备份 volumes 数据即可。

### 内存不足
部分服务（如 Elasticsearch, SonarQube）需要较多内存。如遇内存问题，可以调整：
- 减少副本数
- 调整 JVM 参数
- 使用更低配置的 Docker 镜像

## 注意事项

1. **生产环境**：这些配置主要用于开发和测试，生产环境请进一步优化：
   - 配置密码和安全设置
   - 使用专用网络
   - 配置资源限制
   - 设置日志轮转
   - 配置监控告警

2. **数据安全**：
   - 默认密码仅供测试，生产环境必须修改
   - 定期备份重要数据
   - 不要将配置文件提交到公开仓库

3. **镜像版本**：
   - 示例使用 latest 版本，建议锁定具体版本号
   - 定期更新保持安全补丁

## 贡献

欢迎提交新的配置模板！请确保：
1. 使用稳定的 Docker 镜像
2. 配置数据持久化
3. 添加详细说明注释
4. 遵循现有文件格式

## 许可证

MIT License
