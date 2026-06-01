# 安全基线检查工具集

全面的安全基线检查工具，支持操作系统、数据库、Web服务器、Docker、网络等多方面的安全检查。

## 目录结构

```
security-baseline/
├── security-baseline.sh    # 统一管理脚本
├── os/                    # 操作系统安全检查
│   └── os_baseline.sh
├── database/              # 数据库安全检查
│   └── db_baseline.sh
├── web/                   # Web 服务器安全检查
│   └── web_baseline.sh
├── docker/                # Docker 安全检查
│   └── docker_baseline.sh
├── network/               # 网络安全检查
│   └── network_baseline.sh
└── README.md
```

## 功能特性

### 🎯 支持的检查类型

| 检查类型 | 检查项数量 | 主要内容 |
|---------|-----------|---------|
| **操作系统** | 21 项 | 用户权限、密码策略、服务配置、文件系统、内核参数 |
| **数据库** | 40+ 项 | MySQL、PostgreSQL、MongoDB、Redis 认证、权限、网络配置 |
| **Web 服务器** | 20 项 | Nginx、Apache 安全头、SSL/TLS、目录权限 |
| **Docker** | 16 项 | 容器安全、镜像安全、运行时安全、存储驱动 |
| **网络安全** | 18 项 | 端口扫描、防火墙、内核参数、网络协议 |

### 🛡️ 安全检查项

#### 操作系统安全 (21 项)
1. 密码文件权限 (/etc/passwd, /etc/shadow)
2. root 账户 UID 检查
3. 重复 UID 检查
4. 空密码账户检查
5. 密码策略配置
6. sudo 配置检查
7. SSH 安全配置
8. Cron 服务访问控制
9. 内核参数配置
10. 不必要服务检查
11. 防火墙状态
12. 审计服务状态
13. 全局可写文件检查
14. SUID 文件检查
15. .netrc 文件检查
16. .rhost 文件检查
17. /tmp 分区配置
18. 日志文件权限
19. hosts.allow/deny 配置
20. 用户组配置
21. 安全补丁检查

#### 数据库安全 (支持 MySQL、PostgreSQL、MongoDB、Redis)
- ✅ 账户安全 (root、匿名账户)
- ✅ 密码策略
- ✅ 认证机制
- ✅ 权限配置
- ✅ 网络访问
- ✅ 日志审计
- ✅ SSL/TLS 加密
- ✅ 危险命令限制

#### Web 服务器安全 (Nginx、Apache)
- ✅ 版本信息隐藏
- ✅ 安全响应头 (X-Frame-Options, CSP, etc.)
- ✅ SSL/TLS 配置
- ✅ 目录浏览禁用
- ✅ HTTP 方法限制
- ✅ 文件权限
- ✅ 用户权限

#### Docker 安全 (CIS Docker Benchmark)
- ✅ Docker Socket 权限
- ✅ 容器用户配置
- ✅ 网络模式
- ✅ 端口映射
- ✅ Rootless 模式
- ✅ Content Trust
- ✅ 日志配置
- ✅ 存储驱动
- ✅ 安全选项

#### 网络安全 (18 项)
- ✅ 开放端口扫描
- ✅ 危险端口检测
- ✅ 防火墙规则
- ✅ 网卡混杂模式
- ✅ SYN Cookies
- ✅ IP 转发
- ✅ 源路由
- ✅ ICMP 配置
- ✅ 反向路径过滤
- ✅ DNS 配置
- ✅ ARP 防护

## 快速开始

### 一键执行所有检查

```bash
# 添加执行权限
chmod +x security-baseline.sh

# 执行所有安全检查
sudo ./security-baseline.sh all

# 指定报告目录
sudo ./security-baseline.sh --report-dir ./reports all
```

### 分类执行

```bash
# 仅操作系统安全检查
sudo ./security-baseline.sh os

# 仅数据库安全检查
sudo ./security-baseline.sh database

# 仅 Web 服务器安全检查
sudo ./security-baseline.sh web

# 仅 Docker 安全检查
sudo ./security-baseline.sh docker

# 仅网络安全检查
sudo ./security-baseline.sh network
```

### 单独执行

