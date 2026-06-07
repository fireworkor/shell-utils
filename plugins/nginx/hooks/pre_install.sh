#!/bin/bash
# Nginx 插件 - 安装前钩子
# 在 Nginx 安装前执行

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[PRE-INSTALL HOOK] Nginx 安装前检查..."
echo "[PRE-INSTALL HOOK] 插件路径: $SCRIPT_DIR"

# 检查端口 80 是否被占用
if netstat -tuln 2>/dev/null | grep -q ":80 " || ss -tuln 2>/dev/null | grep -q ":80 "; then
    echo "[PRE-INSTALL HOOK] 警告: 端口 80 已被占用"
fi

# 检查是否已安装
if command -v nginx &>/dev/null; then
    echo "[PRE-INSTALL HOOK] 警告: Nginx 已安装"
fi

echo "[PRE-INSTALL HOOK] 前置检查完成"
