#!/bin/bash
# Docker Compose Templates 安装脚本
# Docker Compose 模板集

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="docker-compose"
SOFTWARE_NAME="docker-compose-templates"
DISPLAY_NAME="Docker Compose Templates"

install() {
    echo "正在安装 Docker Compose Templates..."
    echo "Docker Compose 模板集"
    
    # 根据类别安装
    case "template" in
        language)
            echo "编程语言环境安装"
            echo "请参考官方文档进行安装"
            ;;
        middleware)
            echo "中间件安装"
            echo "请下载并安装 Docker Compose Templates"
            ;;
        tool)
            echo "工具安装"
            echo "请根据 README.md 进行安装"
            ;;
        service)
            if command -v apt &>/dev/null; then
                sudo apt update
                sudo apt install -y docker-compose
            elif command -v yum &>/dev/null; then
                sudo yum install -y docker-compose
            fi
            ;;
        *)
            echo "请手动安装 Docker Compose Templates"
            echo "参考 README.md 中的说明"
            ;;
    esac
    
    echo "Docker Compose Templates 安装完成"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install "$@"
fi
