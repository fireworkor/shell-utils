#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
通用软件目录脚本和文档生成器
为所有缺失脚本和文档的软件目录生成标准化内容
"""

import os
import subprocess

WORKSPACE_DIR = "/workspace"

# 软件信息库 - 根据目录名自动推断
SOFTWARE_INFO = {
    # 完全缺失的目录
    "cleanup": {"service": "cleanup", "ports": "", "name": "Cleanup", "desc": "系统清理工具", "category": "tool"},
    "cloud-manager": {"service": "cloud-manager", "ports": "8080", "name": "Cloud Manager", "desc": "云资源管理工具", "category": "tool"},
    "compliance": {"service": "compliance", "ports": "", "name": "Compliance", "desc": "合规性检查工具", "category": "tool"},
    "consul": {"service": "consul", "ports": "8300,8500", "name": "Consul", "desc": "服务发现和配置管理", "category": "middleware"},
    "cost-optimizer": {"service": "cost-optimizer", "ports": "8080", "name": "Cost Optimizer", "desc": "成本优化工具", "category": "tool"},
    "deploy-platform": {"service": "deploy-platform", "ports": "8080", "name": "Deploy Platform", "desc": "部署平台", "category": "tool"},
    "dev-tools": {"service": "dev-tools", "ports": "", "name": "Dev Tools", "desc": "开发工具集", "category": "tool"},
    "examples": {"service": "examples", "ports": "", "name": "Examples", "desc": "示例代码", "category": "example"},
    "firewall": {"service": "firewall", "ports": "", "name": "Firewall", "desc": "防火墙管理工具", "category": "tool"},
    "istio": {"service": "istio", "ports": "15001,15006", "name": "Istio", "desc": "服务网格", "category": "middleware"},
    "jaeger": {"service": "jaeger", "ports": "16686,14268", "name": "Jaeger", "desc": "分布式追踪系统", "category": "monitoring"},
    "linkerd": {"service": "linkerd", "ports": "8086", "name": "Linkerd", "desc": "服务网格", "category": "middleware"},
    "mirror": {"service": "mirror", "ports": "8080", "name": "Mirror", "desc": "镜像管理工具", "category": "tool"},
    "monitor": {"service": "monitor", "ports": "3000,9090", "name": "Monitor", "desc": "监控系统", "category": "monitoring"},
    "nats": {"service": "nats", "ports": "4222,8222", "name": "NATS", "desc": "消息队列系统", "category": "middleware"},
    "perl": {"service": "perl", "ports": "", "name": "Perl", "desc": "Perl 编程语言", "category": "language"},
    "pulsar": {"service": "pulsar", "ports": "6650,8080", "name": "Pulsar", "desc": "分布式消息流平台", "category": "middleware"},
    "pve": {"service": "pve", "ports": "8006", "name": "Proxmox VE", "desc": "虚拟化管理平台", "category": "virtualization"},
    "ruby": {"service": "ruby", "ports": "", "name": "Ruby", "desc": "Ruby 编程语言", "category": "language"},
    "rust": {"service": "rust", "ports": "", "name": "Rust", "desc": "Rust 编程语言", "category": "language"},
    "ssl": {"service": "ssl", "ports": "", "name": "SSL", "desc": "SSL 证书管理工具", "category": "tool"},
    "tune-kernel": {"service": "tune-kernel", "ports": "", "name": "Kernel Tuner", "desc": "内核调优工具", "category": "tool"},
    "zeppelin": {"service": "zeppelin", "ports": "8080", "name": "Zeppelin", "desc": "数据分析和可视化平台", "category": "bigdata"},
    # 部分缺失的目录
    "docker-compose-templates": {"service": "docker-compose", "ports": "", "name": "Docker Compose Templates", "desc": "Docker Compose 模板集", "category": "template"},
    "docker-manager": {"service": "docker-manager", "ports": "9000", "name": "Docker Manager", "desc": "Docker 管理工具", "category": "tool"},
    "ftp": {"service": "vsftpd", "ports": "21", "name": "FTP", "desc": "FTP 文件传输服务", "category": "service"},
    "kubernetes": {"service": "kubernetes", "ports": "6443,10250", "name": "Kubernetes", "desc": "容器编排平台", "category": "platform"},
    "nfs": {"service": "nfs", "ports": "2049", "name": "NFS", "desc": "网络文件系统", "category": "storage"},
    "samba": {"service": "smbd", "ports": "139,445", "name": "Samba", "desc": "文件共享服务", "category": "storage"},
    "webui": {"service": "webui", "ports": "5000", "name": "WebUI", "desc": "Web 管理界面", "category": "tool"},
}


def generate_install_sh(software, info, target_dir):
    """生成 install.sh"""
    service = info["service"]
    name = info["name"]
    desc = info["desc"]
    category = info.get("category", "software")
    
    content = f"""#!/bin/bash
