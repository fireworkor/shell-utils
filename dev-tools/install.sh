#!/bin/bash
# Dev Tools 安装脚本
# 开发工具集

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="dev-tools"
SOFTWARE_NAME="dev-tools"
DISPLAY_NAME="Dev Tools"

install() {
    echo "正在安装 Dev Tools..."
    echo "开发工具集"
    
    # 根据类别安装
    case "tool" in
        language)
            echo "编程语言环境安装"
            echo "请参考官方文档进行安装"
            ;;
        middleware)
            echo "中间件安装"
            echo "请下载并安装 Dev Tools"
            ;;
        tool)
            echo "工具安装"
            echo "请根据 README.md 进行安装"
            ;;
        service)
            if command -v apt &>/dev/null; then
                sudo apt update
                sudo apt install -y dev-tools
            elif command -v yum &>/dev/null; then
                sudo yum install -y dev-tools
            fi
            ;;
        *)
            echo "请手动安装 Dev Tools"
            echo "参考 README.md 中的说明"
            ;;
    esac
    
    echo "Dev Tools 安装完成"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install "$@"
fi
