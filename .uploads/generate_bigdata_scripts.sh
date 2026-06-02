#!/bin/bash
# 大数据组件脚本生成器

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR"/.. && pwd)"

# 创建标准化脚本
create_scripts() {
    local software="$1"
    local service="$2"
    local ports="$3"
    local display_name="$4"
    
    local target_dir="$WORKSPACE_DIR/$software"
    
    if [ ! -d "$target_dir" ]; then
        echo "跳过 $software: 目录不存在"
        return
    fi

    echo "正在为 $software 生成脚本..."

    # 1. install.sh
    cat > "$target_dir/install.sh" << INSTALLEOF
#!/bin/bash
# ${display_name} 安装脚本

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="\$SCRIPT_DIR/../lib"
VERSION="\${1:-}"

if [ -f "\$LIB_DIR/common.sh" ]; then
    source "\$LIB_DIR/common.sh"
fi

SERVICE_NAME="${service}"
SOFTWARE_NAME="${software}"
DISPLAY_NAME="${display_name}"

install() {
    echo "安装 ${display_name}..."
    
    # 检查系统
    if [ -f /etc/redhat-release ]; then
        echo "检测到 RHEL/CentOS"
        sudo yum install -y java-1.8.0-openjdk
    elif [ -f /etc/debian_version ]; then
        echo "检测到 Debian/Ubuntu"
        sudo apt update && sudo apt install -y openjdk-8-jre-headless
    fi
    
    # 创建目录
    sudo mkdir -p /opt/${software} /var/log/${software} /var/lib/${software}
    
    # 设置权限
    sudo chown -R $USER:$USER /opt/${software} /var/log/${software} /var/lib/${software}
    
    echo "${display_name} 基础环境准备完成"
    echo "请手动下载并解压 ${display_name} 安装包到 /opt/${software}"
}

if [ "\${BASH_SOURCE[0]}" = "\${0}" ]; then
    install "\$@"
fi
INSTALLEOF

    # 2. version.sh
    cat > "$target_dir/version.sh" << VERSIONEOF
#!/bin/bash
# ${display_name} 版本管理脚本

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="\$SCRIPT_DIR/../lib"

if [ -f "\$LIB_DIR/common.sh" ]; then
    source "\$LIB_DIR/common.sh"
fi

show_current_version() {
    if [ -f "/opt/${software}/VERSION" ]; then
        echo "\${GREEN}当前版本:\${NC} \$(cat /opt/${software}/VERSION)"
    elif [ -d "/opt/${software}" ]; then
        echo "\${YELLOW}版本信息未配置\${NC}"
    else
        echo "\${YELLOW}软件未安装\${NC}"
    fi
}

case "\${1:-show}" in
    show|status)
        show_current_version
        ;;
    *)
        show_current_version
        echo "用法: \$0 {show}"
        ;;
esac
VERSIONEOF

    # 3. port.sh
    cat > "$target_dir/port.sh" << PORTEOF
#!/bin/bash
# ${display_name} 端口管理脚本

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="\$SCRIPT_DIR/../lib"

if [ -f "\$LIB_DIR/common.sh" ]; then
    source "\$LIB_DIR/common.sh"
fi

DEFAULT_PORTS="${ports}"

show_ports() {
    echo -e "\${BLUE}=== ${display_name} 端口配置 ===\${NC}"
    echo "  默认端口: \$DEFAULT_PORTS"
}

case "\${1:-show}" in
    show|list)
        show_ports
        ;;
    *)
        show_ports
        echo "用法: \$0 {show}"
        ;;
esac
PORTEOF

    # 4. backup.sh
    cat > "$target_dir/backup.sh" << BACKUPEOF
#!/bin/bash
# ${display_name} 备份脚本

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="\$SCRIPT_DIR/../lib"

if [ -f "\$LIB_DIR/common.sh" ]; then
    source "\$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="${software}"
DISPLAY_NAME="${display_name}"

BACKUP_ROOT="/var/backups/shell-utils/\${SOFTWARE_NAME}"
TIMESTAMP=\$(date +%Y%m%d_%H%M%S)

do_backup() {
    mkdir -p "\$BACKUP_ROOT"
    
    local backup_dir="\$BACKUP_ROOT/backup_\$TIMESTAMP"
    mkdir -p "\$backup_dir"
    
    # 备份配置
    if [ -d "/opt/${software}/etc" ]; then
        cp -r /opt/${software}/etc "\$backup_dir/"
        echo "\${GREEN}配置备份完成\${NC}"
    fi
    
    # 打包
    tar czf "\$BACKUP_ROOT/backup_\${TIMESTAMP}.tar.gz" -C "\$BACKUP_ROOT" "backup_\$TIMESTAMP"
    rm -rf "\$backup_dir"
    
    echo "\${GREEN}备份完成: \$BACKUP_ROOT/backup_\${TIMESTAMP}.tar.gz\${NC}"
}

list_backups() {
    echo "\${display_name} 的备份列表:"
    ls -lt "\$BACKUP_ROOT"/backup_*.tar.gz 2>/dev/null | head -10 || echo "  暂无备份"
}

case "\${1:-all}" in
    all|config)
        do_backup
        ;;
    list)
        list_backups
        ;;
    *)
        do_backup
        ;;
esac
BACKUPEOF

    # 5. restore.sh
    cat > "$target_dir/restore.sh" << RESTOREEOF
#!/bin/bash
# ${display_name} 恢复脚本

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="\$SCRIPT_DIR/../lib"

