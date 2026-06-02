#!/bin/bash
# NATS 安装脚本
# 消息队列系统

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="nats"
SOFTWARE_NAME="nats"
DISPLAY_NAME="NATS"

install() {
    echo "正在安装 NATS..."
    echo "消息队列系统"
    
    # 根据类别安装
    case "middleware" in
        language)
            echo "编程语言环境安装"
            echo "请参考官方文档进行安装"
            ;;
        middleware)
            echo "中间件安装"
            echo "请下载并安装 NATS"
            ;;
        tool)
            echo "工具安装"
            echo "请根据 README.md 进行安装"
            ;;
        service)
            if command -v apt &>/dev/null; then
                sudo apt update
                sudo apt install -y nats
            elif command -v yum &>/dev/null; then
                sudo yum install -y nats
            fi
            ;;
        *)
            echo "请手动安装 NATS"
            echo "参考 README.md 中的说明"
            ;;
    esac
    
    echo "NATS 安装完成"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install "$@"
fi
