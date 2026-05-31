#!/bin/bash

# 工具函数使用示例

# 引入工具函数
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

echo "==================================="
echo "Shell 工具函数示例"
echo "==================================="
echo

# 示例 1: 使用日志函数
echo "--- 示例 1: 日志函数 ---"
log_info "这是一条信息日志"
log_success "这是一条成功日志"
log_warning "这是一条警告日志"
log_error "这是一条错误日志"
echo

# 示例 2: 显示系统信息
echo "--- 示例 2: 系统信息 ---"
show_system_info
echo

# 示例 3: 检查网络连接
echo "--- 示例 3: 网络连接检查 ---"
check_internet
echo

# 示例 4: 字符串处理
echo "--- 示例 4: 字符串处理 ---"
str="  Hello, World!  "
echo "原始字符串: '$str'"
echo "去除空格后: '$(trim "$str")'"
echo "转大写: '$(to_uppercase "$str")'"
echo "转小写: '$(to_lowercase "$str")'"
echo

# 示例 5: 检查命令是否存在
echo "--- 示例 5: 检查命令 ---"
command_exists "ls"
command_exists "nonexistent_command_12345" 2>/dev/null || true
echo

# 示例 6: 统计文件
echo "--- 示例 6: 目录统计 ---"
count_files .
echo

# 示例 7: 检查磁盘使用
echo "--- 示例 7: 磁盘使用 ---"
check_disk_usage 80
echo

# 示例 8: 进度条演示
echo "--- 示例 8: 进度条 ---"
for i in {1..10}; do
    show_progress $i 10
    sleep 0.1
done
echo

# 示例 9: 创建测试文件并备份
echo "--- 示例 9: 文件备份 ---"
test_file="test_example.txt"
echo "这是一个测试文件" > "$test_file"
log_info "已创建测试文件: $test_file"
create_backup "$test_file"
echo

# 清理测试文件
echo "--- 清理测试文件 ---"
rm -f "$test_file" "$test_file".*.bak
log_success "测试文件已清理"
echo

echo "==================================="
echo "所有示例运行完成！"
echo "==================================="