if [ -f "\$LIB_DIR/common.sh" ]; then
    source "\$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="${software}"
DISPLAY_NAME="${display_name}"

BACKUP_ROOT="/var/backups/shell-utils/\${SOFTWARE_NAME}"

list_available() {
    ls -1 "\$BACKUP_ROOT"/backup_*.tar.gz 2>/dev/null | head -10 || echo "暂无备份"
}

do_restore() {
    local backup_file="\$1"
    [ -z "\$backup_file" ] && { echo "请指定备份文件"; return 1; }
    
    if [ ! -f "\$backup_file" ]; then
        backup_file="\$BACKUP_ROOT/\$backup_file"
    fi
    
    [ ! -f "\$backup_file" ] && { echo "备份文件不存在"; return 1; }
    
    local temp_dir=\$(mktemp -d)
    tar xzf "\$backup_file" -C "\$temp_dir"
    
    # 恢复配置
    if [ -d "\$temp_dir/backup_*/etc" ]; then
        cp -r "\$temp_dir"/backup_*/etc/* /opt/${software}/etc/
        echo "\${GREEN}配置恢复完成\${NC}"
    fi
    
    rm -rf "\$temp_dir"
}

case "\${1:-list}" in
    list)
        list_available
        ;;
    *)
        do_restore "\$@"
        ;;
esac
RESTOREEOF

    # 6. healthcheck.sh
    cat > "$target_dir/healthcheck.sh" << HCEOF
#!/bin/bash
# ${display_name} 健康检查脚本

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="\$SCRIPT_DIR/../lib"

if [ -f "\$LIB_DIR/common.sh" ]; then
    source "\$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="${software}"
DISPLAY_NAME="${display_name}"

echo -e "\${BLUE}=== ${display_name} 健康检查 ===\${NC}"

# 检查安装
if [ -d "/opt/${software}" ]; then
    echo -e "\${GREEN}✓ 安装目录存在\${NC}"
else
    echo -e "\${RED}✗ 安装目录不存在\${NC}"
fi

# 检查日志目录
if [ -d "/var/log/${software}" ]; then
    echo -e "\${GREEN}✓ 日志目录存在\${NC}"
else
    echo -e "\${YELLOW}⚠ 日志目录不存在\${NC}"
fi

echo -e "\${GREEN}健康检查完成\${NC}"
HCEOF

    # 7. uninstall.sh
    cat > "$target_dir/uninstall.sh" << UNINSTALLEOF
#!/bin/bash
# ${display_name} 卸载脚本

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="\$SCRIPT_DIR/../lib"

if [ -f "\$LIB_DIR/common.sh" ]; then
    source "\$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="${software}"
DISPLAY_NAME="${display_name}"

echo "正在卸载 ${display_name}..."

echo "\${YELLOW}警告: 将删除 /opt/${software} 和相关目录\${NC}"
read -p "确认卸载? [y/N] " confirm
[ "\$confirm" != "y" ] && { echo "取消卸载"; exit 0; }

# 停止服务
sudo systemctl stop ${software} 2>/dev/null || true

# 删除目录
sudo rm -rf /opt/${software} /var/log/${software} /var/lib/${software}

echo "\${GREEN}${display_name} 卸载完成\${NC}"
UNINSTALLEOF

    # 8. info.sh
    cat > "$target_dir/info.sh" << INFOEOF
#!/bin/bash
# ${display_name} 信息查看脚本

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="\$SCRIPT_DIR/../lib"

if [ -f "\$LIB_DIR/common.sh" ]; then
    source "\$LIB_DIR/common.sh"
fi

SOFTWARE_NAME="${software}"
DISPLAY_NAME="${display_name}"

echo -e "\${BLUE}=== ${display_name} 信息 ===\${NC}"
echo "  软件名称: \$DISPLAY_NAME"
echo "  安装目录: /opt/${software}"
echo "  日志目录: /var/log/${software}"
echo "  数据目录: /var/lib/${software}"
echo ""

# 检查状态
if [ -d "/opt/${software}" ]; then
    echo -e "\${GREEN}状态: 已安装\${NC}"
else
    echo -e "\${RED}状态: 未安装\${NC}"
fi
INFOEOF

    # 9. config
    cat > "$target_dir/config" << CONFIGEOF
# ${display_name} 配置文件
SOFTWARE_NAME="${software}"
SERVICE_NAME="${service}"
DISPLAY_NAME="${display_name}"
DEFAULT_PORTS="${ports}"
CONFIGEOF

    # 设置权限
    chmod +x "$target_dir/install.sh" "$target_dir/version.sh" "$target_dir/port.sh" \
              "$target_dir/backup.sh" "$target_dir/restore.sh" "$target_dir/healthcheck.sh" \
              "$target_dir/uninstall.sh" "$target_dir/info.sh" 2>/dev/null

    echo "  ✓ $software 脚本生成完成"
}

# 主函数
main() {
    echo "========================================"
    echo "  为大数据组件生成标准化脚本"
    echo "========================================"
    echo ""

    # 为现有组件生成脚本
    create_scripts "hadoop" "hadoop" "8088,9000,50070" "Hadoop"
    create_scripts "spark" "spark" "7077,8080" "Spark"
    create_scripts "hive" "hive" "10000,10002" "Hive"
    create_scripts "hbase" "hbase" "16000,16010,16020" "HBase"
    create_scripts "flink" "flink" "8081,6123" "Flink"

    echo ""
    echo "========================================"
    echo "  脚本生成完成"
    echo "========================================"
}

main "$@"
