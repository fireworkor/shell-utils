# 🛠️ 运维工具管理平台

基于 Flask 的可视化运维管理界面，提供一站式运维管理能力。

## ✨ 功能特性

### 📊 仪表盘
- 实时监控 CPU、内存、磁盘使用率
- 服务状态概览
- 已安装软件列表

### 🖥️ 系统信息
- 系统基本信息（主机名、内核版本、运行时间）
- CPU 信息
- 内存使用详情
- 磁盘分区信息
- 网络配置
- 进程列表

### ⚙️ 服务管理
- Nginx、MySQL、Redis、Docker、SSH 服务控制
- 启动/停止/重启操作
- 实时状态显示

### 📦 软件管理
- 查看可安装软件列表
- 一键安装指定软件
- 支持版本选择
- 已安装软件版本显示

### ✅ 健康检查
- 一键运行健康检查
- 显示详细检查结果

### 🔒 安全扫描
- 系统安全基线检查
- 多维度安全评估

### 📋 日常巡检
- 自动化日常巡检
- 生成巡检报告

### 💾 备份恢复
- MySQL、MongoDB、Redis 备份
- 支持全量备份

### 🔄 脚本升级
- 检查更新
- 自动升级

### 📝 日志查看
- Nginx 日志
- MySQL 日志
- 系统日志

## 🚀 快速开始

### 环境要求
- Python 3.6+
- Flask 2.0+

### 安装启动

```bash
# 进入目录
cd webui

# 启动服务
./start.sh

# 停止服务
./stop.sh
```

### 访问地址

启动后访问: **http://localhost:5000**

## 📁 目录结构

```
webui/
├── app.py              # Flask 应用主文件
├── start.sh            # 启动脚本
├── stop.sh             # 停止脚本
├── templates/
│   └── index.html      # Web 界面
└── logs/               # 日志目录（自动创建）
```

## 📖 API 接口

| 接口 | 方法 | 说明 |
|------|------|------|
| `/api/system-info` | GET | 获取系统信息 |
| `/api/services` | GET | 获取服务状态 |
| `/api/cpu` | GET | 获取 CPU 信息 |
| `/api/memory` | GET | 获取内存信息 |
| `/api/disk` | GET | 获取磁盘信息 |
| `/api/network` | GET | 获取网络信息 |
| `/api/processes` | GET | 获取进程列表 |
| `/api/software/list` | GET | 获取软件列表 |
| `/api/software/install` | POST | 安装软件 |
| `/api/software/status` | GET | 获取软件状态 |
| `/api/healthcheck` | POST | 运行健康检查 |
| `/api/security` | POST | 运行安全扫描 |
| `/api/daily` | POST | 运行日常巡检 |
| `/api/backup` | POST | 执行备份 |
| `/api/update/check` | GET | 检查更新 |
| `/api/service/control` | POST | 服务控制 |
| `/api/logs/<service>` | GET | 获取日志 |

## 🔧 配置说明

### 端口配置

修改 `app.py` 中的端口配置：

```python
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
```

### 安全密钥

修改 `app.py` 中的 SECRET_KEY：

```python
app.config['SECRET_KEY'] = 'your-secret-key'
```

## 📝 日志

日志文件位于 `logs/webui.log`

## 📌 注意事项

1. 需要 root 权限才能执行某些操作（如服务控制）
2. 建议在生产环境使用反向代理（如 Nginx）
3. 建议配置 HTTPS

## 📄 License

MIT License