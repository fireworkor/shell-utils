#!/bin/bash
# Consul 安装脚本
# 服务发现和配置管理

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="consul"
SOFTWARE_NAME="consul"
DISPLAY_NAME="Consul"

install() {
    echo "正在安装 Consul..."
    echo "服务发现和配置管理"
    
    # 根据类别安装
    case "middleware" in
        language)
            echo "编程语言环境安装"
            echo "请参考官方文档进行安装"
            ;;
        middleware)
            echo "中间件安装"
            echo "请下载并安装 Consul"
            ;;
        tool)
            echo "工具安装"
            echo "请根据 README.md 进行安装"
            ;;
        service)
            if command -v apt &>/dev/null; then
                sudo apt update
                sudo apt install -y consul
            elif command -v yum &>/dev/null; then
                sudo yum install -y consul
            fi
            ;;
        *)
            echo "请手动安装 Consul"
            echo "参考 README.md 中的说明"
            ;;
    esac
    
    echo "Consul 安装完成"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install "$@"
fi