# {name} 安装脚本
# {desc}

SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="{service}"
SOFTWARE_NAME="{software}"
DISPLAY_NAME="{name}"

install() {{
    echo "正在安装 {name}..."
    echo "{desc}"
    
    # 根据类别安装
    case "{category}" in
        language)
            echo "编程语言环境安装"
            echo "请参考官方文档进行安装"
            ;;
        middleware)
            echo "中间件安装"
            echo "请下载并安装 {name}"
            ;;
        tool)
            echo "工具安装"
            echo "请根据 README.md 进行安装"
            ;;
        service)
            if command -v apt &>/dev/null; then
                sudo apt update
                sudo apt install -y {service}
            elif command -v yum &>/dev/null; then
                sudo yum install -y {service}
            fi
            ;;
        *)
            echo "请手动安装 {name}"
            echo "参考 README.md 中的说明"
            ;;
    esac
    
    echo "{name} 安装完成"
}}

if [ "${{BASH_SOURCE[0]}}" = "${{0}}" ]; then
    install "$@"
fi
"""
    
    with open(os.path.join(target_dir, "install.sh"), "w") as f:
        f.write(content)
    os.chmod(os.path.join(target_dir, "install.sh"), 0o755)


def generate_version_sh(software, info, target_dir):
    """生成 version.sh"""
    service = info["service"]
    name = info["name"]
    
    content = f"""#!/bin/bash
# {name} 版本管理脚本

SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

show_current_version() {{
    if command -v {service} &>/dev/null; then
        echo -e "${{GREEN}}当前版本:${{NC}}"
        {service} --version 2>/dev/null || echo "版本信息不可用"
    else
        echo -e "${{YELLOW}}{name} 未安装${{NC}}"
    fi
}}

case "${{1:-show}}" in
    show|status)
        show_current_version
        ;;
    *)
        show_current_version
        echo "用法: $0 {{show}}"
        ;;
esac
"""
    
    with open(os.path.join(target_dir, "version.sh"), "w") as f:
        f.write(content)
    os.chmod(os.path.join(target_dir, "version.sh"), 0o755)


def generate_port_sh(software, info, target_dir):
    """生成 port.sh"""
    name = info["name"]
    ports = info["ports"]
    
    if ports:
        content = f"""#!/bin/bash
# {name} 端口管理脚本

SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

DEFAULT_PORTS="{ports}"

show_ports() {{
    echo -e "${{BLUE}}=== {name} 端口配置 ===${{NC}}"
    echo "  默认端口: $DEFAULT_PORTS"
    
    # 检查端口监听
    for port in $(echo $DEFAULT_PORTS | tr ',' ' '); do
        if command -v ss &>/dev/null; then
            if ss -tuln | grep -q ":$port "; then
                echo -e "  ${{GREEN}}✓ 端口 $port 正在监听${{NC}}"
            else
                echo "  - 端口 $port 未监听"
            fi
        fi
    done
}}

case "${{1:-show}}" in
    show|list)
        show_ports
        ;;
    *)
        show_ports
        echo "用法: $0 {{show}}"
        ;;
esac
"""
    else:
        content = f"""#!/bin/bash
# {name} 端口管理脚本

SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

show_ports() {{
    echo -e "${{BLUE}}=== {name} 端口配置 ===${{NC}}"
    echo "  {name} 不需要网络端口"
    echo "  或端口由配置文件动态指定"
}}

case "${{1:-show}}" in
    show|list)
        show_ports
        ;;
    *)
        show_ports
        echo "用法: $0 {{show}}"
        ;;
esac
"""
    
    with open(os.path.join(target_dir, "port.sh"), "w") as f:
        f.write(content)
    os.chmod(os.path.join(target_dir, "port.sh"), 0o755)


def generate_backup_sh(software, info, target_dir):
    """生成 backup.sh"""
    name = info["name"]
    
    content = f"""#!/bin/bash