```bash
# 操作系统安全检查
sudo ./os/os_baseline.sh

# 数据库安全检查 (支持参数)
sudo ./database/db_baseline.sh              # 检查所有数据库
sudo ./database/db_baseline.sh mysql        # 仅 MySQL
sudo ./database/db_baseline.sh postgresql   # 仅 PostgreSQL
sudo ./database/db_baseline.sh redis        # 仅 Redis

# Web 服务器安全检查
sudo ./web/web_baseline.sh                  # 检查 Nginx 和 Apache
sudo ./web/web_baseline.sh nginx            # 仅 Nginx
sudo ./web/web_baseline.sh apache           # 仅 Apache

# Docker 安全检查
sudo ./docker/docker_baseline.sh

# 网络安全检查
sudo ./network/network_baseline.sh
```

## 使用示例

### 示例 1：定期安全巡检

```bash
# 创建定时任务 (每天凌晨 2 点执行)
sudo crontab -e

# 添加以下行
0 2 * * * /path/to/security-baseline.sh all --report-dir /var/log/security-reports/$(date +\%Y\%m\%d)
```

### 示例 2：发送邮件报告

```bash
# 设置邮箱并执行检查
EMAIL=admin@example.com ./security-baseline.sh all
```

### 示例 3：集成到 CI/CD

```bash
# 在 CI/CD 流水线中添加
- name: Security Baseline Check
  run: |
    ./security-baseline.sh all
    if grep -q "FAIL" security_reports_*/os_check.log; then
      exit 1
    fi
```

## 输出报告

检查完成后，会在指定目录生成以下文件：

```
security_reports_20240101_120000/
├── os_check.log          # 操作系统安全检查报告
├── database_check.log    # 数据库安全检查报告
├── web_check.log         # Web 服务器安全检查报告
├── docker_check.log      # Docker 安全检查报告
└── network_check.log     # 网络安全检查报告
```

### 报告格式

```
========================================
[INFO] 检查项描述
[PASS] 符合安全要求 - 详细说明
[FAIL] 不符合安全要求 - 问题说明
[WARN] 安全警告 - 建议说明
```

## 安全建议

### 高危问题 (必须修复)

1. **空密码账户** - 立即设置强密码
2. **SSH 允许 root 登录** - 禁用 root 远程登录
3. **MySQL/Redis 无密码** - 配置强密码
4. **防火墙未启用** - 启用并配置规则
5. **危险端口开放** - 确认业务需求，关闭不必要的端口

### 中危问题 (尽快修复)

1. **密码策略过于宽松** - 设置最小长度和过期时间
2. **SSL/TLS 使用旧版本** - 禁用 SSLv3, TLS 1.0, 1.1
3. **Docker 容器特权模式** - 避免使用 --privileged
4. **日志未配置** - 配置适当的日志级别

### 低危问题 (建议关注)

1. **SYN Cookies 未明确启用** - 启用防止 SYN 洪水
2. **非标准端口** - 记录并监控
3. **未使用安全镜像** - 考虑使用 distroless

## 合规性

本工具遵循以下安全标准：

- **CIS Benchmark** - Docker 安全基准
- **PCI DSS** - 支付卡行业数据安全标准
- **ISO 27001** - 信息安全管理体系
- **等级保护 2.0** - 中国网络安全等级保护

## 扩展开发

### 添加新的检查项

在对应模块的脚本中添加检查函数：

```bash
check_custom_item() {
    log_info "检查: 自定义检查项"
    
    if [ condition ]; then
        log_pass "检查通过"
    else
        log_fail "检查失败"
    fi
}
```

### 添加新的数据库支持

在 `database/db_baseline.sh` 中添加新的检查函数：

```bash
check_newdb() {
    log_info "检查: NewDB 安全"
    # 检查逻辑
}
```

## 常见问题

### Q: 需要 root 权限吗？
A: 是的，大部分安全检查需要 root 权限才能读取系统配置文件。

### Q: 会修改系统配置吗？
A: 不会，所有脚本仅做检查，不做任何修改。

### Q: 支持哪些操作系统？
A: 主要支持 CentOS、RHEL、Ubuntu、Debian 等主流 Linux 发行版。

### Q: 可以集成到现有系统吗？
A: 可以，通过脚本输出的日志文件和退出码进行集成。

## 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支
3. 提交更改
4. 发起 Pull Request

## 许可证

MIT License
