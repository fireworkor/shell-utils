#!/bin/bash
# Linkerd 安装脚本
# 服务网格

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="linkerd"
SOFTWARE_NAME="linkerd"
DISPLAY_NAME="Linkerd"

install() {
    echo "正在安装 Linkerd..."
    echo "服务网格"
    
    # 根据类别安装
    case "middleware" in
        language)
            echo "编程语言环境安装"
            echo "请参考官方文档进行安装"
            ;;
        middleware)
            echo "中间件安装"
            echo "请下载并安装 Linkerd"
            ;;
        tool)
            echo "工具安装"
            echo "请根据 README.md 进行安装"
            ;;
        service)
            if command -v apt &>/dev/null; then
                sudo apt update
                sudo apt install -y linkerd
            elif command -v yum &>/dev/null; then
                sudo yum install -y linkerd
            fi
            ;;
        *)
            echo "请手动安装 Linkerd"
            echo "参考 README.md 中的说明"
            ;;
    esac
    
    echo "Linkerd 安装完成"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install "$@"
fi
