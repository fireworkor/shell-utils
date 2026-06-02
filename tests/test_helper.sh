#!/bin/bash
# Shell 脚本测试框架 - 测试辅助工具

# 颜色输出
TEST_RED='\033[0;31m'
TEST_GREEN='\033[0;32m'
TEST_YELLOW='\033[1;33m'
TEST_BLUE='\033[0;34m'
TEST_CYAN='\033[0;36m'
TEST_NC='\033[0m'

# 测试统计
TEST_PASSED=0
TEST_FAILED=0
TEST_TOTAL=0
TEST_ERRORS=()

# 初始化测试
test_init() {
    TEST_PASSED=0
    TEST_FAILED=0
    TEST_TOTAL=0
    TEST_ERRORS=()
    echo -e "${TEST_CYAN}========================================${TEST_NC}"
    echo -e "${TEST_CYAN}  开始测试${TEST_NC}"
    echo -e "${TEST_CYAN}========================================${TEST_NC}"
    echo ""
}

# 断言相等
assert_eq() {
    local actual="$1"
    local expected="$2"
    local message="${3:-}"
    
    TEST_TOTAL=$((TEST_TOTAL + 1))
    
    if [ "$actual" == "$expected" ]; then
        TEST_PASSED=$((TEST_PASSED + 1))
        echo -e "${TEST_GREEN}✓ PASS${TEST_NC}: ${message:-值相等} (期望: \"$expected\", 实际: \"$actual\")"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
        local error_msg="${message:-值不相等} (期望: \"$expected\", 实际: \"$actual\")"
        TEST_ERRORS+=("$error_msg")
        echo -e "${TEST_RED}✗ FAIL${TEST_NC}: $error_msg"
        return 1
    fi
}

# 断言成功（退出码 0）
assert_success() {
    local exit_code=$?
    local message="${1:-}"
    
    TEST_TOTAL=$((TEST_TOTAL + 1))
    
    if [ $exit_code -eq 0 ]; then
        TEST_PASSED=$((TEST_PASSED + 1))
        echo -e "${TEST_GREEN}✓ PASS${TEST_NC}: ${message:-命令成功执行}"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
        local error_msg="${message:-命令执行失败} (退出码: $exit_code)"
        TEST_ERRORS+=("$error_msg")
        echo -e "${TEST_RED}✗ FAIL${TEST_NC}: $error_msg"
        return 1
    fi
}

# 断言失败（退出码非 0）
assert_failure() {
    local exit_code=$?
    local message="${1:-}"
    
    TEST_TOTAL=$((TEST_TOTAL + 1))
    
    if [ $exit_code -ne 0 ]; then
        TEST_PASSED=$((TEST_PASSED + 1))
        echo -e "${TEST_GREEN}✓ PASS${TEST_NC}: ${message:-命令执行失败（预期）}"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
        local error_msg="${message:-命令成功执行（非预期）}"
        TEST_ERRORS+=("$error_msg")
        echo -e "${TEST_RED}✗ FAIL${TEST_NC}: $error_msg"
        return 1
    fi
}

# 断言文件存在
assert_file_exists() {
    local file="$1"
    local message="${2:-}"
    
    TEST_TOTAL=$((TEST_TOTAL + 1))
    
    if [ -f "$file" ]; then
        TEST_PASSED=$((TEST_PASSED + 1))
        echo -e "${TEST_GREEN}✓ PASS${TEST_NC}: ${message:-文件存在} ($file)"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
        local error_msg="${message:-文件不存在} ($file)"
        TEST_ERRORS+=("$error_msg")
        echo -e "${TEST_RED}✗ FAIL${TEST_NC}: $error_msg"
        return 1
    fi
}

# 断言字符串包含
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"
    
    TEST_TOTAL=$((TEST_TOTAL + 1))
    
    if [[ "$haystack" == *"$needle"* ]]; then
        TEST_PASSED=$((TEST_PASSED + 1))
        echo -e "${TEST_GREEN}✓ PASS${TEST_NC}: ${message:-字符串包含预期内容}"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
        local error_msg="${message:-字符串不包含预期内容} (期望: \"$needle\")"
        TEST_ERRORS+=("$error_msg")
        echo -e "${TEST_RED}✗ FAIL${TEST_NC}: $error_msg"
        return 1
    fi
}

# 打印测试摘要
test_summary() {
    echo ""
    echo -e "${TEST_CYAN}========================================${TEST_NC}"
    echo -e "${TEST_CYAN}  测试摘要${TEST_NC}"
    echo -e "${TEST_CYAN}========================================${TEST_NC}"
    echo "总计: $TEST_TOTAL"
    echo -e "${TEST_GREEN}通过: $TEST_PASSED${TEST_NC}"
    if [ $TEST_FAILED -gt 0 ]; then
        echo -e "${TEST_RED}失败: $TEST_FAILED${TEST_NC}"
    else
        echo -e "${TEST_GREEN}失败: $TEST_FAILED${TEST_NC}"
    fi
    echo ""
    
    if [ ${#TEST_ERRORS[@]} -gt 0 ]; then
        echo -e "${TEST_YELLOW}错误详情:${TEST_NC}"
        for i in "${!TEST_ERRORS[@]}"; do
            echo -e "  ${TEST_YELLOW}$((i+1)). ${TEST_ERRORS[$i]}${TEST_NC}"
        done
        echo ""
    fi
    
    if [ $TEST_FAILED -eq 0 ]; then
        echo -e "${TEST_GREEN}🎉 所有测试通过！${TEST_NC}"
        return 0
    else
        echo -e "${TEST_RED}❌ 部分测试失败！${TEST_NC}"
        return 1
    fi
}
