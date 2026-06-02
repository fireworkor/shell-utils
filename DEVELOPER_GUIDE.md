# 运维工具平台 - 开发者指南

## 📋 目录

1. [项目概述](#项目概述)
2. [项目结构](#项目结构)
3. [快速开始](#快速开始)
4. [开发指南](#开发指南)
5. [测试指南](#测试指南)
6. [部署指南](#部署指南)
7. [API 文档](#api-文档)
8. [配置管理](#配置管理)
9. [错误处理](#错误处理)
10. [贡献指南](#贡献指南)

## 项目概述

这是一个基于 Bash 和 Python 的运维工具平台，提供软件安装、配置管理、健康检查、安全扫描、备份恢复等运维功能。

### 主要特性

- ✅ **软件管理**: 支持 75+ 种软件的一键安装、卸载、版本切换
- ✅ **健康检查**: 自动化系统健康检查和预警
- ✅ **安全扫描**: 安全基线扫描和合规检查
- ✅ **备份恢复**: 自动备份和增量恢复
- ✅ **Web UI**: Flask-based 可视化管理界面
- ✅ **CI/CD**: GitHub Actions 自动化测试和部署
- ✅ **单元测试**: 完整的测试框架

## 项目结构

```
/workspace/
├── .github/
│   └── workflows/
│       └── ci.yml                 # CI/CD 配置
├── .shellcheckrc                   # ShellCheck 配置
├── lib/                            # 共享库
│   ├── common.sh                   # 通用函数
│   ├── logging.sh                 # 日志系统
│   ├── logging-v2.sh              # 增强日志
│   ├── config-manager.sh          # 配置管理
│   ├── error-handler.sh           # 错误处理
│   └── error-handler-v2.sh         # 增强错误处理
├── tests/                          # 测试文件
│   ├── test_helper.sh             # 测试辅助工具
│   ├── test_example.sh            # 示例测试
│   ├── test_common.sh             # 库函数测试
│   ├── test_webui.sh              # WebUI 测试
│   ├── test_software.sh           # 软件管理测试
│   └── run_all_tests.sh           # 测试运行器
├── webui/                          # Web UI
│   ├── app.py                     # Flask 主程序
│   ├── utils.py                   # 工具函数
│   ├── health_utils.py            # 健康检查
│   ├── email_alert.py             # 邮件告警
│   └── swagger.json               # API 文档
├── scripts/                        # 工具脚本
│   └── check.sh                   # ShellCheck 检查
└── [software]/                    # 各软件目录
    ├── install.sh                 # 安装脚本
    ├── uninstall.sh               # 卸载脚本
    ├── backup.sh                  # 备份脚本
    ├── restore.sh                 # 恢复脚本
    ├── healthcheck.sh             # 健康检查
    ├── version.sh                 # 版本管理
    ├── port.sh                    # 端口管理
    ├── info.sh                    # 信息查看
    └── README.md                  # 软件文档
```

## 快速开始

### 1. 克隆项目

```bash
git clone <repository-url>
cd shell-utils
```

### 2. 运行测试

```bash
# 运行所有测试
bash tests/run_all_tests.sh

# 运行特定测试
bash tests/test_example.sh
```

### 3. 代码检查

```bash
# 运行 ShellCheck
bash scripts/check.sh
```

### 4. 启动 Web UI

```bash
cd webui
bash webui.sh start
```

## 开发指南

### 添加新软件支持

1. 创建软件目录:
```bash
mkdir -p new-software
```

2. 创建标准化脚本（参考已有软件）

3. 创建 README.md 文档

4. 添加测试用例

### 使用共享库

```bash
# 加载通用库
source lib/common.sh

# 使用日志函数
log_info "这是一条信息"
log_error "这是一个错误"

# 使用错误处理
validate_root
validate_command nginx
```

### 代码规范

1. **Shell 脚本**:
   - 使用 ShellCheck 检查
   - 添加 shebang `#!/bin/bash`
   - 使用 `set -e` 严格模式
   - 遵循 POSIX 标准

2. **Python 代码**:
   - 遵循 PEP 8
   - 添加类型注解
   - 编写单元测试

## 测试指南

### 运行测试

```bash
# 运行所有测试
bash tests/run_all_tests.sh

# 运行特定测试
bash tests/test_example.sh
bash tests/test_common.sh
bash tests/test_webui.sh
bash tests/test_software.sh
```

### 编写测试

```bash
source tests/test_helper.sh

test_my_feature() {
    echo -e "${TEST_BLUE}测试: 我的功能${TEST_NC}"
    
    # 断言相等
    result="hello"
    assert_eq "$result" "hello" "应该相等"
    
    # 断言成功
    command_that_should_succeed
    assert_success "命令应该成功"
    
    # 断言包含
    text="Hello World"
    assert_contains "$text" "World" "应该包含"
}
```

## 部署指南

### 环境要求

- Linux (CentOS 7+ / Ubuntu 18.04+)
- Python 3.8+
- Bash 4.0+
- root 权限

### 安装依赖

```bash
# Web UI 依赖
pip3 install -r webui/requirements.txt

# 安装 ShellCheck (可选)
# Debian/Ubuntu
sudo apt-get install shellcheck

# RHEL/CentOS
sudo yum install epel-release
sudo yum install shellcheck
```

### 启动服务

```bash
# 启动 Web UI
cd webui
bash webui.sh start

# 检查状态
bash webui.sh status

# 查看日志
tail -f webui/logs/webui.log
```

## API 文档

Web UI 提供完整的 REST API，可通过 Swagger UI 访问:

- **地址**: http://localhost:5000/api/docs/
- **API JSON**: http://localhost:5000/apispec.json

### 主要 API 端点

| 端点 | 方法 | 描述 |
|------|------|------|
| `/api/system-info` | GET | 获取系统信息 |
| `/api/services` | GET | 获取服务列表 |
| `/api/software/list` | GET | 获取软件列表 |
| `/api/software/install` | POST | 安装软件 |
| `/api/healthcheck` | POST | 执行健康检查 |
| `/api/backup` | POST | 执行备份 |
| `/api/alert/config` | GET/POST | 邮件预警配置 |

## 配置管理

### 集中配置

```bash
# 查看配置
bash lib/config-manager.sh show

# 验证配置
bash lib/config-manager.sh validate

# 备份配置
bash lib/config-manager.sh backup

# 恢复配置
bash lib/config-manager.sh restore /path/to/backup.conf
```

### 软件配置

每个软件目录下的 `config` 文件用于存储软件配置。

## 错误处理

### 使用错误处理库

```bash
source lib/error-handler-v2.sh

# 设置错误日志
set_error_log "/var/log/my-app/errors.log"

# 验证函数
validate_root || exit $?
validate_command nginx nginx || exit $?

# 带建议的错误输出
print_error_with_suggestion $E_NETWORK_ERROR "网络连接失败"
```

### 错误码

| 错误码 | 描述 |
|--------|------|
| 0 | 成功 |
| 1 | 一般错误 |
| 2 | 无效参数 |
| 3 | 需要 root |
| 4 | 不支持的系统 |
| 5 | 网络错误 |
| 6 | 安装失败 |
| 7 | 服务失败 |
| 8 | 文件未找到 |
| 9 | 权限不足 |
| 10 | 超时 |

## 贡献指南

### 提交代码

1. Fork 项目
2. 创建特性分支
3. 编写代码和测试
4. 运行测试确保通过
5. 提交 Pull Request

### 代码审查清单

- [ ] ShellCheck 检查通过
- [ ] 所有测试通过
- [ ] 添加了单元测试
- [ ] 更新了文档
- [ ] 遵循代码规范

### 提交信息规范

```
<type>(<scope>): <subject>

<body>

<footer>
```

类型: feat, fix, docs, style, refactor, test, chore

## 联系方式

- **项目主页**: https://github.com/your-repo
- **问题反馈**: https://github.com/your-repo/issues
- **讨论群**: 暂无

## 许可证

本项目采用 MIT 许可证 - 详见 LICENSE 文件
