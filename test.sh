#!/bin/bash

# =========================================
# 测试脚本 - 验证脚本语法和功能
# =========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

test_result() {
    local test_name=$1
    local status=$2
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

echo "========================================"
echo "Shell 工具 - 测试套件"
echo "========================================"
echo ""

echo "1. 测试脚本语法..."
echo "----------------------------------------"

for script in "$SCRIPT_DIR"/*/*.sh "$SCRIPT_DIR"/*.sh; do
    if [ -f "$script" ]; then
        script_name=$(basename "$script")
        
        if bash -n "$script" 2>/dev/null; then
            test_result "$script_name" "PASS"
        else
            test_result "$script_name" "FAIL"
        fi
    fi
done

echo ""
echo "2. 测试函数库..."
echo "----------------------------------------"

if [ -f "$SCRIPT_DIR/lib/common.sh" ]; then
    if source "$SCRIPT_DIR/lib/common.sh" 2>/dev/null; then
        test_result "common.sh 加载" "PASS"
        
        if declare -f detect_os >/dev/null; then
            test_result "detect_os 函数" "PASS"
        else
            test_result "detect_os 函数" "FAIL"
        fi
        
        if declare -f check_root >/dev/null; then
            test_result "check_root 函数" "PASS"
        else
            test_result "check_root 函数" "FAIL"
        fi
        
        if declare -f print_success >/dev/null; then
            test_result "print_success 函数" "PASS"
        else
            test_result "print_success 函数" "FAIL"
        fi
        
        if declare -f backup_file >/dev/null; then
            test_result "backup_file 函数" "PASS"
        else
            test_result "backup_file 函数" "FAIL"
        fi
        
        if declare -f validate_version >/dev/null; then
            test_result "validate_version 函数" "PASS"
        else
            test_result "validate_version 函数" "FAIL"
        fi
        
        if declare -f download_with_retry >/dev/null; then
            test_result "download_with_retry 函数" "PASS"
        else
            test_result "download_with_retry 函数" "FAIL"
        fi
        
        if declare -f get_installed_version >/dev/null; then
            test_result "get_installed_version 函数" "PASS"
        else
            test_result "get_installed_version 函数" "FAIL"
        fi
    else
        test_result "common.sh 加载" "FAIL"
    fi
else
    test_result "common.sh 存在" "FAIL"
fi

echo ""
echo "3. 测试配置文件..."
echo "----------------------------------------"

if [ -f "$SCRIPT_DIR/config/versions.conf" ]; then
    test_result "versions.conf 存在" "PASS"
    
    if grep -q "NGINX_VERSION=" "$SCRIPT_DIR/config/versions.conf"; then
        test_result "NGINX_VERSION 配置" "PASS"
    else
        test_result "NGINX_VERSION 配置" "FAIL"
    fi
else
    test_result "versions.conf 存在" "FAIL"
fi

if [ -f "$SCRIPT_DIR/lib/config.sh" ]; then
    test_result "config.sh 存在" "PASS"
fi

echo ""
echo "4. 测试主脚本..."
echo "----------------------------------------"

if [ -f "$SCRIPT_DIR/main.sh" ]; then
    test_result "main.sh 存在" "PASS"
    
    if bash -n "$SCRIPT_DIR/main.sh" 2>/dev/null; then
        test_result "main.sh 语法" "PASS"
    else
        test_result "main.sh 语法" "FAIL"
    fi
fi

echo ""
echo "5. 测试模块完整性..."
echo "----------------------------------------"

required_modules=(
    "nginx/nginx.sh:Web 服务器"
    "apache/apache.sh:Web 服务器"
    "php/php.sh:编程语言"
    "mysql/mysql.sh:数据库"
    "mariadb/mariadb.sh:数据库"
    "redis/redis.sh:缓存"
    "docker/docker.sh:容器"
)

for module in "${required_modules[@]}"; do
    path="${module%%:*}"
    name="${module##*:}"
    
    if [ -f "$SCRIPT_DIR/$path" ]; then
        test_result "$name 模块" "PASS"
    else
        test_result "$name 模块" "FAIL"
    fi
done

echo ""
echo "========================================"
echo "测试结果汇总"
echo "========================================"
echo -e "总测试数: $TOTAL_TESTS"
echo -e "${GREEN}通过: $PASSED_TESTS${NC}"
echo -e "${RED}失败: $FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}所有测试通过！${NC}"
    exit 0
else
    echo -e "${RED}有 $FAILED_TESTS 个测试失败${NC}"
    exit 1
fi