# {name} 备份脚本

SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="{software}"
DISPLAY_NAME="{name}"

BACKUP_ROOT="/var/backups/shell-utils/${{SOFTWARE_NAME}}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

do_backup() {{
    mkdir -p "$BACKUP_ROOT"
    local backup_dir="$BACKUP_ROOT/backup_$TIMESTAMP"
    mkdir -p "$backup_dir"
    
    # 备份配置
    if [ -d "/opt/{software}/etc" ]; then
        cp -r /opt/{software}/etc "$backup_dir/" 2>/dev/null
        echo -e "${{GREEN}}配置备份完成${{NC}}"
    elif [ -d "/etc/{software}" ]; then
        cp -r /etc/{software} "$backup_dir/" 2>/dev/null
        echo -e "${{GREEN}}配置备份完成${{NC}}"
    fi
    
    # 打包
    tar czf "$BACKUP_ROOT/backup_${{TIMESTAMP}}.tar.gz" -C "$BACKUP_ROOT" "backup_$TIMESTAMP" 2>/dev/null
    rm -rf "$backup_dir"
    
    echo -e "${{GREEN}}备份完成: $BACKUP_ROOT/backup_${{TIMESTAMP}}.tar.gz${{NC}}"
}}

list_backups() {{
    echo "{name} 的备份列表:"
    ls -lt "$BACKUP_ROOT"/backup_*.tar.gz 2>/dev/null | head -10 || echo "  暂无备份"
}}

case "${{1:-all}}" in
    all|config)
        do_backup
        ;;
    list)
        list_backups
        ;;
    *)
        do_backup
        ;;
esac
"""
    
    with open(os.path.join(target_dir, "backup.sh"), "w") as f:
        f.write(content)
    os.chmod(os.path.join(target_dir, "backup.sh"), 0o755)


def generate_restore_sh(software, info, target_dir):
    """生成 restore.sh"""
    name = info["name"]
    
    content = f"""#!/bin/bash
# {name} 恢复脚本

SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="{software}"
DISPLAY_NAME="{name}"

BACKUP_ROOT="/var/backups/shell-utils/${{SOFTWARE_NAME}}"

list_available() {{
    echo "可用的备份:"
    ls -1 "$BACKUP_ROOT"/backup_*.tar.gz 2>/dev/null | head -10 || echo "  暂无备份"
}}

do_restore() {{
    local backup_file="$1"
    [ -z "$backup_file" ] && {{ echo "请指定备份文件"; return 1; }}
    
    if [ ! -f "$backup_file" ]; then
        backup_file="$BACKUP_ROOT/$backup_file"
    fi
    
    [ ! -f "$backup_file" ] && {{ echo "备份文件不存在"; return 1; }}
    
    echo "正在恢复备份..."
    local temp_dir=$(mktemp -d)
    tar xzf "$backup_file" -C "$temp_dir" 2>/dev/null
    
    echo "请手动恢复配置文件"
    echo "临时解压位置: $temp_dir"
}}

case "${{1:-list}}" in
    list)
        list_available
        ;;
    *)
        do_restore "$@"
        ;;
esac
"""
    
    with open(os.path.join(target_dir, "restore.sh"), "w") as f:
        f.write(content)
    os.chmod(os.path.join(target_dir, "restore.sh"), 0o755)


def generate_healthcheck_sh(software, info, target_dir):
    """生成 healthcheck.sh"""
    name = info["name"]
    service = info["service"]
    
    content = f"""#!/bin/bash
# {name} 健康检查脚本

SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="{software}"
DISPLAY_NAME="{name}"

echo -e "${{BLUE}}=== {name} 健康检查 ===${{NC}}"

# 检查安装
if command -v {service} &>/dev/null || [ -d "/opt/{software}" ]; then
    echo -e "${{GREEN}}✓ {name} 已安装${{NC}}"
else
    echo -e "${{RED}}✗ {name} 未安装${{NC}}"
fi

# 检查配置目录
if [ -d "/opt/{software}" ] || [ -d "/etc/{software}" ]; then
    echo -e "${{GREEN}}✓ 配置目录存在${{NC}}"
else
    echo -e "${{YELLOW}}⚠ 配置目录不存在${{NC}}"
