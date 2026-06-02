# Cleanup

## 简介
系统清理工具

---

## 端口与组件

### 默认端口

{name} 不需要网络端口，或端口由配置文件动态指定。

### 主要组件

- **cleanup**: 主服务/组件

### 访问入口

- **命令行**: `cleanup`
- **配置路径**: `/opt/cleanup` 或 `/etc/cleanup`

---

## 首次安装后必做设置

### 1. 安装 Cleanup
```bash
cd cleanup
sudo bash install.sh
```

### 2. 查看软件信息
```bash
bash info.sh
```

### 3. 检查健康状态
```bash
bash healthcheck.sh
```

---

## 详细使用说明

### 版本管理
```bash
bash version.sh show
```

### 端口管理
```bash
bash port.sh show
```

### 备份与恢复
```bash
# 完整备份
bash backup.sh all

# 查看备份列表
bash backup.sh list

# 恢复备份
bash restore.sh <备份文件>
```

### 服务管理
```bash
# 启动服务（如适用）
sudo systemctl start cleanup

# 停止服务
sudo systemctl stop cleanup

# 查看状态
sudo systemctl status cleanup
```

### 健康检查
```bash
bash healthcheck.sh
```

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 安装目录 | /opt/cleanup |
| 配置目录 | /etc/cleanup |
| 日志目录 | /var/log/cleanup |
| 数据目录 | /var/lib/cleanup |

---

## 常见问题

### Q: 如何安装 Cleanup？
A: 运行 `bash install.sh` 或参考官方文档。

### Q: 服务无法启动？
A: 查看日志文件 `/var/log/cleanup` 中的错误信息。

### Q: 如何完全卸载？
A: 运行 `bash uninstall.sh` 进行卸载。

---

## 后续改进方向

1. **自动化部署**：完善安装脚本
2. **监控集成**：添加 Prometheus 监控
3. **日志管理**：配置日志轮转
4. **安全加固**：启用认证和加密
5. **高可用**：配置集群模式

---

## 维护信息

本文档随脚本集更新，如有问题请检查最新版本。
