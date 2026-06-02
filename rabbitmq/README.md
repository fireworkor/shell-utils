# RabbitMQ 消息队列

## 简介
RabbitMQ 是一个开源的消息代理和队列服务器，用来通过普通协议在完全不同的应用之间共享数据。

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 5672 | AMQP | 消息协议 |
| 15672 | Web UI | 管理界面 |

### 主要组件

- **rabbitmq-server** - 主服务
- **rabbitmqctl** - 命令行管理
- **rabbitmq-plugins** - 插件管理
- **rabbitmqadmin** - HTTP API 工具

### 访问入口

- **AMQP**: `amqp://<IP>:5672`
- **Web UI**: `http://<IP>:15672`
- **默认账号**: guest / guest（仅 localhost）

---

## 首次安装后必做设置

### 1. 启用管理界面
```bash
sudo rabbitmq-plugins enable rabbitmq_management
```

### 2. 创建管理员用户
```bash
sudo rabbitmqctl add_user admin YourStrongPassword
sudo rabbitmqctl set_user_tags admin administrator
sudo rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
```

### 3. 允许远程访问
```bash
# /etc/rabbitmq/rabbitmq.conf
loopback_users.guest = false
```

### 4. 配置防火墙
```bash
sudo firewall-cmd --permanent --add-port=5672/tcp
sudo firewall-cmd --permanent --add-port=15672/tcp
sudo firewall-cmd --reload
```

### 5. 重启服务
```bash
sudo systemctl restart rabbitmq-server
```

访问 Web UI: `http://<IP>:15672`

---

## 详细使用说明

### 服务管理
```bash
sudo systemctl start rabbitmq-server
sudo systemctl stop rabbitmq-server
sudo systemctl restart rabbitmq-server
sudo systemctl enable rabbitmq-server
```

### 常用命令
```bash
sudo rabbitmqctl status
sudo rabbitmqctl list_users
sudo rabbitmqctl list_queues
sudo rabbitmqctl list_exchanges
sudo rabbitmqctl list_connections
```

### 备份与恢复
```bash
sudo rabbitmqctl export_definitions /tmp/definitions.json
sudo rabbitmqctl import_definitions /tmp/definitions.json
sudo cp -r /var/lib/rabbitmq/mnesia /backup/
```

---

## 常见问题

### Q: 无法远程登录？
A: 设置 loopback_users.guest = false

### Q: 内存告警？
A: 配置 vm_memory_high_watermark

---

## 后续改进方向

1. 集群部署（3 节点）
2. 镜像队列（高可用）
3. Federation（跨地域）
4. Shovel（消息迁移）
5. 监控（Prometheus + Grafana）

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