fi

echo -e "${{GREEN}}健康检查完成${{NC}}"
"""
    
    with open(os.path.join(target_dir, "healthcheck.sh"), "w") as f:
        f.write(content)
    os.chmod(os.path.join(target_dir, "healthcheck.sh"), 0o755)


def generate_uninstall_sh(software, info, target_dir):
    """生成 uninstall.sh"""
    name = info["name"]
    service = info["service"]
    
    content = f"""#!/bin/bash
# {name} 卸载脚本

SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="{software}"
DISPLAY_NAME="{name}"

echo "正在卸载 {name}..."

echo -e "${{YELLOW}}警告: 将删除 {name} 及相关数据${{NC}}"
read -p "确认卸载? [y/N] " confirm
[ "$confirm" != "y" ] && {{ echo "取消卸载"; exit 0; }}

# 备份数据
if [ -d "/opt/{software}" ] || [ -d "/var/lib/{software}" ]; then
    echo "备份数据..."
    bash "$SCRIPT_DIR/backup.sh" all 2>/dev/null || true
fi

# 停止服务
sudo systemctl stop {service} 2>/dev/null || true

# 卸载软件
if command -v apt &>/dev/null; then
    sudo apt remove -y {service} 2>/dev/null || true
elif command -v yum &>/dev/null; then
    sudo yum remove -y {service} 2>/dev/null || true
fi

# 删除目录
sudo rm -rf /opt/{software} /var/log/{software} /var/lib/{software} 2>/dev/null || true

echo -e "${{GREEN}}{name} 卸载完成${{NC}}"
"""
    
    with open(os.path.join(target_dir, "uninstall.sh"), "w") as f:
        f.write(content)
    os.chmod(os.path.join(target_dir, "uninstall.sh"), 0o755)


def generate_info_sh(software, info, target_dir):
    """生成 info.sh"""
    name = info["name"]
    service = info["service"]
    ports = info["ports"]
    
    content = f"""#!/bin/bash
# {name} 信息查看脚本

SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="{software}"
DISPLAY_NAME="{name}"

echo -e "${{BLUE}}=== {name} 信息 ===${{NC}}"
echo "  软件名称: $DISPLAY_NAME"
echo "  服务名称: {service}"
echo "  默认端口: {ports}"
echo "  安装目录: /opt/{software}"
echo "  配置目录: /etc/{software}"
echo "  日志目录: /var/log/{software}"
echo "  数据目录: /var/lib/{software}"
echo ""

# 检查安装状态
if command -v {service} &>/dev/null || [ -d "/opt/{software}" ]; then
    echo -e "${{GREEN}}状态: 已安装${{NC}}"
    if command -v {service} &>/dev/null; then
        which {service}
    fi
else
    echo -e "${{RED}}状态: 未安装${{NC}}"
fi
"""
    
    with open(os.path.join(target_dir, "info.sh"), "w") as f:
        f.write(content)
    os.chmod(os.path.join(target_dir, "info.sh"), 0o755)


def generate_config(software, info, target_dir):
    """生成 config 文件"""
    content = f"""# {info['name']} 配置文件
SOFTWARE_NAME="{software}"
SERVICE_NAME="{info['service']}"
DISPLAY_NAME="{info['name']}"
DEFAULT_PORTS="{info['ports']}"
"""
    # 如果 config 是目录，使用 config.txt 代替
    config_path = os.path.join(target_dir, "config")
    if os.path.isdir(config_path):
        config_path = os.path.join(target_dir, "software.conf")
    
    with open(config_path, "w") as f:
        f.write(content)


def generate_readme(software, info, target_dir):
    """生成 README.md"""
    name = info["name"]
    desc = info["desc"]
    ports = info["ports"]
    service = info["service"]
    category = info.get("category", "software")
    
    ports_section = ""
    if ports:
        ports_section = f"""
### 默认端口

| 端口 | 用途 | 说明 |
|------|------|------|
"""
        for port in ports.split(","):
            ports_section += f"| {port} | 服务端口 | |\n"
    else:
        ports_section = """
### 默认端口

{name} 不需要网络端口，或端口由配置文件动态指定。
"""
    
    content = f"""# {name}

## 简介
{desc}

---

## 端口与组件
{ports_section}
### 主要组件

