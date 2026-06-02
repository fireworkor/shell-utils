#!/bin/bash
# 修复大数据组件安装脚本
# 让它们正确调用原始安装脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR"/.. && pwd)"

# 需要修复的大数据组件
BIGDATA_COMPONENTS="hadoop spark hive hbase flink"

fix_install_script() {
    local software="$1"
    local display_name="$2"
    local target_dir="$WORKSPACE_DIR/$software"
    
    if [ ! -d "$target_dir" ]; then
        echo "跳过 $software: 目录不存在"
        return
    fi

    echo "修复 $software/install.sh..."

    cat > "$target_dir/install.sh" << INSTALLEOF
#!/bin/bash
# ${display_name} 安装脚本
# 自动生成的标准化安装脚本

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="\$SCRIPT_DIR/../lib"
VERSION="\${1:-}"

# 加载通用函数
if [ -f "\$LIB_DIR/common.sh" ]; then
    source "\$LIB_DIR/common.sh"
fi

# 加载软件配置
if [ -f "\$SCRIPT_DIR/config" ]; then
    source "\$SCRIPT_DIR/config"
fi

SERVICE_NAME="${software}"
SOFTWARE_NAME="${software}"
DISPLAY_NAME="${display_name}"

# 调用原始安装脚本
install() {
    if [ -f "\$SCRIPT_DIR/\${SOFTWARE_NAME}.sh.original" ]; then
        bash "\$SCRIPT_DIR/\${SOFTWARE_NAME}.sh.original" "\$VERSION"
    elif [ -f "\$SCRIPT_DIR/\${SOFTWARE_NAME}.sh" ]; then
        bash "\$SCRIPT_DIR/\${SOFTWARE_NAME}.sh" "\$VERSION"
    else
        log_error "未找到 ${software} 的原始安装脚本"
        return 1
    fi
}

if [ "\${BASH_SOURCE[0]}" = "\${0}" ]; then
    install "\$@"
fi
INSTALLEOF

    chmod +x "$target_dir/install.sh"
    echo "  ✓ $software 修复完成"
}

# 主函数
main() {
    echo "========================================"
    echo "  修复大数据组件安装脚本"
    echo "========================================"
    echo ""

    fix_install_script "hadoop" "Hadoop"
    fix_install_script "spark" "Spark"
    fix_install_script "hive" "Hive"
    fix_install_script "hbase" "HBase"
    fix_install_script "flink" "Flink"

    echo ""
    echo "========================================"
    echo "  修复完成"
    echo "========================================"
    echo ""
    echo "现在所有大数据组件的 install.sh 都会正确调用原始安装脚本"
}

main "$@"
