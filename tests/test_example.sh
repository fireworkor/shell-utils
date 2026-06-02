#!/bin/bash
# 示例测试文件

# 加载测试辅助库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"

# 测试函数 1
test_addition() {
    echo -e "${TEST_BLUE}测试: 加法运算${TEST_NC}"
    
    # 测试 1+1=2
    result=$((1 + 1))
    assert_eq "$result" "2" "1+1 应该等于 2"
    
    # 测试 5+3=8
    result=$((5 + 3))
    assert_eq "$result" "8" "5+3 应该等于 8"
}

# 测试函数 2
test_string_operations() {
    echo -e "${TEST_BLUE}测试: 字符串操作${TEST_NC}"
    
    # 测试字符串包含
    text="Hello, World!"
    assert_contains "$text" "Hello" "字符串应该包含 'Hello'"
    assert_contains "$text" "World" "字符串应该包含 'World'"
}

# 测试函数 3
test_file_operations() {
    echo -e "${TEST_BLUE}测试: 文件操作${TEST_NC}"
    
    # 测试脚本文件存在
    assert_file_exists "$SCRIPT_DIR/test_helper.sh" "测试辅助文件应该存在"
    assert_file_exists "$0" "当前测试文件应该存在"
}

# 主函数
main() {
    test_init
    
    # 运行各个测试函数
    test_addition
    echo ""
    test_string_operations
    echo ""
    test_file_operations
    echo ""
    
    # 打印测试摘要
    test_summary
    return $?
}

# 运行测试
main
