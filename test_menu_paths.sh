#!/bin/bash
# 测试脚本路径查找是否正常工作

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

echo "测试脚本路径查找功能..."
echo ""

# 测试几个主要软件
test_software() {
    local software=$1
    echo "测试: $software"
    
    # 首先尝试使用新的标准脚本 install.sh
    local script_path="$SCRIPT_DIR/${software}/install.sh"
    
    if [ -f "$script_path" ]; then
        echo "  ✓ 找到新脚本: $script_path"
    else
        # 如果找不到标准脚本，再尝试旧的格式
        script_path="$SCRIPT_DIR/${software}/${software}.sh"
        if [ -f "$script_path" ]; then
            echo "  ✓ 找到旧脚本: $script_path"
        else
            echo "  ✗ 未找到脚本"
        fi
    fi
}

# 测试一些软件
test_software "nginx"
test_software "mysql"
test_software "python"
test_software "docker"
test_software "hadoop"

echo ""
echo "测试完成！"