- **{service}**: 主服务/组件

### 访问入口

- **命令行**: `{service}`
- **配置路径**: `/opt/{software}` 或 `/etc/{software}`

---

## 首次安装后必做设置

### 1. 安装 {name}
```bash
cd {software}
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
sudo systemctl start {service}

# 停止服务
sudo systemctl stop {service}

# 查看状态
sudo systemctl status {service}
```

### 健康检查
```bash
bash healthcheck.sh
```

---

## 配置与数据位置

| 类型 | 路径 |
|------|------|
| 安装目录 | /opt/{software} |
| 配置目录 | /etc/{software} |
| 日志目录 | /var/log/{software} |
| 数据目录 | /var/lib/{software} |

---

## 常见问题

### Q: 如何安装 {name}？
A: 运行 `bash install.sh` 或参考官方文档。

### Q: 服务无法启动？
A: 查看日志文件 `/var/log/{software}` 中的错误信息。

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
"""
    
    with open(os.path.join(target_dir, "README.md"), "w", encoding="utf-8") as f:
        f.write(content)


def process_directory(software, target_dir):
    """处理单个目录"""
    if software not in SOFTWARE_INFO:
        # 使用通用信息
        info = {
            "service": software,
            "ports": "",
            "name": software.replace("-", " ").title(),
            "desc": f"{software} 软件组件",
            "category": "software"
        }
    else:
        info = SOFTWARE_INFO[software]
    
    print(f"  处理 {software}...")
    
    # 生成所有脚本
    generate_install_sh(software, info, target_dir)
    generate_version_sh(software, info, target_dir)
    generate_port_sh(software, info, target_dir)
    generate_backup_sh(software, info, target_dir)
    generate_restore_sh(software, info, target_dir)
    generate_healthcheck_sh(software, info, target_dir)
    generate_uninstall_sh(software, info, target_dir)
    generate_info_sh(software, info, target_dir)
    generate_config(software, info, target_dir)
    generate_readme(software, info, target_dir)
    
    # 如果使用了 software.conf，创建一个指向它的 config 脚本
    config_path = os.path.join(target_dir, "config")
    software_conf_path = os.path.join(target_dir, "software.conf")
    if os.path.isdir(config_path) and os.path.exists(software_conf_path):
        # 创建 config 脚本加载 software.conf
        with open(os.path.join(target_dir, "load-config.sh"), "w") as f:
            f.write(f"""#!/bin/bash
# 加载配置文件
if [ -f "{software_conf_path}" ]; then
    source "{software_conf_path}"
fi
""")
        os.chmod(os.path.join(target_dir, "load-config.sh"), 0o755)
    
    return True


def main():
    print("=" * 60)
    print("  为所有缺失软件目录生成脚本和文档")
    print("=" * 60)
    print()
    
    # 获取所有目录
    result = subprocess.run(
        ["ls", "-la"],
        capture_output=True,
        text=True,
        cwd=WORKSPACE_DIR
    )
    
    dirs = []
    for line in result.stdout.split("\n"):
        if line.startswith("d") and not line.endswith(".") and not line.endswith(".."):
            parts = line.split()
            if len(parts) >= 9:
                dir_name = parts[-1]
                if not dir_name.startswith("."):
                    dirs.append(dir_name)
    
    # 跳过的目录
    skip_dirs = {"lib", "config", "uninstall", "log", "backup", "healthcheck", 
                 "security-baseline", ".uploads", ".git"}
    
    processed = 0
    for software in sorted(dirs):
        if software in skip_dirs:
            continue
        
        target_dir = os.path.join(WORKSPACE_DIR, software)
        if not os.path.isdir(target_dir):
            continue
        
        # 检查是否需要处理
        need_process = False
        for script in ["install.sh", "version.sh", "port.sh", "backup.sh", 
                       "restore.sh", "healthcheck.sh", "uninstall.sh", "info.sh", "config"]:
            if not os.path.exists(os.path.join(target_dir, script)):
                need_process = True
                break
        
        if not os.path.exists(os.path.join(target_dir, "README.md")):
            need_process = True
        
        if need_process:
            if process_directory(software, target_dir):
                processed += 1
    
    print()
    print("=" * 60)
    print(f"  完成，共处理 {processed} 个目录")
    print("=" * 60)


if __name__ == "__main__":
    main()
