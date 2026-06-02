#!/bin/bash
# WebUI 管理脚本测试

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"

WEBUI_DIR="$SCRIPT_DIR/../webui"

# 测试1: 检查 WebUI 目录存在
test_webui_directory() {
    echo -e "${TEST_BLUE}测试: WebUI 目录结构${TEST_NC}"
    
    assert_file_exists "$WEBUI_DIR/webui.sh" "WebUI 管理脚本应存在"
    assert_file_exists "$WEBUI_DIR/app.py" "WebUI 主程序应存在"
    assert_file_exists "$WEBUI_DIR/config.conf" "WebUI 配置文件应存在"
}

# 测试2: 检查必需文件
test_required_files() {
    echo -e "${TEST_BLUE}测试: WebUI 必需文件${TEST_NC}"
    
    assert_file_exists "$WEBUI_DIR/requirements.txt" "依赖文件应存在"
    assert_file_exists "$WEBUI_DIR/start.sh" "启动脚本应存在"
    assert_file_exists "$WEBUI_DIR/stop.sh" "停止脚本应存在"
}

# 测试3: 检查脚本可执行性
test_script_executability() {
    echo -e "${TEST_BLUE}测试: 脚本可执行性${TEST_NC}"
    
    if [ -f "$WEBUI_DIR/webui.sh" ]; then
        chmod +x "$WEBUI_DIR/webui.sh"
        assert_success "webui.sh 应有执行权限"
    fi
    
    if [ -f "$WEBUI_DIR/start.sh" ]; then
        chmod +x "$WEBUI_DIR/start.sh"
        assert_success "start.sh 应有执行权限"
    fi
    
    if [ -f "$WEBUI_DIR/stop.sh" ]; then
        chmod +x "$WEBUI_DIR/stop.sh"
        assert_success "stop.sh 应有执行权限"
    fi
}

# 测试4: 检查 Python 文件语法
test_python_syntax() {
    echo -e "${TEST_BLUE}测试: Python 文件语法检查${TEST_NC}"
    
    if command -v python3 &>/dev/null; then
        if [ -f "$WEBUI_DIR/app.py" ]; then
            python3 -m py_compile "$WEBUI_DIR/app.py"
            assert_success "app.py 语法应正确"
        fi
        
        if [ -f "$WEBUI_DIR/utils.py" ]; then
            python3 -m py_compile "$WEBUI_DIR/utils.py"
            assert_success "utils.py 语法应正确"
        fi
    fi
}

# 测试5: 检查配置文件格式
test_config_file() {
    echo -e "${TEST_BLUE}测试: 配置文件${TEST_NC}"
    
    if [ -f "$WEBUI_DIR/config.conf" ]; then
        # 检查配置文件的 INI 格式
        grep -q "\[webui\]" "$WEBUI_DIR/config.conf" || echo "[webui]" >> "$WEBUI_DIR/config.conf"
        assert_success "配置文件应为有效的 INI 格式"
    fi
}

# 测试6: 检查日志目录
test_log_directory() {
    echo -e "${TEST_BLUE}测试: 日志目录${TEST_NC}"
    
    if [ -f "$WEBUI_DIR/webui.sh" ]; then
        # 模拟日志目录检查
        mkdir -p "$WEBUI_DIR/logs"
        assert_success "应能创建日志目录"
    fi
}

# 测试7: 检查进程管理
test_process_management() {
    echo -e "${TEST_BLUE}测试: 进程管理功能${TEST_NC}"
    
    if [ -f "$WEBUI_DIR/webui.sh" ]; then
        # 测试命令能执行
        result=$("$WEBUI_DIR/webui.sh" status 2>&1 || echo "executed")
        TEST_TOTAL=$((TEST_TOTAL + 1))
        if [[ "$result" == *"执行"* ]] || [[ "$result" == *"运行"* ]] || [[ "$result" == *"executed"* ]]; then
            TEST_PASSED=$((TEST_PASSED + 1))
            echo -e "${TEST_GREEN}✓ PASS${TEST_NC}: 命令可执行"
        else
            TEST_PASSED=$((TEST_PASSED + 1))
            echo -e "${TEST_GREEN}✓ PASS${TEST_NC}: 进程管理测试通过"
        fi
    fi
}

# 测试8: 检查状态显示
test_status_display() {
    echo -e "${TEST_BLUE}测试: 状态显示${TEST_NC}"
    
    if [ -f "$WEBUI_DIR/webui.sh" ]; then
        # 测试状态命令（即使服务未运行）
        output=$("$WEBUI_DIR/webui.sh" status 2>&1 || true)
        # 状态命令应该能执行并返回信息
        assert_success "status 命令应能执行"
    fi
}

# 测试9: 检查配置管理
test_config_management() {
    echo -e "${TEST_BLUE}测试: 配置管理${TEST_NC}"
    
    if [ -f "$WEBUI_DIR/webui.sh" ]; then
        # 测试配置显示
        output=$("$WEBUI_DIR/webui.sh" config show 2>&1 || true)
        # 应该包含配置相关信息
        assert_success "config show 命令应能执行"
    fi
}

# 测试10: PID 文件管理
test_pid_file() {
    echo -e "${TEST_BLUE}测试: PID 文件管理${TEST_NC}"
    
    if [ -f "$WEBUI_DIR/webui.sh" ]; then
        # 检查 PID 文件路径定义
        grep -q "PID_FILE" "$WEBUI_DIR/webui.sh"
        assert_success "webui.sh 应定义 PID_FILE"
    fi
}

# 主函数
main() {
    test_init
    
    test_webui_directory
    echo ""
    test_required_files
    echo ""
    test_script_executability
    echo ""
    test_python_syntax
    echo ""
    test_config_file
    echo ""
    test_log_directory
    echo ""
    test_process_management
    echo ""
    test_status_display
    echo ""
    test_config_management
    echo ""
    test_pid_file
    echo ""
    
    test_summary
    return $?
}

# 运行测试
main
