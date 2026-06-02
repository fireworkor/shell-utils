#!/bin/bash
# FTP 安装脚本
# FTP 文件传输服务

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

SERVICE_NAME="vsftpd"
SOFTWARE_NAME="ftp"
DISPLAY_NAME="FTP"

install() {
    echo "正在安装 FTP..."
    echo "FTP 文件传输服务"
    
    # 根据类别安装
    case "service" in
        language)
            echo "编程语言环境安装"
            echo "请参考官方文档进行安装"
            ;;
        middleware)
            echo "中间件安装"
            echo "请下载并安装 FTP"
            ;;
        tool)
            echo "工具安装"
            echo "请根据 README.md 进行安装"
            ;;
        service)
            if command -v apt &>/dev/null; then
                sudo apt update
                sudo apt install -y vsftpd
            elif command -v yum &>/dev/null; then
                sudo yum install -y vsftpd
            fi
            ;;
        *)
            echo "请手动安装 FTP"
            echo "参考 README.md 中的说明"
            ;;
    esac
    
    echo "FTP 安装完成"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install "$@"
fi
