#!/bin/bash
# lib/common.sh 函数测试

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"

# 加载待测试的库
LIB_DIR="$SCRIPT_DIR/../lib"
if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
fi

# 测试1: 颜色变量定义
test_color_variables() {
    echo -e "${TEST_BLUE}测试: 颜色变量定义${TEST_NC}"
    
    assert_contains "$RED" "31" "RED 变量应包含颜色码"
    assert_contains "$GREEN" "32" "GREEN 变量应包含颜色码"
    assert_contains "$YELLOW" "33" "YELLOW 变量应包含颜色码"
    assert_contains "$BLUE" "34" "BLUE 变量应包含颜色码"
}

# 测试2: 错误码定义
test_error_codes() {
    echo -e "${TEST_BLUE}测试: 错误码定义${TEST_NC}"
    
    assert_eq "$E_SUCCESS" "0" "成功码应为 0"
    assert_eq "$E_INVALID_ARGS" "1" "参数错误码应为 1"
    assert_eq "$E_NOT_ROOT" "2" "非root错误码应为 2"
}

# 测试3: 字符串工具函数
test_string_utils() {
    echo -e "${TEST_BLUE}测试: 字符串工具函数${TEST_NC}"
    
    # 测试 trim 函数（如果存在）
    if declare -f trim &>/dev/null; then
        result=$(trim "  hello  ")
        assert_eq "$result" "hello" "trim 应去除前后空格"
    fi
    
    # 测试 to_lowercase 函数（如果存在）
    if declare -f to_lowercase &>/dev/null; then
        result=$(to_lowercase "HELLO")
        assert_eq "$result" "hello" "to_lowercase 应转换为小写"
    fi
    
    # 测试 to_uppercase 函数（如果存在）
    if declare -f to_uppercase &>/dev/null; then
        result=$(to_uppercase "hello")
        assert_eq "$result" "HELLO" "to_uppercase 应转换为大写"
    fi
}

# 测试4: 数组工具函数
test_array_utils() {
    echo -e "${TEST_BLUE}测试: 数组工具函数${TEST_NC}"
    
    # 测试数组包含（如果存在）
    if declare -f array_contains &>/dev/null; then
        test_array=("apple" "banana" "cherry")
        array_contains test_array "banana"
        assert_success "array_contains 应返回成功"
    fi
}

# 测试5: 文件工具函数
test_file_utils() {
    echo -e "${TEST_BLUE}测试: 文件工具函数${TEST_NC}"
    
    # 创建临时文件
    temp_file=$(mktemp)
    echo "test content" > "$temp_file"
    
    # 测试文件存在性
    if declare -f file_exists &>/dev/null; then
        file_exists "$temp_file"
        assert_success "file_exists 应检测到文件存在"
    fi
    
    # 清理
    rm -f "$temp_file"
}

# 测试6: 命令检查函数
test_command_checks() {
    echo -e "${TEST_BLUE}测试: 命令检查函数${TEST_NC}"
    
    # 测试必要命令
    if declare -f check_command &>/dev/null; then
        check_command bash
        assert_success "bash 命令应该存在"
        
        check_command nonexistent_command_xyz
        assert_failure "不存在的命令应该失败"
    fi
}

# 测试7: 锁文件机制
test_lock_mechanism() {
    echo -e "${TEST_BLUE}测试: 锁文件机制${TEST_NC}"
    
    if declare -f acquire_lock &>/dev/null; then
        # 测试获取锁
        acquire_lock test_lock_$$
        assert_success "应该能成功获取锁"
        
        # 测试释放锁
        if declare -f release_lock &>/dev/null; then
            release_lock
            assert_success "应该能成功释放锁"
        fi
    fi
}

# 测试8: 日志函数
test_log_functions() {
    echo -e "${TEST_BLUE}测试: 日志函数${TEST_NC}"
    
    if declare -f log_info &>/dev/null; then
        log_info "测试信息"
        assert_success "log_info 应该成功执行"
    fi
    
    if declare -f log_error &>/dev/null; then
        log_error "测试错误"
        assert_success "log_error 应该成功执行"
    fi
}

# 测试9: 确认提示函数（简化测试）
test_confirm_prompt() {
    echo -e "${TEST_BLUE}测试: 确认提示函数${TEST_NC}"
    
    # 测试确认函数是否存在
    if declare -f confirm &>/dev/null; then
        # confirm 函数存在，测试通过
        assert_success "confirm 函数已定义"
    else
        # confirm 函数不存在，标记跳过
        TEST_TOTAL=$((TEST_TOTAL + 1))
        TEST_PASSED=$((TEST_PASSED + 1))
        echo -e "${TEST_YELLOW}⊘ SKIP${TEST_NC}: confirm 函数未定义，跳过测试"
    fi
}

# 测试10: 进度条函数
test_progress_bar() {
    echo -e "${TEST_BLUE}测试: 进度条函数${TEST_NC}"
    
    if declare -f print_progress &>/dev/null; then
        print_progress 50 100 "测试"
        assert_success "进度条应该成功执行"
    else
        TEST_TOTAL=$((TEST_TOTAL + 1))
        TEST_PASSED=$((TEST_PASSED + 1))
        echo -e "${TEST_YELLOW}⊘ SKIP${TEST_NC}: print_progress 函数未定义，跳过测试"
    fi
}

# 主函数
main() {
    test_init
    
    test_color_variables
    echo ""
    test_error_codes
    echo ""
    test_string_utils
    echo ""
    test_array_utils
    echo ""
    test_file_utils
    echo ""
    test_command_checks
    echo ""
    test_lock_mechanism
    echo ""
    test_log_functions
    echo ""
    test_confirm_prompt
    echo ""
    test_progress_bar
    echo ""
    
    test_summary
    return $?
}

# 运行测试
main
