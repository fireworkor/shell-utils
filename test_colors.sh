#!/bin/bash
# 测试颜色输出

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib/common.sh"

echo -e "=== 颜色测试 ==="
echo ""

echo "测试 1: 使用 echo -e"
echo -e "${RED}红色${NC} ${GREEN}绿色${NC} ${YELLOW}黄色${NC} ${BLUE}蓝色${NC} ${CYAN}青色${NC}"
echo ""

echo "测试 2: 使用 printf"
printf "${RED}红色${NC} ${GREEN}绿色${NC} ${YELLOW}黄色${NC} ${BLUE}蓝色${NC} ${CYAN}青色${NC}\n"
echo ""

echo "测试 3: print_header 函数"
print_header "测试标题"
echo ""

echo "测试 4: 检查变量值"
echo "RED: $(printf "%q" "$RED")"
echo "GREEN: $(printf "%q" "$GREEN")"
echo "YELLOW: $(printf "%q" "$YELLOW")"
echo "NC: $(printf "%q" "$NC")"
echo ""

echo "如果上面看到彩色文字，说明修复成功！"
