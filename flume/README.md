# Flume

## 简介
Flume 日志收集

---

## 端口与组件

### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
| 44444 | 默认端口 |  |

### 主要组件

- **flume**: 主服务

### 访问入口

- **服务地址**: 根据实际配置确定

---

## 首次安装后必做设置

### 1. 安装 Flume
请根据官方文档或 README.md 说明进行安装

### 2. 配置环境变量
```bash
# 根据需要配置环境变量
```

### 3. 启动服务
```bash
# 启动 Flume 服务
sudo systemctl start flume
```

---

## 详细使用说明

### 健康检查
```bash
bash healthcheck.sh
```

### 备份与恢复
```bash
bash backup.sh all
bash backup.sh list
bash restore.sh /path/to/backup.tar.gz
```

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 安装目录 | /opt/flume |
| 配置目录 | /etc/flume |
| 日志目录 | /var/log/flume |
| 数据目录 | /var/lib/flume |

---

## 常见问题

### Q: 如何安装 Flume？
A: 请参考官方文档或 README.md 中的说明。

### Q: 服务无法启动？
A: 查看日志文件 /var/log/flume 中的错误信息。

---

## 后续改进方向

1. **集群部署**：配置高可用集群
2. **监控**：集成 Prometheus + Grafana
3. **安全**：启用认证和加密
4. **优化**：调整性能参数

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
