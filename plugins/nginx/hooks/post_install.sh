#!/bin/bash
# Nginx 插件 - 安装后钩子
# 在 Nginx 安装后执行

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[POST-INSTALL HOOK] Nginx 安装后配置..."

# 获取 Nginx 版本
if command -v nginx &>/dev/null; then
    nginx_version=$(nginx -v 2>&1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    echo "[POST-INSTALL HOOK] Nginx 版本: $nginx_version"
fi

# 检查服务状态
if systemctl is-active nginx &>/dev/null; then
    echo "[POST-INSTALL HOOK] Nginx 服务运行正常"
else
    echo "[POST-INSTALL HOOK] 警告: Nginx 服务未运行"
fi

echo "[POST-INSTALL HOOK] 后置配置完成"
