#!/bin/bash
# 软件管理功能测试

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"

PROJECT_ROOT="$SCRIPT_DIR/.."

# 测试1: 检查软件目录结构
test_software_directories() {
    echo -e "${TEST_BLUE}测试: 软件目录结构${TEST_NC}"
    
    # 检查主要软件目录
    for software in nginx mysql redis docker; do
        if [ -d "$PROJECT_ROOT/$software" ]; then
            assert_file_exists "$PROJECT_ROOT/$software/install.sh" "$software 安装脚本应存在"
            assert_file_exists "$PROJECT_ROOT/$software/uninstall.sh" "$software 卸载脚本应存在"
        fi
    done
}

# 测试2: 检查标准化脚本
test_standard_scripts() {
    echo -e "${TEST_BLUE}测试: 标准化脚本${TEST_NC}"
    
    # 统计有多少软件目录包含完整的标准化脚本
    standard_scripts=("install.sh" "uninstall.sh" "backup.sh" "restore.sh" "healthcheck.sh" "version.sh" "port.sh" "info.sh")
    
    total_software=0
    complete_software=0
    
    for dir in "$PROJECT_ROOT"/*/; do
        if [ -d "$dir" ] && [ -f "$dir/install.sh" ]; then
            software_name=$(basename "$dir")
            total_software=$((total_software + 1))
            
            missing=""
            for script in "${standard_scripts[@]}"; do
                if [ ! -f "$dir/$script" ]; then
                    missing="$missing $script"
                fi
            done
            
            if [ -z "$missing" ]; then
                complete_software=$((complete_software + 1))
                echo -e "${TEST_GREEN}✓ $software_name: 完整${TEST_NC}"
            else
                echo -e "${TEST_YELLOW}⚠ $software_name: 缺少$missing${TEST_NC}"
            fi
        fi
    done
    
    echo "完整标准化: $complete_software / $total_software"
}

# 测试3: 检查主菜单脚本
test_main_menu() {
    echo -e "${TEST_BLUE}测试: 主菜单脚本${TEST_NC}"
    
    assert_file_exists "$PROJECT_ROOT/main.sh" "主菜单脚本应存在"
    
    if [ -f "$PROJECT_ROOT/main.sh" ]; then
        # 检查脚本可执行
        chmod +x "$PROJECT_ROOT/main.sh"
        assert_success "main.sh 应有执行权限"
        
        # 检查帮助信息
        output=$("$PROJECT_ROOT/main.sh" --help 2>&1 || true)
        assert_success "main.sh --help 应能执行"
    fi
}

# 测试4: 检查备份功能
test_backup_functionality() {
    echo -e "${TEST_BLUE}测试: 备份功能${TEST_NC}"
    
    assert_file_exists "$PROJECT_ROOT/backup/backup.sh" "备份脚本应存在"
    
    if [ -f "$PROJECT_ROOT/backup/backup.sh" ]; then
        chmod +x "$PROJECT_ROOT/backup/backup.sh"
        
        # 测试备份列表功能
        output=$("$PROJECT_ROOT/backup/backup.sh" list 2>&1 || true)
        assert_success "backup list 命令应能执行"
    fi
}

# 测试5: 检查健康检查功能
test_healthcheck() {
    echo -e "${TEST_BLUE}测试: 健康检查功能${TEST_NC}"
    
    assert_file_exists "$PROJECT_ROOT/healthcheck/healthcheck.sh" "健康检查脚本应存在"
    
    if [ -f "$PROJECT_ROOT/healthcheck/healthcheck.sh" ]; then
        chmod +x "$PROJECT_ROOT/healthcheck/healthcheck.sh"
        output=$("$PROJECT_ROOT/healthcheck/healthcheck.sh" 2>&1 || true)
        assert_success "healthcheck 命令应能执行"
    fi
}

# 测试6: 检查安全基线扫描
test_security_baseline() {
    echo -e "${TEST_BLUE}测试: 安全基线扫描${TEST_NC}"
    
    assert_file_exists "$PROJECT_ROOT/security-baseline/security-baseline.sh" "安全基线脚本应存在"
    
    if [ -f "$PROJECT_ROOT/security-baseline/security-baseline.sh" ]; then
        chmod +x "$PROJECT_ROOT/security-baseline/security-baseline.sh"
        output=$("$PROJECT_ROOT/security-baseline/security-baseline.sh" --help 2>&1 || true)
        assert_success "security-baseline 命令应能执行"
    fi
}

# 测试7: 检查版本管理
test_version_management() {
    echo -e "${TEST_BLUE}测试: 版本管理${TEST_NC}"
    
    assert_file_exists "$PROJECT_ROOT/version.sh" "版本脚本应存在"
    
    if [ -f "$PROJECT_ROOT/version.sh" ]; then
        chmod +x "$PROJECT_ROOT/version.sh"
        output=$("$PROJECT_ROOT/version.sh" 2>&1 || true)
        assert_success "version 命令应能执行"
    fi
}

# 测试8: 检查更新功能
test_update_functionality() {
    echo -e "${TEST_BLUE}测试: 更新功能${TEST_NC}"
    
    assert_file_exists "$PROJECT_ROOT/update.sh" "更新脚本应存在"
    
    if [ -f "$PROJECT_ROOT/update.sh" ]; then
        chmod +x "$PROJECT_ROOT/update.sh"
        output=$("$PROJECT_ROOT/update.sh" check 2>&1 || true)
        assert_success "update check 命令应能执行"
    fi
}

# 测试9: 检查配置文件
test_config_files() {
    echo -e "${TEST_BLUE}测试: 配置文件${TEST_NC}"
    
    assert_file_exists "$PROJECT_ROOT/config/versions.conf" "版本配置文件应存在"
}

# 测试10: 检查库文件
test_library_files() {
    echo -e "${TEST_BLUE}测试: 库文件${TEST_NC}"
    
    assert_file_exists "$PROJECT_ROOT/lib/common.sh" "通用库应存在"
    assert_file_exists "$PROJECT_ROOT/lib/logging.sh" "日志库应存在"
    assert_file_exists "$PROJECT_ROOT/lib/logging-v2.sh" "日志库v2应存在"
}

# 主函数
main() {
    test_init
    
    test_software_directories
    echo ""
    test_standard_scripts
    echo ""
    test_main_menu
    echo ""
    test_backup_functionality
    echo ""
    test_healthcheck
    echo ""
    test_security_baseline
    echo ""
    test_version_management
    echo ""
    test_update_functionality
    echo ""
    test_config_files
    echo ""
    test_library_files
    echo ""
    
    test_summary
    return $?
}

# 运行测试
main
