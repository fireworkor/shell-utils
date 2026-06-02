#!/bin/bash
# ShellCheck 检查脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT" || exit 1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "  运行 ShellCheck 检查"
echo "=========================================="
echo ""

# 检查 shellcheck 是否安装
if ! command -v shellcheck &> /dev/null; then
    echo -e "${YELLOW}ShellCheck 未安装${NC}"
    echo "请先安装 ShellCheck:"
    echo "  Debian/Ubuntu: sudo apt-get install shellcheck"
    echo "  RHEL/CentOS: sudo yum install shellcheck"
    echo "  macOS: brew install shellcheck"
    exit 1
fi

# 查找所有 Shell 脚本
SHELL_SCRIPTS=()
while IFS= read -r -d '' file; do
    SHELL_SCRIPTS+=("$file")
done < <(find . -name "*.sh" -type f -print0)

echo "找到 ${#SHELL_SCRIPTS[@]} 个 Shell 脚本"
echo ""

# 运行检查
TOTAL_ERRORS=0
TOTAL_WARNINGS=0
TOTAL_INFO=0

for script in "${SHELL_SCRIPTS[@]}"; do
    # 跳过 node_modules、.git、uploads 等目录
    if [[ "$script" == *node_modules* ]] || \
       [[ "$script" == *.git* ]] || \
       [[ "$script" == *.uploads* ]] || \
       [[ "$script" == *vendor* ]]; then
        continue
    fi
    
    # 运行检查
    echo "检查 $script ..."
    RESULT=$(shellcheck -f gcc "$script" 2>&1)
    if [ -n "$RESULT" ]; then
        echo "$RESULT"
        while IFS= read -r line; do
            if [[ "$line" == *"error:"* ]]; then
                TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
            elif [[ "$line" == *"warning:"* ]]; then
                TOTAL_WARNINGS=$((TOTAL_WARNINGS + 1))
            elif [[ "$line" == *"info:"* ]]; then
                TOTAL_INFO=$((TOTAL_INFO + 1))
            fi
        done <<< "$RESULT"
    fi
done

echo ""
echo "=========================================="
echo "  检查结果"
echo "=========================================="
echo "错误 (Error):   $TOTAL_ERRORS"
echo "警告 (Warning): $TOTAL_WARNINGS"
echo "信息 (Info):    $TOTAL_INFO"
echo ""

if [ "$TOTAL_ERRORS" -gt 0 ]; then
    echo -e "${RED}❌ 存在错误，请修复后重试${NC}"
    exit 1
elif [ "$TOTAL_WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  存在警告，建议修复${NC}"
    exit 0
else
    echo -e "${GREEN}✅ 检查通过，没有发现问题${NC}"
    exit 0
fi
