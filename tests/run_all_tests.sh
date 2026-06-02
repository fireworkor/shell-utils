#!/bin/bash
# 运行所有测试

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT" || exit 1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  运行所有测试${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 查找所有测试文件 (只查找 test_ 开头的文件)
test_files=()
while IFS= read -r -d '' file; do
    # 跳过 test_helper.sh 和 run_all_tests.sh
    if [[ "$file" != *"test_helper.sh" ]] && [[ "$file" != *"run_all_tests.sh" ]]; then
        test_files+=("$file")
    fi
done < <(find "$SCRIPT_DIR" -name "test_*.sh" -type f -print0)

echo "找到 ${#test_files[@]} 个测试文件"
echo ""

# 运行每个测试文件
for test_file in "${test_files[@]}"; do
    echo -e "${YELLOW}运行: $test_file${NC}"
    chmod +x "$test_file"
    
    # 运行测试
    if bash "$test_file"; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo ""
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  总体测试摘要${NC}"
echo -e "${BLUE}========================================${NC}"
echo "测试文件: $TOTAL_TESTS"
echo -e "${GREEN}通过: $PASSED_TESTS${NC}"
if [ $FAILED_TESTS -gt 0 ]; then
    echo -e "${RED}失败: $FAILED_TESTS${NC}"
else
    echo -e "${GREEN}失败: $FAILED_TESTS${NC}"
fi
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 所有测试通过！${NC}"
    exit 0
else
    echo -e "${RED}❌ 部分测试失败！${NC}"
    exit 1
fi
